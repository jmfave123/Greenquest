import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import '../../shared/services/file_upload_service.dart';

class InstructorController extends GetxController {
  var name = ''.obs;
  var email = ''.obs;
  final RxString phone = ''.obs;
  var about = ''.obs;
  var profileImageUrl = ''.obs;
  var isLoading = true.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;
  var isEditing = false.obs;
  var isUploadingImage = false.obs;

  // Form controllers for editing
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final aboutController = TextEditingController();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _fileUploadService = FileUploadService();

  @override
  void onInit() {
    super.onInit();
    // Delay the data loading to avoid initialization issues
    Future.delayed(const Duration(milliseconds: 100), () {
      loadInstructorData();
    });
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    aboutController.dispose();
    super.onClose();
  }

  /// Load instructor data
  Future<void> loadInstructorData() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      // Add a small delay to ensure Firebase is initialized
      await Future.delayed(const Duration(milliseconds: 200));

      final user = _auth.currentUser;
      if (user == null) {
        hasError.value = true;
        errorMessage.value = 'No authenticated user found';
        isLoading.value = false;
        return;
      }

      final doc =
          await _firestore.collection('instructors').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        name.value = data['name'] ?? '';
        email.value = data['email'] ?? '';
        phone.value = data['phone'] ?? '';
        about.value = data['about'] ?? '';
        // Try profileUrl first, then fall back to profileImageUrl for backward compatibility
        profileImageUrl.value =
            data['profileUrl'] ?? data['profileImageUrl'] ?? '';

