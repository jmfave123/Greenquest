import 'dart:developer' as dev;
import 'section_matching_service.dart';

/// Test with real data from the database to verify the fix works
class RealDataTest {
  /// Test with Jhon Lloyd's actual submission data from the database
  static void testJhonLloydRealData() {
    dev.log('🧪 Testing with Jhon Lloyd\'s real submission data...');

    // Real data from the database (based on the Firestore screenshot)
    final jhonLloydSubmission = {
      'activityId': 'pw7212Ahs',
      'activityTitle': 'gg',
      'activityType': 'Assignment',
      'feedback': null,
      'files': [
        {
          'publicId': 'some_public_id',
          'resourceType': 'raw',
          'size': 1905,
          'type': 'pdf',
          'uploadedAt': '2023-10-18T18:35:22.000Z',
          'url': 'https://res.cloudinary.com/.../submission_flow.pdf',
        },
      ],
      'fullSectionName': 'BSIT-4D', // This is the key field from the database
      'grade': null,
      'gradedAt': null,
      'gradedBy': null,
      'instructorName': 'Sattelo',
      'routedAt': 'October 18, 2023 at 6:35:22 PM UTC+0',
      'routingStatus': 'Success',
      'sectionId': 'BSIT-4D', // This is also from the database
      'sectionName': 'BSIT-4D', // This is also from the database
      'status': 'submitted',
      'studentEmail': 'jhonloydigtig237@gmail.com',
      'studentId': 'YhzgMY7MindV7cfpCMhZ282',
      'studentIdNumber': '2022210647',
      'studentName': 'Jhon Lloyd',
      'submittedAt': 'October 18, 2023 at 6:35:22 PM UTC+0',
    };

    // Test scenarios
    final testCases = [
      {
        'expectedSection': 'BSIT-4D',
        'shouldMatch': true,
        'description':
            'Jhon Lloyd should appear in BSIT-4D section (exact match)',
      },
      {
        'expectedSection': '4D',
        'shouldMatch': true,
        'description': 'Jhon Lloyd should appear in 4D section (partial match)',
      },
      {
        'expectedSection': 'EFWE-3D',
        'shouldMatch': false,
        'description': 'Jhon Lloyd should NOT appear in EFWE-3D section',
      },
      {
        'expectedSection': '3D',
        'shouldMatch': false,
        'description': 'Jhon Lloyd should NOT appear in 3D section',
      },
      {
        'expectedSection': 'BSIT-3D',
        'shouldMatch': false,
        'description': 'Jhon Lloyd should NOT appear in BSIT-3D section',
      },
    ];

    dev.log('🔍 Testing Jhon Lloyd\'s submission against different sections:');

    for (var testCase in testCases) {
      final expectedSection = testCase['expectedSection'] as String;
      final shouldMatch = testCase['shouldMatch'] as bool;
      final description = testCase['description'] as String;

      final result = SectionMatchingService.validateSubmissionSection(
        jhonLloydSubmission,
        expectedSection,
      );

      final status = result == shouldMatch ? '✅' : '❌';
      dev.log('$status $description');
      dev.log('   Expected section: $expectedSection');
      dev.log('   Result: $result (expected: $shouldMatch)');
      dev.log(
        '   Submission sectionName: ${jhonLloydSubmission['sectionName']}',
      );
      dev.log(
        '   Submission fullSectionName: ${jhonLloydSubmission['fullSectionName']}',
      );
      dev.log('');
    }
  }

  /// Test the section extraction logic with real data
  static void testSectionExtraction() {
    dev.log('🧪 Testing section extraction with real data...');

    final testSections = [
      'BSIT-4D',
      'EFWE-3D',
      '4D',
      '3D',
      'BSIT-3D',
      'EFWE-4D',
    ];

    for (String section in testSections) {
      final parts = SectionMatchingService.extractSectionParts(section);
      dev.log('Section: "$section"');
      dev.log('  - Course: "${parts['course']}"');
      dev.log('  - Section: "${parts['section']}"');
      dev.log('');
    }
  }

  /// Test the complete flow with real data
  static void testCompleteFlow() {
    dev.log('🧪 Testing complete flow with real data...');

    // Simulate what happens when viewing BSIT-4D section
    dev.log('📱 Instructor viewing BSIT-4D section:');
    final bsit4dSubmission = {
      'sectionName': 'BSIT-4D',
      'fullSectionName': 'BSIT-4D',
      'studentName': 'Jhon Lloyd',
    };

    final bsit4dResult = SectionMatchingService.validateSubmissionSection(
      bsit4dSubmission,
      'BSIT-4D',
    );

    dev.log(
      '  - Jhon Lloyd in BSIT-4D section: ${bsit4dResult ? "✅ SHOWS" : "❌ HIDDEN"}',
    );

    // Simulate what happens when viewing EFWE-3D section
    dev.log('📱 Instructor viewing EFWE-3D section:');
    final efwe3dResult = SectionMatchingService.validateSubmissionSection(
      bsit4dSubmission,
      'EFWE-3D',
    );

    dev.log(
      '  - Jhon Lloyd in EFWE-3D section: ${efwe3dResult ? "❌ BUG - SHOWS" : "✅ CORRECT - HIDDEN"}',
    );

    // Summary
    if (bsit4dResult && !efwe3dResult) {
      dev.log(
        '🎉 SUCCESS: Jhon Lloyd appears only in BSIT-4D, not in EFWE-3D!',
      );
    } else {
      dev.log('❌ FAILURE: Section separation is not working correctly!');
    }
  }

  /// Run all real data tests
  static void runAllTests() {
    dev.log('🚀 Running real data tests...');

    testSectionExtraction();
    testJhonLloydRealData();
    testCompleteFlow();

    dev.log('🏁 Real data tests completed');
  }
}
