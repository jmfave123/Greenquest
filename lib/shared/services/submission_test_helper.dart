import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper class to test submission functionality
/// This demonstrates how student submissions automatically appear in instructor's activity section
class SubmissionTestHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Test method to simulate a student submitting an activity
  /// This should automatically appear in the instructor's activity section
  static Future<void> testActivitySubmission({
    required String activityId,
    required String instructorId,
    required String studentName,
    required String studentId,
    required String sectionId,
  }) async {
    try {
      print('🧪 Testing activity submission...');

      // Create a test submission
      final submissionData = {
        'activityType': 'activity', // Unified activity type
        'activityId': activityId, // Unified activity ID field
        'instructorId': instructorId,
        'studentId': studentId,
        'studentName': studentName,
        'studentEmail': 'test@example.com',
        'studentIdNumber': 'TEST123',
        'sectionId': sectionId,
        'sectionName': 'BSIT-4D',
        'activityTitle': 'Test Activity',
        'files': ['test_file.pdf'],
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'submitted',
        'grade': null,
        'feedback': null,
        'gradedAt': null,
        'routedAt': FieldValue.serverTimestamp(),
        'routingStatus': 'success',
      };

      // Submit to unified submissions collection
      await _firestore.collection('submissions').add(submissionData);

      print('✅ Test activity submission created successfully');
      print('📋 Activity ID: $activityId');
      print('👨‍🏫 Instructor ID: $instructorId');
      print('👨‍🎓 Student: $studentName');
      print('📚 Section: $sectionId');
    } catch (e) {
      print('❌ Error creating test activity submission: $e');
    }
  }

  /// Test method to simulate a student submitting an assignment
  static Future<void> testAssignmentSubmission({
    required String assignmentId,
    required String instructorId,
    required String studentName,
    required String studentId,
    required String sectionId,
  }) async {
    try {
      print('🧪 Testing assignment submission...');

      // Create a test submission
      final submissionData = {
        'activityType': 'assignment', // Unified activity type
        'activityId': assignmentId, // Unified activity ID field
        'instructorId': instructorId,
        'studentId': studentId,
        'studentName': studentName,
        'studentEmail': 'test@example.com',
        'studentIdNumber': 'TEST123',
        'sectionId': sectionId,
        'sectionName': 'BSIT-4D',
        'activityTitle': 'Test Assignment',
        'files': [
          {
            'name': 'assignment.pdf',
            'url': 'https://example.com/assignment.pdf',
            'size': 1024000,
            'type': 'pdf',
          },
        ],
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'submitted',
        'grade': null,
        'feedback': null,
        'gradedAt': null,
        'routedAt': FieldValue.serverTimestamp(),
        'routingStatus': 'success',
      };

      // Submit to unified submissions collection
      await _firestore.collection('submissions').add(submissionData);

      print('✅ Test assignment submission created successfully');
      print('📋 Assignment ID: $assignmentId');
      print('👨‍🏫 Instructor ID: $instructorId');
      print('👨‍🎓 Student: $studentName');
      print('📚 Section: $sectionId');
    } catch (e) {
      print('❌ Error creating test assignment submission: $e');
    }
  }

  /// Test method to simulate a student submitting a quiz
  static Future<void> testQuizSubmission({
    required String quizId,
    required String instructorId,
    required String studentName,
    required String studentId,
    required String sectionId,
  }) async {
    try {
      print('🧪 Testing quiz submission...');

      // Create a test submission
      final submissionData = {
        'activityType': 'quiz', // Unified activity type
        'activityId': quizId, // Unified activity ID field
        'instructorId': instructorId,
        'studentId': studentId,
        'studentName': studentName,
        'studentEmail': 'test@example.com',
        'studentIdNumber': 'TEST123',
        'sectionId': sectionId,
        'sectionName': 'BSIT-4D',
        'activityTitle': 'Test Quiz',
        'answers': {
          'question1': 'Answer A',
          'question2': 'Answer B',
          'question3': 'Answer C',
        },
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'submitted',
        'grade': null,
        'feedback': null,
        'gradedAt': null,
        'routedAt': FieldValue.serverTimestamp(),
        'routingStatus': 'success',
      };

      // Submit to unified submissions collection
      await _firestore.collection('submissions').add(submissionData);

      print('✅ Test quiz submission created successfully');
      print('📋 Quiz ID: $quizId');
      print('👨‍🏫 Instructor ID: $instructorId');
      print('👨‍🎓 Student: $studentName');
      print('📚 Section: $sectionId');
    } catch (e) {
      print('❌ Error creating test quiz submission: $e');
    }
  }

  /// Test method to simulate a student submitting a PIT
  static Future<void> testPitSubmission({
    required String pitId,
    required String instructorId,
    required String studentName,
    required String studentId,
    required String sectionId,
  }) async {
    try {
      print('🧪 Testing PIT submission...');

      // Create a test submission
      final submissionData = {
        'activityId': pitId,
        'instructorId': instructorId,
        'studentId': studentId,
        'studentName': studentName,
        'studentEmail': 'test@example.com',
        'studentIdNumber': 'TEST123',
        'sectionId': sectionId,
        'sectionName': 'BSIT-4D',
        'activityTitle': 'Test PIT',
        'activityType': 'pit',
        'files': [
          {
            'name': 'pit_document.pdf',
            'url': 'https://example.com/pit.pdf',
            'size': 2048000,
            'type': 'pdf',
          },
        ],
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'submitted',
        'grade': null,
        'feedback': null,
        'gradedAt': null,
        'routedAt': FieldValue.serverTimestamp(),
        'routingStatus': 'success',
      };

      // Submit to the submissions collection
      await _firestore.collection('submissions').add(submissionData);

      print('✅ Test PIT submission created successfully');
      print('📋 PIT ID: $pitId');
      print('👨‍🏫 Instructor ID: $instructorId');
      print('👨‍🎓 Student: $studentName');
      print('📚 Section: $sectionId');
    } catch (e) {
      print('❌ Error creating test PIT submission: $e');
    }
  }

  /// Run all submission tests
  static Future<void> runAllTests({
    required String instructorId,
    required String sectionId,
  }) async {
    print('🚀 Running all submission tests...');
    print('👨‍🏫 Instructor ID: $instructorId');
    print('📚 Section ID: $sectionId');
    print('');

    // Test activity submission
    await testActivitySubmission(
      activityId: 'test_activity_123',
      instructorId: instructorId,
      studentName: 'Test Student 1',
      studentId: 'test_student_1',
      sectionId: sectionId,
    );

    await Future.delayed(const Duration(seconds: 1));

    // Test assignment submission
    await testAssignmentSubmission(
      assignmentId: 'test_assignment_123',
      instructorId: instructorId,
      studentName: 'Test Student 2',
      studentId: 'test_student_2',
      sectionId: sectionId,
    );

    await Future.delayed(const Duration(seconds: 1));

    // Test quiz submission
    await testQuizSubmission(
      quizId: 'test_quiz_123',
      instructorId: instructorId,
      studentName: 'Test Student 3',
      studentId: 'test_student_3',
      sectionId: sectionId,
    );

    await Future.delayed(const Duration(seconds: 1));

    // Test PIT submission
    await testPitSubmission(
      pitId: 'test_pit_123',
      instructorId: instructorId,
      studentName: 'Test Student 4',
      studentId: 'test_student_4',
      sectionId: sectionId,
    );

    print('');
    print('✅ All submission tests completed!');
    print(
      '📱 Check the instructor dashboard to see if submissions appear automatically',
    );
  }
}
