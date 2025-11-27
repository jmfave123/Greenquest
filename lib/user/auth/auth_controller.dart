import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../shared/services/online_status_service.dart';
import '../../shared/services/notify_service.dart';

class AuthController extends GetxController {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool isLoggedIn = false;
  String? errorMessage;

  Future<Map<String, dynamic>> registerUser(
    String fullName,
    String phoneNumber,
    String email,
    String idNumber,
    String password,
    String corUrl,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'email': email,
        'idNumber': idNumber,
        'corUrl': corUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'user',
        'isVerified': false,
      });

      await userCredential.user?.sendEmailVerification();

      return {
        'success': true,
        'message':
            'Registration successful! Please check your email for verification.',
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          message = 'An account already exists for that email.';
          break;
        case 'invalid-email':
          message = 'Please provide a valid email address.';
          break;
        default:
          message = 'Registration failed: ${e.message}';
      }
      return {'success': false, 'message': message, 'error': e.code};
    } catch (e) {
      log('Registration error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      // Try to sign in first
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Refresh the user token to ensure we have the latest emailVerified status
      await userCredential.user?.reload();
      final refreshedUser = _auth.currentUser;

      if (refreshedUser == null) {
        return {
          'success': false,
          'message': 'Session expired. Please try logging in again.',
          'error': 'session-expired',
        };
      }

      // Check if email is verified - BLOCK LOGIN if not verified
      if (!refreshedUser.emailVerified) {
        // Try to send verification email before signing out
        try {
          await refreshedUser.sendEmailVerification();
          log('Verification email sent to ${refreshedUser.email}');
        } catch (e) {
          log('Error sending verification email: $e');
          // Continue even if sending email fails
        }

        // Sign out the user since email is not verified
        await _auth.signOut();
        isLoggedIn = false;
        errorMessage = 'Please verify your email before logging in.';

        return {
          'success': false,
          'message':
              'Please verify your email before logging in. A verification email has been sent to your inbox.',
          'error': 'email-not-verified',
          'emailVerified': false,
        };
      }

      // Email is verified - sync Firestore isVerified field
      await _syncEmailVerificationStatus(refreshedUser.uid, true);

      isLoggedIn = true;
      errorMessage = null;

      // Set user as online after successful login
      await OnlineStatusService().setOnline();

      // Register OneSignal tags for student
      try {
        // Get user document to fetch section code and instructor ID
        final userDoc =
            await _firestore.collection('users').doc(refreshedUser.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          final sectionCode = userData?['selectedSectionCode']?.toString();
          final instructorId = userData?['selectedInstructorId']?.toString();

          await OneSignalHelper.registerStudentTags(
            sectionCode: sectionCode,
            instructorId: instructorId,
          );
        } else {
          // User document doesn't exist yet, register basic tags
          await OneSignalHelper.registerStudentTags();
        }
      } catch (e) {
        log('Error registering OneSignal tags: $e');
        // Continue login even if OneSignal fails
      }

      return {
        'success': true,
        'message': 'Login successful!',
        'user': refreshedUser,
        'emailVerified': true,
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with that email address.';
          break;
        case 'wrong-password':
          message = 'Wrong password provided.';
          break;
        case 'invalid-email':
          message = 'Please provide a valid email address.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          message = 'Too many failed attempts. Please try again later.';
          break;
        case 'invalid-credential':
          message =
              'Invalid credentials. Please check your email and password.';
          break;
        case 'account-exists-with-different-credential':
          message =
              'An account already exists with this email but different sign-in method.';
          break;
        case 'network-request-failed':
          message = 'Network error. Please check your internet connection.';
          break;
        default:
          message = 'Login failed: ${e.message}';
      }

      isLoggedIn = false;
      errorMessage = message;

      return {'success': false, 'message': message, 'error': e.code};
    } catch (e) {
      log('Login error: $e');
      isLoggedIn = false;
      errorMessage = 'An unexpected error occurred. Please try again.';

      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
        'error': e.toString(),
      };
    }
  }

  Future<void> logout() async {
    try {
      // Set user as offline before signing out (with timeout)
      try {
        await OnlineStatusService().setOffline().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            log(
              'OnlineStatusService.setOffline() timed out, continuing logout',
            );
          },
        );
      } catch (e) {
        log('Error setting offline status: $e, continuing logout');
      }

      // Sign out from Firebase Auth
      await _auth.signOut();

      // Clear local state
      isLoggedIn = false;
      errorMessage = null;

      // Clear all GetX controllers to ensure clean logout
      try {
        Get.deleteAll();
      } catch (e) {
        log('Error clearing controllers: $e');
      }

      log('User logged out successfully');
    } catch (e) {
      log('Logout error: $e');
      // Even if there's an error, clear local state
      isLoggedIn = false;
      errorMessage = null;
      rethrow; // Re-throw to handle in UI
    }
  }

  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message':
            'Password reset link sent to $email. Please check your inbox.',
      };
    } on FirebaseAuthException catch (e) {
      log('Password reset error: ${e.message}');
      String message;
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
        default:
          message =
              e.message ?? 'Failed to send reset email. Please try again.';
      }
      return {'success': false, 'message': message, 'error': e.code};
    } catch (e) {
      log('Unexpected password reset error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
        'error': e.toString(),
      };
    }
  }

  /// Check if user is currently authenticated and token is valid
  Future<bool> isUserAuthenticated() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Refresh the user to check if token is still valid
      await user.reload();
      final refreshedUser = _auth.currentUser;

      if (refreshedUser == null) {
        isLoggedIn = false;
        return false;
      }

      isLoggedIn = true;
      return true;
    } catch (e) {
      log('Auth check error: $e');
      isLoggedIn = false;
      return false;
    }
  }

  /// Get current user with token refresh
  Future<User?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Refresh the user to ensure token is valid
      await user.reload();
      return _auth.currentUser;
    } catch (e) {
      log('Get current user error: $e');
      return null;
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      log('Send email verification error: $e');
      rethrow;
    }
  }

  /// Sync email verification status between Firebase Auth and Firestore
  Future<void> _syncEmailVerificationStatus(
    String userId,
    bool isVerified,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isVerified': isVerified,
        'emailVerifiedAt': isVerified ? FieldValue.serverTimestamp() : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      log(
        '✅ Synced email verification status: isVerified=$isVerified for user $userId',
      );
    } catch (e) {
      log('Error syncing email verification status: $e');
      // Don't throw - this is a sync operation, shouldn't block login
    }
  }

  /// Check and sync email verification status (used on app startup)
  Future<void> checkAndSyncEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Reload to get latest emailVerified status
        await user.reload();
        final refreshedUser = _auth.currentUser;

        if (refreshedUser != null) {
          // Sync Firestore with Firebase Auth status
          await _syncEmailVerificationStatus(
            refreshedUser.uid,
            refreshedUser.emailVerified,
          );
        }
      }
    } catch (e) {
      log('Error checking email verification status: $e');
      // Don't throw - this is a background sync
    }
  }
}
