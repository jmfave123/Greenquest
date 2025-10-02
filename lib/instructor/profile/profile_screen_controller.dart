import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InstructorController extends GetxController {
  var name = ''.obs;
  var email = ''.obs;
  var phone = ''.obs;
  var createdAt = ''.obs;
  var isLoading = true.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;
  var isEditing = false.obs;

  // Form controllers for editing
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final createdAtController = TextEditingController();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

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
    createdAtController.dispose();
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

        // Format the createdAt date
        if (data['createdAt'] != null) {
          if (data['createdAt'] is Timestamp) {
            final timestamp = data['createdAt'] as Timestamp;
            final date = timestamp.toDate();
            createdAt.value = _formatDate(date);
          } else {
            createdAt.value = data['createdAt'].toString();
          }
        } else {
          createdAt.value = 'Not available';
        }

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

  /// Format date to readable string
  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return 'Joined ${months[date.month - 1]} ${date.year}';
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
    createdAtController.text = createdAt.value;
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
        return;
      }

      if (emailController.text.trim().isEmpty) {
        Get.snackbar(
          'Validation Error',
          'Email cannot be empty',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      if (phoneController.text.trim().isEmpty) {
        Get.snackbar(
          'Validation Error',
          'Phone cannot be empty',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Email validation
      if (!GetUtils.isEmail(emailController.text.trim())) {
        Get.snackbar(
          'Validation Error',
          'Please enter a valid email address',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

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

      // Parse the created date if it's being edited
      DateTime? newCreatedAt;
      if (createdAtController.text.trim().isNotEmpty) {
        try {
          // Try to parse the date from the format "Joined Month Year"
          final dateText = createdAtController.text.trim();
          if (dateText.startsWith('Joined ')) {
            final monthYear = dateText.substring(7); // Remove "Joined "
            final parts = monthYear.split(' ');
            if (parts.length == 2) {
              final monthName = parts[0];
              final year = int.tryParse(parts[1]);

              if (year != null) {
                const months = [
                  'January',
                  'February',
                  'March',
                  'April',
                  'May',
                  'June',
                  'July',
                  'August',
                  'September',
                  'October',
                  'November',
                  'December',
                ];
                final monthIndex = months.indexOf(monthName);
                if (monthIndex != -1) {
                  newCreatedAt = DateTime(year, monthIndex + 1, 1);
                }
              }
            }
          }
        } catch (e) {
          print('Error parsing date: $e');
        }
      }

      // Update Firestore
      final updateData = {
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newCreatedAt != null) {
        updateData['createdAt'] = Timestamp.fromDate(newCreatedAt);
      }

      await _firestore
          .collection('instructors')
          .doc(user.uid)
          .update(updateData);

      // Update local values
      name.value = nameController.text.trim();
      email.value = emailController.text.trim();
      phone.value = phoneController.text.trim();

      if (newCreatedAt != null) {
        createdAt.value = _formatDate(newCreatedAt);
      }

      isEditing.value = false;

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
}
