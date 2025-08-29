import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _error;

  void _login() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username == 'admin' && password == '123') {
      setState(() => _error = null);
      Get.offAllNamed('/admin-dashboard');
    } else if (username == 'instructor' && password == '123') {
      setState(() => _error = null);
      Get.offAllNamed('/instructor-dashboard');
    } else {
      setState(() => _error = 'Invalid credentials');
    }
  }

  @override
  Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: _loginCardContent(),
          ),
        ),
      );
    }
 

  Widget _loginCardContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('Admin Sign In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        const SizedBox(height: 6),
        const Text('Welcome back! Please sign in to your account', style: TextStyle(color: Colors.black38, fontSize: 14)),
        const SizedBox(height: 18),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Email Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _usernameController,
          decoration: InputDecoration(
            hintText: 'Enter your email',
            hintStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.black45, fontSize: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Color(0xFF34A853), width: 2),
            ),
          ),
          cursorColor: Colors.black54,
        ),
        const SizedBox(height: 30),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Enter your password',
            hintStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.black45, fontSize: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        const SizedBox(height: 30),
        Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: GestureDetector(
              onTap: () => Get.toNamed('/instructor-register'),
              child: RichText(
                text: TextSpan(
                  text: "Don't have an account? ",
                  style: TextStyle(color: Colors.black, fontSize: 13),
                  children: [
                    TextSpan(
                      text: 'Register',
                      style: TextStyle(color: Color(0xFF222B45), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          height: 42,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34A853),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: _login,
              child: const Text('Sign In', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: () => Get.toNamed('/instructor-forgot-password'),
            child: Text(
              'Forgot your password?',
              style: TextStyle(color: Color(0xFF34A853), fontWeight: FontWeight.w500, fontSize: 16,),
            ),
          ),
        ),
      ],
    );
  }
}