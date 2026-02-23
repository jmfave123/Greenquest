import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/services/submission_routing_service.dart';

class ActivityController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Note: Firebase Storage will be added when dependencies are available

  // Observable variables
  var isLoading = true.obs;
  var activities = <Map<String, dynamic>>[].obs;
  var errorMessage = ''.obs;
  var currentInstructorUid = ''.obs;
  var currentInstructorName = ''.obs;
  var selectedActivity = <String, dynamic>{}.obs;
  var isSubmitting = false.obs;
  var submissionStatus = <String, String>{}.obs; // activityId -> status

  @override
  void onInit() {
    super.onInit();
    loadCurrentInstructorActivities();
  }

  /// Get user's section code from their profile
  Future<String?> _getUserSectionCode() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final sectionCode = userData['selectedSectionCode']?.toString();
        print('📚 Student section code: $sectionCode');
        return sectionCode;
      }
      return null;
    } catch (e) {
      print('❌ Error getting user section code: $e');
      return null;
    }
  }

  /// Load activities for the current logged-in user's selected instructor
  Future<void> loadCurrentInstructorActivities() async {
    try {
      isLoading.value = true;
      print('🔍 Loading current instructor activities...');

      // Check if user is authenticated with valid token
      final user = _auth.currentUser;
      print('👤 Current user: ${user?.uid}');

      if (user != null) {
        // Refresh user to ensure token is valid
        await user.reload();
        final refreshedUser = _auth.currentUser;
        print('🔄 Refreshed user: ${refreshedUser?.uid}');

        if (refreshedUser != null) {
          // Check if user has selected an instructor
          final selectedInstructor = await _getSelectedInstructor(
            refreshedUser.uid,
          );

          if (selectedInstructor != null &&
              selectedInstructor['instructorId'] != null) {
            // Load activities from the selected instructor
            final instructorId = selectedInstructor['instructorId'].toString();
            final instructorName =
                selectedInstructor['instructorName']?.toString() ??
                'Unknown Instructor';

            print(
              '✅ User has selected instructor: $instructorName (ID: $instructorId)',
            );
            currentInstructorUid.value = instructorId;
            currentInstructorName.value = instructorName;

            await loadActivitiesByInstructorUid(instructorId);
          } else {
            // No instructor selected, load all activities
            print('⚠️ No instructor selected, loading all activities');
            currentInstructorUid.value = '';
            currentInstructorName.value = '';
            await loadAllActivities();
          }
        } else {
          // Token expired, load all activities as fallback
          print('⚠️ User token expired, loading all activities');
          currentInstructorUid.value = '';
          currentInstructorName.value = '';
          await loadAllActivities();
        }
      } else {
        // If no user is logged in, load all activities as fallback
        print('⚠️ No user logged in, loading all activities');
        currentInstructorUid.value = '';
        currentInstructorName.value = '';
        await loadAllActivities();
      }
    } catch (e) {
      print('❌ Error loading current instructor activities: $e');
      currentInstructorUid.value = '';
      currentInstructorName.value = '';
      await loadAllActivities();
    }
  }

  /// Load activities for a specific instructor by UID
  Future<void> loadActivitiesByInstructorUid(String instructorUid) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('🔍 Loading activities for instructor UID: $instructorUid');

      // Get instructor document first
      final instructorDoc =
          await _firestore.collection('instructors').doc(instructorUid).get();

      if (!instructorDoc.exists) {
        print('❌ Instructor document not found for UID: $instructorUid');
        errorMessage.value = 'Instructor not found';
        activities.value = [];
        return;
      }

      final instructorData = instructorDoc.data()!;
      final instructorName =
          instructorData['name']?.toString() ?? 'Unknown Instructor';

      print('✅ Instructor found: $instructorName');

      // Update instructor name
      currentInstructorName.value = instructorName;

      // Get student's section code for filtering
      final userSectionCode = await _getUserSectionCode();
      print('📚 Student section code: $userSectionCode');

      // Get activities from the instructor's activities subcollection
      print(
        '📚 Querying activities subcollection for instructor: $instructorUid',
      );

      final activitiesQuery =
          await _firestore
              .collection('instructors')
              .doc(instructorUid)
              .collection('activities')
              .where('status', isEqualTo: 'active')
              .get();

      print(
        '📚 Activities query result: ${activitiesQuery.docs.length} documents',
      );

      List<Map<String, dynamic>> instructorActivities = [];

      if (activitiesQuery.docs.isNotEmpty) {
        print(
          '📖 Processing ${activitiesQuery.docs.length} activities from subcollection...',
        );

        for (int i = 0; i < activitiesQuery.docs.length; i++) {
          var activityDoc = activitiesQuery.docs[i];
          var activityData = activityDoc.data();

          print(
            '📄 Activity $i (${activityDoc.id}): ${activityData.runtimeType}',
          );
          print('📄 Activity $i data: ${activityData.keys.toList()}');

          // Skip if activityData is null or empty
          if (activityData.isEmpty) {
            print('⚠️ Skipping empty activity at index $i');
            continue;
          }

          // Get selected classes for this activity
          final selectedClasses = List<String>.from(
            activityData['selectedClasses'] ?? [],
          );

          // 🎯 FILTER BY SECTION: Only include if student's section is in selectedClasses
          if (userSectionCode != null &&
              userSectionCode.isNotEmpty &&
              selectedClasses.isNotEmpty) {
            if (!selectedClasses.contains(userSectionCode)) {
              print(
                '❌ Skipping activity "${activityData['title']}" - not for section $userSectionCode',
              );
              continue;
            }
            print(
              '✅ Activity "${activityData['title']}" matches student section $userSectionCode',
            );
          }

          // Create activity map with proper validation and UI-ready data
          final activityMap = <String, dynamic>{
            'id': activityDoc.id,
            'title': activityData['title']?.toString() ?? 'No Title',
            'instruction':
                activityData['instruction']?.toString() ??
                'No instructions available',
            'instructorName':
                instructorName, // Use instructor name from instructor document
            'instructorId': instructorUid,
            'points': activityData['points'] ?? 0,
            'dueDate': _formatDueDate(activityData['dueDate']),
            'createdAt': activityData['createdAt'],
            'updatedAt': _formatDate(activityData['updatedAt']),
            'status': activityData['status']?.toString() ?? 'active',
            'type': activityData['type']?.toString() ?? 'Activity',
            'period': activityData['period']?.toString() ?? 'Unknown',
            'selectedClasses': selectedClasses,
            'attachments': activityData['attachments'] ?? [],
          };

          print('📄 Processed activity: ${activityMap['title']}');
          print('📄 Instructor name: ${activityMap['instructorName']}');
          print('📄 Activity status: ${activityMap['status']}');
          print('📄 Created date: ${activityMap['createdAt']}');

          // Only add if activity has valid data for UI display
          if (activityMap['title'] != null &&
              activityMap['title'] != 'No Title') {
            instructorActivities.add(activityMap);
            print('✅ Added activity: ${activityMap['title']}');
          } else {
            print('❌ Skipped activity due to missing or invalid title');
          }
        }
      } else {
        print('⚠️ No activities found in instructor subcollection');
        errorMessage.value = 'No activities found for this instructor';
      }

      // Sort by creation date (newest first) - manual sorting since we removed orderBy
      instructorActivities.sort((a, b) {
        final dateA = a['createdAt'] ?? '';
        final dateB = b['createdAt'] ?? '';
        return dateB.compareTo(dateA);
      });

      // Filter out any invalid activities before setting
      final validActivities =
          instructorActivities
              .where(
                (activity) =>
                    activity.isNotEmpty &&
                    activity['title'] != null &&
                    activity['title'] != 'No Title',
              )
              .toList();

      activities.value = validActivities;
      print(
        '📊 Loaded ${validActivities.length} activities from instructor $instructorUid (filtered by section $userSectionCode)',
      );

      // Load submission statuses for all activities
      await loadSubmissionStatuses();

      if (validActivities.isEmpty) {
        print('⚠️ No valid activities found after processing');
        errorMessage.value = 'No activities found for your section';
      } else {
        errorMessage.value = ''; // Clear any previous errors
      }
    } catch (e) {
      errorMessage.value = 'Error loading activities: $e';
      print('❌ Error loading activities: $e');
      activities.value = [];

      Get.snackbar(
        'Error',
        'Failed to load activities: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Load all activities from all instructors
  Future<void> loadAllActivities() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final instructorsQuery = await _firestore.collection('instructors').get();

      List<Map<String, dynamic>> allActivities = [];

      for (var instructorDoc in instructorsQuery.docs) {
        final instructorId = instructorDoc.id;
        final instructorData = instructorDoc.data();
        final instructorName =
            instructorData['name']?.toString() ?? 'Unknown Instructor';

        // Get activities from the instructor's activities subcollection
        try {
          final activitiesQuery =
              await _firestore
                  .collection('instructors')
                  .doc(instructorId)
                  .collection('activities')
                  .where('status', isEqualTo: 'active')
                  .get();

          for (var activityDoc in activitiesQuery.docs) {
            final activityData = activityDoc.data();

            // Skip if activityData is null or empty
            if (activityData.isEmpty) continue;

            // Create activity map with proper validation and UI-ready data
            final activityMap = <String, dynamic>{
              'id': activityDoc.id,
              'title': activityData['title']?.toString() ?? 'No Title',
              'instruction':
                  activityData['instruction']?.toString() ??
                  'No instructions available',
              'instructorName':
                  instructorName, // Use instructor name from instructor document
              'instructorId': instructorId,
              'points': activityData['points'] ?? 0,
              'dueDate': _formatDueDate(activityData['dueDate']),
              'createdAt': activityData['createdAt'],
              'updatedAt': _formatDate(activityData['updatedAt']),
              'status': activityData['status']?.toString() ?? 'active',
              'type': activityData['type']?.toString() ?? 'Activity',
              'period': activityData['period']?.toString() ?? 'Unknown',
              'selectedClasses': activityData['selectedClasses'] ?? [],
              'attachments': activityData['attachments'] ?? [],
            };

            // Only add if activity has valid data for UI display
            if (activityMap['title'] != null &&
                activityMap['title'] != 'No Title') {
              allActivities.add(activityMap);
            }
          }
        } catch (e) {
          print('Error loading activities from instructor $instructorId: $e');
        }
      }

      // Sort by creation date (newest first) - manual sorting since we removed orderBy
      allActivities.sort((a, b) {
        final dateA = a['createdAt'] ?? '';
        final dateB = b['createdAt'] ?? '';
        return dateB.compareTo(dateA);
      });

      // Filter out any invalid activities before setting
      final validActivities =
          allActivities
              .where(
                (activity) =>
                    activity.isNotEmpty &&
                    activity['title'] != null &&
                    activity['title'] != 'No Title',
              )
              .toList();

      activities.value = validActivities;
      print(
        '📊 Loaded ${validActivities.length} activities from all instructors',
      );

      // Load submission statuses for all activities
      await loadSubmissionStatuses();
    } catch (e) {
      errorMessage.value = 'Error loading activities: $e';
      print('Error loading activities: $e');
      Get.snackbar(
        'Error',
        'Failed to load activities: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Get selected instructor from user's document
  Future<Map<String, dynamic>?> _getSelectedInstructor(String userId) async {
    try {
      print('🔍 Getting selected instructor for user: $userId');

      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final selectedInstructorId =
            userData['selectedInstructorId']?.toString();
        final selectedInstructorName =
            userData['selectedInstructorName']?.toString();
        final selectionComplete = userData['selectionComplete'] ?? false;

        print(
          '📋 User data: selectedInstructorId=$selectedInstructorId, selectedInstructorName=$selectedInstructorName, selectionComplete=$selectionComplete',
        );

        if (selectionComplete &&
            selectedInstructorId != null &&
            selectedInstructorId.isNotEmpty) {
          return {
            'instructorId': selectedInstructorId,
            'instructorName': selectedInstructorName ?? 'Unknown Instructor',
          };
        } else {
          print('⚠️ User has not completed instructor selection');
          return null;
        }
      } else {
        print('❌ User document not found');
        return null;
      }
    } catch (e) {
      print('❌ Error getting selected instructor: $e');
      return null;
    }
  }

  /// Set selected activity for detail view
  void setSelectedActivity(Map<String, dynamic> activity) {
    selectedActivity.value = activity;
    print('📄 Selected activity: ${activity['title']}');
  }

  /// Submit activity using automatic routing
  Future<void> submitActivity(
    String activityId,
    List<Map<String, dynamic>> files,
  ) async {
    try {
      isSubmitting.value = true;

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      print('📤 Submitting activity: $activityId');
      print('📁 Files to submit: ${files.length}');

      // Get user data for student information
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      // Create submission data
      final submissionData = {
        'studentId': user.uid,
        'studentName': user.displayName ?? 'Unknown Student',
        'studentEmail': user.email ?? '',
        'studentIdNumber': userData['idNumber'] ?? '',
        'files': files.map((f) => f['name']).toList(),
        'fileNames': files.map((f) => f['name']).toList(),
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'submitted',
        'grade': null,
        'feedback': null,
      };

      // Use routing service to automatically route submission to correct instructor
      final routingResult = await SubmissionRoutingService.routeSubmission(
        activityId: activityId,
        submissionType: 'activity',
        submissionData: submissionData,
      );

      if (!routingResult['success']) {
        throw Exception(routingResult['error'] ?? 'Failed to route submission');
      }

      // Update submission status
      submissionStatus[activityId] = 'submitted';

      print('✅ Activity submission routed successfully');
      print('📍 Routed to instructor: ${routingResult['instructorId']}');
      print('📍 Section: ${routingResult['sectionId']}');

      Get.snackbar(
        'Success',
        'Activity submitted and routed to instructor!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      print('❌ Error submitting activity: $e');
      Get.snackbar(
        'Error',
        'Failed to submit activity: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Pick files for submission (simplified version)
  Future<List<Map<String, dynamic>>> pickFiles() async {
    try {
      // For now, return mock files until file picker is properly configured
      print('📁 File picker not yet configured - using mock files');

      // Show a dialog to simulate file selection
      Get.dialog(
        AlertDialog(
          title: const Text('File Selection'),
          content: const Text(
            'File picker will be configured with proper dependencies. For now, this is a mock submission.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                // Return mock files
                Get.find<ActivityController>()._mockFileSelection();
              },
              child: const Text('Mock Submit'),
            ),
          ],
        ),
      );

      return [];
    } catch (e) {
      print('❌ Error picking files: $e');
      Get.snackbar(
        'Error',
        'Failed to pick files: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return [];
    }
  }

  /// Mock file selection for testing
  void _mockFileSelection() {
    final mockFiles = [
      {'name': 'activity_submission.pdf', 'type': 'pdf'},
      {'name': 'activity_document.docx', 'type': 'docx'},
    ];

    // This would be called from the UI
    print('📁 Mock files selected: ${mockFiles.length}');
  }

  /// Check submission status for an activity
  Future<String> getSubmissionStatus(String activityId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'not_submitted';

      final query =
          await _firestore
              .collection('submissions')
              .where('activityType', isEqualTo: 'activity')
              .where('activityId', isEqualTo: activityId)
              .where('studentId', isEqualTo: user.uid)
              .limit(1)
              .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        return data['status'] ?? 'not_submitted';
      }

      return 'not_submitted';
    } catch (e) {
      print('❌ Error checking submission status: $e');
      return 'not_submitted';
    }
  }

  /// Load submission statuses for all activities
  Future<void> loadSubmissionStatuses() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Clear existing statuses
      submissionStatus.clear();

      // Get status for each activity
      for (final activity in activities) {
        final activityId = activity['id']?.toString();
        if (activityId != null) {
          final status = await getSubmissionStatus(activityId);
          submissionStatus[activityId] = status;
        }
      }

      print(
        '📊 Loaded submission statuses for ${activities.length} activities',
      );
    } catch (e) {
      print('❌ Error loading submission statuses: $e');
    }
  }

  /// Refresh activities
  Future<void> refreshActivities() async {
    try {
      await loadCurrentInstructorActivities();
    } catch (e) {
      print('Error refreshing activities: $e');
      await loadAllActivities();
    }
  }

  /// Helper method to format Firestore Timestamp to date string
  String? _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown Date';

    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        return 'Unknown Date';
      }

      // Format as "July 28" to match the UI design
      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];

      final month = months[date.month - 1];
      return '$month ${date.day}';
    } catch (e) {
      print('Error formatting date: $e');
      return 'Unknown Date';
    }
  }

  /// Clear error message
  void clearError() {
    errorMessage.value = '';
  }

  /// Format due date with time
  String _formatDueDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown Date';

    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        return 'Unknown Date';
      }

      // Format as "MMM dd, yyyy hh:mm AM/PM"
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      final month = months[date.month - 1];
      final day = date.day.toString().padLeft(2, '0');
      final year = date.year;

      // Format time in 12-hour format
      int hour = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';

      if (hour == 0) {
        hour = 12;
      } else if (hour > 12) {
        hour -= 12;
      }

      return '$month $day, $year ${hour.toString().padLeft(2, '0')}:$minute $period';
    } catch (e) {
      print('Error formatting due date: $e');
      return 'Unknown Date';
    }
  }
}
