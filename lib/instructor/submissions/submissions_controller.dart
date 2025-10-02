import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SubmissionsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable variables
  final RxBool isLoading = false.obs;
  final RxList<Map<String, dynamic>> submissions = <Map<String, dynamic>>[].obs;
  final RxString errorMessage = ''.obs;
  final RxString selectedFilter = 'All'.obs;
  final RxMap<String, int> submissionStats = <String, int>{}.obs;

  // Filters
  final List<String> filterOptions = ['All', 'Submitted', 'Graded', 'Late'];

  @override
  void onInit() {
    super.onInit();
    // Initialize stats
    submissionStats.value = {
      'total': 0,
      'submitted': 0,
      'graded': 0,
      'late': 0,
      'pending': 0,
    };
  }

  // Load submissions for a specific assignment
  Future<void> loadAssignmentSubmissions(String assignmentId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      log('📚 Loading submissions for assignment: $assignmentId');

      final query =
          await _firestore
              .collection('assignment_submissions')
              .where('assignmentId', isEqualTo: assignmentId)
              .orderBy('submittedAt', descending: true)
              .get();

      List<Map<String, dynamic>> loadedSubmissions = [];

      for (var doc in query.docs) {
        final data = doc.data();
        loadedSubmissions.add({'id': doc.id, 'type': 'assignment', ...data});
      }

      submissions.assignAll(loadedSubmissions);
      _updateStats();

      log('✅ Loaded ${loadedSubmissions.length} assignment submissions');
    } catch (e) {
      log('❌ Error loading assignment submissions: $e');
      errorMessage.value = 'Failed to load submissions: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Load submissions for a specific activity
  Future<void> loadActivitySubmissions(String activityId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      log('📚 Loading submissions for activity: $activityId');

      final query =
          await _firestore
              .collection('activity_submissions')
              .where('activityId', isEqualTo: activityId)
              .orderBy('submittedAt', descending: true)
              .get();

      List<Map<String, dynamic>> loadedSubmissions = [];

      for (var doc in query.docs) {
        final data = doc.data();
        loadedSubmissions.add({'id': doc.id, 'type': 'activity', ...data});
      }

      submissions.assignAll(loadedSubmissions);
      _updateStats();

      log('✅ Loaded ${loadedSubmissions.length} activity submissions');
    } catch (e) {
      log('❌ Error loading activity submissions: $e');
      errorMessage.value = 'Failed to load submissions: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Load submissions for a specific instructor and section
  Future<void> loadInstructorSubmissions({
    String? instructorId,
    String? sectionId,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = _auth.currentUser;
      final currentInstructorId = instructorId ?? user?.uid;

      if (currentInstructorId == null) {
        throw Exception('No instructor ID provided');
      }

      log('📚 Loading submissions for instructor: $currentInstructorId');

      List<Map<String, dynamic>> allSubmissions = [];

      // Load assignment submissions
      Query assignmentQuery = _firestore
          .collection('assignment_submissions')
          .where('instructorId', isEqualTo: currentInstructorId);

      if (sectionId != null && sectionId.isNotEmpty) {
        assignmentQuery = assignmentQuery.where(
          'sectionId',
          isEqualTo: sectionId,
        );
      }

      final assignmentDocs =
          await assignmentQuery.orderBy('submittedAt', descending: true).get();

      for (var doc in assignmentDocs.docs) {
        final data = doc.data() as Map<String, dynamic>;
        allSubmissions.add({'id': doc.id, 'type': 'assignment', ...data});
      }

      // Load activity submissions
      Query activityQuery = _firestore
          .collection('activity_submissions')
          .where('instructorId', isEqualTo: currentInstructorId);

      if (sectionId != null && sectionId.isNotEmpty) {
        activityQuery = activityQuery.where('sectionId', isEqualTo: sectionId);
      }

      final activityDocs =
          await activityQuery.orderBy('submittedAt', descending: true).get();

      for (var doc in activityDocs.docs) {
        final data = doc.data() as Map<String, dynamic>;
        allSubmissions.add({'id': doc.id, 'type': 'activity', ...data});
      }

      // Sort by submission date
      allSubmissions.sort((a, b) {
        final aDate = a['submittedAt'] as Timestamp?;
        final bDate = b['submittedAt'] as Timestamp?;
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate);
      });

      submissions.assignAll(allSubmissions);
      _updateStats();

      log('✅ Loaded ${allSubmissions.length} total submissions');
    } catch (e) {
      log('❌ Error loading instructor submissions: $e');
      errorMessage.value = 'Failed to load submissions: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Update submission statistics
  void _updateStats() {
    final total = submissions.length;
    final submitted =
        submissions.where((s) => s['status'] == 'submitted').length;
    final graded = submissions.where((s) => s['status'] == 'graded').length;
    final late = submissions.where((s) => _isLateSubmission(s)).length;
    final pending = submitted - graded;

    submissionStats.value = {
      'total': total,
      'submitted': submitted,
      'graded': graded,
      'late': late,
      'pending': pending,
    };
  }

  // Check if submission is late
  bool _isLateSubmission(Map<String, dynamic> submission) {
    // This would need to be implemented based on the assignment/activity due date
    // For now, return false as a placeholder
    return false;
  }

  // Filter submissions
  List<Map<String, dynamic>> get filteredSubmissions {
    if (selectedFilter.value == 'All') {
      return submissions;
    }

    return submissions.where((submission) {
      switch (selectedFilter.value) {
        case 'Submitted':
          return submission['status'] == 'submitted';
        case 'Graded':
          return submission['status'] == 'graded';
        case 'Late':
          return _isLateSubmission(submission);
        default:
          return true;
      }
    }).toList();
  }

  // Set filter
  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  // Grade a submission
  Future<bool> gradeSubmission({
    required String submissionId,
    required String submissionType, // 'assignment' or 'activity'
    required double score,
    String? feedback,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final collection =
          submissionType == 'assignment'
              ? 'assignment_submissions'
              : 'activity_submissions';

      await _firestore.collection(collection).doc(submissionId).update({
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
        _updateStats();
      }

      log('✅ Graded submission successfully');

      Get.snackbar(
        'Success',
        'Submission graded successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      log('❌ Error grading submission: $e');
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
      log('Error formatting date: $e');
      return 'Unknown Date';
    }
  }

  // Refresh submissions
  Future<void> refreshSubmissions() async {
    // This would need to be called with the appropriate parameters
    // based on the current context (assignment, activity, or instructor view)
  }
}
