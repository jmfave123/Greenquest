import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/online_status_service.dart';

class LoginScreenController extends GetxController {
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable variables
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isFormValid = false.obs;

  // Form controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    // Listen to form changes for real-time validation
    _setupFormListeners();
  }

  @override
  void onClose() {
    // Remove listeners before disposing to prevent errors
    try {
      emailController.removeListener(_validateFormRealTime);
      passwordController.removeListener(_validateFormRealTime);
      emailController.removeListener(_clearErrorOnInput);
      passwordController.removeListener(_clearErrorOnInput);
    } catch (e) {
      debugPrint('Error removing listeners: $e');
    }

    // Dispose controllers safely
    try {
      emailController.dispose();
      passwordController.dispose();
    } catch (e) {
      debugPrint('Error disposing controllers: $e');
    }

    super.onClose();
  }

  // Setup form listeners for real-time validation
  void _setupFormListeners() {
    emailController.addListener(_validateFormRealTime);
    passwordController.addListener(_validateFormRealTime);
    emailController.addListener(_clearErrorOnInput);
    passwordController.addListener(_clearErrorOnInput);
  }

  // Clear error message when user starts typing
  void _clearErrorOnInput() {
    try {
      if (errorMessage.value.isNotEmpty) {
        errorMessage.value = '';
      }
    } catch (e) {
      // Controllers might be disposed, ignore silently
      debugPrint(
        'Error clearing error message (controller may be disposed): $e',
      );
    }
  }

  // Real-time form validation
  void _validateFormRealTime() {
    // Check if controllers are still valid before using
    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      isFormValid.value =
          email.isNotEmpty &&
          GetUtils.isEmail(email) &&
          password.isNotEmpty &&
          password.length >= 6;
    } catch (e) {
      // Controllers might be disposed, skip validation silently
      debugPrint('Error in form validation (controller may be disposed): $e');
    }
  }

  // Validate form fields
  bool _validateForm() {
    try {
      if (emailController.text.trim().isEmpty) {
        errorMessage.value = 'Please enter your email';
        return false;
      }

      if (!GetUtils.isEmail(emailController.text.trim())) {
        errorMessage.value = 'Please enter a valid email address';
        return false;
      }

      if (passwordController.text.trim().isEmpty) {
        errorMessage.value = 'Please enter your password';
        return false;
      }

      if (passwordController.text.length < 6) {
        errorMessage.value = 'Password must be at least 6 characters';
        return false;
      }

      return true;
    } catch (e) {
      // Controllers might be disposed
      debugPrint('Error validating form (controller may be disposed): $e');
      return false;
    }
  }

  // Login method - Firebase Auth with email verification
  Future<void> login() async {
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

      // Get text values safely (controllers might be disposed)
      String email;
      String password;
      try {
        email = emailController.text.trim();
        password = passwordController.text.trim();
      } catch (e) {
        debugPrint('Controllers disposed, aborting login: $e');
        isLoading.value = false;
        return;
      }

      // Debug logging
      debugPrint('Attempting Firebase login with email: $email');

      // Sign in with Firebase Auth
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;
      if (user != null) {
        debugPrint('Firebase Auth successful for: ${user.email}');

        // Check if email is verified - but allow admin accounts to bypass this
        if (!user.emailVerified) {
          // Check if this is an admin account in Firestore
          final adminQuery =
              await _firestore
                  .collection('admins')
                  .where('email', isEqualTo: email)
                  .limit(1)
                  .get();

          if (adminQuery.docs.isNotEmpty) {
            // Admin account - allow login even if email not verified
            debugPrint('Admin account - bypassing email verification');
          } else {
            // Regular user - require email verification
            errorMessage.value =
                'Please verify your email before logging in. Check your inbox for verification link.';

            // Show snackbar with resend option
            Get.snackbar(
              'Email Not Verified',
              'Please verify your email before logging in. Check your inbox for verification link.',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.orange,
              colorText: Colors.white,
              duration: const Duration(seconds: 4),
              mainButton: TextButton(
                onPressed: () => resendVerificationEmail(),
                child: const Text(
                  'Resend Email',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
            return;
          }
        }

        // Query Firestore to get user data and determine user type
        final instructorQuery =
            await _firestore
                .collection('instructors')
                .where('email', isEqualTo: email)
                .limit(1)
                .get();

        final adminQuery =
            await _firestore
                .collection('admins')
                .where('email', isEqualTo: email)
                .limit(1)
                .get();

        debugPrint('Instructor query results: ${instructorQuery.docs.length}');
        debugPrint('Admin query results: ${adminQuery.docs.length}');

        String userType = '';

        // Check if user exists in instructors collection
        if (instructorQuery.docs.isNotEmpty) {
          final instructorData = instructorQuery.docs.first.data();
          final status = instructorData['status']?.toString() ?? 'Pending';
          final isActive = instructorData['isActive'] ?? false;
          final isPhoneVerified = instructorData['isPhoneVerified'] ?? false;

          if (status == 'Approved' && isActive) {
            userType = 'instructor';
            debugPrint('Found approved instructor');

            // Check if phone is verified (required for first login after approval)
            if (!isPhoneVerified) {
              debugPrint(
                'Instructor phone not verified. Redirecting to OTP verification.',
              );
              // Set user as online (will be set again after OTP verification)
              await OnlineStatusService().setOnline();

              // Navigate to phone OTP verification screen
              Get.offAllNamed('/instructor-phone-otp-verification');
              return;
            }
          } else {
            debugPrint(
              'Instructor not approved yet. Status: $status, Active: $isActive',
            );
            errorMessage.value =
                'Your instructor account is pending admin approval. Please wait for approval before logging in.';
            await _auth.signOut(); // Sign out from Firebase Auth
            return;
          }
        }
        // Check if user exists in admins collection
        else if (adminQuery.docs.isNotEmpty) {
          userType = 'admin';
          debugPrint('Found admin');
        }
        // No user found in Firestore
        else {
          debugPrint('No user found in Firestore with email: $email');
          errorMessage.value =
              'No account found with this email. Please register first.';
          await _auth.signOut(); // Sign out from Firebase Auth
          return;
        }

        // Set user as online after successful login
        await OnlineStatusService().setOnline();

        // Show success message
        Get.snackbar(
          'Login Successful',
          'Welcome back!',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF34A853),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        // Navigate based on user type
        if (userType == 'admin') {
          Get.offAllNamed('/admin-dashboard');
        } else {
          Get.offAllNamed('/instructor-dashboard');
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth failed: ${e.code} - ${e.message}');

      // Handle Firebase Auth errors
      String message = 'Login failed. Please try again.';
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email address.';
          break;
        case 'wrong-password':
          message = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        case 'user-disabled':
          message =
              'This account has been disabled. Please contact administrator.';
          break;
        case 'too-many-requests':
          message = 'Too many failed attempts. Please try again later.';
          break;
        case 'invalid-credential':
          message =
              'Invalid email or password. Please check your credentials and try again.';
          break;
        case 'network-request-failed':
          message = 'Network error. Please check your internet connection.';
          break;
        case 'operation-not-allowed':
          message =
              'Email/password accounts are not enabled. Please contact administrator.';
          break;
        default:
          message = 'Login failed: ${e.message ?? 'Unknown error occurred'}.';
      }

      errorMessage.value = message;
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred. Please try again.';
      debugPrint('Login error: $e');
    } finally {
      isLoading.value = false;
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

  // Forgot Password - Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      // Send password reset email
      await _auth.sendPasswordResetEmail(email: email);

      // Close the dialog
      Get.back();

      // Show success message
      Get.snackbar(
        'Reset Link Sent',
        'A password reset link has been sent to $email. Please check your inbox.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF34A853),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Password reset failed: ${e.code} - ${e.message}');

      // Handle specific errors
      String message = 'Failed to send reset email. Please try again.';
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email address.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        case 'too-many-requests':
          message = 'Too many requests. Please try again later.';
          break;
        case 'network-request-failed':
          message = 'Network error. Please check your internet connection.';
          break;
        default:
          message = e.message ?? 'An error occurred. Please try again.';
      }

      // Re-throw with proper message for the dialog to catch
      throw Exception(message);
    } catch (e) {
      debugPrint('Unexpected error in password reset: $e');
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  // Clear form data
  void clearForm() {
    // Check if controllers are still valid before using them
    try {
      emailController.clear();
      passwordController.clear();
    } catch (e) {
      debugPrint('Error clearing controllers: $e');
    }

    errorMessage.value = '';
    isFormValid.value = false;
  }

  // Clear error message
  void clearError() {
    errorMessage.value = '';
  }

  // Logout method
  Future<void> logout() async {
    try {
      // Set user as offline before signing out
      await OnlineStatusService().setOffline();

      // Sign out from Firebase Auth
      await _auth.signOut();

      // Clear form data BEFORE disposing controllers
      clearForm();

      // Navigate to login screen
      Get.offAllNamed('/login');

      Get.snackbar(
        'Logged Out',
        'You have been successfully logged out.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint('Logout error: $e');
      Get.snackbar(
        'Logout Error',
        'An error occurred during logout. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Auto-fill test credentials for easier testing
  void fillTestCredentials(String userType) {
    if (userType == 'admin') {
      emailController.text = 'admin@gmail.com';
      passwordController.text = 'admin123';
    } else if (userType == 'instructor') {
      emailController.text = 'instructor@test.com';
      passwordController.text = '123456';
    }
    _validateFormRealTime();
  }

  // Create test admin account for testing
  Future<void> createTestAdmin() async {
    try {
      // First create Firebase Auth user
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: 'admin@gmail.com',
            password: 'admin123',
          );

      // Send email verification
      await userCredential.user?.sendEmailVerification();

      // Then create Firestore document
      await _firestore.collection('admins').add({
        'name': 'Test Admin',
        'email': 'admin@gmail.com',
        'password': 'admin123',
        'isActive': true,
        'isVerified': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Test Admin Created',
        'Admin account created: admin@gmail.com / admin123\nPlease check email for verification.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint('Error creating test admin: $e');
      Get.snackbar(
        'Error',
        'Failed to create test admin: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Fix existing admin account by creating Firebase Auth user
  Future<void> fixExistingAdmin() async {
    try {
      // Check if admin exists in Firestore
      final adminQuery =
          await _firestore
              .collection('admins')
              .where('email', isEqualTo: 'admin@gmail.com')
              .limit(1)
              .get();

      if (adminQuery.docs.isEmpty) {
        Get.snackbar(
          'Error',
          'No admin found in Firestore with email admin@gmail.com',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Create Firebase Auth user
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: 'admin@gmail.com',
            password: 'admin123',
          );

      // Mark email as verified (since we're fixing an existing account)
      await userCredential.user?.updateDisplayName('Test Admin');

      Get.snackbar(
        'Admin Fixed',
        'Firebase Auth user created for admin@gmail.com\nYou can now login!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      debugPrint('Error fixing admin: $e');
      if (e.toString().contains('email-already-in-use')) {
        Get.snackbar(
          'Admin Already Exists',
          'Firebase Auth user already exists for admin@gmail.com\nTry logging in now!',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to fix admin: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  // Create test instructor account for testing
  Future<void> createTestInstructor() async {
    try {
      // Use a specific document ID to avoid duplicates
      const String testInstructorId = 'test_instructor_123';

      await _firestore.collection('instructors').doc(testInstructorId).set({
        'uid': testInstructorId,
        'name': 'Test Instructor',
        'email': 'instructor@test.com',
        'password': '123456',
        'phone': '1234567890',
        'isActive': true,
        'isVerified': true,
        'status': 'Approved',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Test Instructor Created',
        'Instructor account created: instructor@test.com / 123456',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('Error creating test instructor: $e');
      Get.snackbar(
        'Error',
        'Failed to create test instructor: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Test login with better error reporting
  Future<void> testLogin() async {
    try {
      errorMessage.value = '';
      isLoading.value = true;

      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      debugPrint('Testing Firebase login with: $email');

      // Attempt Firebase Auth
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        debugPrint('Test login successful for: $email');
        Get.snackbar(
          'Success',
          'Login test successful!',
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      debugPrint('Test login error: $e');
      errorMessage.value = 'Test login failed: $e';
    } finally {
      isLoading.value = false;
    }
  }
}