        // Update form controllers
        _updateFormControllers();
      } else {
        hasError.value = true;
        errorMessage.value = 'Instructor profile not found';
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Error loading instructor data: $e';
      print("Error loading instructor data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Update instructor profile
  Future<void> updateInstructorData({
    required String newName,
    required String newEmail,
    required String newPhone,
  }) async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final user = _auth.currentUser;
      if (user == null) {
        hasError.value = true;
        errorMessage.value = 'No authenticated user found';
        isLoading.value = false;
        return;
      }

      await _firestore.collection('instructors').doc(user.uid).update({
        'name': newName,
        'email': newEmail,
        'phone': newPhone,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // update local values
      name.value = newName;
      email.value = newEmail;
      phone.value = newPhone;

      Get.snackbar(
        'Success',
        'Profile updated successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Error updating instructor data: $e';
      print("Error updating instructor data: $e");

      Get.snackbar(
        'Error',
        'Failed to update profile: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh instructor data
  Future<void> refreshData() async {
    await loadInstructorData();
  }

  /// Update form controllers with current data
  void _updateFormControllers() {
    nameController.text = name.value;
    emailController.text = email.value;
    phoneController.text = phone.value;
    aboutController.text = about.value;
  }

  /// Start editing mode
  void startEditing() {
    isEditing.value = true;
    _updateFormControllers();
  }

  /// Cancel editing mode
  void cancelEditing() {
    isEditing.value = false;
    _updateFormControllers(); // Reset to original values
  }

  /// Show profile image options dialog
  Future<void> showProfileImageOptions() async {
    final hasImage = profileImageUrl.value.isNotEmpty;

    if (hasImage) {
      // Show options: Change or Remove
      Get.dialog(
        AlertDialog(
          title: const Text('Profile Picture'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Change Picture'),
                onTap: () {
                  Get.back();
                  uploadProfileImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Picture'),
                onTap: () {
                  Get.back();
                  _showRemoveConfirmationDialog();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } else {
      // No image, directly upload
      await uploadProfileImage();
    }
  }

  /// Show confirmation dialog before removing profile image
  Future<void> _showRemoveConfirmationDialog() async {
    Get.dialog(
      AlertDialog(
        title: const Text('Remove Profile Picture'),
        content: const Text(
          'Are you sure you want to remove your profile picture? Your initials will be displayed instead.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Get.back();
              removeProfileImage();
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  /// Remove profile image
  Future<void> removeProfileImage() async {
    try {
      isUploadingImage.value = true;

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Update Firestore to remove profile image URL
      await _firestore.collection('instructors').doc(user.uid).update({
        'profileUrl': FieldValue.delete(),
        'profileImageUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local value
      profileImageUrl.value = '';

      Get.snackbar(
        'Success',
        'Profile picture removed successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to remove profile picture: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isUploadingImage.value = false;
    }
  }

  /// Upload profile image (legacy method for backward compatibility)
  Future<void> uploadProfileImage() async {
    try {
      isUploadingImage.value = true;

      // Use file_picker for web compatibility
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // Important for web
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Ensure we have bytes (important for web)
        if (file.bytes == null) {
          throw Exception('Failed to read file data');
        }

        await _uploadImageFromBytes(file);
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

  /// Upload image from bytes (for web compatibility)
  Future<void> _uploadImageFromBytes(PlatformFile file) async {
    try {
      // Initialize file upload service
      _fileUploadService.initialize();

      // Upload to Cloudinary
      final response = await _fileUploadService.uploadFile(
        file: file,
        folder: 'greenquest/instructors/profiles',
        tags: {
          'type': 'profile-image',
          'instructor': _auth.currentUser?.uid ?? '',
        },
      );

      if (response != null) {
        // Update Firestore with new image URL
        final user = _auth.currentUser;
        if (user != null) {
          await _firestore.collection('instructors').doc(user.uid).update({
            'profileUrl': response.secureUrl,
            'profileImageUrl':
                response.secureUrl, // Keep both for compatibility
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Update local value
          profileImageUrl.value = response.secureUrl;

          Get.snackbar(
            'Success',
            'Profile image updated successfully',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
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
      rethrow;
    }
  }

  /// Save edited data
  Future<void> saveEditedData() async {
    try {
      // Validate form
      if (nameController.text.trim().isEmpty) {
        Get.snackbar(
          'Validation Error',
          'Name cannot be empty',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return; // Keep dialog open
      }

      // Email is read-only, no validation needed

      if (phoneController.text.trim().isEmpty) {
        Get.snackbar(
          'Validation Error',
          'Phone cannot be empty',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return; // Keep dialog open
      }

      // Phone number validation for Philippine mobile numbers
      final phoneValue = phoneController.text.trim();
      if (phoneValue.length != 11) {
        Get.snackbar(
          'Validation Error',
          'Phone number must be exactly 11 digits',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return; // Keep dialog open
      }

      if (!phoneValue.startsWith('09')) {
        Get.snackbar(
          'Validation Error',
          'Phone number must start with 09',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return; // Keep dialog open
      }

      if (!RegExp(r'^[0-9]+$').hasMatch(phoneValue)) {
        Get.snackbar(
          'Validation Error',
          'Phone number must contain only numbers',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return; // Keep dialog open
      }

      // Email is read-only, no validation needed

      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final user = _auth.currentUser;
      if (user == null) {
        hasError.value = true;
        errorMessage.value = 'No authenticated user found';
        isLoading.value = false;
        return; // Keep dialog open
      }

      try {
        // Update Firestore
        final updateData = {
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'phone': phoneController.text.trim(),
          'about': aboutController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await _firestore
            .collection('instructors')
            .doc(user.uid)
            .update(updateData);

        // Update local values
        name.value = nameController.text.trim();
        email.value = emailController.text.trim();
        phone.value = phoneController.text.trim();
        about.value = aboutController.text.trim();

        isEditing.value = false;

        Get.snackbar(
          'Success',
          'Profile updated successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } catch (e) {
        // If update fails, keep dialog open
        Get.snackbar(
          'Error',
          'Failed to update profile: $e',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return; // Keep dialog open
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Error updating instructor data: $e';
      print("Error updating instructor data: $e");

      Get.snackbar(
        'Error',
        'Failed to update profile: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
