import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InstructorForgotPasswordScreen extends StatefulWidget {
  const InstructorForgotPasswordScreen({super.key});

  @override
  State<InstructorForgotPasswordScreen> createState() =>
      _InstructorForgotPasswordScreenState();
}

class _InstructorForgotPasswordScreenState
    extends State<InstructorForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  String? _error;
  String? _success;

  void _sendResetLink() {
    // TODO: Implement password reset logic
    setState(() {
      _success = 'A password reset link has been sent to your email (demo).';
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 50),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Forgot Password',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
              ),
              const SizedBox(height: 6),
              const Text(
                'Enter your email to receive a password reset link.',
                style: TextStyle(color: Colors.black54, fontSize: 15),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Email Address',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  hintStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black45,
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: Color(0xFF34A853), width: 2),
                  ),
                ),
                cursorColor: Colors.black54,
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              if (_success != null) ...[
                const SizedBox(height: 10),
                Text(_success!, style: const TextStyle(color: Colors.green)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF34A853),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: _sendResetLink,
                    child: const Text(
                      'Send Reset Link',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: GestureDetector(
                  onTap: () => Get.toNamed('/login'),
                  child: RichText(
                    text: const TextSpan(
                      text: 'Remembered your password? ',
                      style: TextStyle(color: Colors.black, fontSize: 13),
                      children: [
                        TextSpan(
                          text: 'Sign In',
                          style: TextStyle(
                            color: Color(0xFF222B45),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
