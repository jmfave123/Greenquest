import 'dart:developer' as dev;
import 'section_name_fix_service.dart';

/// Test script to fix section name for the specific student
/// Student ID: KjxFb5MDGwOATaJOEngDzkCLhHj2
/// Student Email: jhonloydtigtig337@gmail.com
/// Expected Section: BSIT 4D
class SectionNameFixTest {
  /// Run the fix for the specific student
  static Future<void> runFix() async {
    try {
      dev.log('🚀 Starting section name fix for student');

      const String studentId = 'KjxFb5MDGwOATaJOEngDzkCLhHj2';
      const String expectedSection = 'BSIT 4D';
      const String expectedSectionId = 'temp_bsit_4d';

      // Step 1: Check student's enrollment data
      dev.log('\n📋 Step 1: Checking student enrollment data');
      final enrollmentData = await SectionNameFixService.checkStudentEnrollment(
        studentId,
      );

      if (enrollmentData == null) {
        dev.log('❌ Could not retrieve student enrollment data');
        return;
      }

      // Step 2: Get current assignment submissions
      dev.log('\n📋 Step 2: Getting current assignment submissions');
      final submissions =
          await SectionNameFixService.getStudentAssignmentSubmissions(
            studentId,
          );

      if (submissions.isEmpty) {
        dev.log('⚠️ No assignment submissions found for this student');
        return;
      }

      // Step 3: Check if any submissions have incorrect section name
      dev.log('\n📋 Step 3: Checking for incorrect section names');
      bool needsFix = false;
      for (var submission in submissions) {
        final currentSectionName = submission['sectionName'];
        if (currentSectionName != expectedSection) {
          dev.log(
            '⚠️ Found submission with incorrect section: $currentSectionName (expected: $expectedSection)',
          );
          needsFix = true;
        } else {
          dev.log(
            '✅ Submission already has correct section: $currentSectionName',
          );
        }
      }

      if (!needsFix) {
        dev.log('✅ All submissions already have correct section name');
        return;
      }

      // Step 4: Fix the section names
      dev.log('\n🔧 Step 4: Fixing section names');
      final success = await SectionNameFixService.fixStudentSectionName(
        studentId: studentId,
        correctSectionName: expectedSection,
        correctSectionId: expectedSectionId,
      );

      if (success) {
        dev.log('✅ Section name fix completed successfully');
      } else {
        dev.log('❌ Section name fix failed');
      }

      // Step 5: Verify the fix
      dev.log('\n📋 Step 5: Verifying the fix');
      final updatedSubmissions =
          await SectionNameFixService.getStudentAssignmentSubmissions(
            studentId,
          );

      for (var submission in updatedSubmissions) {
        final sectionName = submission['sectionName'];
        if (sectionName == expectedSection) {
          dev.log('✅ Submission ${submission['id']}: $sectionName');
        } else {
          dev.log(
            '❌ Submission ${submission['id']}: $sectionName (expected: $expectedSection)',
          );
        }
      }
    } catch (e) {
      dev.log('❌ Error running section name fix: $e');
    }
  }

  /// Check all students in BSIT 4D section
  static Future<void> checkBSIT4DStudents() async {
    try {
      dev.log('🔍 Checking all students in BSIT 4D section');

      // Try different possible section codes
      final possibleSectionCodes = [
        'BSIT 4D',
        'BSIT-4D',
        'bsit4d',
        'bsit-4d',
        '4D',
        'BSIT4D',
      ];

      for (String sectionCode in possibleSectionCodes) {
        dev.log('\n🔍 Checking section code: $sectionCode');
        final students = await SectionNameFixService.findStudentsInSection(
          sectionCode,
        );

        if (students.isNotEmpty) {
          dev.log(
            '✅ Found ${students.length} students in section $sectionCode:',
          );
          for (var student in students) {
            dev.log('  - ${student['studentName']} (${student['id']})');
          }
        } else {
          dev.log('⚠️ No students found in section $sectionCode');
        }
      }
    } catch (e) {
      dev.log('❌ Error checking BSIT 4D students: $e');
    }
  }

  /// Fix all students in BSIT 4D section
  static Future<void> fixAllBSIT4DStudents() async {
    try {
      dev.log('🔧 Fixing all students in BSIT 4D section');

      const String correctSectionName = 'BSIT 4D';
      const String correctSectionId = 'temp_bsit_4d';

      // Try different possible section codes
      final possibleSectionCodes = [
        'BSIT 4D',
        'BSIT-4D',
        'bsit4d',
        'bsit-4d',
        '4D',
        'BSIT4D',
      ];

      for (String sectionCode in possibleSectionCodes) {
        dev.log('\n🔧 Fixing students in section: $sectionCode');
        final success = await SectionNameFixService.fixAllStudentsInSection(
          sectionCode: sectionCode,
          correctSectionName: correctSectionName,
          correctSectionId: correctSectionId,
        );

        if (success) {
          dev.log('✅ Successfully fixed students in section $sectionCode');
        } else {
          dev.log('⚠️ No students found or fixed in section $sectionCode');
        }
      }
    } catch (e) {
      dev.log('❌ Error fixing all BSIT 4D students: $e');
    }
  }
}
