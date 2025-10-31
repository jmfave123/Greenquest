import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'submission_routing_service.dart';

/// Test class to verify submission routing functionality
class SubmissionRoutingTest {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Test the submission routing service
  static Future<void> testSubmissionRouting() async {
    print('🧪 Testing Submission Routing Service...');

    try {
      // Test data
      final testSubmissionData = {
        'studentId': 'test_student_123',
        'studentName': 'Test Student',
        'studentEmail': 'test@example.com',
        'studentIdNumber': '12345',
        'files': [
          {
            'name': 'test_document.pdf',
            'url': 'https://example.com/test.pdf',
            'size': 1024000,
          }
        ],
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'submitted',
        'grade': null,
        'feedback': null,
      };

      // Test routing for different submission types
      final testCases = [
        {
          'activityId': 'test_activity_123',
          'submissionType': 'activity',
        },
        {
          'activityId': 'test_assignment_456',
          'submissionType': 'assignment',
        },
        {
          'activityId': 'test_quiz_789',
          'submissionType': 'quiz',
        },
        {
          'activityId': 'test_pit_101',
          'submissionType': 'pit',
        },
      ];

      for (var testCase in testCases) {
        print('🔍 Testing ${testCase['submissionType']} routing...');
        
        final result = await SubmissionRoutingService.routeSubmission(
          activityId: testCase['activityId']!,
          submissionType: testCase['submissionType']!,
          submissionData: testSubmissionData,
        );

        if (result['success']) {
          print('✅ ${testCase['submissionType']} routing successful');
          print('   - Submission ID: ${result['submissionId']}');
          print('   - Instructor ID: ${result['instructorId']}');
          print('   - Section ID: ${result['sectionId']}');
        } else {
          print('❌ ${testCase['submissionType']} routing failed: ${result['error']}');
        }
      }

      print('🎉 Submission routing test completed!');
    } catch (e) {
      print('❌ Test failed with error: $e');
    }
  }

  /// Test real-time updates
  static void testRealtimeUpdates() {
    print('🧪 Testing Real-time Updates...');

    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user for real-time test');
        return;
      }

      // Test submission updates
      final submissionStream = SubmissionRoutingService.getSubmissionUpdates(
        user.uid,
        'test_activity_123',
        'activity',
      );

      submissionStream.listen(
        (snapshot) {
          print('📡 Real-time update received: ${snapshot.docs.length} submissions');
          for (var doc in snapshot.docs) {
            print('   - Submission: ${doc.id}');
          }
        },
        onError: (error) {
          print('❌ Real-time update error: $error');
        },
      );

      // Test notification updates
      final notificationStream = SubmissionRoutingService.getNotificationUpdates(user.uid);
      
      notificationStream.listen(
        (snapshot) {
          print('🔔 Notification update received: ${snapshot.docs.length} notifications');
          for (var doc in snapshot.docs) {
            print('   - Notification: ${doc.id}');
          }
        },
        onError: (error) {
          print('❌ Notification update error: $error');
        },
      );

      print('✅ Real-time update listeners set up successfully');
    } catch (e) {
      print('❌ Real-time test failed with error: $e');
    }
  }
}
