import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

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
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'user',
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

      // Check if email is verified
      if (userCredential.user?.emailVerified == false) {
        // Sign out the user since email is not verified
        await _auth.signOut();
        return {
          'success': false,
          'message': 'Please verify your email before logging in.',
          'error': 'email-not-verified',
        };
      }

      isLoggedIn = true;
      errorMessage = null;

      return {
        'success': true,
        'message': 'Login successful!',
        'user': userCredential.user,
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
      await _auth.signOut();
      isLoggedIn = false;
      errorMessage = null;
    } catch (e) {
      log('Logout error: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      log('Password reset error: ${e.message}');
      rethrow;
    }
  }
}
