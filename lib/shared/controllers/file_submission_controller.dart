import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/file_upload_service.dart';
import '../config/cloudinary_config.dart';
import '../services/in_app_notification_service.dart';

class FileSubmissionController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FileUploadService _fileUploadService = FileUploadService();
  final ImagePicker _imagePicker = ImagePicker();

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
        selectedFiles.addAll(files);
        log(
          '✅ Added ${files.length} files to selection (Total: ${selectedFiles.length})',
        );

        Get.snackbar(
          'Files Added',
          'Added ${files.length} file(s). Total: ${selectedFiles.length}',
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

  // Take photo using camera
  Future<void> takePhoto() async {
    try {
      errorMessage.value = '';

      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (photo != null) {
        // Convert XFile to PlatformFile
        final bytes = await photo.readAsBytes();
        final platformFile = PlatformFile(
          name: photo.name,
          size: bytes.length,
          bytes: bytes,
          path: photo.path,
        );

        selectedFiles.add(platformFile);
        log('✅ Photo captured and added to selection');

        Get.snackbar(
          'Photo Captured',
          'Photo added successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      log('❌ Error taking photo: $e');
      errorMessage.value = 'Failed to take photo: $e';
      Get.snackbar(
        'Error',
        'Failed to take photo: $e',
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
            folder: folder ?? '${CloudinaryConfig.defaultFolder}/submissions',
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

  // Submit assignment with uploaded files using student's enrolled section
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

      // Get user data for student information and enrolled section
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      // Get student's enrolled section from their profile
      final studentSectionName =
          userData['selectedSectionCode']?.toString() ?? 'Unknown Section';

      log('📚 Student enrolled section: $studentSectionName');

      // Get assignment data to find instructor info
      final assignmentDoc =
          await _firestore
              .collection('instructors')
              .doc(instructorId)
              .collection('assignments')
              .doc(assignmentId)
              .get();

      if (!assignmentDoc.exists) {
        throw Exception('Assignment not found');
      }

      final assignmentData = assignmentDoc.data() ?? {};

      // Extract assignedSemester if it exists
      final assignedSemester =
          assignmentData['assignedSemester'] as Map<String, dynamic>?;

      // Create submission data with student's actual enrolled section
      final submissionData = {
        'activityType': 'assignment', // Unified activity type
        'activityId': assignmentId, // Unified activity ID field
        'studentId': user.uid,
        'studentName':
            userData['fullName'] ?? user.displayName ?? 'Unknown Student',
        'studentEmail': user.email ?? '',
        'studentIdNumber': userData['idNumber'] ?? '',
        'instructorId': instructorId,
        'instructorName': instructorName,
        'activityTitle': assignmentData['title'] ?? 'Unknown Assignment',
        'sectionName': studentSectionName, // Use student's enrolled section
        'files': uploadedFiles.toList(),
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'submitted',
        'grade': null,
        'feedback': null,
        'gradedAt': null,
        'gradedBy': null,
        // Add assigned semester if available
        if (assignedSemester != null) 'assignedSemester': assignedSemester,
      };

      // Save to unified submissions collection
      final docRef = await _firestore
          .collection('submissions')
          .add(submissionData);

      log('✅ Assignment submission saved successfully');
      log('📄 Submission ID: ${docRef.id}');
      log('📍 Section: $studentSectionName');

      // Create notification for instructor
      try {
        await InAppNotificationService.createInstructorNotification(
          type: 'submission',
          targetInstructorId: instructorId,
          studentId: user.uid,
          studentName:
              userData['fullName'] ?? user.displayName ?? 'Unknown Student',
          activityId: assignmentId,
          activityTitle: assignmentData['title'] ?? 'Unknown Assignment',
          activityType: 'assignment',
          submissionId: docRef.id,
          sectionName: studentSectionName,
        );
      } catch (e) {
        log('⚠️ Error creating notification: $e');
      }

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

  // Submit activity with uploaded files using student's enrolled section
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

      // Get user data for student information and enrolled section
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      // Get student's enrolled section from their profile
      final studentSectionName =
          userData['selectedSectionCode']?.toString() ?? 'Unknown Section';

      log('📚 Student enrolled section: $studentSectionName');

      // Get activity data to find instructor info
      final activityDoc =
          await _firestore
              .collection('instructors')
              .doc(instructorId)
              .collection('activities')
              .doc(activityId)
              .get();

      if (!activityDoc.exists) {
        throw Exception('Activity not found');
      }

      final activityData = activityDoc.data() ?? {};

      // Extract assignedSemester if it exists
      final assignedSemester =
          activityData['assignedSemester'] as Map<String, dynamic>?;

      // Create submission data with student's actual enrolled section
      final submissionData = {
        'activityType': 'activity', // Unified activity type
        'activityId': activityId, // Unified activity ID field
        'studentId': user.uid,
        'studentName':
            userData['fullName'] ?? user.displayName ?? 'Unknown Student',
        'studentEmail': user.email ?? '',
        'studentIdNumber': userData['idNumber'] ?? '',
        'instructorId': instructorId,
        'instructorName': instructorName,
        'activityTitle': activityData['title'] ?? 'Unknown Activity',
        'sectionName': studentSectionName, // Use student's enrolled section
        'files': uploadedFiles.toList(),
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'submitted',
        'grade': null,
        'feedback': null,
        'gradedAt': null,
        'gradedBy': null,
        // Add assigned semester if available
        if (assignedSemester != null) 'assignedSemester': assignedSemester,
      };

      // Save to unified submissions collection
      final docRef = await _firestore
          .collection('submissions')
          .add(submissionData);

      log('✅ Activity submission saved successfully');
      log('📄 Submission ID: ${docRef.id}');
      log('📍 Section: $studentSectionName');

      // Create notification for instructor
      try {
        await InAppNotificationService.createInstructorNotification(
          type: 'submission',
          targetInstructorId: instructorId,
          studentId: user.uid,
          studentName:
              userData['fullName'] ?? user.displayName ?? 'Unknown Student',
          activityId: activityId,
          activityTitle: activityData['title'] ?? 'Unknown Activity',
          activityType: 'activity',
          submissionId: docRef.id,
          sectionName: studentSectionName,
        );
      } catch (e) {
        log('⚠️ Error creating notification: $e');
      }

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
              .collection('submissions')
              .where('activityType', isEqualTo: 'assignment')
              .where('activityId', isEqualTo: assignmentId)
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
              .collection('submissions')
              .where('activityType', isEqualTo: 'activity')
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

  // Submit quiz with uploaded files using student's enrolled section
  Future<bool> submitQuiz({
    required String quizId,
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

      // Get user data for student information and enrolled section
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      // Get student's enrolled section from their profile
      final studentSectionName =
          userData['selectedSectionCode']?.toString() ?? 'Unknown Section';

      log('📚 Student enrolled section: $studentSectionName');

      // Get quiz data to find instructor info
      final quizDoc =
          await _firestore
              .collection('instructors')
              .doc(instructorId)
              .collection('quizzes')
              .doc(quizId)
              .get();

      if (!quizDoc.exists) {
        throw Exception('Quiz not found');
      }

      final quizData = quizDoc.data() ?? {};

      // Extract assignedSemester if it exists
      final assignedSemester =
          quizData['assignedSemester'] as Map<String, dynamic>?;

      // Create submission data with student's actual enrolled section
      final submissionData = {
        'activityType': 'quiz', // Unified activity type
        'activityId': quizId, // Unified activity ID field
        'studentId': user.uid,
        'studentName':
            userData['fullName'] ?? user.displayName ?? 'Unknown Student',
        'studentEmail': user.email ?? '',
        'studentIdNumber': userData['idNumber'] ?? '',
        'instructorId': instructorId,
        'instructorName': instructorName,
        'activityTitle': quizData['title'] ?? 'Unknown Quiz',
        'sectionName': studentSectionName, // Use student's enrolled section
        'files': uploadedFiles.toList(),
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'submitted',
        'grade': null,
        'feedback': null,
        'gradedAt': null,
        'gradedBy': null,
        // Add assigned semester if available
        if (assignedSemester != null) 'assignedSemester': assignedSemester,
      };

      // Save to unified submissions collection
      final docRef = await _firestore
          .collection('submissions')
          .add(submissionData);

      log('✅ Quiz submission saved successfully');
      log('📄 Submission ID: ${docRef.id}');
      log('📍 Section: $studentSectionName');

      Get.snackbar(
        'Success',
        'Quiz submitted successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Clear the files after successful submission
      clearFiles();
      return true;
    } catch (e) {
      log('❌ Error submitting quiz: $e');
      errorMessage.value = 'Failed to submit quiz: $e';
      Get.snackbar(
        'Error',
        'Failed to submit quiz: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // Check if user has already submitted for a quiz
  Future<Map<String, dynamic>?> getQuizSubmission(String quizId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final query =
          await _firestore
              .collection('submissions')
              .where('activityType', isEqualTo: 'quiz')
              .where('activityId', isEqualTo: quizId)
              .where('studentId', isEqualTo: user.uid)
              .limit(1)
              .get();

      if (query.docs.isNotEmpty) {
        return {'id': query.docs.first.id, ...query.docs.first.data()};
      }

      return null;
    } catch (e) {
      log('❌ Error getting quiz submission: $e');
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

      // Get section information with fallback values
      final sectionId =
          userData['selectedSectionId'] ?? userData['sectionId'] ?? '';
      final sectionName =
          userData['selectedSectionCode'] ?? userData['sectionName'] ?? '';
      final instructorId =
          userData['selectedInstructorId'] ?? userData['instructorId'] ?? '';
      final instructorName =
          userData['selectedInstructorName'] ??
          userData['instructorName'] ??
          '';

      log(
        '✅ User section info: sectionId=$sectionId, sectionName=$sectionName, instructorId=$instructorId, instructorName=$instructorName',
      );

      return {
        'sectionId': sectionId,
        'sectionName': sectionName,
        'instructorId': instructorId,
        'instructorName': instructorName,
      };
    } catch (e) {
      log('❌ Error getting user section: $e');
      return null;
    }
  }

  // Submit PIT using student's enrolled section
  Future<bool> submitPit({
    required String pitId,
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

      // Get user data for student information and enrolled section
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      // Get student's enrolled section from their profile
      final studentSectionName =
          userData['selectedSectionCode']?.toString() ?? 'Unknown Section';

      log('📚 Student enrolled section: $studentSectionName');

      // Get PIT data to find instructor info
      final pitDoc =
          await _firestore
              .collection('instructors')
              .doc(instructorId)
              .collection('pits')
              .doc(pitId)
              .get();

      if (!pitDoc.exists) {
        throw Exception('PIT not found');
      }

      final pitData = pitDoc.data() ?? {};

      // Extract assignedSemester if it exists
      final assignedSemester =
          pitData['assignedSemester'] as Map<String, dynamic>?;

      // Create submission data with student's actual enrolled section
      final submissionData = {
        'activityType': 'pit', // Unified activity type
        'activityId': pitId, // Unified activity ID field
        'studentId': user.uid,
        'studentName':
            userData['fullName'] ?? user.displayName ?? 'Unknown Student',
        'studentEmail': user.email ?? '',
        'studentIdNumber': userData['idNumber'] ?? '',
        'instructorId': instructorId,
        'instructorName': instructorName,
        'activityTitle': pitData['title'] ?? 'Unknown PIT',
        'sectionName': studentSectionName, // Use student's enrolled section
        'files': uploadedFiles.toList(),
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'submitted',
        'grade': null,
        'feedback': null,
        'gradedAt': null,
        'gradedBy': null,
        // Add assigned semester if available
        if (assignedSemester != null) 'assignedSemester': assignedSemester,
      };

      // Save to unified submissions collection
      final docRef = await _firestore
          .collection('submissions')
          .add(submissionData);

      log('✅ PIT submission saved successfully');
      log('📄 Submission ID: ${docRef.id}');
      log('📍 Section: $studentSectionName');

      Get.snackbar(
        'Submission Successful',
        'Your PIT has been submitted successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Clear the files after successful submission
      clearFiles();

      return true;
    } catch (e) {
      errorMessage.value = 'Failed to submit PIT: $e';
      log('❌ Error submitting PIT: $e');

      Get.snackbar(
        'Submission Failed',
        'Failed to submit PIT: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      return false;
    } finally {
      isSubmitting.value = false;
    }
  }
}
