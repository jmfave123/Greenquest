import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'instructor_register_controller.dart';

class InstructorRegisterScreen extends StatelessWidget {
  const InstructorRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller with proper GetX pattern
    final InstructorRegisterController controller = Get.put(
      InstructorRegisterController(),
    );

    // Get screen dimensions for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    // Responsive dimensions
    final containerWidth =
        isMobile
            ? screenWidth * 0.95
            : isTablet
            ? screenWidth * 0.7
            : 500.0;

    final horizontalPadding =
        isMobile
            ? 20.0
            : isTablet
            ? 40.0
            : 50.0;

    final verticalPadding =
        isMobile
            ? 30.0
            : isTablet
            ? 40.0
            : 50.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16.0 : 24.0,
                vertical: isMobile ? 20.0 : 40.0,
              ),
              child: Container(
                width: containerWidth,
                constraints: BoxConstraints(
                  maxWidth: 500,
                  minHeight: isMobile ? screenHeight * 0.8 : 0,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: isMobile ? 6 : 8,
                      offset: Offset(0, isMobile ? 1 : 2),
                    ),
                  ],
                ),
                child: Obx(
                  () => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Instructor Sign Up',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize:
                              isMobile
                                  ? 22
                                  : isTablet
                                  ? 24
                                  : 26,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isMobile ? 4 : 6),
                      Text(
                        'Please fill up to register your account',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: isMobile ? 13 : 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isMobile ? 20 : 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Name',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 13 : 14,
                          ),
                        ),
                      ),
                      SizedBox(height: isMobile ? 4 : 6),
                      TextField(
                        controller: controller.nameController,
                        decoration: InputDecoration(
                          hintText: 'Enter your name',
                          hintStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black45,
                            fontSize: isMobile ? 13 : 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              isMobile ? 8 : 6,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16 : 12,
                            vertical: isMobile ? 16 : 12,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              isMobile ? 8 : 6,
                            ),
                            borderSide: BorderSide(
                              color: Color(0xFF34A853),
                              width: 2,
                            ),
                          ),
                        ),
                        cursorColor: Colors.black54,
                        style: TextStyle(fontSize: isMobile ? 14 : 16),
                      ),
                      SizedBox(height: isMobile ? 12 : 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Email Address',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 13 : 14,
                          ),
                        ),
                      ),
                      SizedBox(height: isMobile ? 4 : 6),
                      TextField(
                        controller: controller.emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Enter your email',
                          hintStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black45,
                            fontSize: isMobile ? 13 : 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              isMobile ? 8 : 6,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16 : 12,
                            vertical: isMobile ? 16 : 12,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              isMobile ? 8 : 6,
                            ),
                            borderSide: BorderSide(
                              color: Color(0xFF34A853),
                              width: 2,
                            ),
                          ),
                        ),
                        cursorColor: Colors.black54,
                        style: TextStyle(fontSize: isMobile ? 14 : 16),
                      ),
                      SizedBox(height: isMobile ? 6 : 8),
                      // Email verification note
                      Container(
                        padding: EdgeInsets.all(isMobile ? 10 : 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34A853).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                          border: Border.all(
                            color: const Color(0xFF34A853).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: isMobile ? 14 : 16,
                              color: const Color(0xFF34A853),
                            ),
                            SizedBox(width: isMobile ? 6 : 8),
                            Expanded(
                              child: Text(
                                'A verification email will be sent to this address',
                                style: TextStyle(
                                  fontSize: isMobile ? 11 : 12,
                                  color: const Color(0xFF34A853),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isMobile ? 12 : 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Phone Number',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black38,
                            fontSize: isMobile ? 13 : 14,
                          ),
                        ),
                      ),
                      SizedBox(height: isMobile ? 4 : 6),
                      TextField(
                        controller: controller.phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: 'Enter your number',
                          hintStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black45,
                            fontSize: isMobile ? 13 : 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              isMobile ? 8 : 6,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16 : 12,
                            vertical: isMobile ? 16 : 12,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              isMobile ? 8 : 6,
                            ),
                            borderSide: BorderSide(
                              color: Color(0xFF34A853),
                              width: 2,
                            ),
                          ),
                        ),
                        cursorColor: Colors.black54,
                        style: TextStyle(fontSize: isMobile ? 14 : 16),
                      ),
                      SizedBox(height: isMobile ? 12 : 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Password',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 13 : 14,
                          ),
                        ),
                      ),
                      SizedBox(height: isMobile ? 4 : 6),
                      TextField(
                        controller: controller.passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          hintStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black45,
                            fontSize: isMobile ? 13 : 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              isMobile ? 8 : 6,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16 : 12,
                            vertical: isMobile ? 16 : 12,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              isMobile ? 8 : 6,
                            ),
                            borderSide: BorderSide(
                              color: Color(0xFF34A853),
                              width: 2,
                            ),
                          ),
                        ),
                        cursorColor: Colors.black54,
                        style: TextStyle(fontSize: isMobile ? 14 : 16),
                      ),
                      if (controller.errorMessage.value.isNotEmpty) ...[
                        SizedBox(height: isMobile ? 8 : 10),
                        Text(
                          controller.errorMessage.value,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: isMobile ? 11 : 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      SizedBox(height: isMobile ? 20 : 24),
                      SizedBox(
                        width: double.infinity,
                        height: isMobile ? 48 : 42,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                controller.isFormValid.value
                                    ? const Color(0xFF34A853)
                                    : const Color.fromARGB(255, 101, 197, 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                isMobile ? 8 : 6,
                              ),
                            ),
                            elevation: 0,
                          ),
                          onPressed:
                              controller.isLoading.value ||
                                      !controller.isFormValid.value
                                  ? null
                                  : controller.registerInstructor,
                          child:
                              controller.isLoading.value
                                  ? SizedBox(
                                    height: isMobile ? 22 : 20,
                                    width: isMobile ? 22 : 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      fontSize: isMobile ? 16 : 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                        ),
                      ),
                      SizedBox(height: isMobile ? 16 : 18),
                      Center(
                        child: GestureDetector(
                          onTap: () => Get.toNamed('/login'),
                          child: RichText(
                            text: TextSpan(
                              text: 'Already have an account? ',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: isMobile ? 12 : 13,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Sign In',
                                  style: TextStyle(
                                    color: Color(0xFF222B45),
                                    fontWeight: FontWeight.bold,
                                    fontSize: isMobile ? 12 : 13,
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
            ),
          ),
        ),
      ),
    );
  }
}
