import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserAnnouncementController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable variables
  final RxList<Map<String, dynamic>> announcements =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxString selectedInstructorId = ''.obs;
  final RxString selectedInstructorName = ''.obs;
  final RxInt unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    getSelectedInstructor();
  }

  // Get the instructor that the current user has selected
  Future<void> getSelectedInstructor() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        log('No user logged in');
        return;
      }

      log('Getting selected instructor for user: ${user.uid}');

      // Get user document to find selected instructor
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String instructorId = userData['selectedInstructorId'] ?? '';
        String instructorName = userData['selectedInstructorName'] ?? '';

        log(
          'User data: instructorId=$instructorId, instructorName=$instructorName',
        );

        selectedInstructorId.value = instructorId;
        selectedInstructorName.value = instructorName;

        if (instructorId.isNotEmpty) {
          // Verify instructor exists before loading announcements
          await verifyAndLoadAnnouncements(instructorId, instructorName);
        } else {
          log('No instructor selected for this user');
        }
      } else {
        log('User document does not exist');
      }
    } catch (e) {
      log('Error getting selected instructor: $e');
    }
  }

  // Verify instructor exists and load announcements
  Future<void> verifyAndLoadAnnouncements(
    String instructorId,
    String instructorName,
  ) async {
    try {
      log('Verifying instructor exists: $instructorId');

      // Check if instructor document exists
      DocumentSnapshot instructorDoc =
          await _firestore.collection('instructors').doc(instructorId).get();

      if (instructorDoc.exists) {
        log('Instructor verified, loading announcements...');
        await loadAnnouncements(instructorId);
      } else {
        log('Instructor document does not exist: $instructorId');
        // Clear the selection if instructor doesn't exist
        selectedInstructorId.value = '';
        selectedInstructorName.value = '';

        Get.snackbar(
          'Error',
          'Selected instructor no longer exists. Please select another instructor.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      log('Error verifying instructor: $e');
    }
  }

  // Get user's section code
  Future<String?> _getUserSectionCode() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final sectionCode = userData['selectedSectionCode']?.toString();
        log('📚 Student section code: $sectionCode');
        return sectionCode;
      }
      return null;
    } catch (e) {
      log('❌ Error getting user section code: $e');
      return null;
    }
  }

  // Get real-time stream of announcements for selected instructor
  Stream<List<Map<String, dynamic>>> getAnnouncementsStream(
    String instructorId,
  ) {
    if (instructorId.isEmpty) {
      return Stream.value([]);
    }

    try {
      return _firestore
          .collection('instructors')
          .doc(instructorId)
          .collection('announcements')
          .snapshots()
          .asyncMap((snapshot) async {
            // Get user's section code for filtering
            final userSectionCode = await _getUserSectionCode();

            List<Map<String, dynamic>> announcementList =
                snapshot.docs.map((doc) {
                  final data = doc.data();
                  return {
                    'id': doc.id,
                    'title': data['title'] ?? '',
                    'content': data['content'] ?? '',
                    'date': _formatDate(data['createdAt']),
                    'views': data['views'] ?? 0,
                    'pinned': data['pinned'] ?? false,
                    'urgent': data['urgent'] ?? false,
                    'createdAt': data['createdAt'],
                    'instructorName':
                        data['instructorName'] ?? 'Unknown Instructor',
                    'instructorProfileUrl': data['instructorProfileUrl'] ?? '',
                    'imageUrl': data['imageUrl'] ?? '',
                    'selectedClasses': data['selectedClasses'] ?? [],
                  };
                }).toList();

            // Filter announcements by section if user has a section code
            if (userSectionCode != null && userSectionCode.isNotEmpty) {
              log('🔍 Filtering announcements for section: $userSectionCode');
              announcementList =
                  announcementList.where((announcement) {
                    final selectedClasses = List<String>.from(
                      announcement['selectedClasses'] ?? [],
                    );

                    // If announcement has no selected classes (legacy), show it to all
                    if (selectedClasses.isEmpty) {
                      return true;
                    }

                    // Check if user's section is in the selected classes
                    return selectedClasses.contains(userSectionCode);
                  }).toList();
            }

            // Sort announcements manually
            announcementList.sort((a, b) {
              // First sort by pinned status
              if (a['pinned'] != b['pinned']) {
                return (b['pinned'] as bool) ? 1 : -1;
              }
              // Then sort by creation date
              if (a['createdAt'] != null && b['createdAt'] != null) {
                DateTime dateA = (a['createdAt'] as Timestamp).toDate();
                DateTime dateB = (b['createdAt'] as Timestamp).toDate();
                return dateB.compareTo(dateA);
              }
              return 0;
            });

            return announcementList;
          });
    } catch (e) {
      log('Error creating announcements stream: $e');
      return Stream.value([]);
    }
  }

  // Load announcements from the selected instructor
  Future<void> loadAnnouncements(String instructorId) async {
    try {
      isLoading.value = true;

      if (instructorId.isEmpty) {
        log('No instructor selected');
        return;
      }

      log('Loading announcements for instructor: $instructorId');

      // Get user's section code for filtering
      final userSectionCode = await _getUserSectionCode();

      // Try to get announcements with ordering, fallback to simple query if ordering fails
      QuerySnapshot snapshot;
      try {
        snapshot =
            await _firestore
                .collection('instructors')
                .doc(instructorId)
                .collection('announcements')
                .orderBy('pinned', descending: true)
                .orderBy('createdAt', descending: true)
                .get();
      } catch (orderError) {
        log('Ordering failed, trying simple query: $orderError');
        // Fallback to simple query without complex ordering
        snapshot =
            await _firestore
                .collection('instructors')
                .doc(instructorId)
                .collection('announcements')
                .get();
      }

      List<Map<String, dynamic>> announcementList =
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
              'instructorName': data['instructorName'] ?? 'Unknown Instructor',
              'instructorProfileUrl': data['instructorProfileUrl'] ?? '',
              'imageUrl': data['imageUrl'] ?? '',
              'selectedClasses':
                  data['selectedClasses'] ?? [], // Include selected classes
            };
          }).toList();

      // Filter announcements by section if user has a section code
      if (userSectionCode != null && userSectionCode.isNotEmpty) {
        log('🔍 Filtering announcements for section: $userSectionCode');
        announcementList =
            announcementList.where((announcement) {
              final selectedClasses = List<String>.from(
                announcement['selectedClasses'] ?? [],
              );

              // If announcement has no selected classes (legacy), show it to all
              if (selectedClasses.isEmpty) {
                log(
                  '✅ Announcement "${announcement['title']}" has no section filter, showing to all',
                );
                return true;
              }

              // Check if user's section is in the selected classes
              final isMatch = selectedClasses.contains(userSectionCode);
              if (isMatch) {
                log(
                  '✅ Announcement "${announcement['title']}" matches section $userSectionCode',
                );
              } else {
                log(
                  '❌ Skipping announcement "${announcement['title']}" - not for section $userSectionCode (targets: $selectedClasses)',
                );
              }
              return isMatch;
            }).toList();

        log(
          '📊 Filtered announcements: ${announcementList.length} out of ${snapshot.docs.length} match section $userSectionCode',
        );
      } else {
        log('⚠️ No section code found for user, showing all announcements');
      }

      // Sort announcements manually if needed
      announcementList.sort((a, b) {
        // First sort by pinned status
        if (a['pinned'] != b['pinned']) {
          return (b['pinned'] as bool) ? 1 : -1;
        }
        // Then sort by creation date
        if (a['createdAt'] != null && b['createdAt'] != null) {
          DateTime dateA = (a['createdAt'] as Timestamp).toDate();
          DateTime dateB = (b['createdAt'] as Timestamp).toDate();
          return dateB.compareTo(dateA);
        }
        return 0;
      });

      announcements.value = announcementList;

      // Count unread announcements (you can implement read/unread logic here)
      unreadCount.value = announcements.length;

      log(
        'Successfully loaded ${announcements.length} announcements for instructor: $instructorId',
      );

      // Log each announcement for debugging
      for (var announcement in announcements) {
        log(
          'Announcement: ${announcement['title']} - Pinned: ${announcement['pinned']} - Urgent: ${announcement['urgent']}',
        );
      }
    } catch (e) {
      log('Error loading announcements: $e');
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

  // Update announcement views when user views it
  Future<void> updateViews(String announcementId) async {
    try {
      if (selectedInstructorId.value.isEmpty) return;

      await _firestore
          .collection('instructors')
          .doc(selectedInstructorId.value)
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
      log('Error updating views: $e');
    }
  }

  // Refresh announcements
  Future<void> refreshAnnouncements() async {
    if (selectedInstructorId.value.isNotEmpty) {
      await loadAnnouncements(selectedInstructorId.value);
    } else {
      // Try to reload the instructor selection
      await getSelectedInstructor();
    }
  }

  // Force reload instructor selection and announcements
  Future<void> forceReload() async {
    selectedInstructorId.value = '';
    selectedInstructorName.value = '';
    announcements.clear();
    await getSelectedInstructor();
  }

  // Check if user has a valid instructor connection
  bool get hasValidInstructor =>
      selectedInstructorId.value.isNotEmpty &&
      selectedInstructorName.value.isNotEmpty;

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
}
