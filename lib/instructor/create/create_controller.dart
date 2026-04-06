import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/services/in_app_notification_service.dart';
import '../../shared/services/instructor_class_service.dart';

class CreateController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable variables
  var isLoading = false.obs;
  var createdItems = <Map<String, dynamic>>[].obs;
  var errorMessage = ''.obs;
  var instructorName = ''.obs;
  var instructorClasses = <String>[].obs;

  // Add mounted check
  bool _isDisposed = false;
  bool get isMounted => !_isDisposed;

  // Collection references
  static const String assignmentsCollection = 'assignments';
  static const String activitiesCollection = 'activities';
  static const String quizzesCollection = 'quizzes';
  static const String pitsCollection = 'pits';

  @override
  void onInit() {
    super.onInit();
    // Load data once when controller is first created (when screen is first shown)
    // This is NOT auto-loading on every lifecycle change - it only happens once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadInstructor(); // Load instructor name (lightweight operation)
      loadCreatedItems(); // Load created items once when screen first appears
      _loadInstructorClasses();
    });
  }

  Future<void> _loadInstructorClasses() async {
    try {
      final classes = await InstructorClassService.getInstructorSectionCodes();
      instructorClasses.value = classes;
    } catch (e) {
      debugPrint('Error loading instructor classes: $e');
    }
  }

  @override
  void onClose() {
    // Mark as disposed to prevent further operations
    _isDisposed = true;
    super.onClose();
  }

  bool _isDueDateInvalid(DateTime dueDate) {
    return !dueDate.isAfter(DateTime.now());
  }

  // Create Assignment
  Future<bool> createAssignment({
    required String title,
    required String instruction,
    required List<String> selectedClasses,
    required String points,
    required DateTime dueDate,
    String? period,
    List<dynamic>? attachments,
    String? category,
    String? topicId,
    String? topicName,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      if (_isDueDateInvalid(dueDate)) {
        Get.snackbar(
          'Error',
          'Due date and time must be in the future',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get instructor's assigned semester
      final semester = await _getInstructorSemester(user.uid);

      // Fetch instructor name from instructors collection
      final instructorNameToUse = await _getInstructorName(user.uid);

      final assignmentData = {
        'title': title,
        'instruction': instruction,
        'selectedClasses': selectedClasses,
        'points': int.tryParse(points) ?? 0,
        'dueDate': dueDate,
        'period': period,
        'attachments': attachments ?? [],
        'category': category ?? 'class_standing',
        'instructorId': user.uid,
        'instructorName': instructorNameToUse,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'type': 'Assignment',
        if (topicId != null && topicId.isNotEmpty) 'topicId': topicId,
        if (topicName != null &&
            topicName.isNotEmpty &&
            topicName != 'No Topic')
          'topicName': topicName,
        // Add assigned semester data
        if (semester != null) 'assignedSemester': semester,
      };

      // Save to user-specific subcollection: instructors/{userId}/assignments
      DocumentReference docRef = await _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection(assignmentsCollection)
          .add(assignmentData);

      // Create notification for the selected sections
      await InAppNotificationService.createSectionNotification(
        type: 'assignment',
        instructorId: user.uid,
        instructorName: instructorNameToUse,
        itemId: docRef.id,
        title: title,
        targetSections: selectedClasses,
        description: instruction,
        metadata: {
          'dueDate': dueDate.toIso8601String(),
          'points': int.tryParse(points) ?? 0,
          'period': period ?? '',
        },
      );

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
    String? period,
    List<dynamic>? attachments,
    String? category,
    String? topicId,
    String? topicName,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      if (_isDueDateInvalid(dueDate)) {
        Get.snackbar(
          'Error',
          'Due date and time must be in the future',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get instructor's assigned semester
      final semester = await _getInstructorSemester(user.uid);

      // Fetch instructor name from instructors collection
      final instructorNameToUse = await _getInstructorName(user.uid);

      final activityData = {
        'title': title,
        'instruction': instruction,
        'selectedClasses': selectedClasses,
        'points': int.tryParse(points) ?? 0,
        'dueDate': dueDate,
        'period': period,
        'attachments': attachments ?? [],
        'category': category ?? 'class_standing',
        'instructorId': user.uid,
        'instructorName': instructorNameToUse,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'type': 'Activity',
        // Add topic data
        if (topicId != null) 'topicId': topicId,
        if (topicName != null) 'topicName': topicName,
        // Add assigned semester data
        if (semester != null) 'assignedSemester': semester,
      };

      // Save to user-specific subcollection: instructors/{userId}/activities
      DocumentReference docRef = await _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection(activitiesCollection)
          .add(activityData);

      // Create notification for the selected sections
      await InAppNotificationService.createSectionNotification(
        type: 'activity',
        instructorId: user.uid,
        instructorName: instructorNameToUse,
        itemId: docRef.id,
        title: title,
        targetSections: selectedClasses,
        description: instruction,
        metadata: {
          'dueDate': dueDate.toIso8601String(),
          'points': int.tryParse(points) ?? 0,
          'period': period ?? '',
        },
      );

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
    String? period,
    List<dynamic>? attachments,
    String? category,
    String? topicId,
    String? topicName,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      if (_isDueDateInvalid(dueDate)) {
        Get.snackbar(
          'Error',
          'Due date and time must be in the future',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get instructor's assigned semester
      final semester = await _getInstructorSemester(user.uid);

      // Fetch instructor name from instructors collection
      final instructorNameToUse = await _getInstructorName(user.uid);

      final quizData = {
        'title': title,
        'instruction': instruction,
        'selectedClasses': selectedClasses,
        'points': int.tryParse(points) ?? 0,
        'dueDate': dueDate,
        'period': period,
        'attachments': attachments ?? [],
        'category': category ?? 'quiz_prelim',
        'instructorId': user.uid,
        'instructorName': instructorNameToUse,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'type': 'Quiz',
        'topicId': topicId,
        'topicName': topicName,
        // Add assigned semester data
        if (semester != null) 'assignedSemester': semester,
      };

      // Save to user-specific subcollection: instructors/{userId}/quizzes
      DocumentReference docRef = await _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection(quizzesCollection)
          .add(quizData);

      // Create notification for the selected sections
      await InAppNotificationService.createSectionNotification(
        type: 'quiz',
        instructorId: user.uid,
        instructorName: instructorNameToUse,
        itemId: docRef.id,
        title: title,
        targetSections: selectedClasses,
        description: instruction,
        metadata: {
          'dueDate': dueDate.toIso8601String(),
          'points': int.tryParse(points) ?? 0,
          'period': period ?? '',
        },
      );

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

  // Create Exam (stored in quizzes collection for class-record compatibility)
  Future<bool> createExam({
    required String title,
    required String instruction,
    required List<String> selectedClasses,
    required String points,
    required DateTime dueDate,
    required String period,
    List<dynamic>? attachments,
    String? topicId,
    String? topicName,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      if (_isDueDateInvalid(dueDate)) {
        Get.snackbar(
          'Error',
          'Due date and time must be in the future',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final semester = await _getInstructorSemester(user.uid);
      final instructorNameToUse = await _getInstructorName(user.uid);
      final category = period == 'Final' ? 'final_exam' : 'midterm_exam';

      final examData = {
        'title': title,
        'instruction': instruction,
        'selectedClasses': selectedClasses,
        'points': int.tryParse(points) ?? 0,
        'dueDate': dueDate,
        'period': period,
        'attachments': attachments ?? [],
        'category': category,
        'instructorId': user.uid,
        'instructorName': instructorNameToUse,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'type': 'Exam',
        'topicId': topicId,
        'topicName': topicName,
        if (semester != null) 'assignedSemester': semester,
      };

      final docRef = await _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection(quizzesCollection)
          .add(examData);

      await InAppNotificationService.createSectionNotification(
        type: 'quiz',
        instructorId: user.uid,
        instructorName: instructorNameToUse,
        itemId: docRef.id,
        title: title,
        targetSections: selectedClasses,
        description: instruction,
        metadata: {
          'dueDate': dueDate.toIso8601String(),
          'points': int.tryParse(points) ?? 0,
          'period': period,
          'category': category,
        },
      );

      await loadCreatedItems();

      Get.snackbar(
        'Success',
        'Exam created successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF34A853),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      return true;
    } catch (e) {
      errorMessage.value = 'Error creating exam: $e';
      Get.snackbar(
        'Error',
        'Failed to create exam: $e',
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

  // Create PIT
  Future<bool> createPIT({
    required String title,
    required String instruction,
    required List<String> selectedClasses,
    required String points,
    required DateTime dueDate,
    String? period,
    List<dynamic>? attachments,
    String? category,
    String? topicId,
    String? topicName,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      if (_isDueDateInvalid(dueDate)) {
        Get.snackbar(
          'Error',
          'Due date and time must be in the future',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get instructor's assigned semester
      final semester = await _getInstructorSemester(user.uid);

      // Fetch instructor name from instructors collection
      final instructorNameToUse = await _getInstructorName(user.uid);

      final pitData = {
        'title': title,
        'instruction': instruction,
        'selectedClasses': selectedClasses,
        'points': int.tryParse(points) ?? 0,
        'dueDate': dueDate,
        'period': period,
        'attachments': attachments ?? [],
        'category': category ?? 'pit',
        'instructorId': user.uid,
        'instructorName': instructorNameToUse,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'type': 'PIT',
        if (topicId != null && topicId.isNotEmpty) 'topicId': topicId,
        if (topicName != null &&
            topicName.isNotEmpty &&
            topicName != 'No Topic')
          'topicName': topicName,
        // Add assigned semester data
        if (semester != null) 'assignedSemester': semester,
      };

      // Save to user-specific subcollection: instructors/{userId}/pits
      DocumentReference docRef = await _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection(pitsCollection)
          .add(pitData);

      // Create notification for the selected sections
      await InAppNotificationService.createSectionNotification(
        type: 'pit',
        instructorId: user.uid,
        instructorName: instructorNameToUse,
        itemId: docRef.id,
        title: title,
        targetSections: selectedClasses,
        description: instruction,
        metadata: {
          'dueDate': dueDate.toIso8601String(),
          'points': int.tryParse(points) ?? 0,
          'period': period ?? '',
        },
      );

      // Refresh the list
      await loadCreatedItems();

      Get.snackbar(
        'Success',
        'PIT created successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF34A853),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      return true;
    } catch (e) {
      errorMessage.value = 'Error creating PIT: $e';
      Get.snackbar(
        'Error',
        'Failed to create PIT: $e',
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

  // Create Material
  Future<bool> createMaterial({
    required String title,
    required String description,
    required List<String> selectedClasses,
    List<dynamic>? attachments,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get instructor's assigned semester
      final semester = await _getInstructorSemester(user.uid);

      // Fetch instructor name from instructors collection
      final instructorNameToUse = await _getInstructorName(user.uid);

      final materialData = {
        'title': title,
        'description': description,
        'selectedClasses': selectedClasses,
        'attachments': attachments ?? [],
        'instructorId': user.uid,
        'instructorName': instructorNameToUse,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'type': 'Material',
        // Add assigned semester data
        if (semester != null) 'assignedSemester': semester,
      };

      // Save to user-specific subcollection: instructors/{userId}/materials
      DocumentReference docRef = await _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('materials')
          .add(materialData);

      // Create notification for the selected sections
      await InAppNotificationService.createSectionNotification(
        type: 'material',
        instructorId: user.uid,
        instructorName: instructorNameToUse,
        itemId: docRef.id,
        title: title,
        targetSections: selectedClasses,
        description: description,
      );

      // Don't refresh the list here - let the create screen handle it after navigation
      // This prevents any potential interference with navigation
      // The create screen will call _refreshData() in the .then() callback

      return true;
    } catch (e) {
      errorMessage.value = 'Error creating material: $e';
      Get.snackbar(
        'Error',
        'Failed to create material: $e',
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

  // Update Material
  Future<bool> updateMaterial({
    required String itemId,
    required String title,
    required String description,
    required List<String> selectedClasses,
    List<dynamic>? attachments,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final materialData = {
        'title': title,
        'description': description,
        'selectedClasses': selectedClasses,
        'attachments': attachments ?? [],
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update in user-specific subcollection: instructors/{userId}/materials
      await _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('materials')
          .doc(itemId)
          .update(materialData);

      // Refresh the list
      await loadCreatedItems();
      Get.snackbar(
        'Success',
        'Material updated successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF34A853),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      return true;
    } catch (e) {
      errorMessage.value = 'Error updating material: $e';
      Get.snackbar(
        'Error',
        'Failed to update material: $e',
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
      // Check if controller is still mounted
      if (!isMounted) return;

      // Schedule state update for next frame to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!isMounted) return;

        isLoading.value = true;
        errorMessage.value = '';

        final user = _auth.currentUser;
        if (user == null) {
          if (isMounted) {
            isLoading.value = false;
            errorMessage.value = 'User not authenticated';
          }
          return;
        }

        await _fetchAndUpdateItems(user);
      });
    } catch (e) {
      if (isMounted) {
        errorMessage.value = 'Error loading created items: $e';
        isLoading.value = false;
      }
    }
  }

  Future<void> _fetchAndUpdateItems(dynamic user) async {
    try {
      if (!isMounted) return;

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

        for (var doc in assignmentsQuery.docs) {
          final data = doc.data();
          final createdAtRaw = _toDateTime(data['createdAt']) ?? DateTime.now();
          final dueDateRaw = _toDateTime(data['dueDate']);

          allItems.add({
            'id': doc.id,
            'type': 'Assignment',
            'title': data['title'] ?? 'No Title',
            'instruction': data['instruction'] ?? '',
            'period': data['period'],
            'dueDate': _formatDate(data['dueDate']), // Formatted for display
            'dueDateRaw': dueDateRaw,
            'points': data['points']?.toString() ?? '0',
            'selectedClasses': data['selectedClasses'] ?? [],
            'attachments': data['attachments'] ?? [],
            'createdAt': _formatDate(data['createdAt']) ?? 'Unknown',
            'createdAtRaw': createdAtRaw,
            'status': data['status'] ?? 'active',
            'category': data['category'], // Include category for editing
            'topicId': data['topicId'], // Include topic ID
            'topicName': data['topicName'], // Include topic name
          });
        }
      } catch (e) {
        // Keep this catch isolated so other item types can still load.
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

        for (var doc in activitiesQuery.docs) {
          final data = doc.data();
          final createdAtRaw = _toDateTime(data['createdAt']) ?? DateTime.now();
          final dueDateRaw = _toDateTime(data['dueDate']);

          allItems.add({
            'id': doc.id,
            'type': 'Activity',
            'title': data['title'] ?? 'No Title',
            'instruction': data['instruction'] ?? '',
            'period': data['period'],
            'dueDate': _formatDate(data['dueDate']), // Formatted for display
            'dueDateRaw': dueDateRaw,
            'points': data['points']?.toString() ?? '0',
            'selectedClasses': data['selectedClasses'] ?? [],
            'attachments': data['attachments'] ?? [],
            'createdAt': _formatDate(data['createdAt']) ?? 'Unknown',
            'createdAtRaw': createdAtRaw,
            'status': data['status'] ?? 'active',
            'category': data['category'], // Include category for editing
            'topicId': data['topicId'], // Include topic ID
            'topicName': data['topicName'], // Include topic name
          });
        }
      } catch (e) {
        // Keep this catch isolated so other item types can still load.
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

        for (var doc in quizzesQuery.docs) {
          final data = doc.data();
          final createdAtRaw = _toDateTime(data['createdAt']) ?? DateTime.now();
          final dueDateRaw = _toDateTime(data['dueDate']);

          allItems.add({
            'id': doc.id,
            'type': data['type'] ?? 'Quiz',
            'title': data['title'] ?? 'No Title',
            'instruction': data['instruction'] ?? '',
            'period': data['period'],
            'dueDate': _formatDate(data['dueDate']), // Formatted for display
            'dueDateRaw': dueDateRaw,
            'points': data['points']?.toString() ?? '0',
            'selectedClasses': data['selectedClasses'] ?? [],
            'attachments': data['attachments'] ?? [],
            'createdAt': _formatDate(data['createdAt']) ?? 'Unknown',
            'createdAtRaw': createdAtRaw,
            'status': data['status'] ?? 'active',
            'category': data['category'], // Include category for editing
            'topicId': data['topicId'], // Include topic ID
            'topicName': data['topicName'], // Include topic name
          });
        }
      } catch (e) {
        // Keep this catch isolated so other item types can still load.
      }

      // Get PITs from user-specific subcollection
      try {
        final pitsQuery =
            await _firestore
                .collection('instructors')
                .doc(user.uid)
                .collection(pitsCollection)
                .orderBy('createdAt', descending: true)
                .get();

        for (var doc in pitsQuery.docs) {
          final data = doc.data();
          final createdAtRaw = _toDateTime(data['createdAt']) ?? DateTime.now();
          final dueDateRaw = _toDateTime(data['dueDate']);

          allItems.add({
            'id': doc.id,
            'type': 'PIT',
            'title': data['title'] ?? 'No Title',
            'instruction': data['instruction'] ?? '',
            'period': data['period'],
            'dueDate': _formatDate(data['dueDate']), // Formatted for display
            'dueDateRaw': dueDateRaw,
            'points': data['points']?.toString() ?? '0',
            'selectedClasses': data['selectedClasses'] ?? [],
            'attachments': data['attachments'] ?? [],
            'createdAt': _formatDate(data['createdAt']) ?? 'Unknown',
            'createdAtRaw': createdAtRaw,
            'status': data['status'] ?? 'active',
            'category': data['category'], // Include category for editing
            'topicId': data['topicId'], // Include topic ID
            'topicName': data['topicName'], // Include topic name
          });
        }
      } catch (e) {
        // Keep this catch isolated so other item types can still load.
      }

      // Get materials from user-specific subcollection
      try {
        final materialsQuery =
            await _firestore
                .collection('instructors')
                .doc(user.uid)
                .collection('materials')
                .orderBy('createdAt', descending: true)
                .get();

        for (var doc in materialsQuery.docs) {
          final data = doc.data();
          final createdAtRaw = _toDateTime(data['createdAt']) ?? DateTime.now();

          allItems.add({
            'id': doc.id,
            'type': 'Material',
            'title': data['title'] ?? 'No Title',
            'description': data['description'] ?? '',
            'selectedClasses': data['selectedClasses'] ?? [],
            'attachments': data['attachments'] ?? [],
            'createdAt': _formatDate(data['createdAt']) ?? 'Unknown',
            'createdAtRaw': createdAtRaw,
            'status': data['status'] ?? 'active',
            'topicId': data['topicId'], // Include topic ID
            'topicName': data['topicName'], // Include topic name
          });
        }
      } catch (e) {
        // Keep this catch isolated so other item types can still load.
      }

      // Sort all items by creation date
      allItems.sort((a, b) {
        final dateA =
            a['createdAtRaw'] as DateTime? ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final dateB =
            b['createdAtRaw'] as DateTime? ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });

      // Only update if controller is still mounted
      if (isMounted) {
        createdItems.value = allItems;
      }
    } catch (e) {
      // Only update error if controller is still mounted
      if (isMounted) {
        errorMessage.value = 'Error loading created items: $e';
      }
    } finally {
      // Only update loading state if controller is still mounted
      if (isMounted) {
        isLoading.value = false;
      }
    }
  }

  DateTime? _toDateTime(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is DateTime) return timestamp;
    if (timestamp is String) {
      return DateTime.tryParse(timestamp);
    }
    return null;
  }

  // Helper method to format Firestore Timestamp to date string
  String? _formatDate(dynamic timestamp) {
    final date = _toDateTime(timestamp);
    if (date == null) return null;

    try {
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
      return null;
    }
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
        case 'Exam':
          collection = quizzesCollection;
          break;
        case 'PIT':
          collection = pitsCollection;
          break;
        case 'Material':
          collection = 'materials';
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
    String? period,
    String? category,
    List<dynamic>? attachments,
    String? topicId,
    String? topicName,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      if (_isDueDateInvalid(dueDate)) {
        Get.snackbar(
          'Error',
          'Due date and time must be in the future',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }

      final assignmentData = {
        'title': title,
        'instruction': instruction,
        'selectedClasses': selectedClasses,
        'points': int.tryParse(points) ?? 0,
        'dueDate': dueDate,
        'period': period,
        'attachments': attachments ?? [],
        'updatedAt': FieldValue.serverTimestamp(),
        if (category != null) 'category': category,
        if (topicId != null && topicId.isNotEmpty) 'topicId': topicId,
        if (topicName != null &&
            topicName.isNotEmpty &&
            topicName != 'No Topic')
          'topicName': topicName,
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
    String? period,
    String? category,
    List<dynamic>? attachments,
    String? topicId,
    String? topicName,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      if (_isDueDateInvalid(dueDate)) {
        Get.snackbar(
          'Error',
          'Due date and time must be in the future',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }

      final activityData = {
        'title': title,
        'instruction': instruction,
        'selectedClasses': selectedClasses,
        'points': int.tryParse(points) ?? 0,
        'dueDate': dueDate,
        'period': period,
        'attachments': attachments ?? [],
        'updatedAt': FieldValue.serverTimestamp(),
        if (category != null) 'category': category,
        if (topicId != null) 'topicId': topicId,
        if (topicName != null) 'topicName': topicName,
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
    String? period,
    String? category,
    List<dynamic>? attachments,
    String? topicId,
    String? topicName,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      if (_isDueDateInvalid(dueDate)) {
        Get.snackbar(
          'Error',
          'Due date and time must be in the future',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }

      final quizData = {
        'title': title,
        'instruction': instruction,
        'selectedClasses': selectedClasses,
        'points': int.tryParse(points) ?? 0,
        'dueDate': dueDate,
        'period': period,
        'attachments': attachments ?? [],
        'updatedAt': FieldValue.serverTimestamp(),
        'topicId': topicId,
        'topicName': topicName,
        if (category != null) 'category': category,
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

  // Update PIT
  Future<bool> updatePIT({
    required String pitId,
    required String title,
    required String instruction,
    required List<String> selectedClasses,
    required String points,
    required DateTime dueDate,
    String? period,
    String? category,
    List<dynamic>? attachments,
    String? topicId,
    String? topicName,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      if (_isDueDateInvalid(dueDate)) {
        Get.snackbar(
          'Error',
          'Due date and time must be in the future',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }

      final pitData = {
        'title': title,
        'instruction': instruction,
        'selectedClasses': selectedClasses,
        'points': int.tryParse(points) ?? 0,
        'dueDate': dueDate,
        'period': period,
        'attachments': attachments ?? [],
        'updatedAt': FieldValue.serverTimestamp(),
        if (category != null) 'category': category,
        if (topicId != null && topicId.isNotEmpty) 'topicId': topicId,
        if (topicName != null &&
            topicName.isNotEmpty &&
            topicName != 'No Topic')
          'topicName': topicName,
      };

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection(pitsCollection)
          .doc(pitId)
          .update(pitData);

      // Refresh the list
      await loadCreatedItems();

      Get.snackbar(
        'Success',
        'PIT updated successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF34A853),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      return true;
    } catch (e) {
      errorMessage.value = 'Error updating PIT: $e';
      Get.snackbar(
        'Error',
        'Failed to update PIT: $e',
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

  // Update Exam (stored in quizzes collection)
  Future<bool> updateExam({
    required String examId,
    required String title,
    required String instruction,
    required List<String> selectedClasses,
    required String points,
    required DateTime dueDate,
    required String period,
    List<dynamic>? attachments,
    String? topicId,
    String? topicName,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      if (_isDueDateInvalid(dueDate)) {
        Get.snackbar(
          'Error',
          'Due date and time must be in the future',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }

      final examData = {
        'title': title,
        'instruction': instruction,
        'selectedClasses': selectedClasses,
        'points': int.tryParse(points) ?? 0,
        'dueDate': dueDate,
        'period': period,
        'attachments': attachments ?? [],
        'updatedAt': FieldValue.serverTimestamp(),
        'category': period == 'Final' ? 'final_exam' : 'midterm_exam',
        'type': 'Exam',
        'topicId': topicId,
        'topicName': topicName,
      };

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection(quizzesCollection)
          .doc(examId)
          .update(examData);

      await loadCreatedItems();

      Get.snackbar(
        'Success',
        'Exam updated successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF34A853),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      return true;
    } catch (e) {
      errorMessage.value = 'Error updating exam: $e';
      Get.snackbar(
        'Error',
        'Failed to update exam: $e',
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

  /// Get the currently active period that this instructor is assigned to.
  ///
  /// Strategy:
  /// 1. Query the `periods` collection for the one document with `isActive: true`
  ///    (the admin enforces at most one active period at a time).
  /// 2. Check whether the instructor is assigned to that period via their
  ///    `assignedPeriods` array.
  /// 3. Return the period's metadata to be stamped onto the created item,
  ///    or null if the instructor has no active period assignment.
  Future<Map<String, dynamic>?> _getInstructorSemester(
    String instructorId,
  ) async {
    try {
      // Step 1 – Find the globally active period
      final activePeriodSnapshot =
          await _firestore
              .collection('periods')
              .where('isActive', isEqualTo: true)
              .limit(1)
              .get();

      if (activePeriodSnapshot.docs.isEmpty) {
        return null; // No active period set by admin
      }

      final activePeriodDoc = activePeriodSnapshot.docs.first;
      final activePeriodId = activePeriodDoc.id;
      final activePeriodData = activePeriodDoc.data();

      // Step 2 – Check if this instructor is assigned to the active period
      final instructorDoc =
          await _firestore.collection('instructors').doc(instructorId).get();

      if (!instructorDoc.exists) return null;

      final instructorData = instructorDoc.data() as Map<String, dynamic>;
      final assignedPeriods =
          (instructorData['assignedPeriods'] as List<dynamic>?) ?? [];

      final isAssigned = assignedPeriods.any(
        (p) =>
            (p as Map<String, dynamic>)['periodId']?.toString() ==
            activePeriodId,
      );

      if (!isAssigned) {
        return null; // Instructor is not assigned to the active period
      }

      // Step 3 – Return clean period metadata to stamp on the created item
      return {
        'periodId': activePeriodId,
        'semesterName': activePeriodData['semesterName'] ?? '',
        'type': activePeriodData['type'] ?? '',
        'isActive': true,
      };
    } catch (e) {
      debugPrint(
        'CreateController: Error getting instructor active period: $e',
      );
      return null;
    }
  }

  /// Fetch instructor name from instructors collection
  /// Returns the instructor name from the 'name' field in instructors collection
  Future<String> _getInstructorName(String userId) async {
    try {
      final instructorDoc =
          await _firestore.collection('instructors').doc(userId).get();

      if (instructorDoc.exists) {
        final instructorData = instructorDoc.data();
        final nameFromDoc = instructorData?['name']?.toString();

        if (nameFromDoc != null && nameFromDoc.isNotEmpty) {
          return nameFromDoc;
        } else if (instructorName.value.isNotEmpty) {
          // Fallback to loaded instructor name if name field is empty
          return instructorName.value;
        }
      } else if (instructorName.value.isNotEmpty) {
        // Fallback to loaded instructor name if document doesn't exist
        return instructorName.value;
      }
    } catch (e) {
      // Fallback to loaded instructor name
      if (instructorName.value.isNotEmpty) {
        return instructorName.value;
      }
    }

    // Final fallback
    final user = _auth.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!;
    }

    return 'Unknown Instructor';
  }

  /// Load instructor name using FirebaseAuth user.uid
  Future<void> loadInstructor() async {
    try {
      // Check if controller is still mounted
      if (!isMounted) return;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (isMounted) {
          instructorName.value = 'No user logged in';
        }
        return;
      }

      final doc =
          await FirebaseFirestore.instance
              .collection('instructors')
              .doc(user.uid) // 👈 use user.uid here
              .get();

      if (doc.exists) {
        if (isMounted) {
          instructorName.value = doc['name'] ?? 'Unknown Instructor';
        }
      } else {
        if (isMounted) {
          instructorName.value = 'Instructor not found';
        }
      }
    } catch (e) {
      if (isMounted) {
        instructorName.value = 'Error loading name';
      }
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
