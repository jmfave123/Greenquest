import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:greenquest/components/snackbarUtils.dart';
import 'package:greenquest/user/auth/auth_controller.dart';
import '../../shared/widgets/safe_asset_image.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool agreeTerms = false;
  bool isLoading = false;
  bool _isPasswordVisible = false;
  final AuthController authController = Get.put(AuthController());
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController idNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _showTermsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (context, scrollController) => SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Terms & Conditions',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF43A047),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Welcome to GreenQuest! By creating an account, you agree to the following terms and conditions.\n\n'
                          '1. Your data will be used to enhance your experience and for educational purposes.\n'
                          '2. You are responsible for keeping your login credentials secure.\n'
                          '3. Please respect the community guidelines and use the app responsibly.\n'
                          '4. For more details, refer to our privacy policy in the app settings.\n\n'
                          'Thank you for joining GreenQuest!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF43A047),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('I Agree'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 24,
                ),
                onPressed: () => Navigator.pop(context),
                constraints: const BoxConstraints(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: SafeAssetImage(
                        assetPath: 'assets/images/GreenQuest Logo.jpg',
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Let's create your account",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextField(
                      controller: fullNameController,
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(left: 15),
                          child: Image.asset(
                            'assets/icons/solar_user-linear.png',
                            height: 24,
                          ),
                        ),
                        hintText: 'Full name',
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
                      controller: phoneNumberController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(left: 15),
                          child: Image.asset(
                            'assets/icons/solar_phone-linear.png',
                            height: 24,
                          ),
                        ),
                        hintText: 'Phone Number (09XXXXXXXXX)',
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
                      controller: emailController,
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(left: 15),
                          child: Image.asset(
                            'assets/icons/ci_mail.png',
                            height: 24,
                          ),
                        ),
                        hintText: 'Email',
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
                      controller: idNumberController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(left: 15),
                          child: Image.asset(
                            'assets/icons/hugeicons_id.png',
                            height: 24,
                          ),
                        ),
                        hintText: 'ID Number (10 digits)',
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
                        hintText: 'Password',
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
                    Row(
                      children: [
                        Checkbox(
                          value: agreeTerms,
                          onChanged: (v) {
                            setState(() {
                              agreeTerms = v ?? false;
                            });
                          },
                          activeColor: const Color(0xFF43A047),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const Text('Agree with  '),
                        GestureDetector(
                          onTap: () => _showTermsModal(context),
                          child: const Text(
                            'Terms & Condition',
                            style: TextStyle(
                              color: Color(0xFF43A047),
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFF43A047),
                              decorationThickness: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already registered? '),
                        GestureDetector(
                          onTap: () {
                            Get.toNamed('/login_app');
                          },
                          child: const Text(
                            'Sign in',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!agreeTerms) {
                            showInfoSnackBar(
                              context,
                              message:
                                  'Please agree to the terms and conditions',
                            );
                            return;
                          }

                          if (fullNameController.text.isEmpty ||
                              phoneNumberController.text.isEmpty ||
                              emailController.text.isEmpty ||
                              idNumberController.text.isEmpty ||
                              passwordController.text.isEmpty) {
                            showInfoSnackBar(
                              context,
                              message: 'Please fill in all fields',
                            );
                            return;
                          }

                          // Validate phone number format (must start with 09 and be 11 digits)
                          if (!phoneNumberController.text.startsWith('09')) {
                            showErrorSnackBar(
                              context,
                              message: 'Phone number must start with 09',
                            );
                            return;
                          }

                          if (phoneNumberController.text.length != 11) {
                            showErrorSnackBar(
                              context,
                              message: 'Phone number must be exactly 11 digits',
                            );
                            return;
                          }

                          // Validate ID number length (must be 10 digits)
                          if (idNumberController.text.length != 10) {
                            showErrorSnackBar(
                              context,
                              message: 'ID number must be exactly 10 digits',
                            );
                            return;
                          }

                          await _registerUser();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF43A047),
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
                                : const Text('Verify'),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _registerUser() async {
    setState(() {
      isLoading = true;
    });

    try {
      final result = await authController.registerUser(
        fullNameController.text,
        phoneNumberController.text,
        emailController.text,
        idNumberController.text,
        passwordController.text,
        nstpComponent: '',
      );

      setState(() {
        isLoading = false;
      });

      if (result['success']) {
        showInfoSnackBar(context, message: result['message']);
        // Navigate to login screen after successful registration
        Get.offAllNamed('/login_app');
      } else {
        showErrorSnackBar(context, message: result['message']);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showErrorSnackBar(
        context,
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }
}
