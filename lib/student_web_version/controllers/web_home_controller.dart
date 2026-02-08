import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../shared/services/tree_progress_service.dart';

class WebHomeController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TreeProgressService _treeProgressService = TreeProgressService();

  // Observable variables
  final RxBool isLoading = true.obs;
  final RxString fullName = ''.obs;
  final RxString profileImage = ''.obs;
  final RxString enrollmentStatus = 'none'.obs;
  final RxString instructorName = ''.obs;
  final RxString sectionCode = ''.obs;
  final RxDouble treeProgress = 0.0.obs;
  final RxBool isLoadingProgress = false.obs;
  final RxDouble computedGrade = 5.00.obs;
  final RxString activePeriodName = ''.obs;
  final RxString activePeriodType = ''.obs;

  // Getter for first name
  String get firstName {
    if (fullName.value.isEmpty) return 'Student';
    return fullName.value.split(' ').first;
  }

  // Logic for initials (e.g., "JM Ruiz" -> "JR")
  String getInitials() {
    if (fullName.value.isEmpty) return 'S';
    List<String> parts =
        fullName.value.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return 'S';
    if (parts.length == 1) return parts[0][0].toUpperCase();

    // Get first and last parts (ignoring middle names for JR style initials)
    String first = parts.first[0];
    String last = parts.last[0];
    return (first + last).toUpperCase();
  }

  // Completion data for midterm and final periods
  final RxList<Map<String, dynamic>> midtermCompletions =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> finalCompletions =
      <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchStudentData();
  }

  Future<void> fetchStudentData() async {
    try {
      isLoading.value = true;
      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        fullName.value =
            data['fullName'] ??
            data['name'] ??
            data['displayName'] ??
            'Student';
        profileImage.value = data['profileImage'] ?? '';
        enrollmentStatus.value = data['enrollmentStatus'] ?? 'none';
        instructorName.value = data['selectedInstructorName'] ?? '';
        sectionCode.value = data['selectedSectionCode'] ?? '';

        if (enrollmentStatus.value == 'approved') {
          await loadProgressData();
        }
      }
    } catch (e) {
      log('Error fetching student data for web: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadProgressData() async {
    try {
      isLoadingProgress.value = true;
      final result =
          await _treeProgressService.calculateProgressWithCompletion();

      treeProgress.value = result.progress;
      computedGrade.value = result.computedFinalGrade;
      activePeriodName.value = result.activePeriodName ?? '';
      activePeriodType.value = result.activePeriodType ?? '';

      // Map completions for UI usage
      midtermCompletions.value =
          result.midtermCompletions
              .map(
                (c) => {
                  'category': c.category,
                  'displayName': c.displayName,
                  'completed': c.completed,
                  'total': c.total,
                  'percentage': c.percentage,
                },
              )
              .toList();

      finalCompletions.value =
          result.finalCompletions
              .map(
                (c) => {
                  'category': c.category,
                  'displayName': c.displayName,
                  'completed': c.completed,
                  'total': c.total,
                  'percentage': c.percentage,
                },
              )
              .toList();
    } catch (e) {
      log('Error loading progress data for web: $e');
    } finally {
      isLoadingProgress.value = false;
    }
  }

  Future<void> refreshAll() async {
    await fetchStudentData();
  }
}
