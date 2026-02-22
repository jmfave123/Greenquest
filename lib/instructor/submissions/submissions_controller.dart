// ignore_for_file: avoid_print

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/services/submission_routing_service.dart';
import '../../shared/services/realtime_submission_service.dart';
import '../../shared/services/in_app_notification_service.dart';

class SubmissionsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Instructor data
  var instructorName = ''.obs;
  var profileImageUrl = ''.obs;

  // Observable variables
  final RxBool isLoading = false.obs;
  final RxList<Map<String, dynamic>> submissions = <Map<String, dynamic>>[].obs;
  final RxString errorMessage = ''.obs;
  final RxString selectedFilter = 'All'.obs;
  final RxMap<String, int> submissionStats = <String, int>{}.obs;

  // Students data for tracking who submitted/not submitted
  final RxList<Map<String, dynamic>> enrolledStudents =
      <Map<String, dynamic>>[].obs;
  String? _currentActivityId;
  String? _currentActivityType;

  // Filters
  final List<String> filterOptions = [
    'All',
    'Submitted',
    'Not Yet Submitted',
    'Graded',
  ];
  final List<String> categoryOptions = [
    'All',
    'Activities',
    'Assignments',
    'Quizzes',
    'PITs',
  ];
  final RxString selectedCategory = 'All'.obs;

  // Track current section for filtering
  String? _currentSectionId;

  @override
  void onInit() {
    super.onInit();
    // Load instructor data first
    loadInstructor();

    // Initialize stats
    submissionStats.value = {
      'total': 0,
      'submitted': 0,
      'graded': 0,
      'notSubmitted': 0,
      'pending': 0,
    };
  }

  @override
  void onClose() {
    // Cancel all subscriptions
    _realtimeSubscription?.cancel();
    _allSubmissionsSubscription?.cancel();

    // Dispose of the real-time service
    RealtimeSubmissionService.dispose();

    super.onClose();
  }

  /// Load instructor name and profile using email query (same pattern as login flow)
  Future<void> loadInstructor() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        instructorName.value = 'No user logged in';
        return;
      }

      // Reload user to ensure token is fresh (same as login flow)
      try {
        await user.reload();
      } catch (e) {
        // If reload fails, user might still be valid
      }

      final refreshedUser = FirebaseAuth.instance.currentUser;
      if (refreshedUser == null || refreshedUser.email == null) {
        instructorName.value = 'User session expired';
        return;
      }

      // Query instructor by email (same pattern as login flow for reliability)
      final instructorQuery =
          await FirebaseFirestore.instance
              .collection('instructors')
              .where('email', isEqualTo: refreshedUser.email)
              .limit(1)
              .get();

      if (instructorQuery.docs.isNotEmpty) {
        final instructorData = instructorQuery.docs.first.data();
        instructorName.value = instructorData['name'] ?? 'Unknown Instructor';
        // Safely access profileUrl - handles cases where field doesn't exist
        profileImageUrl.value =
            instructorData['profileUrl'] ??
            instructorData['profileImageUrl'] ??
            '';
      } else {
        // Fallback: Try by UID if email query fails
        final doc =
            await FirebaseFirestore.instance
                .collection('instructors')
                .doc(refreshedUser.uid)
                .get();

        if (doc.exists) {
          final data = doc.data() ?? {};
          instructorName.value = data['name'] ?? 'Unknown Instructor';
          // Safely access profileUrl - use data map to avoid errors
          profileImageUrl.value =
              data['profileUrl'] ?? data['profileImageUrl'] ?? '';
        } else {
          instructorName.value = 'Instructor not found';
        }
      }
    } catch (e) {
      instructorName.value = 'Error loading name';
      errorMessage.value = 'Failed to load instructor: $e';
    }
  }

  // Load submissions for a specific assignment
  Future<void> loadAssignmentSubmissions(
    String assignmentId, {
    String? sectionId,
  }) async {
    // Since this is called from initState (which defers the call), we can update directly
    isLoading.value = true;
    errorMessage.value = '';

    try {
      print('🔍 Loading assignment submissions:');
      print('  - Assignment ID: $assignmentId');
      print('  - Section ID: $sectionId');

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      print('  - User ID: ${user.uid}');

      // Build query - query directly by sectionName when sectionId is provided (like class_report_controller)
      Query query = _firestore
          .collection('submissions')
          .where('activityType', isEqualTo: 'assignment')
          .where('activityId', isEqualTo: assignmentId)
          .where('instructorId', isEqualTo: user.uid);

      // If a specific section is provided, query directly by sectionName in Firestore
      if (sectionId != null && sectionId.isNotEmpty) {
        print('  - Querying directly by sectionName: $sectionId');
        query = query.where('sectionName', isEqualTo: sectionId);
      } else {
        // If no specific section, get instructor's assigned sections first
        final instructorSections = await _getInstructorSections(user.uid);
        print('  - Instructor sections: $instructorSections');

        if (instructorSections.isEmpty) {
          print('❌ No sections found for instructor: ${user.uid}');
          submissions.assignAll([]);
          updateStats();
          isLoading.value = false;
          return;
        }
      }

      QuerySnapshot querySnapshot;
      try {
        print('  - Executing query with orderBy...');
        querySnapshot =
            await query.orderBy('submittedAt', descending: true).get();
      } catch (e) {
        print('  - OrderBy failed, trying without it: $e');
        querySnapshot = await query.get();
      }

      print('  - Query returned ${querySnapshot.docs.length} documents');

      List<Map<String, dynamic>> loadedSubmissions = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('  - Found submission: ${doc.id}');
        print('    - Student: ${data['studentName']}');
        print('    - Status: ${data['status']}');
        print('    - Section: ${data['sectionName']}');
        loadedSubmissions.add({'id': doc.id, 'type': 'assignment', ...data});
      }

      // If no specific section was provided, filter by instructor sections
      if (sectionId == null || sectionId.isEmpty) {
        final instructorSections = await _getInstructorSections(user.uid);
        if (instructorSections.isNotEmpty) {
          loadedSubmissions = _filterSubmissionsBySection(
            loadedSubmissions,
            sectionId,
            instructorSections,
          );
        }
      }

      print('  - Total loaded submissions: ${loadedSubmissions.length}');

      // Load enrolled students if section is specified
      if (sectionId != null && sectionId.isNotEmpty) {
        await loadEnrolledStudents(sectionId);
      }

      // Update observables directly - async operations are done, build phase is complete
      submissions.assignAll(loadedSubmissions);
      updateStats();
      isLoading.value = false;
    } catch (e) {
      print('❌ Error loading assignment submissions: $e');
      errorMessage.value = 'Failed to load submissions: $e';
      isLoading.value = false;
    }
  }

  // Load submissions for a specific quiz
  Future<void> loadQuizSubmissions(String quizId, {String? sectionId}) async {
    // Since this is called from initState (which defers the call), we can update directly
    isLoading.value = true;
    errorMessage.value = '';

    try {
      print('🔍 Loading quiz submissions:');
      print('  - Quiz ID: $quizId');
      print('  - Section ID: $sectionId');

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      print('  - User ID: ${user.uid}');

      // Build query - query directly by sectionName when sectionId is provided (like class_report_controller)
      Query query = _firestore
          .collection('submissions')
          .where('activityType', isEqualTo: 'quiz')
          .where('activityId', isEqualTo: quizId)
          .where('instructorId', isEqualTo: user.uid);

      // If a specific section is provided, query directly by sectionName in Firestore
      if (sectionId != null && sectionId.isNotEmpty) {
        print('  - Querying directly by sectionName: $sectionId');
        query = query.where('sectionName', isEqualTo: sectionId);
      } else {
        // If no specific section, get instructor's assigned sections first
        final instructorSections = await _getInstructorSections(user.uid);
        print('  - Instructor sections: $instructorSections');

        if (instructorSections.isEmpty) {
          print('❌ No sections found for instructor: ${user.uid}');
          submissions.assignAll([]);
          updateStats();
          isLoading.value = false;
          return;
        }
      }

      QuerySnapshot querySnapshot;
      try {
        print('  - Executing query with orderBy...');
        querySnapshot =
            await query.orderBy('submittedAt', descending: true).get();
      } catch (e) {
        print('  - OrderBy failed, trying without it: $e');
        querySnapshot = await query.get();
      }

      print('  - Query returned ${querySnapshot.docs.length} documents');

      List<Map<String, dynamic>> loadedSubmissions = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('  - Found submission: ${doc.id}');
        print('    - Student: ${data['studentName']}');
        print('    - Status: ${data['status']}');
        print('    - Section: ${data['sectionName']}');
        loadedSubmissions.add({'id': doc.id, 'type': 'quiz', ...data});
      }

      // If no specific section was provided, filter by instructor sections
      if (sectionId == null || sectionId.isEmpty) {
        final instructorSections = await _getInstructorSections(user.uid);
        if (instructorSections.isNotEmpty) {
          loadedSubmissions = _filterSubmissionsBySection(
            loadedSubmissions,
            sectionId,
            instructorSections,
          );
        }
      }

      print('  - Total loaded submissions: ${loadedSubmissions.length}');

      // Update observables directly - async operations are done, build phase is complete
      submissions.assignAll(loadedSubmissions);
      updateStats();
      isLoading.value = false;
    } catch (e) {
      print('❌ Error loading quiz submissions: $e');
      errorMessage.value = 'Failed to load quiz submissions: $e';
      isLoading.value = false;
    }
  }

  // Load submissions for a specific activity
  Future<void> loadActivitySubmissions(
    String activityId, {
    String? sectionId,
  }) async {
    // Since this is called from initState (which defers the call), we can update directly
    isLoading.value = true;
    errorMessage.value = '';

    try {
      print('🔍 Loading activity submissions:');
      print('  - Activity ID: $activityId');
      print('  - Section ID: $sectionId');

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      print('  - User ID: ${user.uid}');

      // Build query - query directly by sectionName when sectionId is provided (like class_report_controller)
      Query query = _firestore
          .collection('submissions')
          .where('activityType', isEqualTo: 'activity')
          .where('activityId', isEqualTo: activityId)
          .where('instructorId', isEqualTo: user.uid);

      // If a specific section is provided, query directly by sectionName in Firestore
      if (sectionId != null && sectionId.isNotEmpty) {
        print('  - Querying directly by sectionName: $sectionId');
        query = query.where('sectionName', isEqualTo: sectionId);
      } else {
        // If no specific section, get instructor's assigned sections first
        final instructorSections = await _getInstructorSections(user.uid);
        print('  - Instructor sections: $instructorSections');

        if (instructorSections.isEmpty) {
          print('❌ No sections found for instructor: ${user.uid}');
          submissions.assignAll([]);
          updateStats();
          isLoading.value = false;
          return;
        }
      }

      QuerySnapshot querySnapshot;
      try {
        print('  - Executing query with orderBy...');
        querySnapshot =
            await query.orderBy('submittedAt', descending: true).get();
      } catch (e) {
        print('  - OrderBy failed, trying without it: $e');
        querySnapshot = await query.get();
      }

      print('  - Query returned ${querySnapshot.docs.length} documents');

      List<Map<String, dynamic>> loadedSubmissions = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('  - Found submission: ${doc.id}');
        print('    - Student: ${data['studentName']}');
        print('    - Status: ${data['status']}');
        print('    - Section: ${data['sectionName']}');
        loadedSubmissions.add({'id': doc.id, 'type': 'activity', ...data});
      }

      // If no specific section was provided, filter by instructor sections
      if (sectionId == null || sectionId.isEmpty) {
        final instructorSections = await _getInstructorSections(user.uid);
        if (instructorSections.isNotEmpty) {
          loadedSubmissions = _filterSubmissionsBySection(
            loadedSubmissions,
            sectionId,
            instructorSections,
          );
        }
      }

      print('  - Total loaded submissions: ${loadedSubmissions.length}');

      // Load enrolled students if section is specified
      if (sectionId != null && sectionId.isNotEmpty) {
        await loadEnrolledStudents(sectionId);
      }

      // Update observables directly - async operations are done, build phase is complete
      submissions.assignAll(loadedSubmissions);
      updateStats();
      isLoading.value = false;
    } catch (e) {
      print('❌ Error loading activity submissions: $e');
      errorMessage.value = 'Failed to load submissions: $e';
      isLoading.value = false;
    }
  }

  // Load submissions for a specific instructor and section
  Future<void> loadInstructorSubmissions({
    String? instructorId,
    String? sectionId,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final user = _auth.currentUser;
      final currentInstructorId = instructorId ?? user?.uid;

      if (currentInstructorId == null) {
        throw Exception('No instructor ID provided');
      }

      print('🔍 Loading submissions for instructor: $currentInstructorId');
      print('🔍 Section filter: $sectionId');
      print('🔍 Section filter type: ${sectionId.runtimeType}');

      // Track current section for real-time filtering
      _currentSectionId = sectionId;

      List<Map<String, dynamic>> allSubmissions = [];

      // Build query - if sectionId is provided, query directly by sectionName (like class_report_controller does)
      Query allSubmissionsQuery = _firestore
          .collection('submissions')
          .where('instructorId', isEqualTo: currentInstructorId);

      // If a specific section is provided, query directly by sectionName in Firestore
      // This matches the working pattern from class_report_controller
      if (sectionId != null && sectionId.isNotEmpty) {
        print('  - Querying directly by sectionName: $sectionId');
        allSubmissionsQuery = allSubmissionsQuery.where(
          'sectionName',
          isEqualTo: sectionId,
        );
      } else {
        // If no specific section, get instructor's assigned sections and filter
        final instructorSections = await _getInstructorSections(
          currentInstructorId,
        );
        if (instructorSections.isEmpty) {
          print('No sections found for instructor: $currentInstructorId');
          submissions.assignAll([]);
          updateStats();
          isLoading.value = false;
          return;
        }
        print('📚 Instructor sections: $instructorSections');
        // For all sections, we still need to filter by instructor sections
        // But we'll do it after fetching since Firestore doesn't support array-contains-any easily
      }

      QuerySnapshot querySnapshot;
      try {
        print('  - Executing query with orderBy...');
        querySnapshot =
            await allSubmissionsQuery
                .orderBy('submittedAt', descending: true)
                .get();
      } catch (e) {
        print('  - OrderBy failed, trying without it: $e');
        // If orderBy fails (e.g., no index), try without it
        querySnapshot = await allSubmissionsQuery.get();
      }

      print('📝 Found ${querySnapshot.docs.length} submissions from query');

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final activityType = data['activityType'] ?? 'activity';
        final type = activityType; // 'assignment', 'activity', 'quiz', or 'pit'

        print(
          '📝 ${type.toUpperCase()} submission: ${data['studentName']} - sectionId: ${data['sectionId']} - sectionName: ${data['sectionName']}',
        );
        allSubmissions.add({'id': doc.id, 'type': type, ...data});
      }

      // If no specific section was provided, filter by instructor sections
      if (sectionId == null || sectionId.isEmpty) {
        final instructorSections = await _getInstructorSections(
          currentInstructorId,
        );
        if (instructorSections.isNotEmpty) {
          // Filter submissions by section using the helper method
          allSubmissions = _filterSubmissionsBySection(
            allSubmissions,
            sectionId,
            instructorSections,
          );
        }
      }

      // Sort by submission date
      allSubmissions.sort((a, b) {
        try {
          final aDate = _parseTimestamp(a['submittedAt']);
          final bDate = _parseTimestamp(b['submittedAt']);
          if (aDate == null || bDate == null) return 0;
          return bDate.compareTo(aDate);
        } catch (e) {
          print('❌ Error sorting submissions by date: $e');
          return 0;
        }
      });

      print('✅ Total submissions loaded: ${allSubmissions.length}');
      submissions.assignAll(allSubmissions);
      updateStats();
      isLoading.value = false;
    } catch (e) {
      print('❌ Error loading instructor submissions: $e');
      errorMessage.value = 'Failed to load submissions: $e';
      isLoading.value = false;
    }
  }

  // Get submission count for a specific item
  Future<int> getSubmissionCountForItem({
    required String itemId,
    required String itemType, // 'assignment', 'activity', or 'quiz'
    String? sectionId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      // Use unified submissions collection
      Query query = _firestore
          .collection('submissions')
          .where('instructorId', isEqualTo: user.uid)
          .where('activityType', isEqualTo: itemType.toLowerCase())
          .where('activityId', isEqualTo: itemId);

      if (sectionId != null && sectionId.isNotEmpty) {
        query = query.where('sectionId', isEqualTo: sectionId);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting submission count for $itemType $itemId: $e');
      return 0;
    }
  }

  // Get submission statistics for a specific item
  Future<Map<String, int>> getItemSubmissionStats({
    required String itemId,
    required String itemType,
    String? sectionId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {'total': 0, 'submitted': 0, 'graded': 0};

      // Use unified submissions collection
      Query query = _firestore
          .collection('submissions')
          .where('instructorId', isEqualTo: user.uid)
          .where('activityType', isEqualTo: itemType.toLowerCase())
          .where('activityId', isEqualTo: itemId);

      if (sectionId != null && sectionId.isNotEmpty) {
        query = query.where('sectionId', isEqualTo: sectionId);
      }

      final querySnapshot = await query.get();

      int total = querySnapshot.docs.length;
      int submitted = 0;
      int graded = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status']?.toString() ?? 'submitted';

        if (status == 'submitted' || status == 'graded') {
          submitted++;
        }
        if (status == 'graded') {
          graded++;
        }
      }

      return {'total': total, 'submitted': submitted, 'graded': graded};
    } catch (e) {
      print('Error getting submission stats for $itemType $itemId: $e');
      return {'total': 0, 'submitted': 0, 'graded': 0};
    }
  }

  // Update submission statistics
  void updateStats() {
    final total = submissions.length;
    // Submitted includes all submissions (both 'submitted' and 'graded' status)
    // since all submissions have been submitted
    final submitted = total;
    // Graded submissions are those with status 'graded'
    final graded = submissions.where((s) => s['status'] == 'graded').length;
    // Pending submissions are those with status 'submitted' (not yet graded)
    final pending = submissions.where((s) => s['status'] == 'submitted').length;

    // Calculate students who haven't submitted
    // This is the count of enrolled students minus those who have submitted
    final notSubmitted = enrolledStudents.length - submitted;

    submissionStats.value = {
      'total':
          submitted, // Total submissions (only those who submitted or graded)
      'submitted': submitted,
      'graded': graded,
      'notSubmitted': notSubmitted >= 0 ? notSubmitted : 0,
      'pending': pending,
    };
  }

  /// Load enrolled students for a specific section
  Future<void> loadEnrolledStudents(String? sectionId) async {
    if (sectionId == null || sectionId.isEmpty) {
      enrolledStudents.clear();
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      List<Map<String, dynamic>> students = [];

      // Load approved students from instructors/{instructorId}/students collection
      final approvedStudentsSnapshot =
          await _firestore
              .collection('instructors')
              .doc(user.uid)
              .collection('students')
              .where('selectedSectionCode', isEqualTo: sectionId)
              .get();

      for (var doc in approvedStudentsSnapshot.docs) {
        final data = doc.data();
        final studentId = data['studentId'] ?? doc.id;
        final email = data['email'] ?? '';

        // Fetch idNumber from users collection using email
        String idNumber = 'N/A';
        try {
          if (email.isNotEmpty) {
            final userQuery =
                await _firestore
                    .collection('users')
                    .where('email', isEqualTo: email)
                    .limit(1)
                    .get();

            if (userQuery.docs.isNotEmpty) {
              final userData = userQuery.docs.first.data();
              idNumber =
                  userData['idNumber'] ?? userData['studentIdNumber'] ?? 'N/A';
            }
          }
        } catch (e) {
          print('⚠️ Could not fetch idNumber for email $email: $e');
        }

        students.add({
          'id': doc.id,
          'studentId': studentId,
          'studentName': data['studentName'] ?? 'Unknown Student',
          'email': email,
          'idNumber': idNumber,
          'selectedSectionCode': data['selectedSectionCode'] ?? sectionId,
          'enrollmentStatus': 'approved',
        });
      }

      enrolledStudents.assignAll(students);
      print(
        '📚 Loaded ${students.length} enrolled students for section: $sectionId',
      );
    } catch (e) {
      print('❌ Error loading enrolled students: $e');
      enrolledStudents.clear();
    }
  }

  /// Get list of students who haven't submitted
  List<Map<String, dynamic>> getStudentsWithoutSubmission() {
    if (enrolledStudents.isEmpty) return [];

    // Get student IDs who have submitted
    final submittedStudentIds =
        submissions
            .map((s) => s['studentId']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet();

    // Filter enrolled students to find those who haven't submitted
    return enrolledStudents
        .where((student) => !submittedStudentIds.contains(student['studentId']))
        .toList();
  }

  // Filter submissions
  List<Map<String, dynamic>> get filteredSubmissions {
    List<Map<String, dynamic>> filtered = submissions;

    // Apply category filter
    if (selectedCategory.value != 'All') {
      filtered =
          filtered.where((submission) {
            switch (selectedCategory.value) {
              case 'Activities':
                return submission['type'] == 'activity';
              case 'Assignments':
                return submission['type'] == 'assignment';
              case 'Quizzes':
                return submission['type'] == 'quiz';
              case 'PITs':
                return submission['type'] == 'pit';
              default:
                return true;
            }
          }).toList();
    }

    // Apply status filter
    if (selectedFilter.value != 'All') {
      if (selectedFilter.value == 'Not Yet Submitted') {
        // Return empty list here - we'll handle "Not Yet Submitted" differently in the UI
        // since these are students WITHOUT submissions
        return [];
      }

      filtered =
          filtered.where((submission) {
            switch (selectedFilter.value) {
              case 'Submitted':
                // Show both submitted and graded (all who have submitted)
                return submission['status'] == 'submitted' ||
                    submission['status'] == 'graded';
              case 'Graded':
                return submission['status'] == 'graded';
              default:
                return true;
            }
          }).toList();
    }

    return filtered;
  }

  // Set filter
  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  // Set category filter
  void setCategory(String category) {
    selectedCategory.value = category;
  }

  // Load submissions by category
  Future<void> loadSubmissionsByCategory(
    String category, {
    String? sectionId,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      List<Map<String, dynamic>> categorySubmissions = [];

      switch (category.toLowerCase()) {
        case 'activities':
          Query activityQuery = _firestore
              .collection('submissions')
              .where('instructorId', isEqualTo: user.uid)
              .where('activityType', isEqualTo: 'activity');

          // Query directly by sectionName when sectionId is provided
          if (sectionId != null && sectionId.isNotEmpty) {
            activityQuery = activityQuery.where(
              'sectionName',
              isEqualTo: sectionId,
            );
          }

          QuerySnapshot activitySnapshot;
          try {
            activitySnapshot =
                await activityQuery
                    .orderBy('submittedAt', descending: true)
                    .get();
          } catch (e) {
            activitySnapshot = await activityQuery.get();
          }

          for (var doc in activitySnapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            categorySubmissions.add({
              'id': doc.id,
              'type': 'activity',
              ...data,
            });
          }
          break;

        case 'assignments':
          Query assignmentQuery = _firestore
              .collection('submissions')
              .where('instructorId', isEqualTo: user.uid)
              .where('activityType', isEqualTo: 'assignment');

          // Query directly by sectionName when sectionId is provided
          if (sectionId != null && sectionId.isNotEmpty) {
            assignmentQuery = assignmentQuery.where(
              'sectionName',
              isEqualTo: sectionId,
            );
          }

          QuerySnapshot assignmentSnapshot;
          try {
            assignmentSnapshot =
                await assignmentQuery
                    .orderBy('submittedAt', descending: true)
                    .get();
          } catch (e) {
            assignmentSnapshot = await assignmentQuery.get();
          }

          for (var doc in assignmentSnapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            categorySubmissions.add({
              'id': doc.id,
              'type': 'assignment',
              ...data,
            });
          }
          break;

        case 'quizzes':
          Query quizQuery = _firestore
              .collection('submissions')
              .where('instructorId', isEqualTo: user.uid)
              .where('activityType', isEqualTo: 'quiz');

          // Query directly by sectionName when sectionId is provided
          if (sectionId != null && sectionId.isNotEmpty) {
            quizQuery = quizQuery.where('sectionName', isEqualTo: sectionId);
          }

          QuerySnapshot quizSnapshot;
          try {
            quizSnapshot =
                await quizQuery.orderBy('submittedAt', descending: true).get();
          } catch (e) {
            quizSnapshot = await quizQuery.get();
          }

          for (var doc in quizSnapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            categorySubmissions.add({'id': doc.id, 'type': 'quiz', ...data});
          }
          break;

        case 'pits':
          Query pitQuery = _firestore
              .collection('submissions')
              .where('instructorId', isEqualTo: user.uid)
              .where('activityType', isEqualTo: 'pit');

          // Query directly by sectionName when sectionId is provided
          if (sectionId != null && sectionId.isNotEmpty) {
            pitQuery = pitQuery.where('sectionName', isEqualTo: sectionId);
          }

          QuerySnapshot pitSnapshot;
          try {
            pitSnapshot =
                await pitQuery.orderBy('submittedAt', descending: true).get();
          } catch (e) {
            pitSnapshot = await pitQuery.get();
          }

          for (var doc in pitSnapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            categorySubmissions.add({'id': doc.id, 'type': 'pit', ...data});
          }
          break;

        case 'all':
        default:
          return loadInstructorSubmissions(sectionId: sectionId);
      }

      // If no specific section was provided, filter by instructor sections
      if (sectionId == null || sectionId.isEmpty) {
        final instructorSections = await _getInstructorSections(user.uid);
        if (instructorSections.isNotEmpty) {
          categorySubmissions = _filterSubmissionsBySection(
            categorySubmissions,
            sectionId,
            instructorSections,
          );
        }
      }

      submissions.assignAll(categorySubmissions);
      updateStats();
    } catch (e) {
      errorMessage.value = 'Failed to load $category submissions: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Grade a submission
  Future<bool> gradeSubmission({
    required String submissionId,
    required String submissionType, // 'assignment', 'activity', or 'quiz'
    required double score,
    String? feedback,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Validate score against maximum points
      final maxPoints = await _getMaxPointsForSubmission(
        submissionId,
        submissionType,
      );
      if (maxPoints != null && score > maxPoints) {
        throw Exception('Score cannot exceed maximum points of $maxPoints');
      }

      if (score < 0) {
        throw Exception('Score cannot be negative');
      }

      // Get the submission document to extract student info and activity title
      final submissionDoc =
          await _firestore.collection('submissions').doc(submissionId).get();

      if (!submissionDoc.exists) {
        throw Exception('Submission not found');
      }

      final submissionData = submissionDoc.data() as Map<String, dynamic>;
      final studentId = submissionData['studentId'] as String?;
      final activityTitle =
          submissionData['activityTitle'] as String? ?? 'Your submission';
      final activityType =
          submissionData['activityType'] as String? ?? submissionType;
      final activityId = submissionData['activityId'] as String?;

      // Update the document in unified submissions collection
      await _firestore.collection('submissions').doc(submissionId).update({
        'grade': score,
        'feedback': feedback ?? '',
        'status': 'graded',
        'gradedAt': FieldValue.serverTimestamp(),
        'gradedBy': user.uid,
      });

      // Update local submission
      final index = submissions.indexWhere((s) => s['id'] == submissionId);
      if (index != -1) {
        submissions[index]['grade'] = score;
        submissions[index]['feedback'] = feedback ?? '';
        submissions[index]['status'] = 'graded';
        submissions[index]['gradedAt'] = Timestamp.now();
        submissions[index]['gradedBy'] = user.uid;
        submissions.refresh();
        updateStats();
      }

      // Send notification to student
      if (studentId != null && activityId != null) {
        // Map activity type to readable name
        String activityTypeName = activityType.toLowerCase();
        switch (activityTypeName) {
          case 'assignment':
            activityTypeName = 'Assignment';
            break;
          case 'activity':
            activityTypeName = 'Activity';
            break;
          case 'quiz':
            activityTypeName = 'Quiz';
            break;
          case 'pit':
            activityTypeName = 'PIT';
            break;
          default:
            activityTypeName = 'Submission';
        }

        // Create clear notification message
        String title = 'Submission Graded';
        String description =
            '$activityTypeName "$activityTitle" has been graded. '
            'Your score: ${score.toStringAsFixed(2)}';

        if (feedback != null &&
            feedback.isNotEmpty &&
            feedback.trim().isNotEmpty) {
          description += '\n\nFeedback: $feedback';
        }

        // Get instructor name
        final instructorNameValue =
            instructorName.value.isNotEmpty
                ? instructorName.value
                : user.displayName ??
                    submissionData['instructorName'] as String? ??
                    'Your instructor';

        // Send individual notification to student
        await InAppNotificationService.createIndividualNotification(
          type: 'graded',
          instructorId: user.uid,
          instructorName: instructorNameValue,
          itemId: activityId,
          title: title,
          targetUserIds: [studentId],
          description: description,
          metadata: {
            'submissionId': submissionId,
            'activityType': activityType,
            'activityTitle': activityTitle,
            'score': score,
            'maxPoints': maxPoints ?? 0,
            if (feedback != null && feedback.trim().isNotEmpty)
              'feedback': feedback,
            'gradedAt': DateTime.now().toIso8601String(),
          },
        );

        print('✅ Notification sent to student: $studentId');
      }

      Get.snackbar(
        'Success',
        'Submission graded successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to grade submission: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  // Helper method to get maximum points for a submission
  Future<double?> _getMaxPointsForSubmission(
    String submissionId,
    String submissionType,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Get the submission from unified collection to find the activity ID
      final submissionDoc =
          await _firestore.collection('submissions').doc(submissionId).get();
      if (!submissionDoc.exists) return null;

      final submissionData = submissionDoc.data()!;
      final activityId =
          submissionData['activityId']; // Unified activity ID field

      if (activityId == null) return null;

      // Get the assignment/activity/quiz document to find the points
      String sourceCollection;
      switch (submissionType.toLowerCase()) {
        case 'assignment':
          sourceCollection = 'assignments';
          break;
        case 'activity':
          sourceCollection = 'activities';
          break;
        case 'quiz':
          sourceCollection = 'quizzes';
          break;
        case 'pit':
          sourceCollection = 'pits';
          break;
        default:
          sourceCollection = 'assignments';
      }

      final assignmentDoc =
          await _firestore
              .collection('instructors')
              .doc(user.uid)
              .collection(sourceCollection)
              .doc(activityId)
              .get();

      if (assignmentDoc.exists) {
        final assignmentData = assignmentDoc.data()!;
        return (assignmentData['points'] ?? assignmentData['maxPoints'] ?? 100)
            .toDouble();
      }

      return null;
    } catch (e) {
      print('Error getting max points for submission: $e');
      return null;
    }
  }

  // Get submission by ID
  Map<String, dynamic>? getSubmissionById(String submissionId) {
    try {
      return submissions.firstWhere((s) => s['id'] == submissionId);
    } catch (e) {
      return null;
    }
  }

  // Format submission date
  String formatSubmissionDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown Date';

    try {
      final date = _parseTimestamp(timestamp);
      if (date == null) return 'Unknown Date';

      // Format as "Jan 15, 2024 10:30 AM"
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
      final day = date.day;
      final year = date.year;
      final hour =
          date.hour > 12
              ? date.hour - 12
              : date.hour == 0
              ? 12
              : date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final ampm = date.hour >= 12 ? 'PM' : 'AM';

      return '$month $day, $year $hour:$minute $ampm';
    } catch (e) {
      print('❌ Error formatting timestamp: $e');
      return 'Unknown Date';
    }
  }

  // Get instructor's assigned sections
  Future<List<String>> _getInstructorSections(String instructorId) async {
    try {
      print('🔍 Getting instructor sections for: $instructorId');

      // Get instructor's classes to find their assigned sections
      final classesSnapshot =
          await _firestore
              .collection('instructors')
              .doc(instructorId)
              .collection('classes')
              .get();

      print('  - Found ${classesSnapshot.docs.length} class documents');

      final sections = <String>[];
      for (var doc in classesSnapshot.docs) {
        final data = doc.data();
        final sectionId = data['sectionId']?.toString();
        print('  - Class doc ${doc.id}: sectionId = $sectionId');
        if (sectionId != null && sectionId.isNotEmpty) {
          sections.add(sectionId);
        }
      }

      print('  - Sections from classes: $sections');

      // If no sections found in classes, try to get from assignments
      if (sections.isEmpty) {
        print('  - No sections from classes, trying assignments...');
        final assignmentsSnapshot =
            await _firestore
                .collection('assignments')
                .where('instructorId', isEqualTo: instructorId)
                .get();

        print(
          '  - Found ${assignmentsSnapshot.docs.length} assignment documents',
        );

        for (var doc in assignmentsSnapshot.docs) {
          final data = doc.data();
          final selectedClasses = List<String>.from(
            data['selectedClasses'] ?? [],
          );
          print('  - Assignment ${doc.id}: selectedClasses = $selectedClasses');
          sections.addAll(selectedClasses);
        }
      }

      // Also try to get from activities and quizzes
      if (sections.isEmpty) {
        print('  - No sections from assignments, trying activities...');
        final activitiesSnapshot =
            await _firestore
                .collection('activities')
                .where('instructorId', isEqualTo: instructorId)
                .get();

        print('  - Found ${activitiesSnapshot.docs.length} activity documents');

        for (var doc in activitiesSnapshot.docs) {
          final data = doc.data();
          final selectedClasses = List<String>.from(
            data['selectedClasses'] ?? [],
          );
          print('  - Activity ${doc.id}: selectedClasses = $selectedClasses');
          sections.addAll(selectedClasses);
        }
      }

      if (sections.isEmpty) {
        print('  - No sections from activities, trying quizzes...');
        final quizzesSnapshot =
            await _firestore
                .collection('quizzes')
                .where('instructorId', isEqualTo: instructorId)
                .get();

        print('  - Found ${quizzesSnapshot.docs.length} quiz documents');

        for (var doc in quizzesSnapshot.docs) {
          final data = doc.data();
          final selectedClasses = List<String>.from(
            data['selectedClasses'] ?? [],
          );
          print('  - Quiz ${doc.id}: selectedClasses = $selectedClasses');
          sections.addAll(selectedClasses);
        }
      }

      // Remove duplicates and return
      final uniqueSections = sections.toSet().toList();
      print('  - Final unique sections: $uniqueSections');
      return uniqueSections;
    } catch (e) {
      print('❌ Error getting instructor sections: $e');
      return [];
    }
  }

  // Helper method to filter submissions by section
  List<Map<String, dynamic>> _filterSubmissionsBySection(
    List<Map<String, dynamic>> submissions,
    String? sectionId,
    List<String> instructorSections,
  ) {
    print('🔍 Filtering submissions by section:');
    print('  - Section ID: $sectionId');
    print('  - Instructor sections: $instructorSections');
    print('  - Total submissions before filtering: ${submissions.length}');

    if (sectionId == null || sectionId.isEmpty) {
      // Filter by instructor sections - use exact matching only
      final filteredSubmissions =
          submissions.where((submission) {
            final submissionSectionId = submission['sectionId'] ?? '';
            final submissionSectionName = submission['sectionName'] ?? '';

            print('  - Checking submission: ${submission['studentName']}');
            print('    - Submission sectionId: $submissionSectionId');
            print('    - Submission sectionName: $submissionSectionName');

            // Check if submission belongs to any of instructor's sections using exact matching
            final matches = instructorSections.any((instructorSection) {
              final exactMatch =
                  submissionSectionId == instructorSection ||
                  submissionSectionName == instructorSection;

              if (exactMatch) {
                print(
                  '    - ✅ EXACT MATCH with instructor section: $instructorSection',
                );
              }

              return exactMatch;
            });

            print('    - Match result: $matches');
            return matches;
          }).toList();

      print('  - Filtered submissions count: ${filteredSubmissions.length}');
      return filteredSubmissions;
    } else {
      // Filter by specific section - use exact matching only
      final filteredSubmissions =
          submissions.where((submission) {
            final submissionSectionId = submission['sectionId'] ?? '';
            final submissionSectionName = submission['sectionName'] ?? '';

            print('  - Checking submission: ${submission['studentName']}');
            print('    - Submission sectionId: $submissionSectionId');
            print('    - Submission sectionName: $submissionSectionName');
            print('    - Target section: $sectionId');

            // Use exact matching only - no contains() to prevent false matches
            final exactMatch =
                submissionSectionId == sectionId ||
                submissionSectionName == sectionId;

            print('    - Exact match result: $exactMatch');
            return exactMatch;
          }).toList();

      print('  - Filtered submissions count: ${filteredSubmissions.length}');
      return filteredSubmissions;
    }
  }

  // Load submissions with real-time updates for specific activity
  Future<void> loadSubmissionsWithRealtimeUpdates(
    String activityId,
    String itemType,
    String? sectionId,
  ) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('🔄 Loading submissions with real-time updates:');
      print('  - Activity ID: $activityId');
      print('  - Item Type: $itemType');
      print('  - Section ID: $sectionId');

      // Load initial submissions
      switch (itemType.toLowerCase()) {
        case 'assignment':
          await loadAssignmentSubmissions(activityId, sectionId: sectionId);
          break;
        case 'activity':
          await loadActivitySubmissions(activityId, sectionId: sectionId);
          break;
        case 'quiz':
          await loadQuizSubmissions(activityId, sectionId: sectionId);
          break;
        case 'pit':
          // For PITs, we need to load from the submissions collection
          await _loadPitSubmissions(activityId, sectionId: sectionId);
          break;
        default:
          await loadInstructorSubmissions(sectionId: sectionId);
      }

      // Real-time listener removed - no more automatic updates
    } catch (e) {
      print('❌ Error loading submissions with real-time updates: $e');
      errorMessage.value = 'Failed to load submissions: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Load PIT submissions specifically
  Future<void> _loadPitSubmissions(String pitId, {String? sectionId}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Build query - query directly by sectionName when sectionId is provided (like class_report_controller)
      Query query = _firestore
          .collection('submissions')
          .where('activityId', isEqualTo: pitId)
          .where('instructorId', isEqualTo: user.uid)
          .where('activityType', isEqualTo: 'pit');

      // If a specific section is provided, query directly by sectionName in Firestore
      if (sectionId != null && sectionId.isNotEmpty) {
        print(
          '  - Querying PIT submissions directly by sectionName: $sectionId',
        );
        query = query.where('sectionName', isEqualTo: sectionId);
      } else {
        final instructorSections = await _getInstructorSections(user.uid);
        if (instructorSections.isEmpty) return;
      }

      QuerySnapshot querySnapshot;
      try {
        querySnapshot =
            await query.orderBy('submittedAt', descending: true).get();
      } catch (e) {
        querySnapshot = await query.get();
      }

      List<Map<String, dynamic>> loadedSubmissions = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        loadedSubmissions.add({'id': doc.id, 'type': 'pit', ...data});
      }

      // If no specific section was provided, filter by instructor sections
      if (sectionId == null || sectionId.isEmpty) {
        final instructorSections = await _getInstructorSections(user.uid);
        if (instructorSections.isNotEmpty) {
          loadedSubmissions = _filterSubmissionsBySection(
            loadedSubmissions,
            sectionId,
            instructorSections,
          );
        }
      }

      submissions.assignAll(loadedSubmissions);
      updateStats();
    } catch (e) {
      print('❌ Error loading PIT submissions: $e');
    }
  }

  /// Load tree planting submissions
  Future<void> loadTreePlantingSubmissions({String? sectionId}) async {
    try {
      isLoading.value = true;
      _currentActivityId = 'tree_planting';
      _currentActivityType = 'tree_planting';
      _currentSectionId = sectionId;

      final user = _auth.currentUser;
      if (user == null) {
        submissions.value = [];
        isLoading.value = false;
        return;
      }

      print('🌳 Loading tree planting submissions for instructor: ${user.uid}');

      // Build query - get all tree planting submissions for this instructor
      Query query = _firestore
          .collection('submissions')
          .where('activityType', isEqualTo: 'tree_planting')
          .where('instructorId', isEqualTo: user.uid);

      // Filter by section if provided
      if (sectionId != null && sectionId.isNotEmpty) {
        print('🌳 Filtering by section: $sectionId');
        query = query.where('sectionName', isEqualTo: sectionId);
      }

      QuerySnapshot querySnapshot;
      try {
        querySnapshot =
            await query.orderBy('submittedAt', descending: true).get();
      } catch (e) {
        print('🌳 OrderBy failed, trying without it: $e');
        querySnapshot = await query.get();
      }

      print('🌳 Found ${querySnapshot.docs.length} tree planting submissions');

      List<Map<String, dynamic>> loadedSubmissions = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        loadedSubmissions.add({'id': doc.id, 'type': 'tree_planting', ...data});
      }

      // If no specific section was provided, filter by instructor sections
      if (sectionId == null || sectionId.isEmpty) {
        final instructorSections = await _getInstructorSections(user.uid);
        if (instructorSections.isNotEmpty) {
          loadedSubmissions = _filterSubmissionsBySection(
            loadedSubmissions,
            sectionId,
            instructorSections,
          );
        }
      }

      submissions.assignAll(loadedSubmissions);
      updateStats();
      isLoading.value = false;

      print('🌳 Loaded ${loadedSubmissions.length} tree planting submissions');
    } catch (e) {
      print('❌ Error loading tree planting submissions: $e');
      submissions.value = [];
      isLoading.value = false;
    }
  }

  /// Update submission status (for tree planting approvals/rejections)
  Future<void> updateSubmissionStatus(
    String submissionId,
    String status, {
    String? feedback,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Update the document in submissions collection
      await _firestore.collection('submissions').doc(submissionId).update({
        'status': status,
        'feedback': feedback,
        'gradedAt': FieldValue.serverTimestamp(),
        'gradedBy': user.uid,
      });

      // Update local submission
      final index = submissions.indexWhere((s) => s['id'] == submissionId);
      if (index != -1) {
        submissions[index]['status'] = status;
        submissions[index]['feedback'] = feedback;
        submissions[index]['gradedAt'] = Timestamp.now();
        submissions[index]['gradedBy'] = user.uid;
        submissions.refresh();
        updateStats();
      }

      print('✅ Submission $submissionId status updated to: $status');
    } catch (e) {
      print('❌ Error updating submission status: $e');
      rethrow;
    }
  }

  // Set up real-time listener for submissions
  StreamSubscription<QuerySnapshot>? _realtimeSubscription;
  StreamSubscription<QuerySnapshot>? _allSubmissionsSubscription;

  void _setupRealtimeListener(
    String activityId,
    String itemType,
    String? sectionId,
  ) {
    // Real-time listener removed - no more automatic updates
    print('Real-time listener disabled - no automatic updates');
  }

  // Get submission collection name based on item type

  // Get activity ID field name based on item type
  // NOTE: Now all submissions use unified 'activityId' field
  @Deprecated('Use unified activityId field directly')
  String _getActivityIdField(String itemType) {
    return 'activityId'; // Unified activity ID field for all submission types
  }

  // Set up real-time listener for all instructor submissions
  void setupAllSubmissionsRealtimeListener({String? sectionId}) {
    // Real-time listener removed - no more automatic updates
    print('Real-time listener disabled - no automatic updates');
  }

  // Handle new submission from real-time service
  void _handleNewSubmission(Map<String, dynamic> submission) {
    print(
      '📥 Handling new submission: ${submission['studentName']} - ${submission['type']}',
    );

    // Check if submission matches current section filter
    if (_currentSectionId != null && _currentSectionId!.isNotEmpty) {
      final submissionSectionId = submission['sectionId'] ?? '';
      final submissionSectionName = submission['sectionName'] ?? '';

      final sectionMatch =
          submissionSectionId == _currentSectionId ||
          submissionSectionName == _currentSectionId;

      if (!sectionMatch) {
        print(
          '  - ❌ Submission filtered out by section: ${submission['studentName']} (section: $submissionSectionId/$submissionSectionName, target: $_currentSectionId)',
        );
        return; // Don't add this submission
      }

      print(
        '  - ✅ Submission matches current section: ${submission['studentName']}',
      );
    }

    // Check if submission already exists to prevent duplicates
    final existingIndex = submissions.indexWhere(
      (s) => s['id'] == submission['id'],
    );

    if (existingIndex != -1) {
      print(
        '  - ⚠️ Submission already exists in list: ${submission['studentName']}',
      );
      return; // Don't add duplicate
    }

    // Add to current submissions list
    List<Map<String, dynamic>> currentSubmissions = List.from(submissions);
    currentSubmissions.add(submission);

    // Sort by submission date
    currentSubmissions.sort((a, b) {
      try {
        final aDate = _parseTimestamp(a['submittedAt']);
        final bDate = _parseTimestamp(b['submittedAt']);
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate);
      } catch (e) {
        return 0;
      }
    });

    // Update the submissions list
    submissions.assignAll(currentSubmissions);
    updateStats();

    print('✅ New submission added to list: ${submission['studentName']}');
  }

  // Handle submission update from real-time service
  void _handleSubmissionUpdate(Map<String, dynamic> updatedSubmission) {
    print(
      '📝 Handling submission update: ${updatedSubmission['studentName']} - ${updatedSubmission['type']}',
    );

    // Check if submission matches current section filter
    if (_currentSectionId != null && _currentSectionId!.isNotEmpty) {
      final submissionSectionId = updatedSubmission['sectionId'] ?? '';
      final submissionSectionName = updatedSubmission['sectionName'] ?? '';

      final sectionMatch =
          submissionSectionId == _currentSectionId ||
          submissionSectionName == _currentSectionId;

      if (!sectionMatch) {
        print(
          '  - ❌ Submission update filtered out by section: ${updatedSubmission['studentName']} (section: $submissionSectionId/$submissionSectionName, target: $_currentSectionId)',
        );
        // Remove from list if it was previously there
        final index = submissions.indexWhere(
          (s) => s['id'] == updatedSubmission['id'],
        );
        if (index != -1) {
          submissions.removeAt(index);
          submissions.refresh();
          updateStats();
          print('  - 🗑️ Removed submission from list due to section mismatch');
        }
        return;
      }

      print(
        '  - ✅ Submission update matches current section: ${updatedSubmission['studentName']}',
      );
    }

    // Find and update the submission in the list
    final index = submissions.indexWhere(
      (s) => s['id'] == updatedSubmission['id'],
    );
    if (index != -1) {
      submissions[index] = updatedSubmission;
      submissions.refresh();
      updateStats();
      print(
        '✅ Submission updated in list: ${updatedSubmission['studentName']}',
      );
    }
  }

  // Handle submission graded from real-time service
  void _handleSubmissionGraded(Map<String, dynamic> gradedSubmission) {
    print(
      '✅ Handling graded submission: ${gradedSubmission['studentName']} - ${gradedSubmission['type']}',
    );

    // Find and update the submission in the list
    final index = submissions.indexWhere(
      (s) => s['id'] == gradedSubmission['id'],
    );
    if (index != -1) {
      submissions[index] = gradedSubmission;
      submissions.refresh();
      updateStats();
      print(
        '✅ Graded submission updated in list: ${gradedSubmission['studentName']}',
      );
    }
  }

  // Refresh submissions
  Future<void> refreshSubmissions() async {
    // This would need to be called with the appropriate parameters
    // based on the current context (assignment, activity, or instructor view)
    await loadInstructorSubmissions();
  }

  // Real-time updates for submissions
  Stream<QuerySnapshot> getRealtimeSubmissions(
    String activityId,
    String submissionType,
    String? sectionId,
  ) {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    return SubmissionRoutingService.getSubmissionUpdates(
      user.uid,
      activityId,
      submissionType,
    );
  }

  // Real-time updates for notifications
  Stream<QuerySnapshot> getRealtimeNotifications() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    return SubmissionRoutingService.getNotificationUpdates(user.uid);
  }

  // Helper method to parse timestamps safely
  DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;

    try {
      if (timestamp is String) {
        return DateTime.parse(timestamp);
      } else if (timestamp is DateTime) {
        return timestamp;
      } else if (timestamp is Timestamp) {
        return timestamp.toDate();
      }
      return null;
    } catch (e) {
      print('❌ Error parsing timestamp: $e');
      return null;
    }
  }

  // Remove a submission from the list and Firestore
  Future<bool> removeSubmission(
    String submissionId,
    String submissionType,
  ) async {
    try {
      print('🗑️ Removing submission: $submissionId of type: $submissionType');

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Determine the collection based on submission type
      String collectionName;
      switch (submissionType.toLowerCase()) {
        case 'assignment':
          collectionName = 'assignment_submissions';
          break;
        case 'activity':
          collectionName = 'activity_submissions';
          break;
        case 'quiz':
          collectionName = 'quiz_submissions';
          break;
        default:
          collectionName = 'assignment_submissions';
      }

      // Delete from Firestore
      await _firestore.collection(collectionName).doc(submissionId).delete();

      // Remove from local list
      submissions.removeWhere((submission) => submission['id'] == submissionId);

      // Update stats
      updateStats();

      print('✅ Successfully removed submission: $submissionId');
      return true;
    } catch (e) {
      print('❌ Error removing submission: $e');
      errorMessage.value = 'Failed to remove submission: $e';
      return false;
    }
  }
}
