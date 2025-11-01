import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;

/// Service responsible for automatically routing student submissions
/// to the correct instructor's activity section
class SubmissionRoutingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Routes a submission to the correct instructor's activity section
  /// This ensures submissions appear in the instructor's corresponding activity view
  static Future<Map<String, dynamic>> routeSubmission({
    required String activityId,
    required String submissionType, // 'activity', 'assignment', 'quiz', 'pit'
    required Map<String, dynamic> submissionData,
  }) async {
    try {
      dev.log('🔄 Starting submission routing for activity: $activityId');

      // Find the activity in all instructor collections
      final activityInfo = await _findActivityInstructor(
        activityId,
        submissionType,
      );

      if (activityInfo == null) {
        throw Exception('Activity not found in any instructor collection');
      }

      dev.log(
        '📍 Found activity in instructor: ${activityInfo['instructorId']}',
      );
      dev.log('📍 Activity title: ${activityInfo['title']}');
      dev.log('📍 Selected classes: ${activityInfo['selectedClasses']}');

      // Update submission data with correct routing information
      final routedSubmissionData = {
        ...submissionData,
        'activityId': activityId, // Unified activity ID field
        'activityType':
            submissionType
                .toLowerCase(), // Unified activity type ('assignment', 'activity', 'quiz', 'pit')
        'instructorId': activityInfo['instructorId'],
        'instructorName': activityInfo['instructorName'],
        'activityTitle': activityInfo['title'],
        'routedAt': FieldValue.serverTimestamp(),
        'routingStatus': 'success',
        // Add assigned semester if available
        if (activityInfo['assignedSemester'] != null)
          'assignedSemester': activityInfo['assignedSemester'],
      };

      // Determine the correct section based on student's class
      final sectionInfo = await _determineStudentSection(
        activityInfo['selectedClasses'] as List<String>,
        submissionData['studentId'] as String,
      );

      if (sectionInfo != null) {
        routedSubmissionData['sectionId'] = sectionInfo['sectionId'];
        routedSubmissionData['sectionName'] = sectionInfo['sectionName'];
        dev.log(
          '📍 Student assigned to section: ${sectionInfo['sectionName']}',
        );
      }

      // Save the routed submission to unified submissions collection
      // Add activityType to submission data
      routedSubmissionData['activityType'] = submissionType.toLowerCase();

      final docRef = await _firestore
          .collection('submissions')
          .add(routedSubmissionData);

      dev.log(
        '✅ Submission routed successfully to unified submissions collection',
      );
      dev.log('✅ Submission ID: ${docRef.id}');
      dev.log('✅ Activity Type: ${submissionType.toLowerCase()}');

      // Trigger real-time update for instructor
      await _notifyInstructorOfNewSubmission(
        activityInfo['instructorId'],
        activityId,
        docRef.id,
        submissionType,
      );

      return {
        'success': true,
        'submissionId': docRef.id,
        'instructorId': activityInfo['instructorId'],
        'sectionId': sectionInfo?['sectionId'],
        'message': 'Submission routed successfully',
      };
    } catch (e) {
      dev.log('❌ Error routing submission: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to route submission',
      };
    }
  }

  /// Routes a submission using ONLY the student's selected section
  /// regardless of the activity's selected classes. This is useful when
  /// the product requirement is: "student always submits to their own
  /// section for the instructor who owns the activity".
  static Future<Map<String, dynamic>> routeSubmissionForStudentSection({
    required String activityId,
    required String submissionType, // 'activity', 'assignment', 'quiz', 'pit'
    required Map<String, dynamic> submissionData,
  }) async {
    try {
      dev.log(
        '🔄 Starting student-section-first routing for activity: $activityId',
      );

      // Find the activity owner (instructor)
      final activityInfo = await _findActivityInstructor(
        activityId,
        submissionType,
      );

      if (activityInfo == null) {
        throw Exception('Activity not found in any instructor collection');
      }

      // Base routed payload
      final routedSubmissionData = {
        ...submissionData,
        'activityId': activityId, // Unified activity ID field
        'activityType':
            submissionType
                .toLowerCase(), // Unified activity type ('assignment', 'activity', 'quiz', 'pit')
        'instructorId': activityInfo['instructorId'],
        'instructorName': activityInfo['instructorName'],
        'activityTitle': activityInfo['title'],
        'routedAt': FieldValue.serverTimestamp(),
        'routingStatus': 'success',
        // Add assigned semester if available
        if (activityInfo['assignedSemester'] != null)
          'assignedSemester': activityInfo['assignedSemester'],
      };

      // Determine section strictly from student's profile, then map to
      // the instructor's classes to get a concrete sectionId if possible
      final sectionInfo = await _determineSectionFromStudentOnly(
        submissionData['studentId'] as String,
        activityInfo['instructorId'] as String,
      );

      if (sectionInfo != null) {
        routedSubmissionData['sectionId'] = sectionInfo['sectionId'];
        routedSubmissionData['sectionName'] = sectionInfo['sectionName'];
        dev.log('📍 Routed by student section: ${sectionInfo['sectionName']}');
      }

      // Save to unified submissions collection
      // Add activityType to submission data
      routedSubmissionData['activityType'] = submissionType.toLowerCase();

      final docRef = await _firestore
          .collection('submissions')
          .add(routedSubmissionData);

      await _notifyInstructorOfNewSubmission(
        activityInfo['instructorId'],
        activityId,
        docRef.id,
        submissionType,
      );

      return {
        'success': true,
        'submissionId': docRef.id,
        'instructorId': activityInfo['instructorId'],
        'sectionId': sectionInfo?['sectionId'],
        'message': 'Submission routed using student section successfully',
      };
    } catch (e) {
      dev.log('❌ Error in student-section-first routing: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to route submission using student section',
      };
    }
  }

  /// Finds which instructor created the activity
  static Future<Map<String, dynamic>?> _findActivityInstructor(
    String activityId,
    String submissionType,
  ) async {
    try {
      // Get all instructors
      final instructorsQuery = await _firestore.collection('instructors').get();

      for (var instructorDoc in instructorsQuery.docs) {
        final instructorId = instructorDoc.id;
        final instructorData = instructorDoc.data();

        // Check the appropriate collection based on submission type
        String collectionName = _getActivityCollectionName(submissionType);

        try {
          final activityDoc =
              await _firestore
                  .collection('instructors')
                  .doc(instructorId)
                  .collection(collectionName)
                  .doc(activityId)
                  .get();

          if (activityDoc.exists) {
            final activityData = activityDoc.data()!;
            // Safely cast selectedClasses from List<dynamic> to List<String>
            final selectedClasses =
                (activityData['selectedClasses'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                <String>[];

            // Extract assignedSemester if it exists
            final assignedSemester =
                activityData['assignedSemester'] as Map<String, dynamic>?;

            return {
              'instructorId': instructorId,
              'instructorName': instructorData['name'] ?? 'Unknown Instructor',
              'title': activityData['title'],
              'type': activityData['type'],
              'selectedClasses': selectedClasses,
              'assignedSemester': assignedSemester,
            };
          }
        } catch (e) {
          // Continue searching if this instructor doesn't have the activity
          continue;
        }
      }

      return null;
    } catch (e) {
      dev.log('❌ Error finding activity instructor: $e');
      return null;
    }
  }

  /// Determines which section a student belongs to based on their class
  static Future<Map<String, dynamic>?> _determineStudentSection(
    List<String> activityClasses,
    String studentId,
  ) async {
    try {
      // Get student's class information
      final studentDoc =
          await _firestore.collection('users').doc(studentId).get();
      if (!studentDoc.exists) return null;

      final studentData = studentDoc.data()!;

      // Try multiple fields for student's section/class information
      final studentClass =
          studentData['selectedSectionCode'] ??
          studentData['sectionCode'] ??
          studentData['class'] ??
          studentData['section'];

      if (studentClass == null) return null;

      dev.log('🔍 Student class: $studentClass');
      dev.log('🔍 Activity classes: $activityClasses');

      // Find matching section with improved matching logic
      for (String activityClass in activityClasses) {
        dev.log('🔍 Checking activity class: $activityClass');

        // Normalize both class names for better matching
        final normalizedStudentClass = studentClass.toLowerCase().replaceAll(
          ' ',
          '',
        );
        final normalizedActivityClass = activityClass.toLowerCase().replaceAll(
          ' ',
          '',
        );

        // Check for various matching patterns
        bool isMatch = false;

        // Direct match
        if (normalizedStudentClass == normalizedActivityClass) {
          isMatch = true;
        }
        // Contains match (e.g., "bsit4d" contains "bsit")
        else if (normalizedStudentClass.contains(normalizedActivityClass) ||
            normalizedActivityClass.contains(normalizedStudentClass)) {
          isMatch = true;
        }
        // Special case for BSIT 4D variations
        else if (_isBSIT4DMatch(
          normalizedStudentClass,
          normalizedActivityClass,
        )) {
          isMatch = true;
        }
        // Course code match (e.g., "BSIT 4D" matches "BSIT-A" by course)
        else if (_isSameCourse(
          normalizedStudentClass,
          normalizedActivityClass,
        )) {
          isMatch = true;
        }

        if (isMatch) {
          dev.log(
            '✅ Found matching class: $activityClass for student: $studentClass',
          );

          // Try to find the section details from instructor's classes
          final instructorId = await _findInstructorForStudent(studentId);
          if (instructorId != null) {
            final sectionInfo = await _findSectionInInstructorClasses(
              instructorId,
              activityClass,
            );
            if (sectionInfo != null) {
              return sectionInfo;
            }
          }

          // Try to find the section details from sections collection
          final sectionsQuery =
              await _firestore
                  .collection('sections')
                  .where('name', isEqualTo: activityClass)
                  .limit(1)
                  .get();

          if (sectionsQuery.docs.isNotEmpty) {
            final sectionData = sectionsQuery.docs.first.data();
            return {
              'sectionId': sectionsQuery.docs.first.id,
              'sectionName': sectionData['name'],
            };
          }

          // If no section found, create a basic section info
          return {
            'sectionId':
                'temp_${activityClass.replaceAll(' ', '_').toLowerCase()}',
            'sectionName': activityClass,
          };
        }
      }

      // Default fallback - assign to first available activity class
      if (activityClasses.isNotEmpty) {
        dev.log(
          '⚠️ No exact match found, using first activity class as fallback: ${activityClasses.first}',
        );
        return {
          'sectionId':
              'temp_${activityClasses.first.replaceAll(' ', '_').toLowerCase()}',
          'sectionName': activityClasses.first,
        };
      }

      dev.log('⚠️ No activity classes available, using default section');
      return {'sectionId': 'default_section', 'sectionName': 'Default Section'};
    } catch (e) {
      dev.log('❌ Error determining student section: $e');
      return null;
    }
  }

  /// Determines section using ONLY student's selected section and maps it
  /// to the instructor's classes or sections collection for a concrete id
  static Future<Map<String, dynamic>?> _determineSectionFromStudentOnly(
    String studentId,
    String instructorId,
  ) async {
    try {
      final studentDoc =
          await _firestore.collection('users').doc(studentId).get();
      if (!studentDoc.exists) return null;

      final studentData = studentDoc.data()!;
      final studentClass =
          studentData['selectedSectionCode'] ??
          studentData['sectionCode'] ??
          studentData['class'] ??
          studentData['section'];

      if (studentClass == null) return null;

      // First try to map to an instructor class doc to get a sectionId
      final mapped = await _findSectionInInstructorClasses(
        instructorId,
        studentClass.toString(),
      );
      if (mapped != null) return mapped;

      // Try sections collection
      final sectionsQuery =
          await _firestore
              .collection('sections')
              .where('name', isEqualTo: studentClass)
              .limit(1)
              .get();
      if (sectionsQuery.docs.isNotEmpty) {
        final sectionData = sectionsQuery.docs.first.data();
        return {
          'sectionId': sectionsQuery.docs.first.id,
          'sectionName': sectionData['name'],
        };
      }

      // Fallback basic info
      return {
        'sectionId':
            'temp_${studentClass.toString().replaceAll(' ', '_').toLowerCase()}',
        'sectionName': studentClass.toString(),
      };
    } catch (e) {
      dev.log('❌ Error determining section from student only: $e');
      return null;
    }
  }

  /// Find instructor for a student based on their selection
  static Future<String?> _findInstructorForStudent(String studentId) async {
    try {
      final studentDoc =
          await _firestore.collection('users').doc(studentId).get();
      if (!studentDoc.exists) return null;

      final studentData = studentDoc.data()!;
      return studentData['selectedInstructorId'] as String?;
    } catch (e) {
      dev.log('❌ Error finding instructor for student: $e');
      return null;
    }
  }

  /// Find section information in instructor's classes
  static Future<Map<String, dynamic>?> _findSectionInInstructorClasses(
    String instructorId,
    String sectionName,
  ) async {
    try {
      final classesQuery =
          await _firestore
              .collection('instructors')
              .doc(instructorId)
              .collection('classes')
              .where('section', isEqualTo: sectionName)
              .limit(1)
              .get();

      if (classesQuery.docs.isNotEmpty) {
        final classData = classesQuery.docs.first.data();
        return {
          'sectionId': classesQuery.docs.first.id,
          'sectionName': classData['section'],
        };
      }

      return null;
    } catch (e) {
      dev.log('❌ Error finding section in instructor classes: $e');
      return null;
    }
  }

  /// Notifies instructor of new submission via real-time update
  static Future<void> _notifyInstructorOfNewSubmission(
    String instructorId,
    String activityId,
    String submissionId,
    String submissionType,
  ) async {
    try {
      // Create a notification document for real-time updates
      await _firestore
          .collection('instructors')
          .doc(instructorId)
          .collection('notifications')
          .add({
            'type': 'new_submission',
            'activityId': activityId,
            'submissionId': submissionId,
            'submissionType': submissionType,
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
          });

      dev.log('📢 Notification sent to instructor: $instructorId');
    } catch (e) {
      dev.log('❌ Error sending notification: $e');
    }
  }

  /// Gets the appropriate collection name for submission type
  /// NOTE: Now all submissions use unified 'submissions' collection
  /// This method is kept for backwards compatibility but always returns 'submissions'
  @Deprecated('Use unified submissions collection directly')
  static String _getSubmissionCollectionName(String submissionType) {
    return 'submissions'; // Unified collection for all submission types
  }

  /// Gets the appropriate collection name for activity type
  static String _getActivityCollectionName(String submissionType) {
    switch (submissionType.toLowerCase()) {
      case 'assignment':
        return 'assignments';
      case 'activity':
        return 'activities';
      case 'quiz':
        return 'quizzes';
      case 'pit':
        return 'pits';
      default:
        return 'activities';
    }
  }

  /// Gets real-time updates for instructor submissions
  static Stream<QuerySnapshot> getSubmissionUpdates(
    String instructorId,
    String activityId,
    String submissionType,
  ) {
    return _firestore
        .collection('submissions')
        .where('instructorId', isEqualTo: instructorId)
        .where('activityType', isEqualTo: submissionType.toLowerCase())
        .where('activityId', isEqualTo: activityId)
        .orderBy('submittedAt', descending: true)
        .snapshots();
  }

  /// Gets real-time updates for instructor notifications
  static Stream<QuerySnapshot> getNotificationUpdates(String instructorId) {
    return _firestore
        .collection('instructors')
        .doc(instructorId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Helper method to check if two class names belong to the same course
  /// e.g., "BSIT 4D" and "BSIT-A" both belong to BSIT course
  static bool _isSameCourse(String class1, String class2) {
    // Extract course codes (e.g., "BSIT" from "BSIT 4D" or "BSIT-A")
    final course1 = _extractCourseCode(class1);
    final course2 = _extractCourseCode(class2);

    return course1.isNotEmpty && course2.isNotEmpty && course1 == course2;
  }

  /// Helper method to extract course code from class name
  /// e.g., "BSIT 4D" -> "BSIT", "BSIT-A" -> "BSIT"
  static String _extractCourseCode(String className) {
    // Remove spaces and convert to uppercase
    final normalized = className.toUpperCase().replaceAll(' ', '');

    // Extract alphabetic part (course code)
    final match = RegExp(r'^([A-Z]+)').firstMatch(normalized);
    return match?.group(1) ?? '';
  }

  /// Helper method to check if two class names match BSIT 4D variations
  /// Handles different formats like "BSIT 4D", "BSIT-4D", "bsit4d", "4D", etc.
  static bool _isBSIT4DMatch(String class1, String class2) {
    // Normalize both classes to handle various formats
    final normalized1 = class1.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    final normalized2 = class2.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );

    // Check for BSIT 4D patterns
    final bsit4dPatterns = ['bsit4d', 'bsit4d', '4d', 'bsit4'];

    // Check if either class matches BSIT 4D patterns
    bool class1IsBSIT4D = bsit4dPatterns.any(
      (pattern) =>
          normalized1.contains(pattern) || pattern.contains(normalized1),
    );
    bool class2IsBSIT4D = bsit4dPatterns.any(
      (pattern) =>
          normalized2.contains(pattern) || pattern.contains(normalized2),
    );

    // If both are BSIT 4D variations, they match
    if (class1IsBSIT4D && class2IsBSIT4D) {
      return true;
    }

    // If one is BSIT 4D and the other contains "bsit" and "4" or "d"
    if (class1IsBSIT4D &&
        (normalized2.contains('bsit') &&
            (normalized2.contains('4') || normalized2.contains('d')))) {
      return true;
    }
    if (class2IsBSIT4D &&
        (normalized1.contains('bsit') &&
            (normalized1.contains('4') || normalized1.contains('d')))) {
      return true;
    }

    return false;
  }
}
