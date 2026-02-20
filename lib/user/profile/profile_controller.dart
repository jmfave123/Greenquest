import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../shared/services/file_upload_service.dart';
import '../../shared/utils/auth_error_utils.dart';

class ProfileController extends GetxController {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _imagePicker = ImagePicker();
  final _fileUploadService = FileUploadService();

  RxBool isLoading = false.obs;
  RxBool isUploadingImage = false.obs;
  RxBool isChangingPassword = false.obs;
  RxMap userData = {}.obs;

  @override
  void onInit() {
    super.onInit();
    // Use addPostFrameCallback to ensure operations run after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  /// Initialize data without blocking the UI
  Future<void> _initializeData() async {
    try {
      await getUser();
    } catch (e) {
      print('Error initializing ProfileController: $e');
    }
  }

  Future<void> getUser() async {
    isLoading.value = true;
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>;
      this.userData.value = userData;
      log(userData.toString());
    }
    isLoading.value = false;
  }

  /// Show image source selection dialog
  Future<void> showImageSourceDialog() async {
    final hasImage =
        userData['profileImage'] != null && userData['profileImage'].isNotEmpty;

    Get.dialog(
      AlertDialog(
        title: const Text('Profile Image Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Get.back();
                uploadProfileImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Get.back();
                uploadProfileImageFromGallery();
              },
            ),
            if (hasImage) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Remove Current Image',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Get.back();
                  _showRemoveConfirmationDialog();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Show confirmation dialog for removing profile image
  Future<void> _showRemoveConfirmationDialog() async {
    Get.dialog(
      AlertDialog(
        title: const Text('Remove Profile Image'),
        content: const Text(
          'Are you sure you want to remove your profile image? You can always add a new one later.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              removeProfileImage();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  /// Upload profile image from camera
  Future<void> uploadProfileImageFromCamera() async {
    try {
      isUploadingImage.value = true;

      // Pick image from camera
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        await _uploadImageFile(File(pickedFile.path));
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to take photo: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isUploadingImage.value = false;
    }
  }

  /// Upload profile image from gallery
  Future<void> uploadProfileImageFromGallery() async {
    try {
      isUploadingImage.value = true;

      // Pick image from gallery
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        await _uploadImageFile(File(pickedFile.path));
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isUploadingImage.value = false;
    }
  }

  /// Upload image file to Cloudinary
  Future<void> _uploadImageFile(File imageFile) async {
    try {
      // Initialize file upload service
      _fileUploadService.initialize();

      // Convert File to bytes for upload
      final bytes = await imageFile.readAsBytes();

      // Create a temporary file info for the upload service
      final tempFile = PlatformFile(
        name: 'profile_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        size: bytes.length,
        bytes: bytes,
      );

      // Upload to Cloudinary
      final response = await _fileUploadService.uploadFile(
        file: tempFile,
        folder: 'user-profiles',
        tags: {'type': 'profile-image', 'user': _auth.currentUser?.uid ?? ''},
      );

      if (response != null) {
        // Update Firestore with new image URL
        final user = _auth.currentUser;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'profileImage': response.secureUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Update local value
          userData['profileImage'] = response.secureUrl;

          Get.snackbar(
            'Success',
            'Profile image updated successfully',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to upload image: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Upload profile image (convenience method)
  Future<void> uploadProfileImage() async {
    await showImageSourceDialog();
  }

  /// Remove profile image
  Future<void> removeProfileImage() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Remove profileImage field from Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'profileImage': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update local value
        userData.remove('profileImage');

        Get.snackbar(
          'Success',
          'Profile image removed successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to remove profile image: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Generate initials from full name
  String getInitials() {
    final fullName = userData['fullName'] ?? '';
    if (fullName.isEmpty) return 'U'; // Default to 'U' for User

    final names = fullName.trim().split(' ');
    if (names.length >= 2) {
      // Get first letter of first name and first letter of last name
      return '${names[0][0].toUpperCase()}${names[names.length - 1][0].toUpperCase()}';
    } else if (names.length == 1) {
      // If only one name, use first two letters
      return names[0].length >= 2
          ? names[0].substring(0, 2).toUpperCase()
          : names[0][0].toUpperCase();
    }
    return 'U';
  }

  /// Update phone number
  Future<void> updatePhoneNumber(String phoneNumber) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        Get.snackbar(
          'Error',
          'User not authenticated',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Validate phone number
      if (phoneNumber.length != 11) {
        Get.snackbar(
          'Validation Error',
          'Phone number must be exactly 11 digits',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      if (!phoneNumber.startsWith('09')) {
        Get.snackbar(
          'Validation Error',
          'Phone number must start with 09',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      if (!RegExp(r'^[0-9]+$').hasMatch(phoneNumber)) {
        Get.snackbar(
          'Validation Error',
          'Phone number must contain only numbers',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Update Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'phoneNumber': phoneNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local value
      userData['phoneNumber'] = phoneNumber;

      Get.snackbar(
        'Success',
        'Phone number updated successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update phone number: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (isChangingPassword.value) return false;

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      Get.snackbar(
        'Missing information',
        'Please fill out all password fields before continuing.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    if (newPassword != confirmPassword) {
      Get.snackbar(
        'Passwords do not match',
        'Make sure the new password and confirmation match.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    if (newPassword.trim().length < 8) {
      Get.snackbar(
        'Password too short',
        'Use at least 8 characters for your new password.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    if (currentPassword.trim() == newPassword.trim()) {
      Get.snackbar(
        'Password unchanged',
        'Choose a password that is different from your current one.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    final user = _auth.currentUser;
    if (user == null) {
      Get.snackbar(
        'Not signed in',
        'Please re-login before updating your password.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      Get.snackbar(
        'Unsupported',
        'This account is linked to a social provider. Change the password from the provider settings.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    isChangingPassword.value = true;
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

      Get.snackbar(
        'Password updated',
        'Your password has been changed successfully.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return true;
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
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } catch (e) {
      Get.snackbar(
        'Password update failed',
        'Something went wrong while updating your password. Please try again later.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isChangingPassword.value = false;
    }
  }
}
