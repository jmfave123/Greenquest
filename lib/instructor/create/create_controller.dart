import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/services/in_app_notification_service.dart';

class CreateController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable variables
  var isLoading = false.obs;
  var createdItems = <Map<String, dynamic>>[].obs;
  var errorMessage = ''.obs;
  var instructorName = ''.obs;

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
    // Use addPostFrameCallback to ensure operations run after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void onClose() {
    // Mark as disposed to prevent further operations
    _isDisposed = true;
    super.onClose();
  }

  /// Initialize data without blocking the UI
  Future<void> _initializeData() async {
    try {
      // Check if controller is still mounted before starting operations
      if (!isMounted) return;

      // Run both operations concurrently
      await Future.wait([loadCreatedItems(), loadInstructor()]);
    } catch (e) {
      // Only update error if controller is still mounted
      if (isMounted) {
        print('Error initializing CreateController: $e');
        errorMessage.value = 'Error initializing data: $e';
      }
    }
  }

  // Create Assignment
  Future<bool> createAssignment({
    required String title,
    required String instruction,
    required List<String> selectedClasses,
    required String points,
    required DateTime dueDate,
    String? period,
    List<String>? attachments,
    String? category,
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
        'instructorName': user.displayName ?? 'Unknown Instructor',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'type': 'Assignment',
        // Add assigned semester data
        if (semester != null) 'assignedSemester': semester,
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

      // Create notification for the selected sections
      await InAppNotificationService.createSectionNotification(
        type: 'assignment',
        instructorId: user.uid,
        instructorName:
            instructorName.value.isNotEmpty
                ? instructorName.value
                : 'Unknown Instructor',
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
    List<String>? attachments,
    String? category,
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
        'instructorName': user.displayName ?? 'Unknown Instructor',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'type': 'Activity',
        // Add assigned semester data
        if (semester != null) 'assignedSemester': semester,
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

      // Create notification for the selected sections
      await InAppNotificationService.createSectionNotification(
        type: 'activity',
        instructorId: user.uid,
        instructorName:
            instructorName.value.isNotEmpty
                ? instructorName.value
                : 'Unknown Instructor',
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
    List<String>? attachments,
    String? category,
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
        'instructorName': user.displayName ?? 'Unknown Instructor',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'type': 'Quiz',
        // Add assigned semester data
        if (semester != null) 'assignedSemester': semester,
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

      // Create notification for the selected sections
      await InAppNotificationService.createSectionNotification(
        type: 'quiz',
        instructorId: user.uid,
        instructorName:
            instructorName.value.isNotEmpty
                ? instructorName.value
                : 'Unknown Instructor',
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

  // Create PIT
  Future<bool> createPIT({
    required String title,
    required String instruction,
    required List<String> selectedClasses,
    required String points,
    required DateTime dueDate,
    String? period,
    List<String>? attachments,
    String? category,
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
        'instructorName': user.displayName ?? 'Unknown Instructor',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'type': 'PIT',
        // Add assigned semester data
        if (semester != null) 'assignedSemester': semester,
      };

      // Save to user-specific subcollection: instructors/{userId}/pits
      DocumentReference docRef = await _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection(pitsCollection)
          .add(pitData);

      print('✅ PIT saved to user subcollection: instructors/${user.uid}/pits');
      print('📊 PIT ID: ${docRef.id}');
      print('📊 PIT data: $pitData');

      // Create notification for the selected sections
      await InAppNotificationService.createSectionNotification(
        type: 'pit',
        instructorId: user.uid,
        instructorName:
            instructorName.value.isNotEmpty
                ? instructorName.value
                : 'Unknown Instructor',
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

      final materialData = {
        'title': title,
        'description': description,
        'selectedClasses': selectedClasses,
        'attachments': attachments ?? [],
        'instructorId': user.uid,
        'instructorName': user.displayName ?? 'Unknown Instructor',
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

      print(
        '✅ Material saved to user subcollection: instructors/${user.uid}/materials',
      );
      print('📊 Material ID: ${docRef.id}');
      print('📊 Material data: $materialData');

      // Create notification for the selected sections
      await InAppNotificationService.createSectionNotification(
        type: 'material',
        instructorId: user.uid,
        instructorName:
            instructorName.value.isNotEmpty
                ? instructorName.value
                : 'Unknown Instructor',
        itemId: docRef.id,
        title: title,
        targetSections: selectedClasses,
        description: description,
      );

      // Refresh the list
      await loadCreatedItems();

      Get.snackbar(
        'Success',
        'Material created successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF34A853),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

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
      print('🔄 Starting material update...');
      print('🆔 Material ID: $itemId');
      print('📝 Title: $title');
      print('📝 Description: $description');
      print('📚 Selected Classes: $selectedClasses');
      print('📎 Attachments: $attachments');

      isLoading.value = true;
      errorMessage.value = '';

      final user = _auth.currentUser;
      if (user == null) {
        print('❌ User not authenticated');
        throw Exception('User not authenticated');
      }

      print('👤 User ID: ${user.uid}');

      final materialData = {
        'title': title,
        'description': description,
        'selectedClasses': selectedClasses,
        'attachments': attachments ?? [],
        'updatedAt': FieldValue.serverTimestamp(),
      };

      print('📊 Material data to update: $materialData');

      // Update in user-specific subcollection: instructors/{userId}/materials
      await _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('materials')
          .doc(itemId)
          .update(materialData);

      print('✅ Material updated: instructors/${user.uid}/materials/$itemId');

      // Refresh the list
      await loadCreatedItems();

      print('✅ Material update completed successfully');
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
      print('❌ Material update failed with error: $e');
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

      // Get PITs from user-specific subcollection
      try {
        final pitsQuery =
            await _firestore
                .collection('instructors')
                .doc(user.uid)
                .collection(pitsCollection)
                .orderBy('createdAt', descending: true)
                .get();

        print('📊 Found ${pitsQuery.docs.length} PITs');

        for (var doc in pitsQuery.docs) {
          final data = doc.data();
          print('📊 PIT data: $data');
          print(
            '📊 Due date raw: ${data['dueDate']} (type: ${data['dueDate'].runtimeType})',
          );

          allItems.add({
            'id': doc.id,
            'type': 'PIT',
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
        print('Error loading PITs: $e');
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

        print('📊 Found ${materialsQuery.docs.length} materials');

        for (var doc in materialsQuery.docs) {
          final data = doc.data();
          print('📊 Material data: $data');

          allItems.add({
            'id': doc.id,
            'type': 'Material',
            'title': data['title'] ?? 'No Title',
            'description': data['description'] ?? '',
            'selectedClasses': data['selectedClasses'] ?? [],
            'attachments': data['attachments'] ?? [],
            'createdAt': _formatDate(data['createdAt']) ?? 'Unknown',
            'status': data['status'] ?? 'active',
          });
        }
      } catch (e) {
        print('Error loading materials: $e');
      }

      // Sort all items by creation date
      allItems.sort((a, b) {
        final dateA = a['createdAt'] ?? 'Unknown';
        final dateB = b['createdAt'] ?? 'Unknown';
        return dateB.compareTo(dateA);
      });

      print('📊 Total items loaded: ${allItems.length}');
      print('📊 All items data: $allItems');

      // Only update if controller is still mounted
      if (isMounted) {
        createdItems.value = allItems;
      }
    } catch (e) {
      // Only update error if controller is still mounted
      if (isMounted) {
        errorMessage.value = 'Error loading created items: $e';
        print('Error loading created items: $e');
      }
    } finally {
      // Only update loading state if controller is still mounted
      if (isMounted) {
        isLoading.value = false;
      }
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

  /// Get instructor's assigned semester (preferably active one)
  Future<Map<String, dynamic>?> _getInstructorSemester(
    String instructorId,
  ) async {
    try {
      final instructorDoc =
          await _firestore.collection('instructors').doc(instructorId).get();

      if (!instructorDoc.exists) {
        return null;
      }

      final instructorData = instructorDoc.data();
      final assignedSemesters =
          (instructorData?['assignedSemesters'] as List<dynamic>?) ?? [];

      if (assignedSemesters.isEmpty) {
        return null;
      }

      // Prefer active semester, otherwise get the most recent one
      Map<String, dynamic>? activeSemester;
      Map<String, dynamic>? mostRecentSemester;
      Timestamp? mostRecentTimestamp;

      for (var sem in assignedSemesters) {
        final semesterData = sem as Map<String, dynamic>;
        final isActive = semesterData['isActive'] ?? false;
        final assignedAt = semesterData['assignedAt'];

        if (isActive && activeSemester == null) {
          activeSemester = semesterData;
        }

        // Track most recent by assignedAt timestamp
        if (assignedAt is Timestamp) {
          if (mostRecentTimestamp == null ||
              assignedAt.compareTo(mostRecentTimestamp) > 0) {
            mostRecentTimestamp = assignedAt;
            mostRecentSemester = semesterData;
          }
        }
      }

      // Return active semester if found, otherwise most recent
      return activeSemester ?? mostRecentSemester;
    } catch (e) {
      print('Error getting instructor semester: $e');
      return null;
    }
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
