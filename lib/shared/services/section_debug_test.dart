import 'dart:developer' as dev;
import 'section_matching_service.dart';

/// Debug test to verify section filtering is working correctly
class SectionDebugTest {
  /// Test the specific case mentioned in the issue
  static Future<void> testJhonLloydCase() async {
    dev.log('🧪 Testing Jhon Lloyd case...');

    // Simulate Jhon Lloyd's submission data
    final jhonLloydSubmission = {
      'id': 'test_submission_1',
      'studentName': 'Jhon Lloyd',
      'studentId': 'test_student_id',
      'sectionId': 'some_class_id',
      'sectionName': '4D', // This might be the issue - wrong section
      'fullSectionName': 'BSIT-4D', // Student enrolled in BSIT-4D
      'type': 'activity',
    };

    // Test against EFWE-3D section (where it shouldn't appear)
    final efwe3dSection = '3D'; // EFWE-3D section code

    dev.log('🔍 Testing if Jhon Lloyd (BSIT-4D) should appear in EFWE-3D:');

    // Test the validation
    final shouldAppear = SectionMatchingService.validateSubmissionSection(
      jhonLloydSubmission,
      efwe3dSection,
    );

    dev.log('Result: $shouldAppear (should be false)');

    if (shouldAppear) {
      dev.log('❌ BUG: Jhon Lloyd should NOT appear in EFWE-3D section!');
    } else {
      dev.log('✅ CORRECT: Jhon Lloyd correctly excluded from EFWE-3D section');
    }

    // Test against BSIT-4D section (where it should appear)
    final bsit4dSection = '4D'; // BSIT-4D section code

    dev.log('🔍 Testing if Jhon Lloyd (BSIT-4D) should appear in BSIT-4D:');

    final shouldAppearInCorrect =
        SectionMatchingService.validateSubmissionSection(
          jhonLloydSubmission,
          bsit4dSection,
        );

    dev.log('Result: $shouldAppearInCorrect (should be true)');

    if (shouldAppearInCorrect) {
      dev.log('✅ CORRECT: Jhon Lloyd correctly appears in BSIT-4D section');
    } else {
      dev.log('❌ BUG: Jhon Lloyd should appear in BSIT-4D section!');
    }
  }

  /// Test various section matching scenarios
  static void testSectionMatching() {
    dev.log('🧪 Testing section matching scenarios...');

    final testCases = [
      // Format: [submissionSection, expectedSection, shouldMatch]
      ['4D', '3D', false], // Different sections
      ['BSIT-4D', '3D', false], // Different sections with course prefix
      ['4D', '4D', true], // Same section
      ['BSIT-4D', '4D', true], // Course prefix vs section only
      ['4D', 'BSIT-4D', true], // Section only vs course prefix
      ['BSIT-4D', 'BSIT-4D', true], // Same with course prefix
      ['EFWE-3D', '3D', true], // EFWE course
      ['EFWE-3D', '4D', false], // Different sections
      ['3D', '4D', false], // Different section codes
    ];

    for (var testCase in testCases) {
      final submissionSection = testCase[0] as String;
      final expectedSection = testCase[1] as String;
      final shouldMatch = testCase[2] as bool;

      final submission = {
        'sectionId': 'test_id',
        'sectionName': submissionSection,
        'fullSectionName': submissionSection,
      };

      final result = SectionMatchingService.validateSubmissionSection(
        submission,
        expectedSection,
      );

      final status = result == shouldMatch ? '✅' : '❌';
      dev.log(
        '$status "$submissionSection" vs "$expectedSection" = $result (expected $shouldMatch)',
      );
    }
  }

  /// Run all debug tests
  static Future<void> runAllTests() async {
    dev.log('🚀 Running section debug tests...');

    testSectionMatching();
    await testJhonLloydCase();

    dev.log('🏁 Debug tests completed');
  }
}
