import 'dart:developer' as dev;
import 'section_matching_service.dart';

/// Test to verify that EFWE-3D and BSIT-4D sections are completely separated
class SectionSeparationTest {
  /// Test that submissions are properly separated between different sections
  static void testSectionSeparation() {
    dev.log('🧪 Testing section separation between EFWE-3D and BSIT-4D...');

    // Test cases for EFWE-3D section
    final efwe3dTests = [
      {
        'submission': {
          'sectionName': '3D',
          'fullSectionName': 'EFWE-3D',
          'studentName': 'Student A',
        },
        'expectedSection': '3D',
        'shouldMatch': true,
        'description': 'EFWE-3D student in EFWE-3D section',
      },
      {
        'submission': {
          'sectionName': '3D',
          'fullSectionName': 'EFWE-3D',
          'studentName': 'Student B',
        },
        'expectedSection': 'EFWE-3D',
        'shouldMatch': true,
        'description': 'EFWE-3D student with full name in EFWE-3D section',
      },
      {
        'submission': {
          'sectionName': '4D',
          'fullSectionName': 'BSIT-4D',
          'studentName': 'Jhon Lloyd',
        },
        'expectedSection': '3D',
        'shouldMatch': false,
        'description': 'BSIT-4D student should NOT appear in EFWE-3D section',
      },
      {
        'submission': {
          'sectionName': '4D',
          'fullSectionName': 'BSIT-4D',
          'studentName': 'Jhon Lloyd',
        },
        'expectedSection': 'EFWE-3D',
        'shouldMatch': false,
        'description':
            'BSIT-4D student should NOT appear in EFWE-3D section (full name)',
      },
    ];

    // Test cases for BSIT-4D section
    final bsit4dTests = [
      {
        'submission': {
          'sectionName': '4D',
          'fullSectionName': 'BSIT-4D',
          'studentName': 'Jhon Lloyd',
        },
        'expectedSection': '4D',
        'shouldMatch': true,
        'description': 'BSIT-4D student in BSIT-4D section',
      },
      {
        'submission': {
          'sectionName': '4D',
          'fullSectionName': 'BSIT-4D',
          'studentName': 'Student C',
        },
        'expectedSection': 'BSIT-4D',
        'shouldMatch': true,
        'description': 'BSIT-4D student with full name in BSIT-4D section',
      },
      {
        'submission': {
          'sectionName': '3D',
          'fullSectionName': 'EFWE-3D',
          'studentName': 'Student D',
        },
        'expectedSection': '4D',
        'shouldMatch': false,
        'description': 'EFWE-3D student should NOT appear in BSIT-4D section',
      },
      {
        'submission': {
          'sectionName': '3D',
          'fullSectionName': 'EFWE-3D',
          'studentName': 'Student E',
        },
        'expectedSection': 'BSIT-4D',
        'shouldMatch': false,
        'description':
            'EFWE-3D student should NOT appear in BSIT-4D section (full name)',
      },
    ];

    dev.log('🔍 Testing EFWE-3D section filtering:');
    for (var test in efwe3dTests) {
      final submission = test['submission'] as Map<String, dynamic>;
      final expectedSection = test['expectedSection'] as String;
      final shouldMatch = test['shouldMatch'] as bool;
      final description = test['description'] as String;

      final result = SectionMatchingService.validateSubmissionSection(
        submission,
        expectedSection,
      );

      final status = result == shouldMatch ? '✅' : '❌';
      dev.log('$status $description');
      dev.log('   Result: $result (expected: $shouldMatch)');
    }

    dev.log('🔍 Testing BSIT-4D section filtering:');
    for (var test in bsit4dTests) {
      final submission = test['submission'] as Map<String, dynamic>;
      final expectedSection = test['expectedSection'] as String;
      final shouldMatch = test['shouldMatch'] as bool;
      final description = test['description'] as String;

      final result = SectionMatchingService.validateSubmissionSection(
        submission,
        expectedSection,
      );

      final status = result == shouldMatch ? '✅' : '❌';
      dev.log('$status $description');
      dev.log('   Result: $result (expected: $shouldMatch)');
    }
  }

