import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import '../../../shared/services/file_upload_service.dart';
import '../../../shared/services/instructor_class_service.dart';
import '../../../shared/services/in_app_notification_service.dart';
import '../helpers/announcement_image_limiter.dart';

class AnnouncementScreenController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable variables
  final RxBool showCreate = false.obs;
  final RxList<Map<String, dynamic>> announcements =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxString instructorName = ''.obs;
  final RxString instructorProfileUrl = ''.obs;

  // Edit mode
  final RxBool isEditMode = false.obs;
  final RxString editingAnnouncementId = ''.obs;

  // Form controllers
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final RxBool pinToTop = false.obs;
  final RxBool urgent = false.obs;

  // Image upload
  final FileUploadService _fileUploadService = FileUploadService();

  /// Newly picked files not yet uploaded.
  final RxList<PlatformFile> selectedImageFiles = <PlatformFile>[].obs;

  /// URLs already persisted in Firestore (populated when editing).
  final RxList<String> existingImageUrls = <String>[].obs;
  final RxBool isUploadingImage = false.obs;

  /// Total number of images (existing + newly selected).
  int get totalImageCount =>
      existingImageUrls.length + selectedImageFiles.length;

  /// Whether more images can be added according to [AnnouncementImageLimiter].
  bool get canAddMoreImages =>
      AnnouncementImageLimiter.canAddMore(totalImageCount);

  // Section selection
  final RxList<String> availableSections = <String>[].obs;
  final RxMap<String, bool> selectedClasses = <String, bool>{}.obs;
  final RxBool isLoadingSections = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Load data once when controller is first created (when screen is first shown)
    // This is NOT auto-loading on every lifecycle change - it only happens once
    loadInstructor(); // Keep lightweight instructor loading
    loadAnnouncements(); // Load announcements once when screen first appears
    loadInstructorSections(); // Load sections once when screen first appears
    _fileUploadService.initialize();
  }

  // Load instructor's assigned sections (only from admin assignments)
  Future<void> loadInstructorSections() async {
    try {
      isLoadingSections.value = true;
      final sectionCodes =
          await InstructorClassService.getInstructorSectionCodes();

      // Only use sections assigned by admin - no fallback to hardcoded classes
      if (sectionCodes.isNotEmpty) {
        availableSections.value = sectionCodes;
        selectedClasses.value = Map.fromEntries(
          sectionCodes.map((e) => MapEntry(e, true)), // Select all by default
        );
      } else {
        // If no assignments found, show empty list (new instructors won't see any sections until admin assigns them)
        availableSections.value = [];
        selectedClasses.value = {};
      }
    } catch (e) {
      print('Error loading instructor sections: $e');
      // On error, also show empty list - no fallback to hardcoded classes
      availableSections.value = [];
      selectedClasses.value = {};
    } finally {
      isLoadingSections.value = false;
    }
  }

  // Toggle section selection
  void toggleSectionSelection(String section) {
    if (selectedClasses.containsKey(section)) {
      selectedClasses[section] = !selectedClasses[section]!;
    }
  }

  // Get selected sections list
  List<String> getSelectedSections() {
    return selectedClasses.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  // Get selected sections display text
  String getSelectedSectionsText() {
    final selected = getSelectedSections();
    if (selected.isEmpty) {
      return 'Select sections';
    } else if (selected.length == 1) {
      return selected.first;
    } else if (selected.length == availableSections.length) {
      return 'All sections';
    } else {
      return '${selected.length} sections selected';
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    contentController.dispose();
    super.onClose();
  }

  // Load announcements from Firestore
  Future<void> loadAnnouncements() async {
    try {
      isLoading.value = true;
      final user = _auth.currentUser;
      if (user == null) return;

      final QuerySnapshot snapshot =
          await _firestore
              .collection('instructors')
              .doc(user.uid)
              .collection('announcements')
              .orderBy('createdAt', descending: true)
              .get();

      announcements.value =
          snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'title': data['title'] ?? '',
              'content': data['content'] ?? '',
              'date': _formatDate(data['createdAt']),
              'views': data['views'] ?? 0,
              'pinned': data['pinned'] ?? false,
              'urgent': data['urgent'] ?? false,
              'createdAt': data['createdAt'],
              'imageUrls': _extractImageUrls(data),
              'selectedClasses':
                  data['selectedClasses'] ?? [], // Include selected classes
            };
          }).toList();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load announcements: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Show create announcement form
  void showCreateAnnouncement() {
    showCreate.value = true;
  }

  // Cancel create announcement
  void cancelCreate() {
    showCreate.value = false;
    isEditMode.value = false;
    editingAnnouncementId.value = '';
    titleController.clear();
    contentController.clear();
    pinToTop.value = false;
    urgent.value = false;
    selectedImageFiles.value = [];
    existingImageUrls.value = [];
    // Reset section selection to all selected
    selectedClasses.updateAll((key, value) => true);
  }

  /// Pick one or more images to attach to the announcement.
  /// Respects the [AnnouncementImageLimiter] cap and silently truncates
  /// excess selections rather than showing a limit message in the UI.
  Future<void> pickImages() async {
    if (!canAddMoreImages) return;
    try {
      final files = await _fileUploadService.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (files != null && files.isNotEmpty) {
        final allowed = AnnouncementImageLimiter.remaining(totalImageCount);
        final toAdd = files.take(allowed).toList();
        selectedImageFiles.addAll(toAdd);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick images: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Remove a newly selected (not yet uploaded) file by its list index.
  void removeSelectedFile(int index) {
    if (index >= 0 && index < selectedImageFiles.length) {
      selectedImageFiles.removeAt(index);
    }
  }

  /// Remove an already-persisted image URL by its list index (edit mode).
  void removeExistingUrl(int index) {
    if (index >= 0 && index < existingImageUrls.length) {
      existingImageUrls.removeAt(index);
    }
  }

  // Show edit announcement form
  void showEditAnnouncement(Map<String, dynamic> announcement) {
    isEditMode.value = true;
    editingAnnouncementId.value = announcement['id'];
    titleController.text = announcement['title'];
    contentController.text = announcement['content'];
    pinToTop.value = announcement['pinned'];
    urgent.value = announcement['urgent'];

    // Populate existing image URLs (supports both legacy single and new multi format)
    existingImageUrls.value = List<String>.from(
      announcement['imageUrls'] as List? ?? [],
    );
    selectedImageFiles.value = [];

    // Load selected sections if available
    if (announcement['selectedClasses'] != null) {
      final savedSections = List<String>.from(announcement['selectedClasses']);
      // Update selection to match saved sections
      selectedClasses.updateAll((key, value) => savedSections.contains(key));
      // Ensure all saved sections are in the map (in case sections were added)
      for (var section in savedSections) {
        if (!selectedClasses.containsKey(section)) {
          selectedClasses[section] = true;
        }
      }
    } else {
      // If no saved sections, select all by default
      selectedClasses.updateAll((key, value) => true);
    }

    showCreate.value = true;
  }

  // Post new announcement or update existing one
  Future<void> postAnnouncement() async {
    if (titleController.text.trim().isEmpty ||
        contentController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill in both title and content',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // Validate section selection
    final selectedSections = getSelectedSections();
    if (selectedSections.isEmpty) {
      Get.snackbar(
        'Error',
        'Please select at least one section',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;
      final user = _auth.currentUser;
      if (user == null) {
        Get.snackbar(
          'Error',
          'User not authenticated',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      if (isEditMode.value) {
        // Upload any newly selected images
        final List<String> newImageUrls = [];
        if (selectedImageFiles.isNotEmpty) {
          try {
            isUploadingImage.value = true;
            for (final file in List<PlatformFile>.from(selectedImageFiles)) {
              final response = await _fileUploadService.uploadFile(
                file: file,
                folder: 'greenquest/announcements',
              );
              if (response != null) {
                newImageUrls.add(response.url);
              } else {
                throw Exception('Failed to upload one or more images');
              }
            }
          } catch (e) {
            Get.snackbar(
              'Error',
              'Failed to upload images: $e',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
            isUploadingImage.value = false;
            return;
          } finally {
            isUploadingImage.value = false;
          }
        }

        final List<String> allImageUrls = [
          ...existingImageUrls,
          ...newImageUrls,
        ];

        // Get selected sections
        final selectedSections = getSelectedSections();

        // Update existing announcement
        final updateData = <String, dynamic>{
          'title': titleController.text.trim(),
          'content': contentController.text.trim(),
          'pinned': pinToTop.value,
          'urgent': urgent.value,
          'selectedClasses': selectedSections,
          'updatedAt': FieldValue.serverTimestamp(),
          'imageUrls':
              allImageUrls.isEmpty ? FieldValue.delete() : allImageUrls,
        };

        await _firestore
            .collection('instructors')
            .doc(user.uid)
            .collection('announcements')
            .doc(editingAnnouncementId.value)
            .update(updateData);

        Get.snackbar(
          'Success',
          'Announcement updated successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        // Get instructor's assigned semester
        final semester = await _getInstructorSemester(user.uid);

        // Get instructor profile data to ensure we have the latest profile URL
        String finalInstructorName =
            instructorName.value.isNotEmpty
                ? instructorName.value
                : (user.displayName ?? 'Unknown Instructor');
        String finalInstructorProfileUrl = instructorProfileUrl.value;

        // Fetch instructor data directly to ensure we have the latest profile URL
        try {
          final instructorDoc =
              await _firestore.collection('instructors').doc(user.uid).get();
          if (instructorDoc.exists) {
            final instructorData = instructorDoc.data() as Map<String, dynamic>;
            finalInstructorName = instructorData['name'] ?? finalInstructorName;
            // Try profileUrl first, then fall back to profileImageUrl for backward compatibility
            finalInstructorProfileUrl =
                instructorData['profileUrl'] ??
                instructorData['profileImageUrl'] ??
                finalInstructorProfileUrl;
          }
        } catch (e) {
          print('Error fetching instructor profile: $e');
          // Continue with existing values if fetch fails
        }

        // Upload all newly selected images
        final List<String> newImageUrls = [];
        if (selectedImageFiles.isNotEmpty) {
          try {
            isUploadingImage.value = true;
            for (final file in List<PlatformFile>.from(selectedImageFiles)) {
              final response = await _fileUploadService.uploadFile(
                file: file,
                folder: 'greenquest/announcements',
              );
              if (response != null) {
                newImageUrls.add(response.url);
              } else {
                throw Exception('Failed to upload one or more images');
              }
            }
          } catch (e) {
            Get.snackbar(
              'Error',
              'Failed to upload images: $e',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
            isUploadingImage.value = false;
            return;
          } finally {
            isUploadingImage.value = false;
          }
        }

        // Get selected sections
        final selectedSections = getSelectedSections();

        // Create new announcement
        final announcementData = <String, dynamic>{
          'title': titleController.text.trim(),
          'content': contentController.text.trim(),
          'pinned': pinToTop.value,
          'urgent': urgent.value,
          'views': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'instructorId': user.uid,
          'instructorName': finalInstructorName,
          'instructorProfileUrl': finalInstructorProfileUrl,
          'selectedClasses': selectedSections,
          if (newImageUrls.isNotEmpty) 'imageUrls': newImageUrls,
          if (semester != null) 'assignedSemester': semester,
        };

        // Add to Firestore
        final docRef = await _firestore
            .collection('instructors')
            .doc(user.uid)
            .collection('announcements')
            .add(announcementData);

        // Send notification to selected sections
        await InAppNotificationService.createSectionNotification(
          type: 'announcement',
          instructorId: user.uid,
          instructorName: finalInstructorName,
          itemId: docRef.id,
          title: titleController.text.trim(),
          targetSections: selectedSections,
          description: contentController.text.trim(),
          metadata: {
            'announcementId': docRef.id,
            'urgent': urgent.value,
            'pinned': pinToTop.value,
            if (newImageUrls.isNotEmpty) 'imageUrls': newImageUrls,
          },
        );

        Get.snackbar(
          'Success',
          'Announcement posted and notifications sent!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }

      // Clear form and hide create form
      cancelCreate();

      // Reload announcements
      await loadAnnouncements();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to ${isEditMode.value ? 'update' : 'post'} announcement: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Update announcement views
  Future<void> updateViews(String announcementId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('announcements')
          .doc(announcementId)
          .update({'views': FieldValue.increment(1)});

      // Update local data
      final index = announcements.indexWhere(
        (announcement) => announcement['id'] == announcementId,
      );
      if (index != -1) {
        announcements[index]['views'] =
            (announcements[index]['views'] as int) + 1;
        announcements.refresh();
      }
    } catch (e) {
      print('Error updating views: $e');
    }
  }

  // Delete announcement
  Future<void> deleteAnnouncement(String announcementId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('announcements')
          .doc(announcementId)
          .delete();

      // Remove from local list
      announcements.removeWhere(
        (announcement) => announcement['id'] == announcementId,
      );

      Get.snackbar(
        'Success',
        'Announcement deleted successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete announcement: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Toggle pin status
  Future<void> togglePin(String announcementId, bool currentPinStatus) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('announcements')
          .doc(announcementId)
          .update({'pinned': !currentPinStatus});

      // Update local data
      final index = announcements.indexWhere(
        (announcement) => announcement['id'] == announcementId,
      );
      if (index != -1) {
        announcements[index]['pinned'] = !currentPinStatus;
        announcements.refresh();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update pin status: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Helper method to format date
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';

    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return 'Unknown date';
    }

    return '${date.month}/${date.day}/${date.year}';
  }

  /// Extracts image URLs from a Firestore document, supporting both the new
  /// multi-image format (`imageUrls` list) and the legacy single-image format
  /// (`imageUrl` string) for backward compatibility.
  List<String> _extractImageUrls(Map<String, dynamic> data) {
    if (data['imageUrls'] != null) {
      return List<String>.from(data['imageUrls'] as List);
    }
    final legacy = data['imageUrl']?.toString().trim() ?? '';
    return legacy.isNotEmpty ? [legacy] : [];
  }

  /// Get the currently active period that this instructor is assigned to.
  ///
  /// Queries the `periods` collection for the globally active period, then
  /// verifies the instructor is assigned to it via their `assignedPeriods`
  /// array. Returns clean period metadata to stamp on the created document,
  /// or null if no active period assignment exists.
  Future<Map<String, dynamic>?> _getInstructorSemester(
    String instructorId,
  ) async {
    try {
      // Step 1 – Find the globally active period
      final activePeriodSnapshot =
          await _firestore
              .collection('periods')
              .where('isActive', isEqualTo: true)
              .limit(1)
              .get();

      if (activePeriodSnapshot.docs.isEmpty) return null;

      final activePeriodDoc = activePeriodSnapshot.docs.first;
      final activePeriodId = activePeriodDoc.id;
      final activePeriodData = activePeriodDoc.data();

      // Step 2 – Verify the instructor is assigned to this period
      final instructorDoc =
          await _firestore.collection('instructors').doc(instructorId).get();

      if (!instructorDoc.exists) return null;

      final instructorData = instructorDoc.data() as Map<String, dynamic>;
      final assignedPeriods =
          (instructorData['assignedPeriods'] as List<dynamic>?) ?? [];

      final isAssigned = assignedPeriods.any(
        (p) =>
            (p as Map<String, dynamic>)['periodId']?.toString() ==
            activePeriodId,
      );

      if (!isAssigned) return null;

      // Step 3 – Return period metadata to stamp on the created document
      return {
        'periodId': activePeriodId,
        'semesterName': activePeriodData['semesterName'] ?? '',
        'type': activePeriodData['type'] ?? '',
        'isActive': true,
      };
    } catch (e) {
      debugPrint(
        'AnnouncementController: Error getting instructor active period: $e',
      );
      return null;
    }
  }

  /// Load instructor name and profile image using FirebaseAuth user.uid
  Future<void> loadInstructor() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        instructorName.value = 'No user logged in';
        instructorProfileUrl.value = '';
        return;
      }

      final doc =
          await FirebaseFirestore.instance
              .collection('instructors')
              .doc(user.uid) // 👈 use user.uid here
              .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        instructorName.value = data['name'] ?? 'Unknown Instructor';
        // Try profileUrl first, then fall back to profileImageUrl for backward compatibility
        instructorProfileUrl.value =
            data['profileUrl'] ?? data['profileImageUrl'] ?? '';
      } else {
        instructorName.value = 'Instructor not found';
        instructorProfileUrl.value = '';
      }
    } catch (e) {
      instructorName.value = 'Error loading name';
      instructorProfileUrl.value = '';
    }
  }
}
