import 'dart:developer' as dev;
import 'section_name_fix_service.dart';

/// Command-line runner for section name fixes
/// This can be used to fix section names for specific students or all students in a section
class SectionNameFixRunner {
  /// Main entry point for running section name fixes
  static Future<void> main(List<String> args) async {
    try {
      dev.log('🚀 Section Name Fix Runner');
      dev.log('========================');

      if (args.isEmpty) {
        _printUsage();
        return;
      }

      final command = args[0].toLowerCase();

      switch (command) {
        case 'fix-student':
          if (args.length < 3) {
            dev.log(
              '❌ Usage: fix-student <studentId> <correctSectionName> [sectionId]',
            );
            return;
          }
          await _fixStudent(args[1], args[2], args.length > 3 ? args[3] : null);
          break;

        case 'fix-section':
          if (args.length < 3) {
            dev.log(
              '❌ Usage: fix-section <sectionCode> <correctSectionName> [sectionId]',
            );
            return;
          }
          await _fixSection(args[1], args[2], args.length > 3 ? args[3] : null);
          break;

        case 'check-student':
          if (args.length < 2) {
            dev.log('❌ Usage: check-student <studentId>');
            return;
          }
          await _checkStudent(args[1]);
          break;

        case 'check-section':
          if (args.length < 2) {
            dev.log('❌ Usage: check-section <sectionCode>');
            return;
          }
          await _checkSection(args[1]);
          break;

        case 'fix-bsit4d':
          await _fixBSIT4D();
          break;

        default:
          dev.log('❌ Unknown command: $command');
          _printUsage();
      }
    } catch (e) {
      dev.log('❌ Error running section name fix: $e');
    }
  }

  /// Fix section name for a specific student
  static Future<void> _fixStudent(
    String studentId,
    String correctSectionName,
    String? sectionId,
  ) async {
    dev.log('\n🔧 Fixing section name for student: $studentId');
    dev.log('  - Correct section name: $correctSectionName');
    if (sectionId != null) {
      dev.log('  - Section ID: $sectionId');
    }

    final success = await SectionNameFixService.fixStudentSectionName(
      studentId: studentId,
      correctSectionName: correctSectionName,
      correctSectionId: sectionId,
    );

    if (success) {
      dev.log('✅ Section name fix completed successfully');
    } else {
      dev.log('❌ Section name fix failed');
    }
  }

  /// Fix section names for all students in a section
  static Future<void> _fixSection(
    String sectionCode,
    String correctSectionName,
    String? sectionId,
  ) async {
    dev.log('\n🔧 Fixing section names for all students in: $sectionCode');
    dev.log('  - Correct section name: $correctSectionName');
    if (sectionId != null) {
      dev.log('  - Section ID: $sectionId');
    }

    final success = await SectionNameFixService.fixAllStudentsInSection(
      sectionCode: sectionCode,
      correctSectionName: correctSectionName,
      correctSectionId: sectionId,
    );

    if (success) {
      dev.log('✅ Section name fix completed successfully');
    } else {
      dev.log('❌ Section name fix failed');
    }
  }

  /// Check student's enrollment and submissions
  static Future<void> _checkStudent(String studentId) async {
    dev.log('\n🔍 Checking student: $studentId');

    // Check enrollment
    final enrollmentData = await SectionNameFixService.checkStudentEnrollment(
      studentId,
    );
    if (enrollmentData == null) {
      dev.log('❌ Could not get student enrollment data');
      return;
    }

    // Get submissions
    final submissions =
        await SectionNameFixService.getStudentAssignmentSubmissions(studentId);
    dev.log('📋 Found ${submissions.length} assignment submissions');
  }

  /// Check all students in a section
  static Future<void> _checkSection(String sectionCode) async {
    dev.log('\n🔍 Checking section: $sectionCode');

    final students = await SectionNameFixService.findStudentsInSection(
      sectionCode,
    );
    dev.log('📋 Found ${students.length} students in section $sectionCode');

    for (var student in students) {
      dev.log('  - ${student['studentName']} (${student['id']})');
    }
  }

  /// Fix BSIT 4D section specifically
  static Future<void> _fixBSIT4D() async {
    dev.log('\n🔧 Fixing BSIT 4D section');

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
  }

  /// Print usage information
  static void _printUsage() {
    dev.log('''
Usage: dart run section_name_fix_runner.dart <command> [args]

Commands:
  fix-student <studentId> <correctSectionName> [sectionId]
    Fix section name for a specific student

  fix-section <sectionCode> <correctSectionName> [sectionId]
    Fix section names for all students in a section

  check-student <studentId>
    Check student's enrollment and submissions

  check-section <sectionCode>
    Check all students in a section

  fix-bsit4d
    Fix BSIT 4D section specifically

Examples:
  dart run section_name_fix_runner.dart fix-student KjxFb5MDGwOATaJOEngDzkCLhHj2 "BSIT 4D"
  dart run section_name_fix_runner.dart fix-section "BSIT-4D" "BSIT 4D"
  dart run section_name_fix_runner.dart check-student KjxFb5MDGwOATaJOEngDzkCLhHj2
  dart run section_name_fix_runner.dart fix-bsit4d
''');
  }
}
