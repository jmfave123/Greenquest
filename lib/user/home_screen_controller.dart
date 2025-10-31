import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeScreenController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable variables
  final RxBool isLoading = true.obs;
  final RxString enrollmentStatus = 'none'.obs;
  final RxString instructorName = ''.obs;
  final RxString instructorId = ''.obs;
  final RxString selectedSectionCode = ''.obs;
  final RxBool isApproved = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Use addPostFrameCallback to ensure operations run after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  /// Initialize data without blocking the UI
  Future<void> _initializeData() async {
    try {
      await _checkApprovalStatus();
    } catch (e) {
      log('Error initializing HomeScreenController: $e');
    }
  }

  Future<void> _checkApprovalStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        isLoading.value = false;
        return;
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;

        enrollmentStatus.value = data['enrollmentStatus'] ?? 'none';
        instructorName.value = data['selectedInstructorName'] ?? '';
        instructorId.value = data['selectedInstructorId'] ?? '';
        selectedSectionCode.value = data['selectedSectionCode'] ?? '';

        // Check if user is approved
        isApproved.value = enrollmentStatus.value == 'approved';

        log('Home screen - Enrollment status: ${enrollmentStatus.value}');
        log('Home screen - Instructor: ${instructorName.value}');
        log('Home screen - Section: ${selectedSectionCode.value}');
        log('Home screen - Is approved: ${isApproved.value}');
      }
    } catch (e) {
      log('Error checking approval status: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshStatus() async {
    isLoading.value = true;
    await _checkApprovalStatus();
  }

  void navigateToPendingApproval() {
    Get.toNamed('/pending-approval');
  }

  void navigateToInstructorSelection() {
    Get.toNamed('/select-instructor');
  }

  Future<void> cancelRequest() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get current user data to find instructor and section
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final instructorId = userData['selectedInstructorId'] ?? '';
        final sectionCode = userData['selectedSectionCode'] ?? '';

        // Remove student from instructor's class if they were enrolled
        if (instructorId.isNotEmpty && sectionCode.isNotEmpty) {
          await _removeStudentFromInstructorClass(
            instructorId,
            sectionCode,
            user.uid,
          );
        }
      }

      // Reset user selection
      await _firestore.collection('users').doc(user.uid).update({
        'selectedInstructorId': '',
        'selectedInstructorName': '',
        'selectedSectionCode': '',
        'selectionComplete': false,
        'enrollmentStatus': 'none',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Show success message
      Get.snackbar(
        'Request Cancelled',
        'Your enrollment request has been cancelled. You can now select a different instructor.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );

      // Navigate to instructor selection
      Get.offAllNamed('/select-instructor');
    } catch (e) {
      log('Error cancelling request: $e');
      Get.snackbar(
        'Error',
        'Failed to cancel request. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  Future<void> _removeStudentFromInstructorClass(
    String instructorId,
    String sectionCode,
    String studentId,
  ) async {
    try {
      // Extract section part from full section code (e.g., "BSIT-4D" -> "4D")
      String sectionOnly = sectionCode;
      if (sectionCode.contains('-')) {
        sectionOnly = sectionCode.split('-').last;
      }

      // Find the instructor's class for this section
      final classesSnapshot =
          await _firestore
              .collection('instructors')
              .doc(instructorId)
              .collection('classes')
              .where('section', isEqualTo: sectionOnly)
              .get();

      // Remove student from all matching classes
      for (QueryDocumentSnapshot classDoc in classesSnapshot.docs) {
        await _firestore
            .collection('instructors')
            .doc(instructorId)
            .collection('classes')
            .doc(classDoc.id)
            .collection('students')
            .doc(studentId)
            .delete();

        log('Student $studentId removed from instructor class ${classDoc.id}');
      }
    } catch (e) {
      log('Error removing student from instructor class: $e');
      // Don't throw error here as the main cancellation should still proceed
    }
  }
}
