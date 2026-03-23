import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/services/cloudinary_service.dart';
import '../../../shared/config/cloudinary_config.dart';
import '../../../shared/utils/auth_error_utils.dart';
import '../../../shared/widgets/forgot_password_dialog.dart';
import '../../../user/auth/auth_controller.dart';
import '../../../shared/services/student_data_service.dart';

class WebProfileController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable variables
  final RxBool isLoading = true.obs;
  final RxBool isImageLoading = false.obs;
  final RxMap<String, dynamic> userData = <String, dynamic>{}.obs;
  final RxInt totalPoints = 0.obs;

  // Image upload services
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Form controllers for editing (matching InstructorController pattern for reuse)
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final RxBool isEditing = false.obs;
  final RxBool isPasswordSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeCloudinary();
    fetchProfileData();
  }

  void _initializeCloudinary() {
    if (CloudinaryConfig.cloudName.isNotEmpty) {
      _cloudinaryService.initialize(
        cloudName: CloudinaryConfig.cloudName,
        apiKey: CloudinaryConfig.apiKey,
        apiSecret: CloudinaryConfig.apiSecret,
      );
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    aboutController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  Future<void> fetchProfileData({bool forceRefresh = false}) async {
    try {
      isLoading.value = true;
      
      final data = await StudentDataService.getStudentData(forceRefresh: forceRefresh);
      if (data != null) {
        userData.value = data;
        _populateControllers();
        
        // Fetch total points from submissions using the cache service
        totalPoints.value = await StudentDataService.getTotalPoints(forceRefresh: forceRefresh);
      }
    } catch (e) {
      print('Error fetching profile data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _populateControllers() {
    nameController.text = userData['fullName'] ?? userData['name'] ?? '';
    emailController.text = userData['email'] ?? '';
    phoneController.text = userData['phone'] ?? '';
    aboutController.text = userData['about'] ?? '';
  }

  void startEditing() {
    isEditing.value = true;
  }

  void cancelEditing() {
    isEditing.value = false;
    _populateControllers();
  }

  Future<void> saveEditedData() async {
    try {
      isLoading.value = true;
      final user = _auth.currentUser;
      if (user == null) return;

      final data = {
        'fullName': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'about': aboutController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await StudentDataService.updateStudentProfile(data);

      userData.addAll(data);
      isEditing.value = false;

      Get.snackbar(
        'Success',
        'Profile updated successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error saving profile data: $e');
      Get.snackbar(
        'Error',
        'Failed to update profile',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfilePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image == null) return;

      isImageLoading.value = true;

      // Upload to Cloudinary using bytes for web
      final bytes = await image.readAsBytes();
      final response = await _cloudinaryService.uploadImageFromBytes(
        imageBytes: bytes,
        fileName:
            'profile_${_auth.currentUser?.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        folder: 'profile_pictures',
      );

      final imageUrl = response.secureUrl;

      // Update Firestore through service so cache is synced
      await StudentDataService.updateStudentProfile({
        'profileImage': imageUrl,
      });

      // Update local state
      userData['profileImage'] = imageUrl;
      userData.refresh();

      Get.snackbar(
        'Success',
        'Profile picture updated!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error updating profile picture: $e');
      Get.snackbar(
        'Error',
        'Failed to upload image',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isImageLoading.value = false;
    }
  }

  String getInitials() {
    final String name =
        (userData['fullName'] ?? userData['name'] ?? 'Student').toString();
    List<String> parts =
        name.trim().split(' ').where((String s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return 'S';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Future<void> handlePasswordChange({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (isPasswordSaving.value) return;

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      Get.snackbar(
        'Missing information',
        'Please fill out all password fields before continuing.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (newPassword != confirmPassword) {
      Get.snackbar(
        'Passwords do not match',
        'Make sure the new password and confirmation are the same.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (newPassword.trim().length < 8) {
      Get.snackbar(
        'Password too short',
        'Use at least 8 characters for your new password.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (newPassword.trim() == currentPassword.trim()) {
      Get.snackbar(
        'Password unchanged',
        'Choose a password that is different from your current one.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      Get.snackbar(
        'Not signed in',
        'Please re-login before updating your password.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      Get.snackbar(
        'Password not supported',
        'This account is linked to a social provider. Use the provider settings to change the password.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    isPasswordSaving.value = true;
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword.trim());

      await _firestore.collection('users').doc(user.uid).update({
        'passwordUpdatedAt': FieldValue.serverTimestamp(),
      });

      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

      Get.snackbar(
        'Password updated',
        'Your password has been changed successfully.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } on FirebaseAuthException catch (e) {
      final message = AuthErrorUtils.friendlyMessage(
        code: e.code,
        scenario: AuthErrorScenario.passwordChange,
        fallback: 'Unable to change password. Please try again.',
        rawMessage: e.message,
      );
      Get.snackbar(
        'Password update failed',
        message,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Password update failed',
        'Something went wrong while updating your password. Please try again later.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isPasswordSaving.value = false;
    }
  }

  void showPasswordResetGuide() {
    Get.dialog(
      ForgotPasswordDialog(
        onResetPassword: (email) async {
          final authController = Get.find<AuthController>();
          final result = await authController.resetPassword(email);
          if (result['success']) {
            // Show success message after dialog closes
            Future.delayed(const Duration(milliseconds: 300), () {
              Get.snackbar(
                'Success',
                'Password reset link has been sent to your email!',
                backgroundColor: Colors.green,
                colorText: Colors.white,
                duration: const Duration(seconds: 3),
              );
            });
          } else {
            throw Exception(result['message']);
          }
        },
      ),
    );
  }
}
