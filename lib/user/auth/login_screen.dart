import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenquest/components/snackbarUtils.dart';
import 'package:greenquest/user/auth/auth_controller.dart';
import '../../shared/widgets/forgot_password_dialog.dart';
import '../../shared/widgets/safe_asset_image.dart';

class LoginScreenApp extends StatefulWidget {
  const LoginScreenApp({super.key});

  @override
  State<LoginScreenApp> createState() => _LoginScreenAppState();
}

class _LoginScreenAppState extends State<LoginScreenApp> {
  bool _isPasswordVisible = false;
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  bool isLoading = false;
  final AuthController authController = Get.put(AuthController());

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    // Safely dispose controllers
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              const SafeAssetImage(
                assetPath: 'assets/images/GreenQuest Logo.jpg',
                height: 150,
                fit: BoxFit.contain,
              ),
              const Text(
                "Let's sign you in",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(left: 15),
                    child: Image.asset('assets/icons/ci_mail.png', height: 24),
                  ),
                  hintText: '@gmail.com',
                  hintStyle: TextStyle(color: Colors.black38),
                  filled: true,
                  fillColor: Color(0xFFF2F2F2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(left: 15),
                    child: Image.asset(
                      'assets/icons/charm_shield-keyhole.png',
                      height: 24,
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  hintText: '********',
                  hintStyle: TextStyle(color: Colors.black38),
                  filled: true,
                  fillColor: Color(0xFFF2F2F2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    // Show forgot password dialog
                    Get.dialog(
                      ForgotPasswordDialog(
                        onResetPassword: (email) async {
                          final result = await authController.resetPassword(
                            email,
                          );
                          if (result['success']) {
                            // Show success message after dialog closes
                            Future.delayed(const Duration(milliseconds: 300), () {
                              showInfoSnackBar(
                                context,
                                message:
                                    'Password reset link has been sent to your email!',
                              );
                            });
                          } else {
                            throw Exception(result['message']);
                          }
                        },
                      ),
                    );
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Color(0xFF43A047),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () {
                      Get.toNamed('/register');
                    },
                    child: const Text(
                      'Register',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (emailController.text.isEmpty ||
                        passwordController.text.isEmpty) {
                      showInfoSnackBar(
                        context,
                        message: 'Please enter your email and password',
                      );
                      return;
                    }
                    await _loginUser();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF43A047),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child:
                      isLoading
                          ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                          : const Text('Sign in'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loginUser() async {
    // Check if controllers are still valid before using
    if (!mounted) return;

    // Get text values before async operation to avoid using disposed controllers
    final email = emailController.text;
    final password = passwordController.text;

    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    final result = await authController.loginUser(email, password);

    // Check if widget is still mounted before updating state
    if (!mounted) return;
    setState(() {
      isLoading = false;
    });

    if (result['success']) {
      showInfoSnackBar(context, message: result['message']);
      // Navigate to home screen or dashboard
      Get.offAllNamed('/select-instructor');
    } else {
      if (mounted) {
        // Check if error is due to email not verified
        if (result['error'] == 'email-not-verified') {
          // Show error message (verification email was already sent during login attempt)
          showErrorSnackBar(
            context,
            message:
                result['message'] ??
                'Please verify your email before logging in. Check your inbox for the verification link.',
          );
        } else {
          // Show regular error
          showErrorSnackBar(context, message: result['message']);
        }
      }
    }
  }
}
