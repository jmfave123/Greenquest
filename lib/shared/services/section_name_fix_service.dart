import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;

/// Service to fix section name issues in assignment submissions
class SectionNameFixService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check student's enrollment data to verify their section
  static Future<Map<String, dynamic>?> checkStudentEnrollment(
    String studentId,
  ) async {
    try {
      dev.log('🔍 Checking enrollment for student: $studentId');

      final studentDoc =
          await _firestore.collection('users').doc(studentId).get();
      if (!studentDoc.exists) {
        dev.log('❌ Student document not found');
        return null;
      }

      final studentData = studentDoc.data()!;

      // Get all possible section fields
      final selectedSectionCode = studentData['selectedSectionCode'];
      final sectionCode = studentData['sectionCode'];
      final section = studentData['section'];
      final classField = studentData['class'];

      dev.log('📋 Student enrollment data:');
      dev.log('  - selectedSectionCode: $selectedSectionCode');
      dev.log('  - sectionCode: $sectionCode');
      dev.log('  - section: $section');
      dev.log('  - class: $classField');
      dev.log('  - fullName: ${studentData['fullName']}');
      dev.log('  - name: ${studentData['name']}');
      dev.log('  - displayName: ${studentData['displayName']}');

      return {
        'studentId': studentId,
        'selectedSectionCode': selectedSectionCode,
        'sectionCode': sectionCode,
        'section': section,
        'class': classField,
        'studentName':
            studentData['fullName'] ??
            studentData['name'] ??
            studentData['displayName'] ??
            'Unknown',
      };
    } catch (e) {
      dev.log('❌ Error checking student enrollment: $e');
      return null;
    }
  }

  /// Update assignment submission with correct section name
  static Future<bool> updateAssignmentSubmissionSection({
    required String submissionId,
    required String correctSectionName,
    String? correctSectionId,
  }) async {
    try {
      dev.log('🔄 Updating assignment submission: $submissionId');
      dev.log('  - New section name: $correctSectionName');
      dev.log('  - New section ID: $correctSectionId');

      final updateData = <String, dynamic>{
        'sectionName': correctSectionName,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (correctSectionId != null) {
        updateData['sectionId'] = correctSectionId;
      }

      await _firestore
          .collection('assignment_submissions')
          .doc(submissionId)
          .update(updateData);

      dev.log('✅ Assignment submission updated successfully');
      return true;
    } catch (e) {
      dev.log('❌ Error updating assignment submission: $e');
      return false;
    }
  }

  /// Find all assignment submissions for a specific student
  static Future<List<Map<String, dynamic>>> getStudentAssignmentSubmissions(
    String studentId,
  ) async {
    try {
      dev.log('🔍 Finding assignment submissions for student: $studentId');

      final querySnapshot =
          await _firestore
              .collection('assignment_submissions')
              .where('studentId', isEqualTo: studentId)
              .orderBy('submittedAt', descending: true)
              .get();

      List<Map<String, dynamic>> submissions = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        submissions.add({
          'id': doc.id,
          'assignmentId': data['assignmentId'],
          'studentName': data['studentName'],
          'sectionName': data['sectionName'],
          'sectionId': data['sectionId'],
          'status': data['status'],
          'submittedAt': data['submittedAt'],
          'instructorName': data['instructorName'],
        });
      }

      dev.log('📋 Found ${submissions.length} assignment submissions');
      for (var submission in submissions) {
        dev.log(
          '  - ${submission['id']}: ${submission['studentName']} - ${submission['sectionName']}',
        );
      }

      return submissions;
    } catch (e) {
      dev.log('❌ Error getting student assignment submissions: $e');
      return [];
    }
  }

  /// Fix section name for a specific student's submissions
  static Future<bool> fixStudentSectionName({
    required String studentId,
    required String correctSectionName,
    String? correctSectionId,
  }) async {
    try {
      dev.log('🔧 Fixing section name for student: $studentId');
      dev.log('  - Correct section name: $correctSectionName');

      // First check student's enrollment
      final enrollmentData = await checkStudentEnrollment(studentId);
      if (enrollmentData == null) {
        dev.log('❌ Could not get student enrollment data');
        return false;
      }

      // Get all assignment submissions for this student
      final submissions = await getStudentAssignmentSubmissions(studentId);
      if (submissions.isEmpty) {
        dev.log('⚠️ No assignment submissions found for student');
        return true;
      }

      // Update each submission
      int updatedCount = 0;
      for (var submission in submissions) {
        final success = await updateAssignmentSubmissionSection(
          submissionId: submission['id'],
          correctSectionName: correctSectionName,
          correctSectionId: correctSectionId,
        );

        if (success) {
          updatedCount++;
        }
      }

      dev.log(
        '✅ Updated $updatedCount out of ${submissions.length} submissions',
      );
      return updatedCount > 0;
    } catch (e) {
      dev.log('❌ Error fixing student section name: $e');
      return false;
    }
  }

  /// Find students enrolled in a specific section
  static Future<List<Map<String, dynamic>>> findStudentsInSection(
    String sectionCode,
  ) async {
    try {
      dev.log('🔍 Finding students in section: $sectionCode');

      final querySnapshot =
          await _firestore
              .collection('users')
              .where('selectedSectionCode', isEqualTo: sectionCode)
              .get();

      List<Map<String, dynamic>> students = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        students.add({
          'id': doc.id,
          'studentName':
              data['fullName'] ??
              data['name'] ??
              data['displayName'] ??
              'Unknown',
          'selectedSectionCode': data['selectedSectionCode'],
          'selectedInstructorId': data['selectedInstructorId'],
          'selectedInstructorName': data['selectedInstructorName'],
        });
      }

      dev.log('📋 Found ${students.length} students in section $sectionCode');
      return students;
    } catch (e) {
      dev.log('❌ Error finding students in section: $e');
      return [];
    }
  }

  /// Fix section names for all students in a specific section
  static Future<bool> fixAllStudentsInSection({
    required String sectionCode,
    required String correctSectionName,
    String? correctSectionId,
  }) async {
    try {
      dev.log('🔧 Fixing section names for all students in: $sectionCode');

      final students = await findStudentsInSection(sectionCode);
      if (students.isEmpty) {
        dev.log('⚠️ No students found in section $sectionCode');
        return true;
      }

      int successCount = 0;
      for (var student in students) {
        final success = await fixStudentSectionName(
          studentId: student['id'],
          correctSectionName: correctSectionName,
          correctSectionId: correctSectionId,
        );

        if (success) {
          successCount++;
        }
      }

      dev.log(
        '✅ Fixed section names for $successCount out of ${students.length} students',
      );
      return successCount > 0;
    } catch (e) {
      dev.log('❌ Error fixing all students in section: $e');
      return false;
    }
  }
}
