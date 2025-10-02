import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable variables
  var isLoading = false.obs;
  var createdItems = <Map<String, dynamic>>[].obs;
  var errorMessage = ''.obs;
  var instructorName = ''.obs;

  // Collection references
  static const String assignmentsCollection = 'assignments';
  static const String activitiesCollection = 'activities';
  static const String quizzesCollection = 'quizzes';

  @override
  void onInit() {
    super.onInit();
    loadCreatedItems();
    loadInstructor();
  }

  // Create Assignment
  Future<bool> createAssignment({
    required String title,
    required String instruction,
    required List<String> selectedClasses,
    required String points,
    required DateTime dueDate,
    required String topic,
    String? period,
    List<String>? attachments,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final assignmentData = {
        'title': title,
        'instruction': instruction,
        'selectedClasses': selectedClasses,
        'points': int.tryParse(points) ?? 0,
        'dueDate': dueDate,
        'topic': topic,
        'period': period,
        'attachments': attachments ?? [],
        'instructorId': user.uid,
        'instructorName': user.displayName ?? 'Unknown Instructor',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'type': 'Assignment',
      };

      // Save to user-specific subcollection: instructors/{userId}/assignments
      DocumentReference docRef = await _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection(assignmentsCollection)
          .add(assignmentData);

      print(
        '✅ Assignment saved to user subcollection: instructors/${user.uid}/assignments',
      );
      print('📊 Assignment ID: ${docRef.id}');
      print('📊 Assignment data: $assignmentData');

      // Refresh the list
      await loadCreatedItems();

      Get.snackbar(
        'Success',
        'Assignment created successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF34A853),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      return true;
    } catch (e) {
      errorMessage.value = 'Error creating assignment: $e';
      Get.snackbar(
        'Error',
        'Failed to create assignment: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Create Activity
  Future<bool> createActivity({
    required String title,
    required String instruction,
    required List<String> selectedClasses,
    required String points,
    required DateTime dueDate,
    required String topic,
    String? period,
    List<String>? attachments,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final activityData = {
        'title': title,
        'instruction': instruction,
        'selectedClasses': selectedClasses,
        'points': int.tryParse(points) ?? 0,
        'dueDate': dueDate,
        'topic': topic,
        'period': period,
        'attachments': attachments ?? [],
        'instructorId': user.uid,
        'instructorName': user.displayName ?? 'Unknown Instructor',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'type': 'Activity',
      };

      // Save to user-specific subcollection: instructors/{userId}/activities
      DocumentReference docRef = await _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection(activitiesCollection)
          .add(activityData);

      print(
        '✅ Activity saved to user subcollection: instructors/${user.uid}/activities',
      );
      print('📊 Activity ID: ${docRef.id}');
      print('📊 Activity data: $activityData');

      // Refresh the list
      await loadCreatedItems();

      Get.snackbar(
        'Success',
        'Activity created successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF34A853),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      return true;
    } catch (e) {
      errorMessage.value = 'Error creating activity: $e';
      Get.snackbar(
        'Error',
        'Failed to create activity: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Create Quiz
  Future<bool> createQuiz({
    required String title,
    required String instruction,
    required List<String> selectedClasses,
    required String points,
    required DateTime dueDate,
    required String topic,
    String? period,
    List<String>? attachments,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final quizData = {
        'title': title,
        'instruction': instruction,
        'selectedClasses': selectedClasses,
        'points': int.tryParse(points) ?? 0,
        'dueDate': dueDate,
        'topic': topic,
        'period': period,
        'attachments': attachments ?? [],
        'instructorId': user.uid,
        'instructorName': user.displayName ?? 'Unknown Instructor',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'type': 'Quiz',
      };

      // Save to user-specific subcollection: instructors/{userId}/quizzes
      DocumentReference docRef = await _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection(quizzesCollection)
          .add(quizData);

      print(
        '✅ Quiz saved to user subcollection: instructors/${user.uid}/quizzes',
      );
      print('📊 Quiz ID: ${docRef.id}');
      print('📊 Quiz data: $quizData');

      // Refresh the list
      await loadCreatedItems();

      Get.snackbar(
        'Success',
        'Quiz created successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF34A853),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      return true;
    } catch (e) {
      errorMessage.value = 'Error creating quiz: $e';
      Get.snackbar(
        'Error',
        'Failed to create quiz: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Load all created items
  Future<void> loadCreatedItems() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      List<Map<String, dynamic>> allItems = [];

      // Get assignments from user-specific subcollection
      try {
        final assignmentsQuery =
            await _firestore
                .collection('instructors')
                .doc(user.uid)
                .collection(assignmentsCollection)
                .orderBy('createdAt', descending: true)
                .get();

        print('📊 Found ${assignmentsQuery.docs.length} assignments');

        for (var doc in assignmentsQuery.docs) {
          final data = doc.data();
          print('📊 Assignment data: $data');
          print(
            '📊 Due date raw: ${data['dueDate']} (type: ${data['dueDate'].runtimeType})',
          );

          allItems.add({
            'id': doc.id,
            'type': 'Assignment',
            'title': data['title'] ?? 'No Title',
            'instruction': data['instruction'] ?? '',
            'period': data['period'],
            'dueDate': _formatDate(data['dueDate']),
            'points': data['points']?.toString() ?? '0',
            'topic': data['topic'] ?? 'No Topic',
            'selectedClasses': data['selectedClasses'] ?? [],
            'attachments': data['attachments'] ?? [],
            'createdAt': _formatDate(data['createdAt']) ?? 'Unknown',
            'status': data['status'] ?? 'active',
          });
        }
      } catch (e) {
        print('Error loading assignments: $e');
      }

      // Get activities from user-specific subcollection
      try {
        final activitiesQuery =
            await _firestore
                .collection('instructors')
                .doc(user.uid)
                .collection(activitiesCollection)
                .orderBy('createdAt', descending: true)
                .get();

        print('📊 Found ${activitiesQuery.docs.length} activities');

        for (var doc in activitiesQuery.docs) {
          final data = doc.data();
          print('📊 Activity data: $data');
          print(
            '📊 Due date raw: ${data['dueDate']} (type: ${data['dueDate'].runtimeType})',
          );

          allItems.add({
            'id': doc.id,
            'type': 'Activity',
            'title': data['title'] ?? 'No Title',
            'instruction': data['instruction'] ?? '',
            'period': data['period'],
            'dueDate': _formatDate(data['dueDate']),
            'points': data['points']?.toString() ?? '0',
            'topic': data['topic'] ?? 'No Topic',
            'selectedClasses': data['selectedClasses'] ?? [],
            'attachments': data['attachments'] ?? [],
            'createdAt': _formatDate(data['createdAt']) ?? 'Unknown',
            'status': data['status'] ?? 'active',
          });
        }
      } catch (e) {
        print('Error loading activities: $e');
      }

      // Get quizzes from user-specific subcollection
      try {
        final quizzesQuery =
            await _firestore
                .collection('instructors')
                .doc(user.uid)
                .collection(quizzesCollection)
                .orderBy('createdAt', descending: true)
                .get();

        print('📊 Found ${quizzesQuery.docs.length} quizzes');

        for (var doc in quizzesQuery.docs) {
          final data = doc.data();
          print('📊 Quiz data: $data');
          print(
            '📊 Due date raw: ${data['dueDate']} (type: ${data['dueDate'].runtimeType})',
          );

          allItems.add({
            'id': doc.id,
            'type': 'Quiz',
            'title': data['title'] ?? 'No Title',
            'instruction': data['instruction'] ?? '',
            'period': data['period'],
            'dueDate': _formatDate(data['dueDate']),
            'points': data['points']?.toString() ?? '0',
            'topic': data['topic'] ?? 'No Topic',
            'selectedClasses': data['selectedClasses'] ?? [],
            'attachments': data['attachments'] ?? [],
            'createdAt': _formatDate(data['createdAt']) ?? 'Unknown',
            'status': data['status'] ?? 'active',
          });
        }
      } catch (e) {
        print('Error loading quizzes: $e');
      }

      // Sort all items by creation date
      allItems.sort((a, b) {
        final dateA = a['createdAt'] ?? 'Unknown';
        final dateB = b['createdAt'] ?? 'Unknown';
        return dateB.compareTo(dateA);
      });

      print('📊 Total items loaded: ${allItems.length}');
      print('📊 All items data: $allItems');

      createdItems.value = allItems;
    } catch (e) {
      errorMessage.value = 'Error loading created items: $e';
      print('Error loading created items: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Helper method to format Firestore Timestamp to date string
  String? _formatDate(dynamic timestamp) {
    if (timestamp == null) return null;

    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      } else if (timestamp is DateTime) {
        return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
      } else if (timestamp is String) {
        // If it's already a string, try to parse and format it
        try {
          final date = DateTime.parse(timestamp);
          return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        } catch (e) {
          // If parsing fails, return the original string
          return timestamp;
        }
      }
    } catch (e) {
      print('Error formatting date: $e');
    }

    return null;
  }

  // Delete item
  Future<bool> deleteItem(String itemId, String type) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      String collection = '';
      switch (type) {
        case 'Assignment':
          collection = assignmentsCollection;
          break;
        case 'Activity':
          collection = activitiesCollection;
          break;
        case 'Quiz':
          collection = quizzesCollection;
          break;
        default:
          throw Exception('Invalid item type');
      }

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection(collection)
          .doc(itemId)
          .delete();

      // Refresh the list
      await loadCreatedItems();

      Get.snackbar(
        'Success',
        '$type deleted successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF34A853),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      return true;
    } catch (e) {
      errorMessage.value = 'Error deleting $type: $e';
      Get.snackbar(
        'Error',
        'Failed to delete $type: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Update assignment
  Future<bool> updateAssignment({
    required String assignmentId,
    required String title,
    required String instruction,
    required List<String> selectedClasses,
    required String points,
    required DateTime dueDate,
    required String topic,
    String? period,
    List<String>? attachments,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final assignmentData = {
        'title': title,
        'instruction': instruction,
        'selectedClasses': selectedClasses,
        'points': int.tryParse(points) ?? 0,
        'dueDate': dueDate,
        'topic': topic,
        'period': period,
        'attachments': attachments ?? [],
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection(assignmentsCollection)
          .doc(assignmentId)
          .update(assignmentData);

      // Refresh the list
      await loadCreatedItems();

      Get.snackbar(
        'Success',
        'Assignment updated successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF34A853),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      return true;
    } catch (e) {
      errorMessage.value = 'Error updating assignment: $e';
      Get.snackbar(
        'Error',
        'Failed to update assignment: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Update activity
  Future<bool> updateActivity({
    required String activityId,
    required String title,
    required String instruction,
    required List<String> selectedClasses,
    required String points,
    required DateTime dueDate,
    required String topic,
    String? period,
    List<String>? attachments,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final activityData = {
        'title': title,
        'instruction': instruction,
        'selectedClasses': selectedClasses,
        'points': int.tryParse(points) ?? 0,
        'dueDate': dueDate,
        'topic': topic,
        'period': period,
        'attachments': attachments ?? [],
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection(activitiesCollection)
          .doc(activityId)
          .update(activityData);

      // Refresh the list
      await loadCreatedItems();

      Get.snackbar(
        'Success',
        'Activity updated successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF34A853),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      return true;
    } catch (e) {
      errorMessage.value = 'Error updating activity: $e';
      Get.snackbar(
        'Error',
        'Failed to update activity: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Update quiz
  Future<bool> updateQuiz({
    required String quizId,
    required String title,
    required String instruction,
    required List<String> selectedClasses,
    required String points,
    required DateTime dueDate,
    required String topic,
    String? period,
    List<String>? attachments,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final quizData = {
        'title': title,
        'instruction': instruction,
        'selectedClasses': selectedClasses,
        'points': int.tryParse(points) ?? 0,
        'dueDate': dueDate,
        'topic': topic,
        'period': period,
        'attachments': attachments ?? [],
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection(quizzesCollection)
          .doc(quizId)
          .update(quizData);

      // Refresh the list
      await loadCreatedItems();

      Get.snackbar(
        'Success',
        'Quiz updated successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF34A853),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      return true;
    } catch (e) {
      errorMessage.value = 'Error updating quiz: $e';
      Get.snackbar(
        'Error',
        'Failed to update quiz: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Load instructor name using FirebaseAuth user.uid
  Future<void> loadInstructor() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        instructorName.value = 'No user logged in';
        return;
      }

      final doc =
          await FirebaseFirestore.instance
              .collection('instructors')
              .doc(user.uid) // 👈 use user.uid here
              .get();

      if (doc.exists) {
        instructorName.value = doc['name'] ?? 'Unknown Instructor';
      } else {
        instructorName.value = 'Instructor not found';
      }
    } catch (e) {
      instructorName.value = 'Error loading name';
    }
  }

  /// Clear error message
  void clearError() {
    errorMessage.value = '';
  }

  /// Force refresh all data
  Future<void> forceRefresh() async {
    await loadCreatedItems();
    await loadInstructor();
  }
}
