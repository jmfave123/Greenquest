import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/services/submission_routing_service.dart';

class QuizController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable variables
  final RxBool isLoading = false.obs;
  final RxList<Map<String, dynamic>> quizzes = <Map<String, dynamic>>[].obs;
  final RxString errorMessage = ''.obs;
  final RxString currentInstructorUid = ''.obs;
  final RxString currentInstructorName = ''.obs;
  final RxMap<String, dynamic> selectedQuiz = <String, dynamic>{}.obs;
  final RxMap<String, String> submissionStatus = <String, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCurrentInstructor();
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
        log('📚 Student section code: $sectionCode');
        return sectionCode;
      }
      return null;
    } catch (e) {
      log('❌ Error getting user section code: $e');
      return null;
    }
  }

  // Load current instructor information
  Future<void> _loadCurrentInstructor() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        log('❌ No authenticated user');
        return;
      }

      log('🔍 Loading instructor for user: ${user.uid}');

      // Get user's selected instructor from their profile
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final instructorId = userData['selectedInstructorId'] ?? '';
        final instructorName = userData['selectedInstructorName'] ?? '';
        final selectionComplete = userData['selectionComplete'] ?? false;

        log(
          '📋 User data: selectedInstructorId=$instructorId, selectedInstructorName=$instructorName, selectionComplete=$selectionComplete',
        );

        if (selectionComplete && instructorId.isNotEmpty) {
          currentInstructorUid.value = instructorId;
          currentInstructorName.value = instructorName;

          log('📚 Loaded instructor: $instructorName ($instructorId)');

          // Load quizzes for this instructor
          await loadQuizzes();
        } else {
          log(
            '⚠️ User has not completed instructor selection or no instructor selected',
          );
          errorMessage.value = 'Please select an instructor first';
        }
      } else {
        log('❌ User document not found');
        errorMessage.value = 'User profile not found';
      }
    } catch (e) {
      log('❌ Error loading current instructor: $e');
      errorMessage.value = 'Failed to load instructor: $e';
    }
  }

  // Load quizzes for the current instructor
  Future<void> loadQuizzes() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      if (currentInstructorUid.value.isEmpty) {
        log('❌ No instructor selected');
        quizzes.clear();
        return;
      }

      // Get student's section code for filtering
      final userSectionCode = await _getUserSectionCode();
      log('📚 Student section code: $userSectionCode');

      log('📚 Loading quizzes for instructor: ${currentInstructorUid.value}');

      // Query quizzes subcollection under the instructor document
      final query =
          await _firestore
              .collection('instructors')
              .doc(currentInstructorUid.value)
              .collection('quizzes')
              .orderBy('createdAt', descending: true)
              .get();

      List<Map<String, dynamic>> loadedQuizzes = [];

      for (var doc in query.docs) {
        final quizData = doc.data();

        // Skip if quizData is null or empty
        if (quizData.isEmpty) {
          log('⚠️ Quiz ${doc.id} has empty data, skipping');
          continue;
        }

        // Get selected classes for this quiz
        final selectedClasses = List<String>.from(
          quizData['selectedClasses'] ?? [],
        );

        // 🎯 FILTER BY SECTION: Only include if student's section is in selectedClasses
        if (userSectionCode != null &&
            userSectionCode.isNotEmpty &&
            selectedClasses.isNotEmpty) {
          if (!selectedClasses.contains(userSectionCode)) {
            log(
              '❌ Skipping quiz "${quizData['title']}" - not for section $userSectionCode',
            );
            continue;
          }
          log(
            '✅ Quiz "${quizData['title']}" matches student section $userSectionCode',
          );
        }

        // Create quiz map with proper data structure
        Map<String, dynamic> quizMap = {
          'id': doc.id,
          'title': quizData['title']?.toString() ?? 'No Title',
          'instruction':
              quizData['instruction']?.toString() ??
              'No instructions available',
          'instructorName': currentInstructorName.value,
          'instructorId': currentInstructorUid.value,
          'points': quizData['points'] ?? 0,
          'dueDate': _formatDate(quizData['dueDate']),
          'createdAt': _formatDate(quizData['createdAt']),
          'isActive': quizData['isActive'] ?? true,
          'period': quizData['period']?.toString() ?? '',
          'questions': quizData['questions'] ?? [],
          'selectedClasses': selectedClasses,
          'type': 'Quiz',
        };

        log('📚 Processed quiz: ${quizMap['title']}');
        loadedQuizzes.add(quizMap);
      }

      quizzes.assignAll(loadedQuizzes);
      log(
        '✅ Loaded ${loadedQuizzes.length} quizzes (filtered by section $userSectionCode)',
      );

      // Load submission statuses for all quizzes
      await loadSubmissionStatuses();
    } catch (e) {
      log('❌ Error loading quizzes: $e');
      errorMessage.value = 'Failed to load quizzes: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Refresh quizzes
  Future<void> refreshQuizzes() async {
    await loadQuizzes();
  }

  // Set selected quiz
  void setSelectedQuiz(Map<String, dynamic> quiz) {
    selectedQuiz.value = quiz;
  }

  // Format date for display
  String _formatDate(dynamic timestamp) {
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

      // Format as "Sep 25, 2025"
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
      log('Error formatting date: $e');
      return 'Unknown Date';
    }
  }

  // Submit quiz using automatic routing
  Future<void> submitQuiz(String quizId, Map<String, dynamic> answers) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      log('📤 Submitting quiz: $quizId');
      log('📝 Answers: ${answers.keys.length} questions answered');

      // Get user data for student information
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      // Create submission data
      final submissionData = {
        'studentId': user.uid,
        'studentName':
            user.displayName ?? user.email?.split('@')[0] ?? 'Student',
        'studentEmail': user.email ?? '',
        'studentIdNumber': userData['idNumber'] ?? user.uid,
        'answers': answers,
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'submitted',
        'grade': null,
        'feedback': null,
        'gradedAt': null,
      };

      // Use routing service to automatically route submission to correct instructor
      final routingResult = await SubmissionRoutingService.routeSubmission(
        activityId: quizId,
        submissionType: 'quiz',
        submissionData: submissionData,
      );

      if (!routingResult['success']) {
        throw Exception(routingResult['error'] ?? 'Failed to route submission');
      }

      log('✅ Quiz submission routed successfully');
      log('📍 Routed to instructor: ${routingResult['instructorId']}');
      log('📍 Section: ${routingResult['sectionId']}');

      Get.snackbar(
        'Success',
        'Quiz submitted and routed to instructor!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      log('❌ Error submitting quiz: $e');
      Get.snackbar(
        'Error',
        'Failed to submit quiz: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Get submission status for a quiz
  Future<String> getSubmissionStatus(String quizId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'not_submitted';

      final query =
          await _firestore
              .collection('submissions')
              .where('activityType', isEqualTo: 'quiz')
              .where('activityId', isEqualTo: quizId)
              .where('studentId', isEqualTo: user.uid)
              .limit(1)
              .get();

      if (query.docs.isNotEmpty) {
        final submissionData = query.docs.first.data();
        return submissionData['status']?.toString() ?? 'not_submitted';
      }

      return 'not_submitted';
    } catch (e) {
      log('❌ Error getting submission status: $e');
      return 'not_submitted';
    }
  }

  /// Load submission statuses for all quizzes
  Future<void> loadSubmissionStatuses() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Clear existing statuses
      submissionStatus.clear();

      // Get status for each quiz
      for (final quiz in quizzes) {
        final quizId = quiz['id']?.toString();
        if (quizId != null) {
          final status = await getSubmissionStatus(quizId);
          submissionStatus[quizId] = status;
        }
      }

      log('📊 Loaded submission statuses for ${quizzes.length} quizzes');
    } catch (e) {
      log('❌ Error loading submission statuses: $e');
    }
  }

  // Clear error message
  void clearError() {
    errorMessage.value = '';
  }
}
