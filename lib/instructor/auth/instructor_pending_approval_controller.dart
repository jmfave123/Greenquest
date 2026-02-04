import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/services/online_status_service.dart';

class InstructorPendingApprovalController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable variables
  final RxBool isLoading = false.obs;
  final RxString instructorName = ''.obs;
  final RxString instructorEmail = ''.obs;
  final RxString accountStatus = 'Pending'.obs;

  @override
  void onInit() {
    super.onInit();
    loadInstructorData();
  }

  /// Load instructor data from Firestore
  Future<void> loadInstructorData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        Get.offAllNamed('/login');
        return;
      }

      final instructorQuery =
          await _firestore
              .collection('instructors')
              .where('email', isEqualTo: user.email)
              .limit(1)
              .get();

      if (instructorQuery.docs.isNotEmpty) {
        final data = instructorQuery.docs.first.data();
        instructorName.value = data['name'] ?? 'Instructor';
        instructorEmail.value = data['email'] ?? user.email ?? '';
        accountStatus.value = data['status']?.toString() ?? 'Pending';
      }
    } catch (e) {
      debugPrint('Error loading instructor data: $e');
    }
  }

  /// Refresh status to check if approved
  Future<void> refreshStatus() async {
    try {
      isLoading.value = true;
      await loadInstructorData();

      // If approved, navigate to dashboard
      if (accountStatus.value == 'Approved') {
        Get.snackbar(
          'Account Approved!',
          'Your account has been approved. Redirecting to dashboard...',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF34A853),
          colorText: Colors.white,
        );
        await Future.delayed(const Duration(seconds: 1));
        Get.offAllNamed('/instructor-dashboard');
      } else {
        Get.snackbar(
          'Status Unchanged',
          'Your account is still pending approval.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('Error refreshing status: $e');
      Get.snackbar(
        'Error',
        'Failed to refresh status. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Logout and return to login screen
  Future<void> logout() async {
    try {
      await OnlineStatusService().setOffline();
      await _auth.signOut();
      Get.offAllNamed('/login');
      Get.snackbar(
        'Logged Out',
        'You have been successfully logged out.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  /// Submit reapplication request to database
  Future<void> submitReapplication(String statement) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Create reapplication request document
      await _firestore.collection('reapplication_requests').add({
        'instructorId': user.uid,
        'instructorName': instructorName.value,
        'instructorEmail': instructorEmail.value,
        'statement': statement,
        'status': 'Pending Review',
        'submittedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Close dialog
      Get.back();

      // Show success message
      Get.snackbar(
        'Request Submitted',
        'Your reapplication request has been submitted successfully. The admin will review it shortly.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF34A853),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );

      debugPrint('✅ Reapplication request submitted successfully');
    } catch (e) {
      debugPrint('❌ Error submitting reapplication: $e');
      Get.back();
      Get.snackbar(
        'Submission Failed',
        'Failed to submit your request. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Get status color based on status value
  Color getStatusColor() {
    switch (accountStatus.value.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  /// Get status icon based on status value
  IconData getStatusIcon() {
    switch (accountStatus.value.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
      default:
        return Icons.hourglass_empty;
    }
  }
}
