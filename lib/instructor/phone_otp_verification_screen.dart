import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/sms_provider/sms_chef_client.dart';
import '../shared/services/online_status_service.dart';

class PhoneOtpVerificationScreen extends StatefulWidget {
  const PhoneOtpVerificationScreen({super.key});

  @override
  State<PhoneOtpVerificationScreen> createState() =>
      _PhoneOtpVerificationScreenState();
}

class _PhoneOtpVerificationScreenState
    extends State<PhoneOtpVerificationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SmsChefClient _smsClient = SmsChefClient();

  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isSendingOtp = false;
  bool _isVerifying = false;
  String _errorMessage = '';
  String _phoneNumber = '';
  String _formattedPhone = '';
  int _cooldownSeconds = 0;
  bool _otpSent = false;

  @override
  void initState() {
    super.initState();
    _loadInstructorPhone();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadInstructorPhone() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Wait a bit to ensure Firebase Auth is ready
      await Future.delayed(const Duration(milliseconds: 300));

      // Get user and ensure token is fresh (same as login flow)
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'User not authenticated. Please login again.';
          _isLoading = false;
        });
        return;
      }

      // Reload user to get fresh token (same as login flow)
      try {
        await user.reload();
      } catch (e) {
        // If reload fails, user might still be valid
      }

      final refreshedUser = _auth.currentUser;
      if (refreshedUser == null || refreshedUser.email == null) {
        setState(() {
          _errorMessage = 'User session expired. Please login again.';
          _isLoading = false;
        });
        return;
      }

      // Query instructor by email (same pattern as login flow)
      // This ensures we get all instructor data exactly like login does
      final instructorQuery =
          await _firestore
              .collection('instructors')
              .where('email', isEqualTo: refreshedUser.email)
              .limit(1)
              .get();

      if (instructorQuery.docs.isEmpty) {
        setState(() {
          _errorMessage =
              'Instructor data not found. Please contact support or try logging in again.';
          _isLoading = false;
        });
        return;
      }

      // Get instructor data (same as login flow)
      final instructorData = instructorQuery.docs.first.data();
      final phone = instructorData['phone'] ?? '';

      if (phone.isEmpty) {
        setState(() {
          _errorMessage =
              'Phone number not found in your profile. Please contact support.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _phoneNumber = phone;
        _formattedPhone = _smsClient.formatPhoneNumber(phone);
        _isLoading = false;
      });

      // Auto-send OTP when screen loads
      await _sendOtp();
    } catch (e) {
      setState(() {
        _errorMessage =
            'Unable to load instructor data. Please try logging in again. If the problem persists, contact support.';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendOtp() async {
    if (_phoneNumber.isEmpty) return;

    setState(() {
      _isSendingOtp = true;
      _errorMessage = '';
    });

    try {
      final result = await _smsClient.sendOtp(_phoneNumber);

      if (result['success'] == true) {
        setState(() {
          _otpSent = true;
          _cooldownSeconds = 60; // 1 minute cooldown
        });

        // Start cooldown timer
        _startCooldownTimer();

        Get.snackbar(
          'OTP Sent',
          'Verification code has been sent to $_formattedPhone',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF34A853),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } else {
        setState(() {
          _errorMessage =
              result['error'] ?? 'Failed to send OTP. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error sending OTP: $e';
      });
    } finally {
      setState(() {
        _isSendingOtp = false;
      });
    }
  }

  void _startCooldownTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          if (_cooldownSeconds > 0) {
            _cooldownSeconds--;
          }
        });
        return _cooldownSeconds > 0;
      }
      return false;
    });
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the OTP code.';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = '';
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'User not authenticated. Please login again.';
        });
        return;
      }

      final result = await _smsClient.verifyOtp(otp);

      if (result['success'] == true) {
        // Update Firestore with phone verification status (same as login flow updates)
        await _firestore.collection('instructors').doc(user.uid).update({
          'isPhoneVerified': true,
          'phoneVerifiedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Set user as online after successful verification (same as login flow)
        await OnlineStatusService().setOnline();

        // Show success message (same style as login)
        Get.snackbar(
          'Phone Verified!',
          'Your phone number has been verified successfully.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF34A853),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        // Navigate to dashboard (same as login flow)
        Get.offAllNamed('/instructor-dashboard');
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Invalid OTP. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error verifying OTP: $e';
      });
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700 || screenWidth < 400;
    final padding = isSmallScreen ? 16.0 : 24.0;

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
              child:
                  _isLoading
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                const Color(0xFF34A853),
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 20 : 24),
                            Text(
                              'Loading your information...',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                      : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Phone Icon with modern design
                          Container(
                            width: isSmallScreen ? 80 : 120,
                            height: isSmallScreen ? 80 : 120,
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
                                  color: const Color(
                                    0xFF34A853,
                                  ).withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.phone_android_outlined,
                              size: (isSmallScreen ? 80 : 120) * 0.5,
                              color: const Color(0xFF34A853),
                            ),
                          ),

                          SizedBox(height: isSmallScreen ? 28 : 36),

                          // Title
                          Text(
                            'Verify Your Phone',
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
                            'We\'ve sent a verification code to:',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: isSmallScreen ? 10 : 12),

                          // Phone Number Display with modern card
                          Container(
                            constraints: BoxConstraints(
                              maxWidth:
                                  isSmallScreen ? screenWidth * 0.85 : 400,
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
                              _formattedPhone.isEmpty
                                  ? 'Loading...'
                                  : _formattedPhone,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 15 : 17,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF34A853),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          SizedBox(height: isSmallScreen ? 28 : 36),

                          // OTP Input Field - Centered with modern design
                          Center(
                            child: SizedBox(
                              width: isSmallScreen ? screenWidth * 0.7 : 280,
                              child: TextField(
                                controller: _otpController,
                                focusNode: _otpFocusNode,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 28 : 32,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 10,
                                  color: Colors.black87,
                                ),
                                maxLength: 6,
                                decoration: InputDecoration(
                                  hintText: '000000',
                                  hintStyle: TextStyle(
                                    fontSize: isSmallScreen ? 28 : 32,
                                    letterSpacing: 10,
                                    color: Colors.grey[300],
                                  ),
                                  counterText: '',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                      width: 1.5,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                      width: 1.5,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF34A853),
                                      width: 2.5,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 16 : 20,
                                    vertical: isSmallScreen ? 20 : 24,
                                  ),
                                ),
                                onSubmitted: (_) => _verifyOtp(),
                              ),
                            ),
                          ),

                          if (_errorMessage.isNotEmpty) ...[
                            SizedBox(height: isSmallScreen ? 12 : 16),
                            Center(
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      isSmallScreen ? screenWidth * 0.85 : 400,
                                ),
                                padding: EdgeInsets.all(
                                  isSmallScreen ? 12 : 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red[300]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red[700],
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage,
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 12 : 14,
                                          color: Colors.red[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          SizedBox(height: isSmallScreen ? 32 : 40),

                          // Verify Button - Centered and shorter
                          Center(
                            child: SizedBox(
                              width: isSmallScreen ? screenWidth * 0.75 : 280,
                              child: ElevatedButton(
                                onPressed:
                                    (_isVerifying || _isLoading)
                                        ? null
                                        : _verifyOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF34A853),
                                  foregroundColor: Colors.white,
                                  minimumSize: Size(0, isSmallScreen ? 48 : 52),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 20 : 24,
                                    vertical: isSmallScreen ? 14 : 16,
                                  ),
                                  elevation: 4,
                                  shadowColor: const Color(
                                    0xFF34A853,
                                  ).withOpacity(0.4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child:
                                    _isVerifying
                                        ? SizedBox(
                                          height: isSmallScreen ? 20 : 24,
                                          width: isSmallScreen ? 20 : 24,
                                          child:
                                              const CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                        )
                                        : Text(
                                          'Verify',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 16 : 17,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                              ),
                            ),
                          ),

                          SizedBox(height: isSmallScreen ? 14 : 18),

                          // Resend OTP Button - Centered and shorter
                          Center(
                            child: SizedBox(
                              width: isSmallScreen ? screenWidth * 0.75 : 280,
                              child: OutlinedButton.icon(
                                onPressed:
                                    (_cooldownSeconds > 0 ||
                                            _isSendingOtp ||
                                            _isLoading)
                                        ? null
                                        : _sendOtp,
                                icon:
                                    _isSendingOtp
                                        ? SizedBox(
                                          width: 18,
                                          height: 18,
                                          child:
                                              const CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Color(0xFF34A853)),
                                              ),
                                        )
                                        : const Icon(Icons.refresh, size: 18),
                                label: Text(
                                  _cooldownSeconds > 0
                                      ? 'Resend in ${_cooldownSeconds}s'
                                      : 'Resend Code',
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
                                  minimumSize: Size(0, isSmallScreen ? 44 : 48),
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
                              'Didn\'t receive the code? Check your messages or wait for the cooldown to resend.',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 12,
                                color: Colors.grey[500],
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
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
