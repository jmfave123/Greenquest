import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/instructor_assignment_model.dart';

class InstructorClassService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get section codes from instructor's assignments
  /// Returns list of unique section codes that instructor has created content for
  static Future<List<String>> getInstructorSectionCodes() async {
    try {
      // 1. Get current instructor ID
      final user = _auth.currentUser;
      if (user == null) return [];

      // 2. Get instructor document and read assignments array
      final instructorDoc =
          await _firestore.collection('instructors').doc(user.uid).get();

      if (!instructorDoc.exists) return [];

      final assignments =
          (instructorDoc.data()!['assignments'] as List? ?? [])
              .whereType<Map<String, dynamic>>()
              .map(InstructorAssignment.fromMap)
              .toList();

      // 3. Extract sectionCodes from typed assignments
      final uniqueSectionCodes =
          assignments
              .map((a) => a.sectionCode)
              .where((code) => code.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

      return uniqueSectionCodes;
    } catch (e) {
      return [];
    }
  }

  /// Get section codes from all instructor's content (assignments, activities, quizzes, PITs)
  /// This provides a more comprehensive view of sections instructor has worked with
  static Future<List<String>> getAllInstructorSectionCodes() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final sectionCodes = <String>[];

      // Query assignments
      final assignmentsSnapshot =
          await _firestore
              .collection('instructors')
              .doc(user.uid)
              .collection('assignments')
              .get();

      for (var doc in assignmentsSnapshot.docs) {
        final sectionCode = doc.data()['sectionCode'] as String?;
        if (sectionCode != null && sectionCode.isNotEmpty) {
          sectionCodes.add(sectionCode);
        }
      }

      // Query activities
      final activitiesSnapshot =
          await _firestore
              .collection('instructors')
              .doc(user.uid)
              .collection('activities')
              .get();

      for (var doc in activitiesSnapshot.docs) {
        final sectionCode = doc.data()['sectionCode'] as String?;
        if (sectionCode != null && sectionCode.isNotEmpty) {
          sectionCodes.add(sectionCode);
        }
      }

      // Query quizzes
      final quizzesSnapshot =
          await _firestore
              .collection('instructors')
              .doc(user.uid)
              .collection('quizzes')
              .get();

      for (var doc in quizzesSnapshot.docs) {
        final sectionCode = doc.data()['sectionCode'] as String?;
        if (sectionCode != null && sectionCode.isNotEmpty) {
          sectionCodes.add(sectionCode);
        }
      }

      // Query PITs
      final pitsSnapshot =
          await _firestore
              .collection('instructors')
              .doc(user.uid)
              .collection('pits')
              .get();

      for (var doc in pitsSnapshot.docs) {
        final sectionCode = doc.data()['sectionCode'] as String?;
        if (sectionCode != null && sectionCode.isNotEmpty) {
          sectionCodes.add(sectionCode);
        }
      }

      // Remove duplicates and sort
      final uniqueSectionCodes = sectionCodes.toSet().toList()..sort();

      return uniqueSectionCodes;
    } catch (e) {
      return [];
    }
  }

  /// Fallback method - returns static classes if dynamic loading fails
  static List<String> getFallbackClasses() {
    return ['BSIT-A', 'BSIT-B', 'BSIT-C'];
  }
}
