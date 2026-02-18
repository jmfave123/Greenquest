import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/services/cloudinary_service.dart';
import '../../../shared/config/cloudinary_config.dart';

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

  final RxBool isEditing = false.obs;

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
    super.onClose();
  }

  Future<void> fetchProfileData() async {
    try {
      isLoading.value = true;
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        userData.value = doc.data()!;
        _populateControllers();
        // Fetch total points from submissions
        await _calculateTotalPoints();
      }
    } catch (e) {
      print('Error fetching profile data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Calculate total points for the logged-in student from all submissions
  Future<void> _calculateTotalPoints() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get the student's instructor ID
      final instructorId = userData['selectedInstructorId'] as String?;
      if (instructorId == null || instructorId.isEmpty) {
        totalPoints.value = 0;
        return;
      }

      int points = 0;

      // Get all submissions for this student from the unified collection
      final allSubmissions =
          await _firestore
              .collection('submissions')
              .where('studentId', isEqualTo: user.uid)
              .where('instructorId', isEqualTo: instructorId)
              .get();

      // Sum up all grades
      for (var doc in allSubmissions.docs) {
        final data = doc.data();
        final grade = data['grade'];
        if (grade != null && grade is num) {
          points += grade.toInt();
        }
      }

      totalPoints.value = points;
    } catch (e) {
      print('Error calculating total points: $e');
      totalPoints.value = 0;
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

      await _firestore.collection('users').doc(user.uid).update(data);

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

      // Update Firestore
      await _firestore.collection('users').doc(_auth.currentUser?.uid).update({
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
}
