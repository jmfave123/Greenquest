import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

    // Check if user is authenticated
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User is logged in, navigate to select-instructor
      Get.offAllNamed('/select-instructor');
    } else {
      // User is not logged in, navigate to login
      Get.offAllNamed('/login_app');
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
