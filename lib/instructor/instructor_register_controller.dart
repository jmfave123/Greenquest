import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InstructorRegisterController extends GetxController {
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable variables
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isFormValid = false.obs;

  // Form controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    // Listen to form changes for real-time validation
    _setupFormListeners();
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  // Setup form listeners for real-time validation
  void _setupFormListeners() {
    nameController.addListener(_validateFormRealTime);
    emailController.addListener(_validateFormRealTime);
    phoneController.addListener(_validateFormRealTime);
    passwordController.addListener(_validateFormRealTime);
  }

  // Real-time form validation
  void _validateFormRealTime() {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();

    isFormValid.value =
        name.isNotEmpty &&
        email.isNotEmpty &&
        GetUtils.isEmail(email) &&
        phone.isNotEmpty &&
        password.isNotEmpty &&
        password.length >= 6;
  }

  // Validate form fields
  bool _validateForm() {
    if (nameController.text.trim().isEmpty) {
      errorMessage.value = 'Please enter your full name';
      return false;
    }

    if (emailController.text.trim().isEmpty) {
      errorMessage.value = 'Please enter your email address';
      return false;
    }

    if (!GetUtils.isEmail(emailController.text.trim())) {
      errorMessage.value = 'Please enter a valid email address';
      return false;
    }

    if (phoneController.text.trim().isEmpty) {
      errorMessage.value = 'Please enter your phone number';
      return false;
    }

    if (passwordController.text.trim().isEmpty) {
      errorMessage.value = 'Please enter a password';
      return false;
    }

    if (passwordController.text.length < 6) {
      errorMessage.value = 'Password must be at least 6 characters';
      return false;
    }

    return true;
  }

  // Register instructor method - Firebase Auth + Firestore
  Future<void> registerInstructor() async {
    try {
      // Clear previous error
      errorMessage.value = '';

      // Validate form
      if (!_validateForm()) {
        return;
      }

      // Set loading state
      isLoading.value = true;

      // Dismiss keyboard
      Get.focusScope?.unfocus();

      // Create user account with Firebase Auth
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      final User? user = userCredential.user;

      if (user != null) {
        // Send email verification
        await user.sendEmailVerification();

        // Store instructor data in Firestore
        await _firestore.collection('instructors').doc(user.uid).set({
          'uid': user.uid,
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'phone': phoneController.text.trim(),
          'password':
              passwordController.text
                  .trim(), // Store password for Firestore auth
          'isVerified': false,
          'isActive': false, // Set to false until admin approval
          'status': 'Pending', // Set status to Pending for admin review
          'isPhoneVerified':
              false, // Phone verification required on first login
          'phoneVerifiedAt': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Show success message
        Get.snackbar(
          'Registration Successful!',
          'Please check your email and verify your account before logging in.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF34A853),
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );

        // Navigate to email verification screen
        Get.offAllNamed('/instructor-email-verification');
      } else {
        errorMessage.value = 'Failed to create account. Please try again.';
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed. Please try again.';

      switch (e.code) {
        case 'weak-password':
          message = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          message = 'An account already exists for this email.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        case 'operation-not-allowed':
          message = 'Email/password accounts are not enabled.';
          break;
        case 'network-request-failed':
          message = 'Network error. Please check your internet connection.';
          break;
        default:
          message =
              'Registration failed: ${e.message ?? 'Unknown error occurred'}.';
      }

      errorMessage.value = message;
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred. Please try again.';
      debugPrint('Registration error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Check if email is verified
  Future<bool> isEmailVerified() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        return user.emailVerified;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking email verification: $e');
      return false;
    }
  }

  // Resend verification email
  Future<void> resendVerificationEmail() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        Get.snackbar(
          'Verification Email Sent',
          'Please check your email for verification link.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF34A853),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      errorMessage.value =
          'Failed to send verification email. Please try again.';
    }
  }

  // Clear form data
  void clearForm() {
    nameController.clear();
    emailController.clear();
    phoneController.clear();
    passwordController.clear();
    errorMessage.value = '';
    isFormValid.value = false;
  }

  // Clear error message
  void clearError() {
    errorMessage.value = '';
  }
}
