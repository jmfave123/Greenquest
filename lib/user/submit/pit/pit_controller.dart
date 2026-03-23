import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/services/submission_routing_service.dart';
import '../../../shared/services/student_data_service.dart';

class PitController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _log(Object? message) {
    if (kDebugMode) {
      debugPrint('$message');
    }
  }

  // Observable variables
  final RxList<Map<String, dynamic>> pits = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;
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

      final userData = await StudentDataService.getStudentData();
      if (userData != null) {
        final sectionCode = userData['selectedSectionCode']?.toString();
        _log('📚 Student section code: $sectionCode');
        return sectionCode;
      }
      return null;
    } catch (e) {
      _log('❌ Error getting user section code: $e');
      return null;
    }
  }

  Future<void> _initializeInstructorInfo() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _log('❌ No authenticated user');
        return;
      }

      _log('🔍 Loading instructor for user: ${user.uid}');

      // Get user's selected instructor from their profile snapshot via the cache
      final userData = await StudentDataService.getStudentData();
      if (userData != null) {
        final instructorId = userData['selectedInstructorId'] ?? '';
        final instructorName = userData['selectedInstructorName'] ?? '';
        final selectionComplete = userData['selectionComplete'] ?? false;

        _log(
          '📋 User data: selectedInstructorId=$instructorId, selectedInstructorName=$instructorName, selectionComplete=$selectionComplete',
        );

        if (selectionComplete && instructorId.isNotEmpty) {
          currentInstructorUid.value = instructorId;
          currentInstructorName.value = instructorName;

          _log('📚 Loaded instructor: $instructorName ($instructorId)');

          // Load pits for this instructor
          await loadCurrentInstructorPits();
        } else {
          _log(
            '⚠️ User has not completed instructor selection or no instructor selected',
          );
          errorMessage.value = 'Please select an instructor first';
        }
      } else {
        _log('❌ User data from cache was empty');
        errorMessage.value = 'User profile not found';
      }
    } catch (e) {
      _log('❌ Error loading current instructor: $e');
      errorMessage.value = 'Failed to load instructor: $e';
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
      _log('📚 Student section code: $userSectionCode');

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
            _log(
              '❌ Skipping PIT "${pitData['title']}" - not for section $userSectionCode',
            );
            continue;
          }
          _log(
            '✅ PIT "${pitData['title']}" matches student section $userSectionCode',
          );
        }

        pitData['id'] = doc.id;

        // Keep raw date data for proper formatting in UI
        // createdAt and dueDate will be passed as Timestamp objects

        pits.add(pitData);
      }

      _log(
        '✅ Loaded ${pits.length} pits for instructor: ${currentInstructorName.value} (filtered by section $userSectionCode)',
      );

      // Load submission statuses for all PITs
      await loadSubmissionStatuses();
    } catch (e) {
      _log('❌ Error loading pits: $e');
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

      _log('✅ Loaded ${pits.length} pits from all instructors');

      // Load submission statuses for all PITs
      await loadSubmissionStatuses();
    } catch (e) {
      _log('❌ Error loading all pits: $e');
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

      _log('📤 Submitting PIT: $pitId');
      _log('📝 PIT data: ${pitData.keys.length} fields');

      // Get user data for student information from cache
      final userData = await StudentDataService.getStudentData() ?? {};

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
        if (userData['assignedSemester'] != null)
          'assignedSemester': userData['assignedSemester'],
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

      _log('✅ PIT submission routed successfully');
      _log('📍 Routed to instructor: ${routingResult['instructorId']}');
      _log('📍 Section: ${routingResult['sectionId']}');

      Get.snackbar(
        'Success',
        'PIT submitted and routed to instructor!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      _log('❌ Error submitting PIT: $e');
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

  /// Get submission status for a PIT (Legacy individual read - fallback)
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
      _log('❌ Error getting submission status: $e');
      return 'not_submitted';
    }
  }

  /// Bulk load ALL submission statuses in a SINGLE query (N+1 query fix)
  Future<void> loadSubmissionStatuses() async {
    try {
      final user = _auth.currentUser;
      if (user == null || pits.isEmpty) return;

      // Clear existing statuses and extract IDs
      submissionStatus.clear();
      final pitIds = pits.map((a) => a['id']?.toString()).whereType<String>().toList();
      
      if (pitIds.isEmpty) return;

      // Set defaults for all first
      for (final id in pitIds) {
        submissionStatus[id] = 'not_submitted';
      }

      _log('🔍 Bulk loading submissions for ${pitIds.length} PITs');

      // 1 single query to fetch all pit submissions created by THIS student 
      final allSubmissions = await _firestore
          .collection('submissions')
          .where('studentId', isEqualTo: user.uid)
          .where('activityType', isEqualTo: 'pit')
          .get();

      // Process them locally in memory instantly
      for (var doc in allSubmissions.docs) {
        final data = doc.data();
        final activityId = data['activityId']?.toString();
        
        if (activityId != null && submissionStatus.containsKey(activityId)) {
           submissionStatus[activityId] = data['status']?.toString() ?? 'not_submitted';
        }
      }

      _log('📊 Successfully mapped submission statuses without looping queries.');
    } catch (e) {
      _log('❌ Error bulk loading submission statuses: $e');
    }
  }

  // Debug method for instructor selection
  Future<void> debugInstructorSelection() async {
    _log('🔍 Current instructor UID: ${currentInstructorUid.value}');
    _log('🔍 Current instructor name: ${currentInstructorName.value}');
    _log('🔍 Number of pits loaded: ${pits.length}');
  }
}
