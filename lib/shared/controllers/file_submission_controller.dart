import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/file_upload_service.dart';

class FileSubmissionController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FileUploadService _fileUploadService = FileUploadService();

  // Observable variables
  final RxBool isUploading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxDouble uploadProgress = 0.0.obs;
  final RxString uploadStatus = ''.obs;
  final RxList<PlatformFile> selectedFiles = <PlatformFile>[].obs;
  final RxList<Map<String, dynamic>> uploadedFiles =
      <Map<String, dynamic>>[].obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _fileUploadService.initialize();
  }

  // Pick files for submission
  Future<void> pickFiles() async {
    try {
      errorMessage.value = '';

      List<PlatformFile>? files = await _fileUploadService.pickFiles(
        allowMultiple: true,
      );

      if (files != null && files.isNotEmpty) {
        selectedFiles.assignAll(files);
        log('✅ Selected ${files.length} files for submission');

        Get.snackbar(
          'Files Selected',
          'Selected ${files.length} file(s) for submission',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      log('❌ Error picking files: $e');
      errorMessage.value = 'Failed to pick files: $e';
      Get.snackbar(
        'Error',
        'Failed to pick files: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Remove a selected file
  void removeFile(int index) {
    if (index >= 0 && index < selectedFiles.length) {
      selectedFiles.removeAt(index);
    }
  }

  // Clear all selected files
  void clearFiles() {
    selectedFiles.clear();
    uploadedFiles.clear();
    uploadProgress.value = 0.0;
    uploadStatus.value = '';
    errorMessage.value = '';
  }

  // Upload files to Cloudinary
  Future<bool> uploadFiles({String? folder, Map<String, String>? tags}) async {
    if (selectedFiles.isEmpty) {
      errorMessage.value = 'No files selected';
      return false;
    }

    try {
      isUploading.value = true;
      uploadProgress.value = 0.0;
      uploadStatus.value = 'Preparing upload...';
      uploadedFiles.clear();

      List<Map<String, dynamic>> uploaded = await _fileUploadService
          .uploadMultipleFiles(
            files: selectedFiles.toList(),
            folder: folder,
            tags: tags,
            onProgress: (current, total) {
              uploadProgress.value = current / total;
              uploadStatus.value = 'Uploading file ${current + 1} of $total...';
            },
          );

      uploadedFiles.assignAll(uploaded);
      uploadProgress.value = 1.0;
      uploadStatus.value = 'Upload completed successfully!';

      log('✅ Successfully uploaded ${uploaded.length} files');
      return true;
    } catch (e) {
      log('❌ Error uploading files: $e');
      errorMessage.value = 'Failed to upload files: $e';
      uploadStatus.value = 'Upload failed';
      return false;
    } finally {
      isUploading.value = false;
    }
  }

  // Submit assignment with uploaded files
  Future<bool> submitAssignment({
    required String assignmentId,
    required String instructorId,
    required String instructorName,
    required String sectionId,
    String? sectionName,
  }) async {
    if (uploadedFiles.isEmpty) {
      errorMessage.value = 'No files uploaded';
      return false;
    }

    try {
      isSubmitting.value = true;
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get user data for student information
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      // Create submission data
      final submissionData = {
        'assignmentId': assignmentId,
        'studentId': user.uid,
        'studentName':
            userData['fullName'] ?? user.displayName ?? 'Unknown Student',
        'studentEmail': user.email ?? '',
        'studentIdNumber': userData['idNumber'] ?? '',
        'instructorId': instructorId,
        'instructorName': instructorName,
        'sectionId': sectionId,
        'sectionName': sectionName ?? '',
        'files': uploadedFiles.toList(),
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'submitted',
        'grade': null,
        'feedback': null,
        'gradedAt': null,
        'gradedBy': null,
      };

      // Save submission to Firestore
      await _firestore.collection('assignment_submissions').add(submissionData);

      log('✅ Assignment submission completed successfully');

      Get.snackbar(
        'Success',
        'Assignment submitted successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Clear the files after successful submission
      clearFiles();
      return true;
    } catch (e) {
      log('❌ Error submitting assignment: $e');
      errorMessage.value = 'Failed to submit assignment: $e';
      Get.snackbar(
        'Error',
        'Failed to submit assignment: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // Submit activity with uploaded files
  Future<bool> submitActivity({
    required String activityId,
    required String instructorId,
    required String instructorName,
    required String sectionId,
    String? sectionName,
  }) async {
    if (uploadedFiles.isEmpty) {
      errorMessage.value = 'No files uploaded';
      return false;
    }

    try {
      isSubmitting.value = true;
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get user data for student information
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      // Create submission data
      final submissionData = {
        'activityId': activityId,
        'studentId': user.uid,
        'studentName':
            userData['fullName'] ?? user.displayName ?? 'Unknown Student',
        'studentEmail': user.email ?? '',
        'studentIdNumber': userData['idNumber'] ?? '',
        'instructorId': instructorId,
        'instructorName': instructorName,
        'sectionId': sectionId,
        'sectionName': sectionName ?? '',
        'files': uploadedFiles.toList(),
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'submitted',
        'grade': null,
        'feedback': null,
        'gradedAt': null,
        'gradedBy': null,
      };

      // Save submission to Firestore
      await _firestore.collection('activity_submissions').add(submissionData);

      log('✅ Activity submission completed successfully');

      Get.snackbar(
        'Success',
        'Activity submitted successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Clear the files after successful submission
      clearFiles();
      return true;
    } catch (e) {
      log('❌ Error submitting activity: $e');
      errorMessage.value = 'Failed to submit activity: $e';
      Get.snackbar(
        'Error',
        'Failed to submit activity: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // Check if user has already submitted for an assignment
  Future<Map<String, dynamic>?> getAssignmentSubmission(
    String assignmentId,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final query =
          await _firestore
              .collection('assignment_submissions')
              .where('assignmentId', isEqualTo: assignmentId)
              .where('studentId', isEqualTo: user.uid)
              .limit(1)
              .get();

      if (query.docs.isNotEmpty) {
        return {'id': query.docs.first.id, ...query.docs.first.data()};
      }

      return null;
    } catch (e) {
      log('❌ Error getting assignment submission: $e');
      return null;
    }
  }

  // Check if user has already submitted for an activity
  Future<Map<String, dynamic>?> getActivitySubmission(String activityId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final query =
          await _firestore
              .collection('activity_submissions')
              .where('activityId', isEqualTo: activityId)
              .where('studentId', isEqualTo: user.uid)
              .limit(1)
              .get();

      if (query.docs.isNotEmpty) {
        return {'id': query.docs.first.id, ...query.docs.first.data()};
      }

      return null;
    } catch (e) {
      log('❌ Error getting activity submission: $e');
      return null;
    }
  }

  // Get current user's section information
  Future<Map<String, dynamic>?> getCurrentUserSection() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data()!;
      return {
        'sectionId': userData['selectedSectionId'] ?? '',
        'sectionName': userData['selectedSectionCode'] ?? '',
        'instructorId': userData['selectedInstructorId'] ?? '',
        'instructorName': userData['selectedInstructorName'] ?? '',
      };
    } catch (e) {
      log('❌ Error getting user section: $e');
      return null;
    }
  }
}
