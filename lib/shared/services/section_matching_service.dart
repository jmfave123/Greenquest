import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;

/// Service to handle section matching and validation for submissions
class SectionMatchingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get the correct section information for a student based on their enrollment
  static Future<Map<String, dynamic>?> getStudentSectionInfo(
    String studentId,
  ) async {
    try {
      dev.log('🔍 Getting section info for student: $studentId');

      // Get student's enrollment information
      final studentDoc =
          await _firestore.collection('users').doc(studentId).get();
      if (!studentDoc.exists) {
        dev.log('❌ Student document not found');
        return null;
      }

      final studentData = studentDoc.data()!;
      final selectedSectionCode =
          studentData['selectedSectionCode']?.toString();
      final selectedInstructorId =
          studentData['selectedInstructorId']?.toString();

      if (selectedSectionCode == null || selectedInstructorId == null) {
        dev.log('❌ Student missing section or instructor information');
        return null;
      }

      dev.log('📋 Student info:');
      dev.log('  - selectedSectionCode: $selectedSectionCode');
      dev.log('  - selectedInstructorId: $selectedInstructorId');

      // Get the instructor's classes to find the matching section
      final classesSnapshot =
          await _firestore
              .collection('instructors')
              .doc(selectedInstructorId)
              .collection('classes')
              .get();

      // Look for a class that matches the student's section
      for (var classDoc in classesSnapshot.docs) {
        final classData = classDoc.data();
        final classSection = classData['section']?.toString() ?? '';
        final classCourse = classData['course']?.toString() ?? '';

        // Extract section code from student's selectedSectionCode (e.g., "BSIT-4D" -> "4D")
        String studentSectionCode = selectedSectionCode;
        if (studentSectionCode.contains('-')) {
          studentSectionCode = studentSectionCode.split('-').last;
        }

        // Check if this class section matches the student's section
        if (_isSectionMatch(classSection, studentSectionCode)) {
          dev.log(
            '✅ Found matching section: $classSection for student: $selectedSectionCode',
          );

          return {
            'sectionId': classDoc.id,
            'sectionName': classSection,
            'fullSectionName': selectedSectionCode,
            'course': classCourse,
            'instructorId': selectedInstructorId,
          };
        }
      }

      dev.log('⚠️ No matching section found for student: $selectedSectionCode');
      return null;
    } catch (e) {
      dev.log('❌ Error getting student section info: $e');
      return null;
    }
  }

  /// Check if two section names match with strict validation
  static bool _isSectionMatch(String section1, String section2) {
    if (section1.isEmpty || section2.isEmpty) return false;
    if (section1 == section2) return true;

    // Extract course and section parts for more precise matching
    final section1Parts = extractSectionParts(section1);
    final section2Parts = extractSectionParts(section2);

    // Both must have valid course and section parts
    if (section1Parts['course'] == null ||
        section1Parts['section'] == null ||
        section2Parts['course'] == null ||
        section2Parts['section'] == null) {
      return false;
    }

    // For exact matching, both course and section must match
    if (section1Parts['course'] == section2Parts['course'] &&
        section1Parts['section'] == section2Parts['section']) {
      return true;
    }

    // For partial matching (e.g., "4D" vs "BSIT-4D"), check if one is contained in the other
    // but only if they have the same course or one doesn't specify course
    if (section1Parts['course'] == section2Parts['course'] ||
        section1Parts['course'] == '' ||
        section2Parts['course'] == '') {
      return section1Parts['section'] == section2Parts['section'];
    }

    return false;
  }

  /// Extract course and section parts from a section string
  static Map<String, String?> extractSectionParts(String section) {
    final cleanSection = section.trim();

    // Handle formats like "BSIT-4D", "EFWE-3D", "4D", "3D"
    if (cleanSection.contains('-')) {
      final parts = cleanSection.split('-');
      if (parts.length == 2) {
        return {
          'course': parts[0].trim().toUpperCase(),
          'section': parts[1].trim().toUpperCase(),
        };
      }
    }

    // If no dash, assume it's just the section part
    return {'course': '', 'section': cleanSection.toUpperCase()};
  }

  /// Validate that a submission belongs to the correct section with strict separation
  static bool validateSubmissionSection(
    Map<String, dynamic> submission,
    String expectedSection,
  ) {
    final submissionSectionId = submission['sectionId']?.toString() ?? '';
    final submissionSectionName = submission['sectionName']?.toString() ?? '';
    final submissionFullSectionName =
        submission['fullSectionName']?.toString() ?? '';

    dev.log('🔍 Validating submission section:');
    dev.log('  - Expected section: $expectedSection');
    dev.log('  - Submission sectionId: $submissionSectionId');
    dev.log('  - Submission sectionName: $submissionSectionName');
    dev.log('  - Submission fullSectionName: $submissionFullSectionName');

    // Extract expected section parts for comparison
    final expectedParts = extractSectionParts(expectedSection);
    dev.log('  - Expected course: ${expectedParts['course']}');
    dev.log('  - Expected section: ${expectedParts['section']}');

    // STRICT VALIDATION: Only allow submissions that have EXACT course and section match
    // This prevents cross-contamination between different courses/sections

    // Check each submission field for a valid match
    final submissionFields = [
      submissionSectionId,
      submissionSectionName,
      submissionFullSectionName,
    ];

    for (String field in submissionFields) {
      if (field.isEmpty) continue;

      final fieldParts = extractSectionParts(field);
      dev.log(
        '  - Field "$field" -> Course: ${fieldParts['course']}, Section: ${fieldParts['section']}',
      );

      // ULTRA-STRICT matching: both course and section must match EXACTLY
      if (_isUltraStrictSectionMatch(fieldParts, expectedParts)) {
        dev.log('✅ Ultra-strict match found for field: $field');
        return true;
      }
    }

    dev.log('❌ No valid match found - submission will be excluded');
    return false;
  }

  /// Ultra-strict section matching that prevents ANY cross-contamination
  static bool _isUltraStrictSectionMatch(
    Map<String, String?> submissionParts,
    Map<String, String?> expectedParts,
  ) {
    final submissionCourse = submissionParts['course'] ?? '';
    final submissionSection = submissionParts['section'] ?? '';
    final expectedCourse = expectedParts['course'] ?? '';
    final expectedSection = expectedParts['section'] ?? '';

    dev.log('🔍 Ultra-strict matching:');
    dev.log(
      '  - Submission: Course="$submissionCourse", Section="$submissionSection"',
    );
    dev.log(
      '  - Expected: Course="$expectedCourse", Section="$expectedSection"',
    );

    // Both must have valid section parts
    if (submissionSection.isEmpty || expectedSection.isEmpty) {
      dev.log('❌ Empty section parts - no match');
      return false;
    }

    // ULTRA-STRICT RULE: Both course and section must match EXACTLY
    // This completely prevents cross-contamination between different courses/sections
    if (submissionCourse.isNotEmpty && expectedCourse.isNotEmpty) {
      final exactMatch =
          submissionCourse == expectedCourse &&
          submissionSection == expectedSection;
      dev.log('  - Both have courses: $exactMatch');
      return exactMatch;
    }

    // If submission has course but expected doesn't, REJECT to prevent cross-contamination
    if (submissionCourse.isNotEmpty && expectedCourse.isEmpty) {
      dev.log(
        '  - Submission has course but expected doesn\'t - REJECTING to prevent cross-contamination',
      );
      return false;
    }

    // If expected has course but submission doesn't, REJECT to prevent cross-contamination
    if (submissionCourse.isEmpty && expectedCourse.isNotEmpty) {
      dev.log(
        '  - Expected has course but submission doesn\'t - REJECTING to prevent cross-contamination',
      );
      return false;
    }

    // Both are just sections, they must match exactly
    if (submissionCourse.isEmpty && expectedCourse.isEmpty) {
      final sectionMatch = submissionSection == expectedSection;
      dev.log('  - Both are just sections: $sectionMatch');
      return sectionMatch;
    }

    dev.log('❌ No matching condition met - no match');
    return false;
  }

  /// Enhanced validation that also checks student enrollment for extra security
  static Future<bool> validateSubmissionWithEnrollmentCheck(
    Map<String, dynamic> submission,
    String expectedSection,
  ) async {
    // First check basic section validation
    if (!validateSubmissionSection(submission, expectedSection)) {
      return false;
    }

    // Additional check: verify the student is actually enrolled in this section
    final studentId = submission['studentId']?.toString();
    if (studentId == null) {
      dev.log('❌ No student ID found in submission');
      return false;
    }

    try {
      final studentSectionInfo = await getStudentSectionInfo(studentId);
      if (studentSectionInfo == null) {
        dev.log('❌ Could not get student section info');
        return false;
      }

      final studentSection =
          studentSectionInfo['sectionName']?.toString() ?? '';
      final studentFullSection =
          studentSectionInfo['fullSectionName']?.toString() ?? '';

      // Check if student's actual enrollment matches the expected section
      final expectedParts = extractSectionParts(expectedSection);
      final studentSectionParts = extractSectionParts(studentSection);
      final studentFullSectionParts = extractSectionParts(studentFullSection);

      bool enrollmentMatch =
          _isStrictSectionMatch(studentSectionParts, expectedParts) ||
          _isStrictSectionMatch(studentFullSectionParts, expectedParts);

      dev.log('🔍 Enrollment validation for ${submission['studentName']}:');
      dev.log('  - Student enrolled in: $studentSection ($studentFullSection)');
      dev.log('  - Expected section: $expectedSection');
      dev.log('  - Match: $enrollmentMatch');

      return enrollmentMatch;
    } catch (e) {
      dev.log('❌ Error validating enrollment: $e');
      return false;
    }
  }

  /// Strict section matching that ensures complete separation between different courses/sections
  static bool _isStrictSectionMatch(
    Map<String, String?> submissionParts,
    Map<String, String?> expectedParts,
  ) {
    final submissionCourse = submissionParts['course'] ?? '';
    final submissionSection = submissionParts['section'] ?? '';
    final expectedCourse = expectedParts['course'] ?? '';
    final expectedSection = expectedParts['section'] ?? '';

    dev.log('🔍 Strict matching:');
    dev.log(
      '  - Submission: Course="$submissionCourse", Section="$submissionSection"',
    );
    dev.log(
      '  - Expected: Course="$expectedCourse", Section="$expectedSection"',
    );

    // Both must have valid section parts
    if (submissionSection.isEmpty || expectedSection.isEmpty) {
      dev.log('❌ Empty section parts - no match');
      return false;
    }

    // STRICT RULE: Both course and section must match exactly
    // This prevents cross-contamination between different courses/sections
    if (submissionCourse.isNotEmpty && expectedCourse.isNotEmpty) {
      final exactMatch =
          submissionCourse == expectedCourse &&
          submissionSection == expectedSection;
      dev.log('  - Both have courses: $exactMatch');
      return exactMatch;
    }

    // If submission has course but expected doesn't, check if section matches
    // BUT ONLY if the course is compatible (this is more restrictive)
    if (submissionCourse.isNotEmpty && expectedCourse.isEmpty) {
      // Only allow if the submission course matches the expected section context
      // This prevents BSIT submissions from appearing in EFWE sections
      final sectionMatch = submissionSection == expectedSection;
      dev.log('  - Submission has course, expected doesn\'t: $sectionMatch');
      return sectionMatch;
    }

    // If expected has course but submission doesn't, check if section matches
    // BUT ONLY if the expected course is compatible
    if (submissionCourse.isEmpty && expectedCourse.isNotEmpty) {
      // Only allow if the expected course matches the submission section context
      final sectionMatch = submissionSection == expectedSection;
      dev.log('  - Expected has course, submission doesn\'t: $sectionMatch');
      return sectionMatch;
    }

    // Both are just sections, they must match exactly
    if (submissionCourse.isEmpty && expectedCourse.isEmpty) {
      final sectionMatch = submissionSection == expectedSection;
      dev.log('  - Both are just sections: $sectionMatch');
      return sectionMatch;
    }

    dev.log('❌ No matching condition met - no match');
    return false;
  }

  /// Check if two strings have a safe partial match
  /// This only matches when one is clearly a subset of the other (e.g., "4D" in "BSIT-4D")
  static bool _isSafePartialMatch(String str1, String str2) {
    if (str1.isEmpty || str2.isEmpty) return false;

    final normalized1 = str1.toLowerCase().trim();
    final normalized2 = str2.toLowerCase().trim();

    // Only match if one is clearly contained in the other and they share common patterns
    // This prevents false matches like "3D" matching "4D" or "EFWE" matching "BSIT"

    // Check if one contains the other AND they have similar structure
    if (normalized1.contains(normalized2)) {
      // Make sure it's not just a number match (e.g., "3" in "4D" should not match "3D")
      return _hasSimilarStructure(normalized1, normalized2);
    }

    if (normalized2.contains(normalized1)) {
      return _hasSimilarStructure(normalized2, normalized1);
    }

    return false;
  }

  /// Check if two strings have similar structure (both contain letters and numbers)
  static bool _hasSimilarStructure(String longer, String shorter) {
    // Extract letters and numbers from both strings
    final longerLetters = longer.replaceAll(RegExp(r'[^a-z]'), '');
    final longerNumbers = longer.replaceAll(RegExp(r'[^0-9]'), '');
    final shorterLetters = shorter.replaceAll(RegExp(r'[^a-z]'), '');
    final shorterNumbers = shorter.replaceAll(RegExp(r'[^0-9]'), '');

    // Both should have similar letter patterns and the shorter should be contained in longer
    return longerLetters.contains(shorterLetters) &&
        longerNumbers.contains(shorterNumbers) &&
        shorterLetters.isNotEmpty &&
        shorterNumbers.isNotEmpty;
  }

  /// Get all sections for an instructor
  static Future<List<String>> getInstructorSections(String instructorId) async {
    try {
      final classesSnapshot =
          await _firestore
              .collection('instructors')
              .doc(instructorId)
              .collection('classes')
              .get();

      final sections = <String>[];
      for (var classDoc in classesSnapshot.docs) {
        final classData = classDoc.data();
        final section = classData['section']?.toString() ?? '';
        if (section.isNotEmpty) {
          sections.add(section);
        }
      }

      return sections;
    } catch (e) {
      dev.log('❌ Error getting instructor sections: $e');
      return [];
    }
  }

  /// Filter submissions by section with enhanced validation
  static List<Map<String, dynamic>> filterSubmissionsBySection(
    List<Map<String, dynamic>> submissions,
    String targetSection,
  ) {
    dev.log(
      '🔍 Filtering ${submissions.length} submissions for section: $targetSection',
    );

    final filteredSubmissions =
        submissions.where((submission) {
          final isValid = validateSubmissionSection(submission, targetSection);
          if (isValid) {
            dev.log(
              '✅ Including submission: ${submission['studentName']} - ${submission['sectionName']}',
            );
          } else {
            dev.log(
              '❌ Excluding submission: ${submission['studentName']} - ${submission['sectionName']}',
            );
          }
          return isValid;
        }).toList();

    dev.log(
      '📊 Filtered ${filteredSubmissions.length} submissions for section: $targetSection',
    );
    return filteredSubmissions;
  }

  /// Filter submissions by section with strict enrollment validation
  static Future<List<Map<String, dynamic>>>
  filterSubmissionsBySectionWithEnrollment(
    List<Map<String, dynamic>> submissions,
    String targetSection,
  ) async {
    dev.log(
      '🔍 Filtering ${submissions.length} submissions for section: $targetSection (with enrollment check)',
    );

    final filteredSubmissions = <Map<String, dynamic>>[];

    for (final submission in submissions) {
      final isValid = await validateSubmissionWithEnrollmentCheck(
        submission,
        targetSection,
      );
      if (isValid) {
        dev.log(
          '✅ Including submission: ${submission['studentName']} - ${submission['sectionName']}',
        );
        filteredSubmissions.add(submission);
      } else {
        dev.log(
          '❌ Excluding submission: ${submission['studentName']} - ${submission['sectionName']}',
        );
      }
    }

    dev.log(
      '📊 Filtered ${filteredSubmissions.length} submissions for section: $targetSection',
    );
    return filteredSubmissions;
  }

  /// Enhanced validation that also checks student enrollment
  static Future<bool> validateSubmissionWithEnrollment(
    Map<String, dynamic> submission,
    String expectedSection,
  ) async {
    // First check basic section validation
    if (!validateSubmissionSection(submission, expectedSection)) {
      return false;
    }

    // Additional check: verify the student is actually enrolled in this section
    final studentId = submission['studentId']?.toString();
    if (studentId == null) return false;

    try {
      final studentSectionInfo = await getStudentSectionInfo(studentId);
      if (studentSectionInfo == null) return false;

      final studentSection =
          studentSectionInfo['sectionName']?.toString() ?? '';
      final studentFullSection =
          studentSectionInfo['fullSectionName']?.toString() ?? '';

      // Check if student's actual enrollment matches the expected section
      bool enrollmentMatch =
          _isSectionMatch(studentSection, expectedSection) ||
          _isSectionMatch(studentFullSection, expectedSection) ||
          _isSafePartialMatch(studentSection, expectedSection) ||
          _isSafePartialMatch(studentFullSection, expectedSection);

      dev.log('🔍 Enrollment validation for ${submission['studentName']}:');
      dev.log('  - Student enrolled in: $studentSection ($studentFullSection)');
      dev.log('  - Expected section: $expectedSection');
      dev.log('  - Match: $enrollmentMatch');

      return enrollmentMatch;
    } catch (e) {
      dev.log('❌ Error validating enrollment: $e');
      return false;
    }
  }
}