  /// Test the specific Jhon Lloyd case
  static void testJhonLloydSeparation() {
    dev.log('🧪 Testing Jhon Lloyd separation specifically...');

    final jhonLloydSubmission = {
      'sectionName': '4D',
      'fullSectionName': 'BSIT-4D',
      'studentName': 'Jhon Lloyd',
    };

    // Test that Jhon Lloyd should NOT appear in EFWE-3D
    final efwe3dResult = SectionMatchingService.validateSubmissionSection(
      jhonLloydSubmission,
      '3D',
    );

    // Test that Jhon Lloyd should NOT appear in EFWE-3D (full name)
    final efwe3dFullResult = SectionMatchingService.validateSubmissionSection(
      jhonLloydSubmission,
      'EFWE-3D',
    );

    // Test that Jhon Lloyd SHOULD appear in BSIT-4D
    final bsit4dResult = SectionMatchingService.validateSubmissionSection(
      jhonLloydSubmission,
      '4D',
    );

    // Test that Jhon Lloyd SHOULD appear in BSIT-4D (full name)
    final bsit4dFullResult = SectionMatchingService.validateSubmissionSection(
      jhonLloydSubmission,
      'BSIT-4D',
    );

    dev.log('🔍 Jhon Lloyd section validation results:');
    dev.log(
      '  - Should NOT appear in EFWE-3D (3D): ${efwe3dResult ? "❌ BUG" : "✅ CORRECT"}',
    );
    dev.log(
      '  - Should NOT appear in EFWE-3D (EFWE-3D): ${efwe3dFullResult ? "❌ BUG" : "✅ CORRECT"}',
    );
    dev.log(
      '  - Should appear in BSIT-4D (4D): ${bsit4dResult ? "✅ CORRECT" : "❌ BUG"}',
    );
    dev.log(
      '  - Should appear in BSIT-4D (BSIT-4D): ${bsit4dFullResult ? "✅ CORRECT" : "❌ BUG"}',
    );

    if (!efwe3dResult &&
        !efwe3dFullResult &&
        bsit4dResult &&
        bsit4dFullResult) {
      dev.log('🎉 SUCCESS: Jhon Lloyd is properly separated between sections!');
    } else {
      dev.log('❌ FAILURE: Jhon Lloyd separation is not working correctly!');
    }
  }

  /// Test edge cases and boundary conditions
  static void testEdgeCases() {
    dev.log('🧪 Testing edge cases...');

    final edgeCases = [
      {
        'submission': {'sectionName': '3D', 'fullSectionName': 'EFWE-3D'},
        'expectedSection': '4D',
        'shouldMatch': false,
        'description': 'Different section numbers (3D vs 4D)',
      },
      {
        'submission': {'sectionName': '4D', 'fullSectionName': 'BSIT-4D'},
        'expectedSection': '3D',
        'shouldMatch': false,
        'description': 'Different section numbers (4D vs 3D)',
      },
      {
        'submission': {'sectionName': 'EFWE-3D', 'fullSectionName': 'EFWE-3D'},
        'expectedSection': 'BSIT-4D',
        'shouldMatch': false,
        'description': 'Different courses (EFWE vs BSIT)',
      },
      {
        'submission': {'sectionName': 'BSIT-4D', 'fullSectionName': 'BSIT-4D'},
        'expectedSection': 'EFWE-3D',
        'shouldMatch': false,
        'description': 'Different courses (BSIT vs EFWE)',
      },
      {
        'submission': {'sectionName': '', 'fullSectionName': ''},
        'expectedSection': '3D',
        'shouldMatch': false,
        'description': 'Empty section names',
      },
      {
        'submission': {'sectionName': '3D', 'fullSectionName': 'EFWE-3D'},
        'expectedSection': '',
        'shouldMatch': false,
        'description': 'Empty expected section',
      },
    ];

    for (var test in edgeCases) {
      final submission = test['submission'] as Map<String, dynamic>;
      final expectedSection = test['expectedSection'] as String;
      final shouldMatch = test['shouldMatch'] as bool;
      final description = test['description'] as String;

      final result = SectionMatchingService.validateSubmissionSection(
        submission,
        expectedSection,
      );

      final status = result == shouldMatch ? '✅' : '❌';
      dev.log('$status $description');
    }
  }

  /// Run all separation tests
  static void runAllTests() {
    dev.log('🚀 Running section separation tests...');

    testSectionSeparation();
    testJhonLloydSeparation();
    testEdgeCases();

    dev.log('🏁 Section separation tests completed');
  }
}
