import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import '../../../shared/services/file_upload_service.dart';
import '../../../shared/services/instructor_class_service.dart';
import '../../../shared/services/in_app_notification_service.dart';

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
  final RxString announcementImageUrl =
      ''.obs; // For existing images from Firestore
  final RxString originalImageUrl =
      ''.obs; // Store original image URL when editing (for restore)
  final Rx<PlatformFile?> selectedImageFile = Rx<PlatformFile?>(
    null,
  ); // For newly selected file
  final RxBool isUploadingImage = false.obs;
  final RxBool imageRemovedByUser =
      false.obs; // Track if user clicked X to remove image

  // Section selection
  final RxList<String> availableSections = <String>[].obs;
  final RxMap<String, bool> selectedClasses = <String, bool>{}.obs;
  final RxBool isLoadingSections = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAnnouncements();
    loadInstructor();
    loadInstructorSections();
    _fileUploadService.initialize();
  }

  // Load instructor's assigned sections
  Future<void> loadInstructorSections() async {
    try {
      isLoadingSections.value = true;
      final sectionCodes =
          await InstructorClassService.getInstructorSectionCodes();

      if (sectionCodes.isNotEmpty) {
        availableSections.value = sectionCodes;
        selectedClasses.value = Map.fromEntries(
          sectionCodes.map((e) => MapEntry(e, true)), // Select all by default
        );
      } else {
        // Fallback to static classes if no assignments found
        final fallbackClasses = InstructorClassService.getFallbackClasses();
        availableSections.value = fallbackClasses;
        selectedClasses.value = Map.fromEntries(
          fallbackClasses.map((e) => MapEntry(e, true)),
        );
      }
    } catch (e) {
      print('Error loading instructor sections: $e');
      // Fallback to static classes on error
      final fallbackClasses = InstructorClassService.getFallbackClasses();
      availableSections.value = fallbackClasses;
      selectedClasses.value = Map.fromEntries(
        fallbackClasses.map((e) => MapEntry(e, true)),
      );
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
              'imageUrl':
                  data['imageUrl'] ?? '', // Include image URL for editing
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
    announcementImageUrl.value = '';
    originalImageUrl.value = '';
    selectedImageFile.value = null;
    imageRemovedByUser.value = false; // Reset removal flag
    // Reset section selection to all selected
    selectedClasses.updateAll((key, value) => true);
  }

  // Pick image for announcement (without uploading)
  Future<void> pickImage() async {
    try {
      // Pick image file
      final files = await _fileUploadService.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (files != null && files.isNotEmpty) {
        selectedImageFile.value = files.first;
        imageRemovedByUser.value =
            false; // Reset removal flag when new image is selected
        // Don't clear existing URL - keep it in case user wants to restore
        // The preview will show the new selected file instead
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Remove announcement image (explicitly called by user)
  // This hides the preview but doesn't delete from database until save
  void removeImage() {
    selectedImageFile.value = null;
    announcementImageUrl.value = ''; // Clear current image preview
    imageRemovedByUser.value = true; // Mark that user wants to remove it
    // Keep originalImageUrl so we know there was an image (for save logic)
  }

  // Get preview image URL (for display)
  String? get previewImageUrl {
    // If user explicitly removed the image, don't show it
    if (imageRemovedByUser.value) {
      return null;
    }
    // Priority 1: Show newly selected file (if any)
    if (selectedImageFile.value != null &&
        selectedImageFile.value!.bytes != null) {
      // Convert bytes to data URL for preview
      final bytes = selectedImageFile.value!.bytes!;
      final base64 = base64Encode(bytes);
      return 'data:image/${selectedImageFile.value!.extension ?? 'jpg'};base64,$base64';
    }
    // Priority 2: Show existing image URL (from Firestore or original)
    if (announcementImageUrl.value.isNotEmpty) {
      return announcementImageUrl.value;
    }
    // Priority 3: If editing and we have original, show it
    if (isEditMode.value && originalImageUrl.value.isNotEmpty) {
      return originalImageUrl.value;
    }
    return null;
  }

  // Show edit announcement form
  void showEditAnnouncement(Map<String, dynamic> announcement) {
    isEditMode.value = true;
    editingAnnouncementId.value = announcement['id'];
    titleController.text = announcement['title'];
    contentController.text = announcement['content'];
    pinToTop.value = announcement['pinned'];
    urgent.value = announcement['urgent'];

    // Handle image - ensure it displays when editing
    final existingImageUrl = announcement['imageUrl']?.toString().trim() ?? '';
    // Set both values to ensure the image displays
    announcementImageUrl.value = existingImageUrl;
    originalImageUrl.value =
        existingImageUrl; // Store original for potential restore
    selectedImageFile.value = null; // Clear any selected file when editing
    imageRemovedByUser.value = false; // Reset removal flag when editing starts

    // Force update to ensure UI reacts to image URL change
    announcementImageUrl.refresh();

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
        snackPosition: SnackPosition.BOTTOM,
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
        // Upload image if a new file is selected
        String? finalImageUrl =
            announcementImageUrl.value.isNotEmpty
                ? announcementImageUrl
                    .value // Preserve existing image URL
                : null;

        if (selectedImageFile.value != null) {
          try {
            isUploadingImage.value = true;
            final response = await _fileUploadService.uploadFile(
              file: selectedImageFile.value!,
              folder: 'greenquest/announcements',
            );

            if (response != null) {
              finalImageUrl = response.url; // Use new uploaded image
            } else {
              throw Exception('Failed to upload image');
            }
          } catch (e) {
            Get.snackbar(
              'Error',
              'Failed to upload image: $e',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
            isUploadingImage.value = false;
            return; // Don't update announcement if image upload fails
          } finally {
            isUploadingImage.value = false;
          }
        }

        // Get selected sections
        final selectedSections = getSelectedSections();

        // Update existing announcement
        final updateData = {
          'title': titleController.text.trim(),
          'content': contentController.text.trim(),
          'pinned': pinToTop.value,
          'urgent': urgent.value,
          'selectedClasses': selectedSections, // Update selected sections
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Handle image update
        if (selectedImageFile.value != null && finalImageUrl != null) {
          // New image was uploaded - update with new URL
          updateData['imageUrl'] = finalImageUrl;
          imageRemovedByUser.value =
              false; // Reset removal flag since we have new image
        } else if (imageRemovedByUser.value &&
            originalImageUrl.value.isNotEmpty) {
          // User explicitly removed the image (clicked X) - delete from Firestore
          updateData['imageUrl'] = FieldValue.delete();
        } else if (selectedImageFile.value == null &&
            announcementImageUrl.value.isNotEmpty) {
          // No new file selected, but existing image URL is preserved - keep it
          updateData['imageUrl'] = announcementImageUrl.value;
          imageRemovedByUser.value = false; // Reset removal flag
        } else if (selectedImageFile.value == null &&
            announcementImageUrl.value.isEmpty &&
            originalImageUrl.value.isEmpty) {
          // No image was ever set, don't update the field
        }

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

        // Upload image if a new file is selected
        String? finalImageUrl =
            announcementImageUrl.value.isNotEmpty
                ? announcementImageUrl.value
                : null;

        if (selectedImageFile.value != null) {
          try {
            isUploadingImage.value = true;
            final response = await _fileUploadService.uploadFile(
              file: selectedImageFile.value!,
              folder: 'greenquest/announcements',
            );

            if (response != null) {
              finalImageUrl = response.url;
            } else {
              throw Exception('Failed to upload image');
            }
          } catch (e) {
            Get.snackbar(
              'Error',
              'Failed to upload image: $e',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
            isUploadingImage.value = false;
            return; // Don't create announcement if image upload fails
          } finally {
            isUploadingImage.value = false;
          }
        }

        // Get selected sections
        final selectedSections = getSelectedSections();

        // Create new announcement
        final announcementData = {
          'title': titleController.text.trim(),
          'content': contentController.text.trim(),
          'pinned': pinToTop.value,
          'urgent': urgent.value,
          'views': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'instructorId': user.uid,
          'instructorName': finalInstructorName,
          'instructorProfileUrl': finalInstructorProfileUrl,
          'selectedClasses': selectedSections, // Store selected sections
          // Add image URL if available
          if (finalImageUrl != null && finalImageUrl.isNotEmpty)
            'imageUrl': finalImageUrl,
          // Add assigned semester data
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
            if (finalImageUrl != null && finalImageUrl.isNotEmpty)
              'imageUrl': finalImageUrl,
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

  /// Get instructor's assigned semester (preferably active one)
  Future<Map<String, dynamic>?> _getInstructorSemester(
    String instructorId,
  ) async {
    try {
      final instructorDoc =
          await _firestore.collection('instructors').doc(instructorId).get();

      if (!instructorDoc.exists) {
        return null;
      }

      final instructorData = instructorDoc.data();
      final assignedSemesters =
          (instructorData?['assignedSemesters'] as List<dynamic>?) ?? [];

      if (assignedSemesters.isEmpty) {
        return null;
      }

      // Prefer active semester, otherwise get the most recent one
      Map<String, dynamic>? activeSemester;
      Map<String, dynamic>? mostRecentSemester;
      Timestamp? mostRecentTimestamp;

      for (var sem in assignedSemesters) {
        final semesterData = sem as Map<String, dynamic>;
        final isActive = semesterData['isActive'] ?? false;
        final assignedAt = semesterData['assignedAt'];

        if (isActive && activeSemester == null) {
          activeSemester = semesterData;
        }

        // Track most recent by assignedAt timestamp
        if (assignedAt is Timestamp) {
          if (mostRecentTimestamp == null ||
              assignedAt.compareTo(mostRecentTimestamp) > 0) {
            mostRecentTimestamp = assignedAt;
            mostRecentSemester = semesterData;
          }
        }
      }

      // Return active semester if found, otherwise most recent
      return activeSemester ?? mostRecentSemester;
    } catch (e) {
      print('Error getting instructor semester: $e');
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
