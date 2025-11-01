import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/services/submission_routing_service.dart';

class PitController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable variables
  final RxList<Map<String, dynamic>> pits = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString currentInstructorUid = ''.obs;
  final RxString currentInstructorName = ''.obs;
  final Rx<Map<String, dynamic>?> selectedPit = Rx<Map<String, dynamic>?>(null);
  final RxMap<String, String> submissionStatus = <String, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeInstructorInfo();
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
        print('📚 Student section code: $sectionCode');
        return sectionCode;
      }
      return null;
    } catch (e) {
      print('❌ Error getting user section code: $e');
      return null;
    }
  }

  Future<void> _initializeInstructorInfo() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get user's section and instructor info
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final instructorUid = userData['instructorUid'] as String?;
        final instructorName = userData['instructorName'] as String?;

        if (instructorUid != null && instructorName != null) {
          currentInstructorUid.value = instructorUid;
          currentInstructorName.value = instructorName;

          // Load pits for the current instructor
          await loadCurrentInstructorPits();
        }
      }
    } catch (e) {
      print('Error initializing instructor info: $e');
      errorMessage.value = 'Failed to load instructor information';
    }
  }

  Future<void> loadCurrentInstructorPits() async {
    if (currentInstructorUid.value.isEmpty) {
      errorMessage.value = 'No instructor selected';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Get student's section code for filtering
      final userSectionCode = await _getUserSectionCode();
      print('📚 Student section code: $userSectionCode');

      final pitsQuery =
          await _firestore
              .collection('instructors')
              .doc(currentInstructorUid.value)
              .collection('pits')
              .orderBy('createdAt', descending: true)
              .get();

      pits.clear();

      for (var doc in pitsQuery.docs) {
        final pitData = doc.data();

        // Get selected classes for this PIT
        final selectedClasses = List<String>.from(
          pitData['selectedClasses'] ?? [],
        );

        // 🎯 FILTER BY SECTION: Only include if student's section is in selectedClasses
        if (userSectionCode != null &&
            userSectionCode.isNotEmpty &&
            selectedClasses.isNotEmpty) {
          if (!selectedClasses.contains(userSectionCode)) {
            print(
              '❌ Skipping PIT "${pitData['title']}" - not for section $userSectionCode',
            );
            continue;
          }
          print(
            '✅ PIT "${pitData['title']}" matches student section $userSectionCode',
          );
        }

        pitData['id'] = doc.id;

        // Keep raw date data for proper formatting in UI
        // createdAt and dueDate will be passed as Timestamp objects

        pits.add(pitData);
      }

      print(
        '✅ Loaded ${pits.length} pits for instructor: ${currentInstructorName.value} (filtered by section $userSectionCode)',
      );

      // Load submission statuses for all PITs
      await loadSubmissionStatuses();
    } catch (e) {
      print('❌ Error loading pits: $e');
      errorMessage.value = 'Failed to load pits: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadAllPits() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Get all instructors and their pits
      final instructorsQuery = await _firestore.collection('instructors').get();
      pits.clear();

      for (var instructorDoc in instructorsQuery.docs) {
        final instructorData = instructorDoc.data();
        final instructorUid = instructorDoc.id;
        final instructorName = instructorData['name'] ?? 'Unknown Instructor';

        final pitsQuery =
            await _firestore
                .collection('instructors')
                .doc(instructorUid)
                .collection('pits')
                .orderBy('createdAt', descending: true)
                .get();

        for (var doc in pitsQuery.docs) {
          final pitData = doc.data();
          pitData['id'] = doc.id;
          pitData['instructorUid'] = instructorUid;
          pitData['instructorName'] = instructorName;

          // Keep raw date data for proper formatting in UI
          // createdAt and dueDate will be passed as Timestamp objects

          pits.add(pitData);
        }
      }

      // Sort by creation date
      pits.sort((a, b) {
        final dateA = DateTime.tryParse(a['createdAt'] ?? '');
        final dateB = DateTime.tryParse(b['createdAt'] ?? '');
        if (dateA == null || dateB == null) return 0;
        return dateB.compareTo(dateA);
      });

      print('✅ Loaded ${pits.length} pits from all instructors');

      // Load submission statuses for all PITs
      await loadSubmissionStatuses();
    } catch (e) {
      print('❌ Error loading all pits: $e');
      errorMessage.value = 'Failed to load pits: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshPits() async {
    if (currentInstructorUid.value.isNotEmpty) {
      await loadCurrentInstructorPits();
    } else {
      await loadAllPits();
    }
  }

  void setSelectedPit(Map<String, dynamic> pit) {
    selectedPit.value = pit;
  }

  void clearError() {
    errorMessage.value = '';
  }

  // Debug method to set instructor for testing
  Future<void> setInstructorForTesting() async {
    currentInstructorUid.value = 'test_instructor_uid';
    currentInstructorName.value = 'Test Instructor';
    await loadCurrentInstructorPits();
  }

  // Submit PIT using automatic routing
  Future<void> submitPit(String pitId, Map<String, dynamic> pitData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      print('📤 Submitting PIT: $pitId');
      print('📝 PIT data: ${pitData.keys.length} fields');

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
        'pitData': pitData,
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'submitted',
        'grade': null,
        'feedback': null,
        'gradedAt': null,
      };

      // Use routing service to automatically route submission to correct instructor
      final routingResult = await SubmissionRoutingService.routeSubmission(
        activityId: pitId,
        submissionType: 'pit',
        submissionData: submissionData,
      );

      if (!routingResult['success']) {
        throw Exception(routingResult['error'] ?? 'Failed to route submission');
      }

      print('✅ PIT submission routed successfully');
      print('📍 Routed to instructor: ${routingResult['instructorId']}');
      print('📍 Section: ${routingResult['sectionId']}');

      Get.snackbar(
        'Success',
        'PIT submitted and routed to instructor!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      print('❌ Error submitting PIT: $e');
      Get.snackbar(
        'Error',
        'Failed to submit PIT: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Get submission status for a PIT
  Future<String> getSubmissionStatus(String pitId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'not_submitted';

      final query =
          await _firestore
              .collection('submissions')
              .where('activityType', isEqualTo: 'pit')
              .where('activityId', isEqualTo: pitId)
              .where('studentId', isEqualTo: user.uid)
              .limit(1)
              .get();

      if (query.docs.isNotEmpty) {
        final submissionData = query.docs.first.data();
        return submissionData['status']?.toString() ?? 'not_submitted';
      }

      return 'not_submitted';
    } catch (e) {
      print('❌ Error getting submission status: $e');
      return 'not_submitted';
    }
  }

  /// Load submission statuses for all PITs
  Future<void> loadSubmissionStatuses() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Clear existing statuses
      submissionStatus.clear();

      // Get status for each PIT
      for (final pit in pits) {
        final pitId = pit['id']?.toString();
        if (pitId != null) {
          final status = await getSubmissionStatus(pitId);
          submissionStatus[pitId] = status;
        }
      }

      print('📊 Loaded submission statuses for ${pits.length} PITs');
    } catch (e) {
      print('❌ Error loading submission statuses: $e');
    }
  }

  // Debug method for instructor selection
  Future<void> debugInstructorSelection() async {
    print('🔍 Current instructor UID: ${currentInstructorUid.value}');
    print('🔍 Current instructor name: ${currentInstructorName.value}');
    print('🔍 Number of pits loaded: ${pits.length}');
  }
}
