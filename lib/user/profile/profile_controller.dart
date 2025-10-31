import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../shared/services/file_upload_service.dart';

class ProfileController extends GetxController {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _imagePicker = ImagePicker();
  final _fileUploadService = FileUploadService();

  RxBool isLoading = false.obs;
  RxBool isUploadingImage = false.obs;
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
}
