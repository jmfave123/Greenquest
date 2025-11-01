import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;
import 'section_matching_service.dart';

/// Test service to verify section filtering functionality
class SectionFilteringTest {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Test the section filtering functionality
  static Future<void> runTest() async {
    dev.log('🧪 Starting section filtering test...');

    try {
      // Test 1: Get student section info
      await _testStudentSectionInfo();

      // Test 2: Test section matching
      await _testSectionMatching();

      // Test 3: Test submission filtering
      await _testSubmissionFiltering();

      dev.log('✅ All tests completed successfully!');
    } catch (e) {
      dev.log('❌ Test failed: $e');
    }
  }

  /// Test getting student section information
  static Future<void> _testStudentSectionInfo() async {
    dev.log('🔍 Test 1: Getting student section info...');

    // Get a sample student
    final studentsSnapshot =
        await _firestore
            .collection('users')
            .where('selectedInstructorId', isNull: false)
            .limit(1)
            .get();

    if (studentsSnapshot.docs.isEmpty) {
      dev.log('⚠️ No students found for testing');
      return;
    }

    final studentId = studentsSnapshot.docs.first.id;
    final sectionInfo = await SectionMatchingService.getStudentSectionInfo(
      studentId,
    );

    if (sectionInfo != null) {
      dev.log('✅ Student section info retrieved:');
      dev.log('  - sectionId: ${sectionInfo['sectionId']}');
      dev.log('  - sectionName: ${sectionInfo['sectionName']}');
      dev.log('  - fullSectionName: ${sectionInfo['fullSectionName']}');
      dev.log('  - course: ${sectionInfo['course']}');
    } else {
      dev.log('❌ Failed to get student section info');
    }
  }

  /// Test section matching logic
  static Future<void> _testSectionMatching() async {
    dev.log('🔍 Test 2: Testing section matching...');

    // Test various section matching scenarios
    final testCases = [
      {'section1': '4D', 'section2': '4D', 'expected': true},
      {'section1': 'BSIT-4D', 'section2': '4D', 'expected': true},
      {'section1': '4D', 'section2': 'BSIT-4D', 'expected': true},
      {'section1': 'BSIT-4D', 'section2': 'BSIT-4D', 'expected': true},
      {'section1': '4A', 'section2': '4D', 'expected': false},
      {'section1': 'BSIT-4A', 'section2': 'BSIT-4D', 'expected': false},
    ];

    for (var testCase in testCases) {
      final section1 = testCase['section1'] as String;
      final section2 = testCase['section2'] as String;
      final expected = testCase['expected'] as bool;

      // Test with sample submission data
      final submission = {
        'sectionId': section1,
        'sectionName': section1,
        'fullSectionName': section1,
      };

      final result = SectionMatchingService.validateSubmissionSection(
        submission,
        section2,
      );

      if (result == expected) {
        dev.log('✅ Match test passed: "$section1" vs "$section2" = $result');
      } else {
        dev.log(
          '❌ Match test failed: "$section1" vs "$section2" = $result (expected $expected)',
        );
      }
    }
  }

  /// Test submission filtering
  static Future<void> _testSubmissionFiltering() async {
    dev.log('🔍 Test 3: Testing submission filtering...');

    // Create sample submissions
    final submissions = [
      {
        'id': '1',
        'studentName': 'Student 1',
        'sectionId': 'class1',
        'sectionName': '4D',
        'fullSectionName': 'BSIT-4D',
        'type': 'assignment',
      },
      {
        'id': '2',
        'studentName': 'Student 2',
        'sectionId': 'class2',
        'sectionName': '4A',
        'fullSectionName': 'BSIT-4A',
        'type': 'activity',
      },
      {
        'id': '3',
        'studentName': 'Student 3',
        'sectionId': 'class1',
        'sectionName': '4D',
        'fullSectionName': 'BSIT-4D',
        'type': 'quiz',
      },
    ];

    // Test filtering by section
    final filteredSubmissions =
        SectionMatchingService.filterSubmissionsBySection(submissions, '4D');

    dev.log('📊 Filtering results:');
    dev.log('  - Total submissions: ${submissions.length}');
    dev.log('  - Filtered submissions: ${filteredSubmissions.length}');

    for (var submission in filteredSubmissions) {
      dev.log('  - ${submission['studentName']}: ${submission['sectionName']}');
    }

    if (filteredSubmissions.length == 2) {
      dev.log('✅ Submission filtering test passed');
    } else {
      dev.log('❌ Submission filtering test failed');
    }
  }

  /// Test with real data from Firestore
  static Future<void> testWithRealData() async {
    dev.log('🔍 Testing with real Firestore data...');

    try {
      // Get a sample instructor
      final instructorsSnapshot =
          await _firestore.collection('instructors').limit(1).get();

      if (instructorsSnapshot.docs.isEmpty) {
        dev.log('⚠️ No instructors found for testing');
        return;
      }

      final instructorId = instructorsSnapshot.docs.first.id;
      dev.log('📋 Testing with instructor: $instructorId');

      // Get instructor's sections
      final sections = await SectionMatchingService.getInstructorSections(
        instructorId,
      );
      dev.log('📚 Instructor sections: $sections');

      // Get some submissions
      final assignmentSubmissions =
          await _firestore
              .collection('submissions')
              .where('activityType', isEqualTo: 'assignment')
              .where('instructorId', isEqualTo: instructorId)
              .limit(5)
              .get();

      dev.log(
        '📝 Found ${assignmentSubmissions.docs.length} assignment submissions',
      );

      for (var doc in assignmentSubmissions.docs) {
        final data = doc.data();
        dev.log(
          '  - ${data['studentName']}: ${data['sectionName']} (${data['fullSectionName']})',
        );
      }
    } catch (e) {
      dev.log('❌ Real data test failed: $e');
    }
  }
}
