import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:greenquest/shared/login/login_screen.dart';
import 'package:greenquest/user/auth/auth_controller.dart';
import 'package:greenquest/components/snackbarUtils.dart';
import '../../../shared/widgets/safe_asset_image.dart';

class WebRegisterScreen extends StatefulWidget {
  const WebRegisterScreen({super.key});

  @override
  State<WebRegisterScreen> createState() => _WebRegisterScreenState();
}

class _WebRegisterScreenState extends State<WebRegisterScreen> {
  final AuthController authController = Get.put(AuthController());
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final idController = TextEditingController();
  final passwordController = TextEditingController();
  final RxBool isLoading = false.obs;
  final RxBool isPasswordVisible = false.obs;
  final RxBool agreeTerms = false.obs;

  Future<void> _register() async {
    if (!agreeTerms.value) {
      showInfoSnackBar(
        context,
        message: 'Please agree to the terms and conditions',
      );
      return;
    }
    if ([
      nameController,
      phoneController,
      emailController,
      idController,
      passwordController,
    ].any((c) => c.text.isEmpty)) {
      showInfoSnackBar(context, message: 'Please fill in all fields');
      return;
    }
    if (!phoneController.text.startsWith('09') ||
        phoneController.text.length != 11) {
      showErrorSnackBar(
        context,
        message: 'Phone number must start with 09 and be 11 digits',
      );
      return;
    }
    if (idController.text.length != 10) {
      showErrorSnackBar(
        context,
        message: 'ID number must be exactly 10 digits',
      );
      return;
    }

    isLoading.value = true;
    try {
      final res = await authController.registerUser(
        nameController.text,
        phoneController.text,
        emailController.text,
        idController.text,
        passwordController.text,
      );
      if (res['success']) {
        showInfoSnackBar(context, message: res['message']);
        Get.offAllNamed('/login');
      } else {
        showErrorSnackBar(context, message: res['message']);
      }
    } catch (e) {
      showErrorSnackBar(context, message: 'An unexpected error occurred');
    } finally {
      isLoading.value = false;
    }
  }

  void _showTermsModal() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Terms & Conditions',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF34A853),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: const Text(
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
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF34A853),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('I Agree'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SafeAssetImage(
                  assetPath: 'assets/images/GreenQuest Logo.jpg',
                  height: 100,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Create Student Account',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Join the green movement today',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                _buildField(
                  'Full Name',
                  nameController,
                  Icons.person_outline,
                  hint: 'e.g. Juan Dela Cruz',
                ),
                _buildField(
                  'Phone Number',
                  phoneController,
                  Icons.phone_android_outlined,
                  inputType: TextInputType.phone,
                  hint: '09XXXXXXXXX',
                  formatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                ),
                _buildField(
                  'Email',
                  emailController,
                  Icons.email_outlined,
                  inputType: TextInputType.emailAddress,
                  hint: 'example@email.com',
                ),
                _buildField(
                  'ID Number (10 digits)',
                  idController,
                  Icons.badge_outlined,
                  inputType: TextInputType.number,
                  hint: 'e.g. 1234567890',
                  formatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
                _buildPasswordField(hint: 'At least 6 characters'),
                const SizedBox(height: 16),
                Obx(
                  () => Row(
                    children: [
                      Checkbox(
                        value: agreeTerms.value,
                        onChanged: (v) => agreeTerms.value = v ?? false,
                        activeColor: const Color(0xFF34A853),
                      ),
                      const Text('I agree with the '),
                      TextButton(
                        onPressed: _showTermsModal,
                        child: const Text(
                          'Terms & Conditions',
                          style: TextStyle(
                            color: Color(0xFF34A853),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading.value ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF34A853),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          isLoading.value
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? '),
                    TextButton(
                      onPressed: () => Get.to(() => const LoginScreen()),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF34A853),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType inputType = TextInputType.text,
    List<TextInputFormatter>? formatters,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: inputType,
            inputFormatters: formatters,
            cursorColor: const Color(0xFF34A853),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 20),
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.black26),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF34A853),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({String? hint}) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Password',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: passwordController,
            obscureText: !isPasswordVisible.value,
            cursorColor: const Color(0xFF34A853),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.black26),
              suffixIcon: IconButton(
                icon: Icon(
                  isPasswordVisible.value
                      ? Icons.visibility
                      : Icons.visibility_off,
                  size: 20,
                ),
                onPressed: () => isPasswordVisible.toggle(),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF34A853),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
