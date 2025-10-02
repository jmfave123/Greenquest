import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_controller.dart';

class QuizController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable variables
  var isLoading = false.obs;
  var quizzes = <Map<String, dynamic>>[].obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadQuizzes();
  }

  // Load quizzes from current instructor only
  Future<void> loadQuizzes() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final User? user = _auth.currentUser;
      if (user == null) {
        errorMessage.value = 'No instructor logged in';
        return;
      }

      // Get instructor data
      final instructorDoc =
          await _firestore.collection('instructors').doc(user.uid).get();
      final instructorName =
          instructorDoc.exists
              ? (instructorDoc.data()?['name'] ?? 'Unknown Instructor')
              : 'Unknown Instructor';

      // Get quizzes for current instructor
      final quizzesSnapshot =
          await _firestore
              .collection('instructors')
              .doc(user.uid)
              .collection('quizzes')
              .orderBy('createdAt', descending: true)
              .get();

      List<Map<String, dynamic>> instructorQuizzes = [];

      for (var quizDoc in quizzesSnapshot.docs) {
        final quizData = quizDoc.data();
        instructorQuizzes.add({
          'id': quizDoc.id,
          'instructorId': user.uid,
          'instructorName': instructorName,
          'title': quizData['title'] ?? '',
          'instruction': quizData['instruction'] ?? '',
          'points': quizData['points'] ?? 0,
          'dueDate': quizData['dueDate'] ?? '',
          'topic': quizData['topic'] ?? 'No Topic',
          'period': quizData['period'] ?? '',
          'questions': quizData['questions'] ?? [],
          'createdAt': quizData['createdAt'] ?? Timestamp.now(),
          'type': 'Quiz',
        });
      }

      quizzes.value = instructorQuizzes;
    } catch (e) {
      errorMessage.value = 'Error loading quizzes: $e';
      print('Error loading quizzes: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Create a new quiz for a specific instructor
  Future<void> createQuiz({
    required String instructorId,
    required String title,
    required String instruction,
    required int points,
    required String dueDate,
    required String topic,
    required String period,
    required List<Map<String, dynamic>> questions,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Validate required fields
      if (title.trim().isEmpty) {
        throw Exception('Quiz title is required');
      }
      if (instruction.trim().isEmpty) {
        throw Exception('Quiz instruction is required');
      }
      if (points <= 0) {
        throw Exception('Points must be greater than 0');
      }
      if (questions.isEmpty) {
        throw Exception('At least one question is required');
      }

      final quizData = {
        'title': title.trim(),
        'instruction': instruction.trim(),
        'points': points,
        'dueDate': dueDate,
        'topic': topic.trim(),
        'period': period.trim(),
        'questions': questions,
        'createdAt': Timestamp.now(),
        'type': 'Quiz',
        'isActive': true,
      };

      // Add quiz to Firestore
      final docRef = await _firestore
          .collection('instructors')
          .doc(instructorId)
          .collection('quizzes')
          .add(quizData);

      print('Quiz created with ID: ${docRef.id}');

      // Reload quizzes to show the new one
      await loadQuizzes();

      // Also refresh the CreateController if it exists
      try {
        final createController = Get.find<CreateController>();
        await createController.loadCreatedItems();
      } catch (e) {
        // CreateController might not be initialized, that's okay
        print('CreateController not found, skipping refresh: $e');
      }

      Get.snackbar(
        'Success',
        'Quiz created successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF34A853),
        colorText: Colors.white,
      );
    } catch (e) {
      errorMessage.value = 'Error creating quiz: $e';
      print('Error creating quiz: $e');
      Get.snackbar(
        'Error',
        'Failed to create quiz: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Update an existing quiz
  Future<void> updateQuiz({
    required String instructorId,
    required String quizId,
    required String title,
    required String instruction,
    required int points,
    required String dueDate,
    required String topic,
    required String period,
    required List<Map<String, dynamic>> questions,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Validate required fields
      if (title.trim().isEmpty) {
        throw Exception('Quiz title is required');
      }
      if (instruction.trim().isEmpty) {
        throw Exception('Quiz instruction is required');
      }
      if (points <= 0) {
        throw Exception('Points must be greater than 0');
      }
      if (questions.isEmpty) {
        throw Exception('At least one question is required');
      }

      final quizData = {
        'title': title.trim(),
        'instruction': instruction.trim(),
        'points': points,
        'dueDate': dueDate,
        'topic': topic.trim(),
        'period': period.trim(),
        'questions': questions,
        'updatedAt': Timestamp.now(),
      };

      // Check if quiz exists before updating
      final quizDoc =
          await _firestore
              .collection('instructors')
              .doc(instructorId)
              .collection('quizzes')
              .doc(quizId)
              .get();

      if (!quizDoc.exists) {
        throw Exception('Quiz not found');
      }

      await _firestore
          .collection('instructors')
          .doc(instructorId)
          .collection('quizzes')
          .doc(quizId)
          .update(quizData);

      print('Quiz updated with ID: $quizId');

      // Reload quizzes to show the updated one
      await loadQuizzes();

      // Also refresh the CreateController if it exists
      try {
        final createController = Get.find<CreateController>();
        await createController.loadCreatedItems();
      } catch (e) {
        // CreateController might not be initialized, that's okay
        print('CreateController not found, skipping refresh: $e');
      }

      Get.snackbar(
        'Success',
        'Quiz updated successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF34A853),
        colorText: Colors.white,
      );
    } catch (e) {
      errorMessage.value = 'Error updating quiz: $e';
      print('Error updating quiz: $e');
      Get.snackbar(
        'Error',
        'Failed to update quiz: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Delete a quiz
  Future<void> deleteQuiz({
    required String instructorId,
    required String quizId,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Check if quiz exists before deleting
      final quizDoc =
          await _firestore
              .collection('instructors')
              .doc(instructorId)
              .collection('quizzes')
              .doc(quizId)
              .get();

      if (!quizDoc.exists) {
        throw Exception('Quiz not found');
      }

      await _firestore
          .collection('instructors')
          .doc(instructorId)
          .collection('quizzes')
          .doc(quizId)
          .delete();

      print('Quiz deleted with ID: $quizId');

      // Reload quizzes to remove the deleted one
      await loadQuizzes();

      // Also refresh the CreateController if it exists
      try {
        final createController = Get.find<CreateController>();
        await createController.loadCreatedItems();
      } catch (e) {
        // CreateController might not be initialized, that's okay
        print('CreateController not found, skipping refresh: $e');
      }

      Get.snackbar(
        'Success',
        'Quiz deleted successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF34A853),
        colorText: Colors.white,
      );
    } catch (e) {
      errorMessage.value = 'Error deleting quiz: $e';
      print('Error deleting quiz: $e');
      Get.snackbar(
        'Error',
        'Failed to delete quiz: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Get instructors list for dropdown
  Future<List<Map<String, dynamic>>> getInstructors() async {
    try {
      final querySnapshot = await _firestore.collection('instructors').get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown Instructor',
          'email': data['email'] ?? '',
          'department': data['department'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('Error loading instructors: $e');
      return [];
    }
  }

  // Filter quizzes by instructor
  List<Map<String, dynamic>> getQuizzesByInstructor(String instructorId) {
    return quizzes
        .where((quiz) => quiz['instructorId'] == instructorId)
        .toList();
  }

  // Filter quizzes by period
  List<Map<String, dynamic>> getQuizzesByPeriod(String period) {
    return quizzes.where((quiz) => quiz['period'] == period).toList();
  }

  // Search quizzes
  List<Map<String, dynamic>> searchQuizzes(String query) {
    if (query.isEmpty) return quizzes;

    return quizzes.where((quiz) {
      final title = (quiz['title'] ?? '').toLowerCase();
      final instructorName = (quiz['instructorName'] ?? '').toLowerCase();
      final topic = (quiz['topic'] ?? '').toLowerCase();
      final searchQuery = query.toLowerCase();

      return title.contains(searchQuery) ||
          instructorName.contains(searchQuery) ||
          topic.contains(searchQuery);
    }).toList();
  }

  // Create a quiz for the current logged-in instructor
  Future<void> createQuizForCurrentInstructor({
    required String title,
    required String instruction,
    required int points,
    required String dueDate,
    required String topic,
    required String period,
    required List<Map<String, dynamic>> questions,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No instructor is logged in');
      }

      await createQuiz(
        instructorId: user.uid,
        title: title,
        instruction: instruction,
        points: points,
        dueDate: dueDate,
        topic: topic,
        period: period,
        questions: questions,
      );
    } catch (e) {
      rethrow; // Re-throw to let the calling method handle the error
    }
  }

  // Get quizzes for the current logged-in instructor
  List<Map<String, dynamic>> getCurrentInstructorQuizzes() {
    final User? user = _auth.currentUser;
    if (user == null) return [];

    return getQuizzesByInstructor(user.uid);
  }

  // Debug method to test validation
  void debugValidation({
    String? title,
    String? instruction,
    int? points,
    String? dueDate,
    String? topic,
    String? period,
    List<Map<String, dynamic>>? questions,
  }) {
    print('=== DEBUG VALIDATION ===');
    print('Title: "$title" (null: ${title == null}, empty: ${title?.isEmpty})');
    print(
      'Instruction: "$instruction" (null: ${instruction == null}, empty: ${instruction?.isEmpty})',
    );
    print(
      'Points: $points (null: ${points == null}, <=0: ${points != null && points <= 0})',
    );
    print('DueDate: "$dueDate" (null: ${dueDate == null})');
    print('Topic: "$topic" (null: ${topic == null}, empty: ${topic?.isEmpty})');
    print(
      'Period: "$period" (null: ${period == null}, empty: ${period?.isEmpty})',
    );
    print(
      'Questions: ${questions?.length} items (null: ${questions == null}, empty: ${questions?.isEmpty})',
    );
    print('========================');
  }
}
