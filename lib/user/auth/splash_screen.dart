import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_controller.dart';
import '../../student_web_version/config/web_routes.dart';

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
          // Sync email verification status (backup sync on app startup)
          try {
            // Try to find existing controller, or create one if it doesn't exist
            AuthController authController;
            try {
              authController = Get.find<AuthController>();
            } catch (e) {
              authController = Get.put(AuthController());
            }
            await authController.checkAndSyncEmailVerification();
          } catch (e) {
            // If sync fails, that's okay - it will sync on next login
            print('Could not sync email verification on splash: $e');
          }

          // Check if user has completed selection and approval status
          final hasCompletedSelection = await _checkUserSelectionStatus(
            refreshedUser.uid,
          );
          final enrollmentStatus = await _getUserEnrollmentStatus(
            refreshedUser.uid,
          );

          print(
            '🔍 Splash screen - Selection complete: $hasCompletedSelection',
          );
          print('🔍 Splash screen - Enrollment status: $enrollmentStatus');

          if (hasCompletedSelection && enrollmentStatus == 'approved') {
            // User has completed selection and is approved, go directly to home
            print('✅ Splash screen - User approved, navigating to home');
            Get.offAllNamed('/home');
          } else if (hasCompletedSelection &&
              (enrollmentStatus == 'pending' ||
                  enrollmentStatus == 'rejected')) {
            // User has completed selection but needs approval or was rejected
            print(
              '⏳ Splash screen - User pending/rejected, navigating to pending approval',
            );
            if (kIsWeb) {
              Get.offAllNamed(WebRoutes.pendingApproval);
            } else {
              Get.offAllNamed('/pending-approval');
            }
          } else {
            // User hasn't completed selection, go to instructor selection
            print(
              '📝 Splash screen - User needs to complete selection, navigating to instructor selection',
            );
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
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final selectionComplete = data['selectionComplete'] ?? false;
        final instructorId = data['selectedInstructorId'] ?? '';
        final instructorName = data['selectedInstructorName'] ?? '';

        // Check if user has completed instructor and course selection
        return selectionComplete &&
            instructorId.isNotEmpty &&
            instructorName.isNotEmpty;
      }
      return false;
    } catch (e) {
      print('Error checking selection status: $e');
      return false;
    }
  }

  Future<String> _getUserEnrollmentStatus(String userId) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final status = data['enrollmentStatus'] ?? 'none';
        print('🔍 Splash screen - User enrollment status: $status');
        return status;
      }
      print('⚠️ Splash screen - User document does not exist');
      return 'none';
    } catch (e) {
      print('❌ Splash screen - Error checking enrollment status: $e');
      return 'none';
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
