import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StudentSubmissionController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable variables
  final RxBool isLoading = false.obs;
  final RxMap<String, dynamic> submissionData = <String, dynamic>{}.obs;
  final RxString errorMessage = ''.obs;
  final RxString submissionStatus = 'Missing'.obs;
  final RxDouble submissionScore = 0.0.obs;
  final RxString submissionFeedback = ''.obs;
  final RxBool isGraded = false.obs;

  // Stream subscription for real-time updates
  StreamSubscription<QuerySnapshot>? _submissionStream;

  @override
  void onInit() {
    super.onInit();
    // Initialize with default values
    submissionStatus.value = 'Missing';
    submissionScore.value = 0.0;
    submissionFeedback.value = '';
    isGraded.value = false;
  }

  @override
  void onClose() {
    _submissionStream?.cancel();
    super.onClose();
  }

  // Load submission data for a specific activity/assignment
  Future<void> loadSubmissionData({
    required String activityId,
    required String activityType, // 'activity', 'assignment', or 'quiz'
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      log('📚 Loading submission data for $activityType: $activityId');

      // Query unified submissions collection
      final query =
          await _firestore
              .collection('submissions')
              .where('studentId', isEqualTo: user.uid)
              .where('activityType', isEqualTo: activityType.toLowerCase())
              .where('activityId', isEqualTo: activityId)
              .limit(1)
              .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();
        data['id'] = doc.id;

        submissionData.value = data;
        _updateSubmissionStatus(data);

        log('✅ Found submission data: ${data['status']}');
      } else {
        // No submission found
        submissionData.value = {};
        submissionStatus.value = 'Missing';
        submissionScore.value = 0.0;
        submissionFeedback.value = '';
        isGraded.value = false;

        log('📚 No submission found for this $activityType');
      }

      // Set up real-time listener for updates
      _setupRealtimeListener(activityId, activityType);
    } catch (e) {
      log('❌ Error loading submission data: $e');
      errorMessage.value = 'Failed to load submission data: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Set up real-time listener for submission updates
  void _setupRealtimeListener(String activityId, String activityType) {
    final user = _auth.currentUser;
    if (user == null) return;

    // Cancel existing stream
    _submissionStream?.cancel();

    // Create new stream from unified submissions collection
    _submissionStream = _firestore
        .collection('submissions')
        .where('studentId', isEqualTo: user.uid)
        .where('activityType', isEqualTo: activityType.toLowerCase())
        .where('activityId', isEqualTo: activityId)
        .limit(1)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.docs.isNotEmpty) {
              final doc = snapshot.docs.first;
              final data = doc.data();
              data['id'] = doc.id;

              submissionData.value = data;
              _updateSubmissionStatus(data);

              log(
                '🔄 Real-time update received: ${data['status']} - Score: ${data['grade']}',
              );
            } else {
              // No submission found
              submissionData.value = {};
              submissionStatus.value = 'Missing';
              submissionScore.value = 0.0;
              submissionFeedback.value = '';
              isGraded.value = false;
            }
          },
          onError: (error) {
            log('❌ Real-time listener error: $error');
            errorMessage.value = 'Real-time update failed: $error';
          },
        );
  }

  // Update submission status based on data
  void _updateSubmissionStatus(Map<String, dynamic> data) {
    final status = data['status'] ?? 'submitted';
    final grade = data['grade']?.toDouble() ?? 0.0;
    final feedback = data['feedback'] ?? '';

    if (status == 'graded' && grade > 0) {
      submissionStatus.value = '${grade.toInt()}';
      submissionScore.value = grade;
      submissionFeedback.value = feedback;
      isGraded.value = true;
    } else if (status == 'submitted') {
      submissionStatus.value = 'Submitted';
      submissionScore.value = 0.0;
      submissionFeedback.value = '';
      isGraded.value = false;
    } else {
      submissionStatus.value = 'Missing';
      submissionScore.value = 0.0;
      submissionFeedback.value = '';
      isGraded.value = false;
    }
  }

  // Get collection name based on activity type (deprecated - kept for backwards compatibility)
  @Deprecated('Use unified submissions collection directly')
  String _getCollectionName(String activityType) {
    return 'submissions'; // Unified collection for all submission types
  }

  // Get status color for UI
  Color getStatusColor() {
    if (isGraded.value) {
      return Colors.green;
    } else if (submissionStatus.value == 'Submitted') {
      return Colors.blue;
    } else {
      return Colors.red;
    }
  }

  // Get status icon for UI
  IconData getStatusIcon() {
    if (isGraded.value) {
      return Icons.check_circle;
    } else if (submissionStatus.value == 'Submitted') {
      return Icons.upload_file;
    } else {
      return Icons.schedule;
    }
  }

  // Get formatted submission date
  String getFormattedSubmissionDate() {
    final submittedAt = submissionData['submittedAt'];
    if (submittedAt == null) return 'Not submitted';

    try {
      if (submittedAt is Timestamp) {
        final date = submittedAt.toDate();
        return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (submittedAt is String) {
        final date = DateTime.parse(submittedAt);
        return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return 'Invalid date';
    }

    return 'Not submitted';
  }

  // Check if submission is late
  bool isSubmissionLate() {
    // This would need to be implemented based on the activity/assignment due date
    // For now, return false as a placeholder
    return false;
  }
}
