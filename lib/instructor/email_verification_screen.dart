import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/sms_provider/semaphore_client.dart';
import 'instructor_register_controller.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final InstructorRegisterController _controller =
      Get.find<InstructorRegisterController>();

  bool _isResending = false;
  bool _isVerified = false;
  String _userEmail = '';
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _getUserEmail();
    // Auto-poll every 3 seconds — when Firebase email is verified, update Firestore
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkVerificationStatus(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _getUserEmail() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _userEmail = user.email ?? '';
      });
    }
  }

  Future<void> _checkVerificationStatus() async {
    if (_isVerified) return;
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      await user.reload();
      if (!user.emailVerified) return;

      // Email is verified in Firebase Auth — now update Firestore via server
      _pollTimer?.cancel();
      setState(() => _isVerified = true);

      final idToken = await user.getIdToken(true);
      if (idToken != null) {
        final client = SemaphoreClient();
        await client.callVerifyEmail(idToken);
      }

      Get.snackbar(
        'Email Verified!',
        'Your email has been verified successfully. You can now log in.',
        backgroundColor: const Color(0xFF34A853),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
      await Future.delayed(const Duration(seconds: 2));
      Get.offAllNamed('/login');
    } catch (_) {}
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isResending = true;
    });

    try {
      await _controller.resendVerificationEmail();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to resend verification email. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700 || screenWidth < 400;
    final buttonHeight = isSmallScreen ? 48.0 : 56.0;
    final padding = isSmallScreen ? 16.0 : 24.0;
    final iconSize = isSmallScreen ? 80.0 : 120.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    screenHeight -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Email Icon with modern design
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF34A853).withOpacity(0.15),
                          const Color(0xFF34A853).withOpacity(0.05),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF34A853).withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.email_outlined,
                      size: iconSize * 0.5,
                      color: const Color(0xFF34A853),
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 28 : 36),

                  // Title
                  Text(
                    'Verify Your Email',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 26 : 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: isSmallScreen ? 14 : 18),

                  // Description
                  Text(
                    'We\'ve sent a verification link to:',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: isSmallScreen ? 10 : 12),

                  // Email Address with modern card
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: isSmallScreen ? screenWidth * 0.85 : 400,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 16 : 20,
                      vertical: isSmallScreen ? 14 : 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF34A853).withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      _userEmail,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 15 : 17,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF34A853),
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 20 : 28),

                  // Instructions
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 20 : 32,
                    ),
                    child: Text(
                      'Please check your email and click the verification link to activate your instructor account.',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        color: Colors.grey[600],
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 32 : 40),

                  // Auto-verification status indicator
                  _isVerified
                      ? Column(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF34A853),
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Email verified! Redirecting...',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              color: const Color(0xFF34A853),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                      : Column(
                        children: [
                          const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF34A853),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Waiting for verification...',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 13 : 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This page will update automatically once you click the link.',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                              color: Colors.grey[400],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),

                  SizedBox(height: isSmallScreen ? 14 : 18),

                  // Resend Email Button - Centered and shorter
                  Center(
                    child: SizedBox(
                      width: isSmallScreen ? screenWidth * 0.75 : 280,
                      child: OutlinedButton.icon(
                        onPressed:
                            _isResending ? null : _resendVerificationEmail,
                        icon:
                            _isResending
                                ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF34A853),
                                    ),
                                  ),
                                )
                                : const Icon(Icons.send, size: 18),
                        label: Text(
                          _isResending ? 'Sending...' : 'Resend Email',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF34A853),
                          side: const BorderSide(
                            color: Color(0xFF34A853),
                            width: 1.5,
                          ),
                          minimumSize: Size(0, buttonHeight - 4),
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 20 : 24,
                            vertical: isSmallScreen ? 14 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 20 : 28),

                  // Help Text
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 24 : 40,
                    ),
                    child: Text(
                      'Didn\'t receive the email? Check your spam folder or contact support.',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 12,
                        color: Colors.grey[500],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 24 : 32),

                  // Back to Login Button
                  TextButton(
                    onPressed: () {
                      Get.offAllNamed('/login');
                    },
                    child: Text(
                      'Back to Login',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: isSmallScreen ? 13 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
