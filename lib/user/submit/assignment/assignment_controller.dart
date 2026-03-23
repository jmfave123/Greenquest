import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/services/submission_routing_service.dart';
import '../../../shared/services/student_data_service.dart';

class AssignmentController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _log(Object? message) {
    if (kDebugMode) {
      debugPrint('$message');
    }
  }

  // Observable variables
  final RxBool isLoading = true.obs;
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

  /// Get user's section code from their profile
  Future<String?> _getUserSectionCode() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userData = await StudentDataService.getStudentData();
      if (userData != null) {
        final sectionCode = userData['selectedSectionCode']?.toString();
        _log('📚 Student section code: $sectionCode');
        return sectionCode;
      }
      return null;
    } catch (e) {
      _log('❌ Error getting user section code: $e');
      return null;
    }
  }

  /// Load assignments from the current instructor
  Future<void> loadCurrentInstructorAssignments() async {
    try {
      _log('🔍 Loading current instructor assignments...');
      isLoading.value = true;
      errorMessage.value = '';

      final user = _auth.currentUser;
      _log('👤 Current user: ${user?.uid}');

      if (user != null) {
        await user.reload();
        final refreshedUser = _auth.currentUser;
        _log('🔄 Refreshed user: ${refreshedUser?.uid}');

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

            _log(
              '✅ User has selected instructor: $instructorName (ID: $instructorId)',
            );
            currentInstructorUid.value = instructorId;
            currentInstructorName.value = instructorName;

            await loadAssignmentsByInstructorUid(instructorId);
          } else {
            _log('⚠️ No instructor selected, showing empty state');
            currentInstructorUid.value = '';
            currentInstructorName.value = '';
            assignments.value = [];
            errorMessage.value = 'Please select an instructor first';
          }
        } else {
          _log('⚠️ User token expired, showing empty state');
          currentInstructorUid.value = '';
          currentInstructorName.value = '';
          assignments.value = [];
          errorMessage.value = 'Please log in and select an instructor';
        }
      } else {
        _log('⚠️ No user logged in, showing empty state');
        currentInstructorUid.value = '';
        currentInstructorName.value = '';
        assignments.value = [];
        errorMessage.value = 'Please log in and select an instructor';
      }
    } catch (e) {
      _log('❌ Error loading current instructor assignments: $e');
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
      _log('🔍 Loading assignments for instructor UID: $instructorUid');
      isLoading.value = true;
      errorMessage.value = '';

      // Get instructor document first
      final instructorDoc =
          await _firestore.collection('instructors').doc(instructorUid).get();

      if (!instructorDoc.exists) {
        _log('❌ Instructor document not found for UID: $instructorUid');
        errorMessage.value = 'Instructor not found';
        assignments.value = [];
        return;
      }

      final instructorData = instructorDoc.data()!;
      final instructorName =
          instructorData['name']?.toString() ?? 'Unknown Instructor';

      _log('✅ Instructor found: $instructorName');

      // Get student's section code for filtering
      final userSectionCode = await _getUserSectionCode();
      _log('📚 Student section code: $userSectionCode');

      // Add debug: Print all assignments to see what sections they have
      _log('🔍 DEBUG: Fetching ALL assignments first to inspect data...');
      final allAssignmentsDebug =
          await _firestore
              .collection('instructors')
              .doc(instructorUid)
              .collection('assignments')
              .where('status', isEqualTo: 'active')
              .get();

      _log(
        '🔍 DEBUG: Found ${allAssignmentsDebug.docs.length} total active assignments',
      );
      for (var doc in allAssignmentsDebug.docs) {
        final data = doc.data();
        final classes = data['selectedClasses'] ?? [];
        _log('  - Assignment: ${data['title']} - Selected Classes: $classes');
      }

      // Get assignments from the instructor's assignments subcollection
      _log(
        '📚 Querying assignments subcollection for instructor: $instructorUid',
      );

      // 🔥 OPTIMIZED: Use array-contains for efficient array filtering in Firestore
      QuerySnapshot assignmentsQuery;
      if (userSectionCode != null && userSectionCode.isNotEmpty) {
        _log('🎯 Using array-contains filter with section: "$userSectionCode"');
        assignmentsQuery =
            await _firestore
                .collection('instructors')
                .doc(instructorUid)
                .collection('assignments')
                .where('status', isEqualTo: 'active')
                .where('selectedClasses', arrayContains: userSectionCode)
                .get();
      } else {
        _log('⚠️ No section code found, fetching all active assignments');
        // If no section code, just filter by status
        assignmentsQuery =
            await _firestore
                .collection('instructors')
                .doc(instructorUid)
                .collection('assignments')
                .where('status', isEqualTo: 'active')
                .get();
      }

      _log(
        '📚 Assignments query result: ${assignmentsQuery.docs.length} documents',
      );

      List<Map<String, dynamic>> instructorAssignments = [];

      if (assignmentsQuery.docs.isNotEmpty) {
        _log(
          '📖 Processing ${assignmentsQuery.docs.length} assignments from subcollection...',
        );

        for (int i = 0; i < assignmentsQuery.docs.length; i++) {
          var assignmentDoc = assignmentsQuery.docs[i];
          var assignmentData = assignmentDoc.data() as Map<String, dynamic>;

          _log(
            '📄 Assignment $i (${assignmentDoc.id}): ${assignmentData.runtimeType}',
          );
          _log('📄 Assignment $i data: ${assignmentData.keys.toList()}');

          // Skip if assignmentData is null or empty
          if (assignmentData.isEmpty) {
            _log('⚠️ Assignment $i has empty data, skipping');
            continue;
          }

          // Get selected classes for this assignment
          final selectedClasses = List<String>.from(
            assignmentData['selectedClasses'] ?? [],
          );

          // Note: Firestore array-contains query already filtered by section

          // Create assignment map with proper data structure
          Map<String, dynamic> assignmentMap = {
            'id': assignmentDoc.id,
            'title': assignmentData['title']?.toString() ?? 'No Title',
            'instruction':
                assignmentData['instruction']?.toString() ??
                'No instructions available',
            'instructorName':
                instructorName, // Use instructor name from instructor document
            'instructorId': instructorUid,
            'points': assignmentData['points'] ?? 0,
            'dueDate': _formatDueDate(
              assignmentData['dueDate'],
            ), // Format with time
            'createdAt': assignmentData['createdAt'], // Pass raw date data
            'status': assignmentData['status']?.toString() ?? 'active',
            'type': assignmentData['type']?.toString() ?? 'Assignment',
            'period': assignmentData['period']?.toString() ?? '',
            'attachments': assignmentData['attachments'] ?? [],
            'selectedClasses': selectedClasses,
            'category': assignmentData['category']?.toString() ?? '',
          };

          _log('📄 Processed assignment: ${assignmentMap['title']}');
          _log('📄 Instructor name: ${assignmentMap['instructorName']}');
          _log('📄 Assignment status: ${assignmentMap['status']}');

          // Only add valid assignments
          if (assignmentMap['title'] != 'No Title' &&
              assignmentMap['title'] != null) {
            instructorAssignments.add(assignmentMap);
            _log('✅ Added assignment: ${assignmentMap['title']}');
          } else {
            _log('⚠️ Skipping invalid assignment: ${assignmentMap['title']}');
          }
        }
      } else {
        _log('⚠️ No assignments found in instructor subcollection');
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
                    assignment['title'] != 'No Title',
              )
              .toList();

      assignments.value = validAssignments;
      _log(
        '📊 Loaded ${validAssignments.length} assignments from instructor $instructorUid (filtered by section $userSectionCode)',
      );

      // Load submission statuses for all assignments
      await loadSubmissionStatuses();

      if (validAssignments.isEmpty) {
        errorMessage.value = 'No assignments found for your section';
      }
    } catch (e) {
      _log('❌ Error loading assignments: $e');
      errorMessage.value = 'Error loading assignments: $e';
      assignments.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  /// Load all assignments from all instructors
  Future<void> loadAllAssignments() async {
    try {
      _log('🔍 Loading all assignments from all instructors...');
      isLoading.value = true;
      errorMessage.value = '';

      // Get all instructors
      final instructorsQuery = await _firestore.collection('instructors').get();
      _log('👥 Found ${instructorsQuery.docs.length} instructors');

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
              'instruction':
                  assignmentData['instruction']?.toString() ??
                  'No instructions available',
              'instructorName':
                  instructorName, // Use instructor name from instructor document
              'instructorId': instructorId,
              'points': assignmentData['points'] ?? 0,
              'dueDate': _formatDueDate(
                assignmentData['dueDate'],
              ), // Format with time
              'createdAt': assignmentData['createdAt'], // Pass raw date data
              'status': assignmentData['status']?.toString() ?? 'active',
              'type': assignmentData['type']?.toString() ?? 'Assignment',
              'period': assignmentData['period']?.toString() ?? '',
              'attachments': assignmentData['attachments'] ?? [],
              'selectedClasses': assignmentData['selectedClasses'] ?? [],
            };

            // Only add valid assignments
            if (assignmentMap['title'] != 'No Title') {
              allAssignments.add(assignmentMap);
            }
          }
        } catch (e) {
          _log('Error loading assignments from instructor $instructorId: $e');
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
                    assignment['title'] != 'No Title',
              )
              .toList();

      assignments.value = validAssignments;
      _log(
        '📊 Loaded ${validAssignments.length} assignments from all instructors',
      );

      // Load submission statuses for all assignments
      await loadSubmissionStatuses();
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
      _log('🔍 Getting selected instructor for user: $userId');

      final userData = await StudentDataService.getStudentData();

      if (userData != null) {
        final selectedInstructorId =
            userData['selectedInstructorId']?.toString();
        final selectedInstructorName =
            userData['selectedInstructorName']?.toString();
        final selectionComplete = userData['selectionComplete'] ?? false;

        _log(
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

            _log(
              '✅ Verified instructor exists: $actualInstructorName (ID: $selectedInstructorId)',
            );

            return {
              'instructorId': selectedInstructorId,
              'instructorName':
                  actualInstructorName, // Use the actual name from Firestore
            };
          } else {
            _log(
              '❌ Selected instructor document not found in Firestore: $selectedInstructorId',
            );
            return null;
          }
        } else {
          _log('⚠️ User has not completed instructor selection');
          return null;
        }
      } else {
        _log('❌ User data from cache was empty');
        return null;
      }
    } catch (e) {
      _log('❌ Error getting selected instructor: $e');
      return null;
    }
  }

  /// Refresh assignments
  Future<void> refreshAssignments() async {
    try {
      await loadCurrentInstructorAssignments();
    } catch (e) {
      _log('Error refreshing assignments: $e');
      assignments.value = [];
      errorMessage.value = 'Error refreshing assignments: $e';
    }
  }

  /// Set selected assignment
  void setSelectedAssignment(Map<String, dynamic> assignment) {
    selectedAssignment.value = assignment;
  }

  /// Submit assignment with Cloudinary file URLs using automatic routing
  Future<void> submitAssignmentWithCloudinary(
    String assignmentId,
    List<Map<String, dynamic>> uploadedFiles, {
    String submissionType = 'assignment', // 'assignment', 'activity', or 'quiz'
  }) async {
    try {
      isSubmitting.value = true;

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      _log('📤 Submitting $submissionType: $assignmentId');
      _log('📁 Files to submit: ${uploadedFiles.length}');

      // Get user data for student information from cache
      final userData = await StudentDataService.getStudentData() ?? {};

      // Create submission data with Cloudinary URLs
      final submissionData = {
        'studentId': user.uid,
        'studentName':
            user.displayName ?? user.email?.split('@')[0] ?? 'Student',
        'studentEmail': user.email ?? '',
        'studentIdNumber': userData['idNumber'] ?? user.uid,
        'files':
            uploadedFiles
                .map(
                  (f) => {
                    'name': f['name'],
                    'url': f['url'],
                    'publicId': f['publicId'],
                    'size': f['size'],
                    'type': f['type'],
                    'resourceType': f['resourceType'],
                    'uploadedAt': f['uploadedAt'],
                  },
                )
                .toList(),
        'fileNames': uploadedFiles.map((f) => f['name']).toList(),
        'cloudinaryUrls': uploadedFiles.map((f) => f['url']).toList(),
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'submitted',
        'grade': null,
        'feedback': null,
        'gradedAt': null,
        if (userData['assignedSemester'] != null)
          'assignedSemester': userData['assignedSemester'],
      };

      // Use routing service to automatically route submission to correct instructor
      final routingResult = await SubmissionRoutingService.routeSubmission(
        activityId: assignmentId,
        submissionType: submissionType,
        submissionData: submissionData,
      );

      if (!routingResult['success']) {
        throw Exception(routingResult['error'] ?? 'Failed to route submission');
      }

      // Update submission status
      submissionStatus[assignmentId] = 'submitted';

      _log('✅ $submissionType submission routed successfully');
      _log('📍 Routed to instructor: ${routingResult['instructorId']}');
      _log('📍 Section: ${routingResult['sectionId']}');

      Get.snackbar(
        'Success',
        '${submissionType.capitalizeFirst} submitted and routed to instructor!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      _log('❌ Error submitting $submissionType with Cloudinary: $e');
      Get.snackbar(
        'Error',
        'Failed to submit $submissionType: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Submit assignment using automatic routing
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

      _log('📤 Submitting assignment: $assignmentId');
      _log('📁 Files to submit: ${files.length}');

      // Get user data for student information from cache
      final userData = await StudentDataService.getStudentData() ?? {};

      // Create submission data
      final submissionData = {
        'studentId': user.uid,
        'studentName':
            user.displayName ?? user.email?.split('@')[0] ?? 'Student',
        'studentEmail': user.email ?? '',
        'studentIdNumber': userData['idNumber'] ?? user.uid,
        'files': files.map((f) => f['name']).toList(),
        'fileNames': files.map((f) => f['name']).toList(),
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'submitted',
        'grade': null,
        'feedback': null,
        'gradedAt': null,
        if (userData['assignedSemester'] != null)
          'assignedSemester': userData['assignedSemester'],
      };

      // Use routing service to automatically route submission to correct instructor
      final routingResult = await SubmissionRoutingService.routeSubmission(
        activityId: assignmentId,
        submissionType: 'assignment',
        submissionData: submissionData,
      );

      if (!routingResult['success']) {
        throw Exception(routingResult['error'] ?? 'Failed to route submission');
      }

      // Update submission status
      submissionStatus[assignmentId] = 'submitted';

      _log('✅ Assignment submission routed successfully');
      _log('📍 Routed to instructor: ${routingResult['instructorId']}');
      _log('📍 Section: ${routingResult['sectionId']}');

      Get.snackbar(
        'Success',
        'Assignment submitted and routed to instructor!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      _log('❌ Error submitting assignment: $e');
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
      _log('📁 File picker not yet configured - using mock files');

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
      _log('❌ Error picking files: $e');
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
    _log('📁 Mock files selected: ${mockFiles.length}');
    return mockFiles;
  }

  /// Get submission status for an assignment (Legacy individual read - fallback)
  Future<String> getSubmissionStatus(String assignmentId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'not_submitted';

      final query =
          await _firestore
              .collection('submissions')
              .where('activityType', isEqualTo: 'assignment')
              .where('activityId', isEqualTo: assignmentId)
              .where('studentId', isEqualTo: user.uid)
              .limit(1)
              .get();

      if (query.docs.isNotEmpty) {
        final submissionData = query.docs.first.data();
        return submissionData['status']?.toString() ?? 'not_submitted';
      }

      return 'not_submitted';
    } catch (e) {
      _log('❌ Error getting submission status: $e');
      return 'not_submitted';
    }
  }

  /// Bulk load ALL submission statuses in a SINGLE query (N+1 query fix)
  Future<void> loadSubmissionStatuses() async {
    try {
      final user = _auth.currentUser;
      if (user == null || assignments.isEmpty) return;

      // Clear existing statuses and extract IDs
      submissionStatus.clear();
      final assignmentIds = assignments.map((a) => a['id']?.toString()).whereType<String>().toList();
      
      if (assignmentIds.isEmpty) return;

      // Set defaults for all first
      for (final id in assignmentIds) {
        submissionStatus[id] = 'not_submitted';
      }

      _log('🔍 Bulk loading submissions for ${assignmentIds.length} assignments');

      // 1 single query to fetch all assignment submissions created by THIS student 
      final allSubmissions = await _firestore
          .collection('submissions')
          .where('studentId', isEqualTo: user.uid)
          .where('activityType', isEqualTo: 'assignment')
          .get();

      // Process them locally in memory instantly
      for (var doc in allSubmissions.docs) {
        final data = doc.data();
        final activityId = data['activityId']?.toString();
        
        if (activityId != null && submissionStatus.containsKey(activityId)) {
           submissionStatus[activityId] = data['status']?.toString() ?? 'not_submitted';
        }
      }

      _log('📊 Successfully mapped submission statuses without looping queries.');
    } catch (e) {
      _log('❌ Error bulk loading submission statuses: $e');
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
        _log('❌ No user logged in');
        return;
      }

      _log('🔍 DEBUG: Checking instructor selection for user: ${user.uid}');

      // Check user document
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        _log('📋 User document data: ${userData.toString()}');

        final selectedInstructorId =
            userData['selectedInstructorId']?.toString();
        final selectedInstructorName =
            userData['selectedInstructorName']?.toString();
        final selectionComplete = userData['selectionComplete'] ?? false;

        _log('📋 Selected Instructor ID: $selectedInstructorId');
        _log('📋 Selected Instructor Name: $selectedInstructorName');
        _log('📋 Selection Complete: $selectionComplete');

        if (selectedInstructorId != null && selectedInstructorId.isNotEmpty) {
          // Check if instructor exists
          final instructorDoc =
              await _firestore
                  .collection('instructors')
                  .doc(selectedInstructorId)
                  .get();
          if (instructorDoc.exists) {
            final instructorData = instructorDoc.data()!;
            _log('✅ Instructor found: ${instructorData['name']}');
            _log('📋 Instructor data: ${instructorData.toString()}');
          } else {
            _log('❌ Instructor document not found: $selectedInstructorId');
          }
        }
      } else {
        _log('❌ User document not found');
      }
    } catch (e) {
      _log('❌ Debug error: $e');
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
          _log('✅ Found rolan gwapo instructor: ${doc.id}');

          currentInstructorUid.value = doc.id;
          currentInstructorName.value =
              data['name']?.toString() ?? 'rolan gwapo';

          await loadAssignmentsByInstructorUid(doc.id);
          return;
        }
      }

      _log('❌ rolan gwapo instructor not found');
      errorMessage.value = 'rolan gwapo instructor not found';
    } catch (e) {
      _log('❌ Error setting instructor for testing: $e');
      errorMessage.value = 'Error setting instructor: $e';
    }
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
      _log('Error formatting due date: $e');
      return 'Unknown Date';
    }
  }
}
