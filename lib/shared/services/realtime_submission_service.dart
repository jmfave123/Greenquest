import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Service responsible for handling real-time submission updates
/// and notifications for instructors
class RealtimeSubmissionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream subscriptions for different submission types
  static StreamSubscription<QuerySnapshot>? _assignmentSubscription;
  static StreamSubscription<QuerySnapshot>? _activitySubscription;
  static StreamSubscription<QuerySnapshot>? _quizSubscription;
  static StreamSubscription<QuerySnapshot>? _pitSubscription;

  // Callback functions for different events
  static Function(Map<String, dynamic>)? onNewSubmission;
  static Function(Map<String, dynamic>)? onSubmissionUpdate;
  static Function(Map<String, dynamic>)? onSubmissionGraded;

  /// Initialize real-time listeners for all submission types
  static void initializeRealtimeListeners({
    String? instructorId,
    String? sectionId,
    Function(Map<String, dynamic>)? onNewSubmissionCallback,
    Function(Map<String, dynamic>)? onSubmissionUpdateCallback,
    Function(Map<String, dynamic>)? onSubmissionGradedCallback,
  }) {
    final currentInstructorId = instructorId ?? _auth.currentUser?.uid;
    if (currentInstructorId == null) return;

    // Set up callbacks
    onNewSubmission = onNewSubmissionCallback;
    onSubmissionUpdate = onSubmissionUpdateCallback;
    onSubmissionGraded = onSubmissionGradedCallback;

    print(
      '🔄 Initializing real-time listeners for instructor: $currentInstructorId',
    );

    // Set up assignment submissions listener
    _assignmentSubscription = _firestore
        .collection('assignment_submissions')
        .where('instructorId', isEqualTo: currentInstructorId)
        .snapshots()
        .listen(
          (QuerySnapshot snapshot) {
            _handleSubmissionUpdate(snapshot, 'assignment', sectionId);
          },
          onError: (error) {
            print('❌ Assignment submissions listener error: $error');
          },
        );

    // Set up activity submissions listener
    _activitySubscription = _firestore
        .collection('activity_submissions')
        .where('instructorId', isEqualTo: currentInstructorId)
        .snapshots()
        .listen(
          (QuerySnapshot snapshot) {
            _handleSubmissionUpdate(snapshot, 'activity', sectionId);
          },
          onError: (error) {
            print('❌ Activity submissions listener error: $error');
          },
        );

    // Set up quiz submissions listener
    _quizSubscription = _firestore
        .collection('quiz_submissions')
        .where('instructorId', isEqualTo: currentInstructorId)
        .snapshots()
        .listen(
          (QuerySnapshot snapshot) {
            _handleSubmissionUpdate(snapshot, 'quiz', sectionId);
          },
          onError: (error) {
            print('❌ Quiz submissions listener error: $error');
          },
        );

    // Set up PIT submissions listener
    _pitSubscription = _firestore
        .collection('submissions')
        .where('instructorId', isEqualTo: currentInstructorId)
        .where('activityType', isEqualTo: 'pit')
        .snapshots()
        .listen(
          (QuerySnapshot snapshot) {
            _handleSubmissionUpdate(snapshot, 'pit', sectionId);
          },
          onError: (error) {
            print('❌ PIT submissions listener error: $error');
          },
        );
  }

  /// Handle submission updates from Firestore
  static void _handleSubmissionUpdate(
    QuerySnapshot snapshot,
    String submissionType,
    String? sectionId,
  ) {
    print(
      '🔄 Real-time update received for $submissionType: ${snapshot.docs.length} documents',
    );

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final submission = {'id': doc.id, 'type': submissionType, ...data};

      // Filter by section if specified
      if (sectionId != null && sectionId.isNotEmpty) {
        final submissionSectionId = submission['sectionId'] ?? '';
        final submissionSectionName = submission['sectionName'] ?? '';

        // Check if submission belongs to the specified section
        final sectionMatch =
            submissionSectionId == sectionId ||
            submissionSectionName == sectionId;

        if (!sectionMatch) {
          print(
            '  - ❌ Submission filtered out: ${submission['studentName']} (section: $submissionSectionId/$submissionSectionName, target: $sectionId)',
          );
          continue; // Skip this submission
        }

        print('  - ✅ Submission matches section: ${submission['studentName']}');
      }

      // Check if this is a new submission or an update
      final docChanges = snapshot.docChanges;
      for (var change in docChanges) {
        if (change.type == DocumentChangeType.added) {
          print(
            '📥 New $submissionType submission: ${submission['studentName']}',
          );
          _notifyNewSubmission(submission);
        } else if (change.type == DocumentChangeType.modified) {
          print(
            '📝 Updated $submissionType submission: ${submission['studentName']}',
          );
          _notifySubmissionUpdate(submission);

          // Check if submission was graded
          if (submission['status'] == 'graded' && submission['grade'] != null) {
            print(
              '✅ Graded $submissionType submission: ${submission['studentName']}',
            );
            _notifySubmissionGraded(submission);
          }
        }
      }
    }
  }

  /// Notify about new submission
  static void _notifyNewSubmission(Map<String, dynamic> submission) {
    if (onNewSubmission != null) {
      onNewSubmission!(submission);
    }

    // Show snackbar notification
    // Get.snackbar(
    //   'New Submission',
    //   '${submission['studentName']} submitted ${submission['type']}',
    //   snackPosition: SnackPosition.TOP,
    //   backgroundColor: Colors.blue,
    //   colorText: Colors.white,
    //   duration: const Duration(seconds: 3),
    //   icon: const Icon(Icons.upload_file, color: Colors.white),
    // );
  }

  /// Notify about submission update
  static void _notifySubmissionUpdate(Map<String, dynamic> submission) {
    if (onSubmissionUpdate != null) {
      onSubmissionUpdate!(submission);
    }
  }

  /// Notify about submission being graded
  static void _notifySubmissionGraded(Map<String, dynamic> submission) {
    if (onSubmissionGraded != null) {
      onSubmissionGraded!(submission);
    }

    // Show snackbar notification
    Get.snackbar(
      'Submission Graded',
      '${submission['type']} by ${submission['studentName']} has been graded',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  /// Get real-time stream for specific submission type
  static Stream<QuerySnapshot> getSubmissionStream(
    String submissionType,
    String instructorId, {
    String? sectionId,
  }) {
    String collectionName = _getCollectionName(submissionType);
    Query query = _firestore
        .collection(collectionName)
        .where('instructorId', isEqualTo: instructorId);

    if (sectionId != null && sectionId.isNotEmpty) {
      query = query.where('sectionId', isEqualTo: sectionId);
    }

    return query.orderBy('submittedAt', descending: true).snapshots();
  }

  /// Get collection name for submission type
  static String _getCollectionName(String submissionType) {
    switch (submissionType.toLowerCase()) {
      case 'assignment':
        return 'assignment_submissions';
      case 'activity':
        return 'activity_submissions';
      case 'quiz':
        return 'quiz_submissions';
      case 'pit':
        return 'submissions';
      default:
        return 'activity_submissions';
    }
  }

  /// Clean up all subscriptions
  static void dispose() {
    _assignmentSubscription?.cancel();
    _activitySubscription?.cancel();
    _quizSubscription?.cancel();
    _pitSubscription?.cancel();

    _assignmentSubscription = null;
    _activitySubscription = null;
    _quizSubscription = null;
    _pitSubscription = null;

    onNewSubmission = null;
    onSubmissionUpdate = null;
    onSubmissionGraded = null;

    print('🧹 RealtimeSubmissionService disposed');
  }

  /// Check if there are active subscriptions
  static bool get hasActiveSubscriptions {
    return _assignmentSubscription != null ||
        _activitySubscription != null ||
        _quizSubscription != null ||
        _pitSubscription != null;
  }
}
