import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  void _checkAuthAndNavigate() async {
    // Wait for 2 seconds to show splash
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Check if user is authenticated with proper token validation
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Refresh user to check if token is still valid
        await user.reload();
        final refreshedUser = FirebaseAuth.instance.currentUser;

        if (refreshedUser != null) {
          // Check if user has completed selection
          final hasCompletedSelection = await _checkUserSelectionStatus(
            refreshedUser.uid,
          );

          if (hasCompletedSelection) {
            // User has completed selection, go directly to home
            Get.offAllNamed('/home');
          } else {
            // User hasn't completed selection, go to instructor selection
            Get.offAllNamed('/select-instructor');
          }
        } else {
          // Token expired, navigate to login
          Get.offAllNamed('/login_app');
        }
      } else {
        // User is not logged in, navigate to login
        Get.offAllNamed('/login_app');
      }
    } catch (e) {
      // If there's any error, navigate to login
      print('Auth check error: $e');
      Get.offAllNamed('/login_app');
    }
  }

  Future<bool> _checkUserSelectionStatus(String userId) async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('user_selections')
              .doc(userId)
              .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['isComplete'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking selection status: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset('assets/images/image 297.png', height: 200),
      ),
    );
  }
}
