import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AssignmentController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable variables
  final RxBool isLoading = false.obs;
  final RxList<Map<String, dynamic>> assignments = <Map<String, dynamic>>[].obs;
  final RxString errorMessage = ''.obs;
  final RxString currentInstructorUid = ''.obs;
  final RxString currentInstructorName = ''.obs;
  final RxMap<String, dynamic> selectedAssignment = <String, dynamic>{}.obs;
  final RxBool isSubmitting = false.obs;
  final RxMap<String, String> submissionStatus = <String, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadCurrentInstructorAssignments();
  }

  /// Load assignments from the current instructor
  Future<void> loadCurrentInstructorAssignments() async {
    try {
      print('🔍 Loading current instructor assignments...');
      isLoading.value = true;
      errorMessage.value = '';

      final user = _auth.currentUser;
      print('👤 Current user: ${user?.uid}');

      if (user != null) {
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
            // Load assignments from the selected instructor
            final instructorId = selectedInstructor['instructorId'].toString();
            final instructorName =
                selectedInstructor['instructorName']?.toString() ??
                'Unknown Instructor';

            print(
              '✅ User has selected instructor: $instructorName (ID: $instructorId)',
            );
            currentInstructorUid.value = instructorId;
            currentInstructorName.value = instructorName;

            await loadAssignmentsByInstructorUid(instructorId);
          } else {
            print('⚠️ No instructor selected, showing empty state');
            currentInstructorUid.value = '';
            currentInstructorName.value = '';
            assignments.value = [];
            errorMessage.value = 'Please select an instructor first';
          }
        } else {
          print('⚠️ User token expired, showing empty state');
          currentInstructorUid.value = '';
          currentInstructorName.value = '';
          assignments.value = [];
          errorMessage.value = 'Please log in and select an instructor';
        }
      } else {
        print('⚠️ No user logged in, showing empty state');
        currentInstructorUid.value = '';
        currentInstructorName.value = '';
        assignments.value = [];
        errorMessage.value = 'Please log in and select an instructor';
      }
    } catch (e) {
      print('❌ Error loading current instructor assignments: $e');
      errorMessage.value = 'Error loading assignments: $e';
      currentInstructorUid.value = '';
      currentInstructorName.value = '';
      assignments.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  /// Load assignments for a specific instructor
  Future<void> loadAssignmentsByInstructorUid(String instructorUid) async {
    try {
      print('🔍 Loading assignments for instructor UID: $instructorUid');
      isLoading.value = true;
      errorMessage.value = '';

      // Get instructor document first
      final instructorDoc =
          await _firestore.collection('instructors').doc(instructorUid).get();

      if (!instructorDoc.exists) {
        print('❌ Instructor document not found for UID: $instructorUid');
        errorMessage.value = 'Instructor not found';
        assignments.value = [];
        return;
      }

      final instructorData = instructorDoc.data()!;
      final instructorName =
          instructorData['name']?.toString() ?? 'Unknown Instructor';

      print('✅ Instructor found: $instructorName');

      // Get assignments from the instructor's assignments subcollection
      print(
        '📚 Querying assignments subcollection for instructor: $instructorUid',
      );

      final assignmentsQuery =
          await _firestore
              .collection('instructors')
              .doc(instructorUid)
              .collection('assignments')
              .where('status', isEqualTo: 'active')
              .get();

      print(
        '📚 Assignments query result: ${assignmentsQuery.docs.length} documents',
      );

      List<Map<String, dynamic>> instructorAssignments = [];

      if (assignmentsQuery.docs.isNotEmpty) {
        print(
          '📖 Processing ${assignmentsQuery.docs.length} assignments from subcollection...',
        );

        for (int i = 0; i < assignmentsQuery.docs.length; i++) {
          var assignmentDoc = assignmentsQuery.docs[i];
          var assignmentData = assignmentDoc.data();

          print(
            '📄 Assignment $i (${assignmentDoc.id}): ${assignmentData.runtimeType}',
          );
          print('📄 Assignment $i data: ${assignmentData.keys.toList()}');

          // Skip if assignmentData is null or empty
          if (assignmentData.isEmpty) {
            print('⚠️ Assignment $i has empty data, skipping');
            continue;
          }

          // Create assignment map with proper data structure
          Map<String, dynamic> assignmentMap = {
            'id': assignmentDoc.id,
            'title': assignmentData['title']?.toString() ?? 'No Title',
            'topic': assignmentData['topic']?.toString() ?? 'No Topic',
            'instruction':
                assignmentData['instruction']?.toString() ??
                'No instructions available',
            'instructorName':
                instructorName, // Use instructor name from instructor document
            'instructorId': instructorUid,
            'points': assignmentData['points'] ?? 0,
            'dueDate': _formatDate(assignmentData['dueDate']),
            'createdAt': _formatDate(assignmentData['createdAt']),
            'status': assignmentData['status']?.toString() ?? 'active',
            'type': assignmentData['type']?.toString() ?? 'Assignment',
            'period': assignmentData['period']?.toString() ?? '',
            'attachments': assignmentData['attachments'] ?? [],
            'selectedClasses': assignmentData['selectedClasses'] ?? [],
          };

          print(
            '📄 Processed assignment: ${assignmentMap['title']} - ${assignmentMap['topic']}',
          );
          print('📄 Instructor name: ${assignmentMap['instructorName']}');
          print('📄 Assignment status: ${assignmentMap['status']}');

          // Only add valid assignments
          if (assignmentMap['title'] != 'No Title' &&
              assignmentMap['topic'] != 'No Topic') {
            instructorAssignments.add(assignmentMap);
          } else {
            print('⚠️ Skipping invalid assignment: ${assignmentMap['title']}');
          }
        }
      } else {
        print('⚠️ No assignments found in instructor subcollection');
        errorMessage.value = 'No assignments found for this instructor';
      }

      // Sort by creation date (newest first) - manual sorting since we removed orderBy
      instructorAssignments.sort((a, b) {
        final dateA = a['createdAt'] ?? '';
        final dateB = b['createdAt'] ?? '';
        return dateB.compareTo(dateA);
      });

      // Filter out any invalid assignments before setting
      final validAssignments =
          instructorAssignments
              .where(
                (assignment) =>
                    assignment.isNotEmpty &&
                    assignment['title'] != null &&
                    assignment['title'] != 'No Title' &&
                    assignment['topic'] != null &&
                    assignment['topic'] != 'No Topic',
              )
              .toList();

      assignments.value = validAssignments;
      print(
        '📊 Loaded ${validAssignments.length} assignments from instructor $instructorUid',
      );

      if (validAssignments.isEmpty) {
        errorMessage.value = 'No assignments found for this instructor';
      }
    } catch (e) {
      print('❌ Error loading assignments: $e');
      errorMessage.value = 'Error loading assignments: $e';
      assignments.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  /// Load all assignments from all instructors
  Future<void> loadAllAssignments() async {
    try {
      print('🔍 Loading all assignments from all instructors...');
      isLoading.value = true;
      errorMessage.value = '';

      // Get all instructors
      final instructorsQuery = await _firestore.collection('instructors').get();
      print('👥 Found ${instructorsQuery.docs.length} instructors');

      List<Map<String, dynamic>> allAssignments = [];

      for (var instructorDoc in instructorsQuery.docs) {
        final instructorId = instructorDoc.id;
        final instructorData = instructorDoc.data();
        final instructorName =
            instructorData['name']?.toString() ?? 'Unknown Instructor';

        // Get assignments from the instructor's assignments subcollection
        try {
          final assignmentsQuery =
              await _firestore
                  .collection('instructors')
                  .doc(instructorId)
                  .collection('assignments')
                  .where('status', isEqualTo: 'active')
                  .get();

          for (var assignmentDoc in assignmentsQuery.docs) {
            final assignmentData = assignmentDoc.data();

            // Skip if assignmentData is null or empty
            if (assignmentData.isEmpty) continue;

            Map<String, dynamic> assignmentMap = {
              'id': assignmentDoc.id,
              'title': assignmentData['title']?.toString() ?? 'No Title',
              'topic': assignmentData['topic']?.toString() ?? 'No Topic',
              'instruction':
                  assignmentData['instruction']?.toString() ??
                  'No instructions available',
              'instructorName':
                  instructorName, // Use instructor name from instructor document
              'instructorId': instructorId,
              'points': assignmentData['points'] ?? 0,
              'dueDate': _formatDate(assignmentData['dueDate']),
              'createdAt': _formatDate(assignmentData['createdAt']),
              'status': assignmentData['status']?.toString() ?? 'active',
              'type': assignmentData['type']?.toString() ?? 'Assignment',
              'period': assignmentData['period']?.toString() ?? '',
              'attachments': assignmentData['attachments'] ?? [],
              'selectedClasses': assignmentData['selectedClasses'] ?? [],
            };

            // Only add valid assignments
            if (assignmentMap['title'] != 'No Title' &&
                assignmentMap['topic'] != 'No Topic') {
              allAssignments.add(assignmentMap);
            }
          }
        } catch (e) {
          print('Error loading assignments from instructor $instructorId: $e');
        }
      }

      // Sort by creation date (newest first) - manual sorting since we removed orderBy
      allAssignments.sort((a, b) {
        final dateA = a['createdAt'] ?? '';
        final dateB = b['createdAt'] ?? '';
        return dateB.compareTo(dateA);
      });

      // Filter out any invalid assignments before setting
      final validAssignments =
          allAssignments
              .where(
                (assignment) =>
                    assignment.isNotEmpty &&
                    assignment['title'] != null &&
                    assignment['title'] != 'No Title' &&
                    assignment['topic'] != null &&
                    assignment['topic'] != 'No Topic',
              )
              .toList();

      assignments.value = validAssignments;
      print(
        '📊 Loaded ${validAssignments.length} assignments from all instructors',
      );
    } catch (e) {
      errorMessage.value = 'Error loading assignments: $e';
      assignments.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  /// Get selected instructor from user document
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
          // Verify the instructor exists in Firestore
          final instructorDoc =
              await _firestore
                  .collection('instructors')
                  .doc(selectedInstructorId)
                  .get();

          if (instructorDoc.exists) {
            final instructorData = instructorDoc.data()!;
            final actualInstructorName =
                instructorData['name']?.toString() ?? 'Unknown Instructor';

            print(
              '✅ Verified instructor exists: $actualInstructorName (ID: $selectedInstructorId)',
            );

            return {
              'instructorId': selectedInstructorId,
              'instructorName':
                  actualInstructorName, // Use the actual name from Firestore
            };
          } else {
            print(
              '❌ Selected instructor document not found in Firestore: $selectedInstructorId',
            );
            return null;
          }
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

  /// Refresh assignments
  Future<void> refreshAssignments() async {
    try {
      await loadCurrentInstructorAssignments();
    } catch (e) {
      print('Error refreshing assignments: $e');
      assignments.value = [];
      errorMessage.value = 'Error refreshing assignments: $e';
    }
  }

  /// Set selected assignment
  void setSelectedAssignment(Map<String, dynamic> assignment) {
    selectedAssignment.value = assignment;
  }

  /// Submit assignment (simplified version without file upload for now)
  Future<void> submitAssignment(
    String assignmentId,
    List<Map<String, dynamic>> files,
  ) async {
    try {
      isSubmitting.value = true;

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Create submission data
      Map<String, dynamic> submissionData = {
        'assignmentId': assignmentId,
        'studentId': user.uid,
        'studentEmail': user.email ?? '',
        'instructorId': currentInstructorUid.value,
        'instructorName': currentInstructorName.value,
        'files':
            files.map((f) => f['name']).toList(), // Store file names for now
        'fileNames': files.map((f) => f['name']).toList(),
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'submitted',
        'grade': null,
        'feedback': null,
        'gradedAt': null,
      };

      await _firestore.collection('assignment_submissions').add(submissionData);

      // Update submission status
      submissionStatus[assignmentId] = 'submitted';

      print('✅ Assignment submission completed successfully');

      Get.snackbar(
        'Success',
        'Assignment submitted successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      print('❌ Error submitting assignment: $e');
      Get.snackbar(
        'Error',
        'Failed to submit assignment: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Pick files (simplified version for now)
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
                _mockFileSelection();
              },
              child: const Text('Select Mock Files'),
            ),
          ],
        ),
      );

      return [];
    } catch (e) {
      print('❌ Error picking files: $e');
      return [];
    }
  }

  /// Mock file selection
  List<Map<String, dynamic>> _mockFileSelection() {
    List<Map<String, dynamic>> mockFiles = [
      {'name': 'assignment_reflection.pdf', 'type': 'pdf'},
      {'name': 'my_contribution.docx', 'type': 'docx'},
      {'name': 'nation_building_essay.docx', 'type': 'docx'},
    ];

    // This would be called from the UI
    print('📁 Mock files selected: ${mockFiles.length}');
    return mockFiles;
  }

  /// Get submission status for an assignment
  Future<String> getSubmissionStatus(String assignmentId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'not_submitted';

      final query =
          await _firestore
              .collection('assignment_submissions')
              .where('assignmentId', isEqualTo: assignmentId)
              .where('studentId', isEqualTo: user.uid)
              .limit(1)
              .get();

      if (query.docs.isNotEmpty) {
        final submissionData = query.docs.first.data();
        return submissionData['status']?.toString() ?? 'not_submitted';
      }

      return 'not_submitted';
    } catch (e) {
      print('❌ Error getting submission status: $e');
      return 'not_submitted';
    }
  }

  /// Clear error message
  void clearError() {
    errorMessage.value = '';
  }

  /// Debug method to check instructor selection status
  Future<void> debugInstructorSelection() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return;
      }

      print('🔍 DEBUG: Checking instructor selection for user: ${user.uid}');

      // Check user document
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        print('📋 User document data: ${userData.toString()}');

        final selectedInstructorId =
            userData['selectedInstructorId']?.toString();
        final selectedInstructorName =
            userData['selectedInstructorName']?.toString();
        final selectionComplete = userData['selectionComplete'] ?? false;

        print('📋 Selected Instructor ID: $selectedInstructorId');
        print('📋 Selected Instructor Name: $selectedInstructorName');
        print('📋 Selection Complete: $selectionComplete');

        if (selectedInstructorId != null && selectedInstructorId.isNotEmpty) {
          // Check if instructor exists
          final instructorDoc =
              await _firestore
                  .collection('instructors')
                  .doc(selectedInstructorId)
                  .get();
          if (instructorDoc.exists) {
            final instructorData = instructorDoc.data()!;
            print('✅ Instructor found: ${instructorData['name']}');
            print('📋 Instructor data: ${instructorData.toString()}');
          } else {
            print('❌ Instructor document not found: $selectedInstructorId');
          }
        }
      } else {
        print('❌ User document not found');
      }
    } catch (e) {
      print('❌ Debug error: $e');
    }
  }

  /// Method to manually set instructor for testing (temporary)
  Future<void> setInstructorForTesting() async {
    try {
      // Find "rolan gwapo" instructor
      final instructorsQuery = await _firestore.collection('instructors').get();

      for (var doc in instructorsQuery.docs) {
        final data = doc.data();
        final name = data['name']?.toString().toLowerCase() ?? '';

        if (name.contains('rolan') && name.contains('gwapo')) {
          print('✅ Found rolan gwapo instructor: ${doc.id}');

          currentInstructorUid.value = doc.id;
          currentInstructorName.value =
              data['name']?.toString() ?? 'rolan gwapo';

          await loadAssignmentsByInstructorUid(doc.id);
          return;
        }
      }

      print('❌ rolan gwapo instructor not found');
      errorMessage.value = 'rolan gwapo instructor not found';
    } catch (e) {
      print('❌ Error setting instructor for testing: $e');
      errorMessage.value = 'Error setting instructor: $e';
    }
  }

  /// Format date from Firestore timestamp
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
}
