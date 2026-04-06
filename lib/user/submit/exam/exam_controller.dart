import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../../shared/services/student_data_service.dart';

class ExamController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxBool isLoading = true.obs;
  final RxList<Map<String, dynamic>> exams = <Map<String, dynamic>>[].obs;
  final RxString errorMessage = ''.obs;
  final RxString currentInstructorUid = ''.obs;
  final RxString currentInstructorName = ''.obs;
  final RxMap<String, dynamic> selectedExam = <String, dynamic>{}.obs;
  final RxMap<String, String> submissionStatus = <String, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCurrentInstructor();
  }

  Future<String?> _getUserSectionCode() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userData = await StudentDataService.getStudentData();
      if (userData == null) return null;

      return userData['selectedSectionCode']?.toString();
    } catch (e) {
      log('Error getting user section code for exams: $e');
      return null;
    }
  }

  Future<void> _loadCurrentInstructor() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        errorMessage.value = 'User not authenticated';
        return;
      }

      final userData = await StudentDataService.getStudentData();
      if (userData == null) {
        errorMessage.value = 'User profile not found';
        return;
      }

      final instructorId = userData['selectedInstructorId']?.toString() ?? '';
      final instructorName =
          userData['selectedInstructorName']?.toString() ?? 'Instructor';
      final selectionComplete = userData['selectionComplete'] ?? false;

      if (!selectionComplete || instructorId.isEmpty) {
        errorMessage.value = 'Please select an instructor first';
        exams.clear();
        isLoading.value = false;
        return;
      }

      currentInstructorUid.value = instructorId;
      currentInstructorName.value = instructorName;
      await loadExams();
    } catch (e) {
      errorMessage.value = 'Failed to load exams: $e';
      isLoading.value = false;
    }
  }

  Future<void> loadExams() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      if (currentInstructorUid.value.isEmpty) {
        exams.clear();
        return;
      }

      final userSectionCode = await _getUserSectionCode();

      final query =
          await _firestore
              .collection('instructors')
              .doc(currentInstructorUid.value)
              .collection('quizzes')
              .orderBy('createdAt', descending: true)
              .get();

      final loadedExams = <Map<String, dynamic>>[];

      for (final doc in query.docs) {
        final data = doc.data();
        if (data.isEmpty) continue;

        final type = (data['type'] ?? '').toString();
        final category = (data['category'] ?? '').toString();
        final isExamItem =
            type.toLowerCase() == 'exam' ||
            category == 'midterm_exam' ||
            category == 'final_exam';

        if (!isExamItem) continue;

        final selectedClasses = List<String>.from(
          data['selectedClasses'] ?? [],
        );

        if (userSectionCode != null &&
            userSectionCode.isNotEmpty &&
            selectedClasses.isNotEmpty &&
            !selectedClasses.contains(userSectionCode)) {
          continue;
        }

        loadedExams.add({
          'id': doc.id,
          'title': data['title']?.toString() ?? 'No Title',
          'instruction':
              data['instruction']?.toString() ?? 'No instructions available',
          'instructorName': currentInstructorName.value,
          'instructorId': currentInstructorUid.value,
          'points': data['points'] ?? 0,
          'dueDate': _formatDate(data['dueDate']),
          'createdAt': _formatDate(data['createdAt']),
          'isActive': data['isActive'] ?? true,
          'period': data['period']?.toString() ?? '',
          'questions': data['questions'] ?? [],
          'selectedClasses': selectedClasses,
          'category': category,
          'type': 'Exam',
          'attachments': data['attachments'] ?? [],
        });
      }

      exams.assignAll(loadedExams);
      await loadSubmissionStatuses();
    } catch (e) {
      errorMessage.value = 'Failed to load exams: $e';
      log('Error loading exams: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshExams() async {
    await loadExams();
  }

  void setSelectedExam(Map<String, dynamic> exam) {
    selectedExam.value = exam;
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown Date';

    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        return 'Unknown Date';
      }

      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      final month = months[date.month - 1];
      final day = date.day.toString().padLeft(2, '0');
      final year = date.year;
      int hour = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';

      if (hour == 0) {
        hour = 12;
      } else if (hour > 12) {
        hour -= 12;
      }

      return '$month $day, $year ${hour.toString().padLeft(2, '0')}:$minute $period';
    } catch (e) {
      log('Error formatting exam date: $e');
      return 'Unknown Date';
    }
  }

  Future<void> loadSubmissionStatuses() async {
    try {
      final user = _auth.currentUser;
      if (user == null || exams.isEmpty) return;

      submissionStatus.clear();
      final examIds =
          exams.map((e) => e['id']?.toString()).whereType<String>().toList();
      if (examIds.isEmpty) return;

      for (final id in examIds) {
        submissionStatus[id] = 'not_submitted';
      }

      final allSubmissions =
          await _firestore
              .collection('submissions')
              .where('studentId', isEqualTo: user.uid)
              .where('activityType', isEqualTo: 'exam')
              .get();

      for (final doc in allSubmissions.docs) {
        final data = doc.data();
        final activityId = data['activityId']?.toString();

        if (activityId != null && submissionStatus.containsKey(activityId)) {
          submissionStatus[activityId] =
              data['status']?.toString() ?? 'not_submitted';
        }
      }
    } catch (e) {
      log('Error loading exam submission statuses: $e');
    }
  }
}
