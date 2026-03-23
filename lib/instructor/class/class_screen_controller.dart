import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'models/class_schedule.dart';
import '../../shared/services/in_app_notification_service.dart';

class ClassController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _log(Object? message) {
    if (kDebugMode) {
      debugPrint('$message');
    }
  }

  var instructorName = ''.obs;
  var classes = <Map<String, dynamic>>[].obs;
  var archivedClasses = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var classStudents = <String, List<Map<String, dynamic>>>{}.obs;

  // Debounce timer to prevent too frequent updates
  Timer? _debounceTimer;

  @override
  void onInit() {
    super.onInit();
    loadInstructor();
    // Load classes once when controller is first created (when screen is first shown)
    // This is NOT auto-loading on every lifecycle change - it only happens once
    loadClasses(); // Load classes once when screen first appears
    // Delete the "4D" class on initialization
    delete4DClass();
  }

  /// Get the currently active period that this instructor is assigned to.
  ///
  /// Queries the `periods` collection for the globally active period, then
  /// verifies the instructor is assigned to it via their `assignedPeriods`
  /// array. Returns clean period metadata to stamp on the created class,
  /// or null if no active period assignment exists.
  Future<Map<String, dynamic>?> _getInstructorActivePeriod(
    String instructorId,
  ) async {
    try {
      // Step 1 – Find the globally active period
      final activePeriodSnapshot =
          await _firestore
              .collection('periods')
              .where('isActive', isEqualTo: true)
              .limit(1)
              .get();

      if (activePeriodSnapshot.docs.isEmpty) return null;

      final activePeriodDoc = activePeriodSnapshot.docs.first;
      final activePeriodId = activePeriodDoc.id;
      final activePeriodData = activePeriodDoc.data();

      // Step 2 – Verify the instructor is assigned to this period
      final instructorDoc =
          await _firestore.collection('instructors').doc(instructorId).get();

      if (!instructorDoc.exists) return null;

      final instructorData = instructorDoc.data() as Map<String, dynamic>;
      final assignedPeriods =
          (instructorData['assignedPeriods'] as List<dynamic>?) ?? [];

      final isAssigned = assignedPeriods.any(
        (p) =>
            (p as Map<String, dynamic>)['periodId']?.toString() ==
            activePeriodId,
      );

      if (!isAssigned) return null;

      // Step 3 – Return period metadata to stamp on the created document
      return {
        'periodId': activePeriodId,
        'semesterName': activePeriodData['semesterName'] ?? '',
        'type': activePeriodData['type'] ?? '',
        'isActive': true,
      };
    } catch (e) {
      debugPrint('ClassController: Error getting instructor active period: $e');
      return null;
    }
  }

  /// Check if a class with the same section already exists
  Future<bool> checkSectionDuplicate(String? sectionId) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null || sectionId == null) return false;

      final QuerySnapshot existingClasses =
          await _firestore
              .collection('instructors')
              .doc(user.uid)
              .collection('classes')
              .where('sectionId', isEqualTo: sectionId)
              .where('isArchived', isEqualTo: false)
              .get();

      return existingClasses.docs.isNotEmpty;
    } catch (e) {
      _log('Error checking section duplicate: $e');
      return false;
    }
  }

  /// Add class to Firestore under logged-in instructor's document
  /// Supports multiple schedules per class
  Future<void> addClass({
    required String section,
    required String course,
    required String room,
    required List<ClassSchedule>
    schedules, // Changed to support multiple schedules
    String? sectionId,
    String? classImageUrl, // Optional custom banner image URL
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        Get.snackbar("Error", "No instructor is logged in.");
        return;
      }

      // Check for duplicate section
      if (sectionId != null) {
        final isDuplicate = await checkSectionDuplicate(sectionId);
        if (isDuplicate) {
          Get.snackbar(
            "Error",
            "A class with this section already exists. Please select a different section or edit the existing class.",
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
          return;
        }
      }

      // Convert schedules to list of maps
      final schedulesData =
          schedules.map((schedule) => schedule.toMap()).toList();

      // Fetch the currently active period this instructor is assigned to
      final activePeriod = await _getInstructorActivePeriod(user.uid);

      final classData = {
        'section': section,
        'course': course,
        'room': room,
        'schedules': schedulesData, // Store as array
        'sectionId': sectionId,
        'createdAt': FieldValue.serverTimestamp(),
        // Stamp active period so the class is tied to the correct semester
        if (activePeriod != null) 'assignedSemester': activePeriod,
      };

      // Add custom image URL if provided
      if (classImageUrl != null && classImageUrl.isNotEmpty) {
        classData['classImageUrl'] = classImageUrl;
      }

      await _firestore
          .collection('instructors')
          .doc(user.uid) // <-- use Firebase user ID
          .collection('classes')
          .add(classData);

      Get.snackbar("Success", "Class created successfully!");
      // Reload classes after creating a new one
      loadClasses();
    } catch (e) {
      Get.snackbar("Error", "Failed to create class: $e");
    }
  }

  /// Update class in Firestore
  /// Supports multiple schedules per class
  Future<void> updateClass({
    required String classId,
    required String section,
    required String course,
    required String room,
    required List<ClassSchedule> schedules,
    String? sectionId,
    String? classImageUrl, // Optional custom banner image URL
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        Get.snackbar("Error", "No instructor is logged in.");
        return;
      }

      // Check for duplicate section (excluding current class)
      if (sectionId != null) {
        final QuerySnapshot existingClasses =
            await _firestore
                .collection('instructors')
                .doc(user.uid)
                .collection('classes')
                .where('sectionId', isEqualTo: sectionId)
                .where('isArchived', isEqualTo: false)
                .get();

        // Check if there's a duplicate that's not the current class
        final hasDuplicate = existingClasses.docs.any(
          (doc) => doc.id != classId,
        );

        if (hasDuplicate) {
          Get.snackbar(
            "Error",
            "A class with this section already exists. Please select a different section.",
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
          return;
        }
      }

      // Convert schedules to list of maps
      final schedulesData =
          schedules.map((schedule) => schedule.toMap()).toList();

      final updateData = {
        'section': section,
        'course': course,
        'room': room,
        'schedules': schedulesData,
        'sectionId': sectionId,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add or update custom image URL if provided
      if (classImageUrl != null && classImageUrl.isNotEmpty) {
        updateData['classImageUrl'] = classImageUrl;
      }

      await _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('classes')
          .doc(classId)
          .update(updateData);

      Get.snackbar("Success", "Class updated successfully!");
      // Reload classes after updating
      loadClasses();
    } catch (e) {
      Get.snackbar("Error", "Failed to update class: $e");
    }
  }

  /// Update class banner image
  Future<void> updateClassBannerImage({
    required String classId,
    String? imageUrl,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        Get.snackbar("Error", "No instructor is logged in.");
        return;
      }

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (imageUrl != null && imageUrl.isNotEmpty) {
        updateData['classImageUrl'] = imageUrl;
      } else {
        // Remove custom image (reset to default)
        updateData['classImageUrl'] = FieldValue.delete();
      }

      await _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('classes')
          .doc(classId)
          .update(updateData);

      Get.snackbar(
        "Success",
        imageUrl != null
            ? "Banner image updated successfully!"
            : "Banner reset to default!",
      );

      // Reload classes to reflect changes
      loadClasses();
    } catch (e) {
      Get.snackbar("Error", "Failed to update banner image: $e");
    }
  }

  /// Load instructor name using FirebaseAuth user.uid
  Future<void> loadInstructor() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        instructorName.value = 'No user logged in';
        return;
      }

      final doc =
          await FirebaseFirestore.instance
              .collection('instructors')
              .doc(user.uid) // 👈 use user.uid here
              .get();

      if (doc.exists) {
        instructorName.value = doc['name'] ?? 'Unknown Instructor';
      } else {
        instructorName.value = 'Instructor not found';
      }
    } catch (e) {
      instructorName.value = 'Error loading name';
    }
  }

  /// Load classes from Firestore for the logged-in instructor
  Future<void> loadClasses() async {
    try {
      isLoading.value = true;
      final User? user = _auth.currentUser;
      if (user == null) {
        Get.snackbar("Error", "No instructor is logged in.");
        return;
      }

      final QuerySnapshot snapshot =
          await _firestore
              .collection('instructors')
              .doc(user.uid)
              .collection('classes')
              .orderBy('createdAt', descending: true)
              .get();

      List<Map<String, dynamic>> activeClasses = [];
      List<Map<String, dynamic>> archivedClassesList = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Handle both old format (single schedule) and new format (multiple schedules)
        List<Map<String, dynamic>> schedules = [];

        if (data.containsKey('schedules') && data['schedules'] is List) {
          // New format: multiple schedules
          schedules = List<Map<String, dynamic>>.from(data['schedules']);
        } else if (data.containsKey('day')) {
          // Old format: single schedule - convert to new format
          schedules = [
            {
              'day': data['day'] ?? '',
              'startTime': data['startTime'] ?? '',
              'endTime': data['endTime'] ?? '',
              'room': data['room'],
            },
          ];
        }

        final classData = {
          'id': doc.id,
          'course': data['course'] ?? '',
          'section': data['section'] ?? '',
          'room': data['room'] ?? '',
          'schedules': schedules, // Store schedules array
          // Keep old fields for backward compatibility in display
          'day': schedules.isNotEmpty ? schedules[0]['day'] : '',
          'startTime': schedules.isNotEmpty ? schedules[0]['startTime'] : '',
          'endTime': schedules.isNotEmpty ? schedules[0]['endTime'] : '',
          'sectionId': data['sectionId'] ?? '',
          'classImageUrl': data['classImageUrl'], // Custom banner image
          'createdAt': data['createdAt'],
          'isArchived': data['isArchived'] ?? false,
          'archivedAt': data['archivedAt'],
        };

        if (classData['isArchived'] == true) {
          archivedClassesList.add(classData);
        } else {
          activeClasses.add(classData);
        }
      }

      classes.value = activeClasses;
      archivedClasses.value = archivedClassesList;

      // Load students for all active classes
      await loadAllClassStudents();
    } catch (e) {
      Get.snackbar("Error", "Failed to load classes: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete class from Firestore
  Future<void> deleteClass(String classId) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        Get.snackbar("Error", "No instructor is logged in.");
        return;
      }

      await _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('classes')
          .doc(classId)
          .delete();

      Get.snackbar("Success", "Class deleted successfully!");
      // Reload classes after deletion
      loadClasses();
    } catch (e) {
      Get.snackbar("Error", "Failed to delete class: $e");
    }
  }

  /// Archive class in Firestore
  Future<void> archiveClass(String classId) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        Get.snackbar("Error", "No instructor is logged in.");
        return;
      }

      await _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('classes')
          .doc(classId)
          .update({
            'isArchived': true,
            'archivedAt': FieldValue.serverTimestamp(),
          });

      Get.snackbar("Success", "Class archived successfully!");
      // Reload classes after archiving
      loadClasses();
    } catch (e) {
      Get.snackbar("Error", "Failed to archive class: $e");
    }
  }

  /// Unarchive class in Firestore
  Future<void> unarchiveClass(String classId) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        Get.snackbar("Error", "No instructor is logged in.");
        return;
      }

      await _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('classes')
          .doc(classId)
          .update({'isArchived': false, 'archivedAt': FieldValue.delete()});

      Get.snackbar("Success", "Class unarchived successfully!");
      // Reload classes after unarchiving
      loadClasses();
    } catch (e) {
      Get.snackbar("Error", "Failed to unarchive class: $e");
    }
  }

  /// Delete the "4D" class specifically
  Future<void> delete4DClass() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        Get.snackbar("Error", "No instructor is logged in.");
        return;
      }

      // Find the class with section "4D"
      final QuerySnapshot snapshot =
          await _firestore
              .collection('instructors')
              .doc(user.uid)
              .collection('classes')
              .where('section', isEqualTo: '4D')
              .get();

      if (snapshot.docs.isEmpty) {
        // No class with section "4D" found - this is expected behavior
        // No need to show error notification
        return;
      }

      // Delete all classes with section "4D"
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        await _firestore
            .collection('instructors')
            .doc(user.uid)
            .collection('classes')
            .doc(doc.id)
            .delete();
      }

      Get.snackbar("Success", "Class '4D' deleted successfully!");
      // Reload classes after deletion
      loadClasses();
    } catch (e) {
      Get.snackbar("Error", "Failed to delete class: $e");
    }
  }

  /// Load students for a specific class
  Future<void> loadStudentsForClass(String classId) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      QuerySnapshot studentsSnapshot =
          await _firestore
              .collection('instructors')
              .doc(user.uid)
              .collection('classes')
              .doc(classId)
              .collection('students')
              .where('isActive', isEqualTo: true)
              .get();

      List<Map<String, dynamic>> students =
          studentsSnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'studentId': data['studentId'] ?? '',
              'studentName': data['studentName'] ?? 'Unknown Student',
              'enrolledAt': data['enrolledAt'],
              'isActive': data['isActive'] ?? true,
            };
          }).toList();

      classStudents[classId] = students;
    } catch (e) {
      _log('Error loading students for class $classId: $e');
    }
  }

  /// Load students for all classes
  Future<void> loadAllClassStudents() async {
    try {
      for (var classData in classes) {
        String classId = classData['id'] ?? '';
        if (classId.isNotEmpty) {
          await loadStudentsForClass(classId);
        }
      }
    } catch (e) {
      _log('Error loading all class students: $e');
    }
  }

  /// Get students for a specific class
  List<Map<String, dynamic>> getStudentsForClass(String classId) {
    return classStudents[classId] ?? [];
  }

  /// Fetch students who have selected this instructor from users collection
  /// If sectionCode is provided, only load students from that specific section
  Future<void> loadStudentsFromUsersCollection({String? sectionCode}) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      List<Map<String, dynamic>> allStudents = [];

      // 1. Load PENDING/REJECTED students from users collection
      Query query = _firestore
          .collection('users')
          .where('selectedInstructorId', isEqualTo: user.uid)
          .where('selectionComplete', isEqualTo: true);

      // If a specific section is requested, filter by that section
      if (sectionCode != null && sectionCode.isNotEmpty) {
        query = query.where('selectedSectionCode', isEqualTo: sectionCode);
      }

      QuerySnapshot studentsSnapshot = await query.get();

      for (QueryDocumentSnapshot doc in studentsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        final enrollmentStatus = data['enrollmentStatus'] ?? 'pending';

        // Only include pending or rejected students from users
        if (enrollmentStatus == 'pending' || enrollmentStatus == 'rejected') {
          allStudents.add({
            'id': doc.id,
            'studentId': doc.id,
            'studentName':
                data['fullName'] ??
                data['name'] ??
                data['displayName'] ??
                'Unknown Student',
            'selectedSectionCode':
                data['selectedSectionCode'] ?? 'Unknown Section',
            'selectedInstructorName':
                data['selectedInstructorName'] ?? 'Unknown Instructor',
            'enrolledAt': data['updatedAt'] ?? FieldValue.serverTimestamp(),
            'isActive': true,
            'enrollmentStatus': enrollmentStatus,
            'isOnline': data['isOnline'] ?? false,
            'lastSeen': data['lastSeen'],
            'corUrl': data['corUrl'] ?? '',
            'source': 'users', // For audit tracking
          });
        }
      }

      // 2. Load APPROVED students from instructors/{instructorId}/students collection
      QuerySnapshot approvedStudentsSnapshot =
          await _firestore
              .collection('instructors')
              .doc(user.uid)
              .collection('students')
              .get();

      for (QueryDocumentSnapshot doc in approvedStudentsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        final studentSection = data['selectedSectionCode'] ?? 'Unknown Section';

        // Filter by section if specified
        if (sectionCode == null ||
            sectionCode.isEmpty ||
            studentSection == sectionCode) {
          allStudents.add({
            'id': doc.id,
            'studentId': data['studentId'] ?? doc.id,
            'studentName': data['studentName'] ?? 'Unknown Student',
            'email': data['email'] ?? '',
            'selectedSectionCode': studentSection,
            'selectedInstructorName':
                data['approvedByInstructor'] ?? 'Unknown Instructor',
            'enrolledAt': data['enrolledAt'],
            'approvedAt': data['approvedAt'],
            'isActive': data['isActive'] ?? true,
            'enrollmentStatus': 'approved',
            'isOnline': data['isOnline'] ?? false,
            'lastSeen': data['lastSeen'],
            'corUrl': data['corUrl'] ?? '',
            'source': 'instructor_students', // For audit tracking
          });
        }
      }

      // Group students by section
      Map<String, List<Map<String, dynamic>>> studentsBySection = {};
      for (var student in allStudents) {
        String section = student['selectedSectionCode'];
        if (!studentsBySection.containsKey(section)) {
          studentsBySection[section] = [];
        }
        studentsBySection[section]!.add(student);
      }

      // Update classStudents with the fetched data
      classStudents.clear();
      classStudents.addAll(studentsBySection);

      _log(
        'Loaded ${allStudents.length} students (pending/rejected from users, approved from instructor/students)${sectionCode != null ? ' for section $sectionCode' : ''}',
      );
    } catch (e) {
      _log('Error loading students from users collection: $e');
    }
  }

  /// Get students for a specific section
  List<Map<String, dynamic>> getStudentsForSection(String sectionCode) {
    return classStudents[sectionCode] ?? [];
  }

  /// Get all students who selected this instructor
  List<Map<String, dynamic>> getAllStudents() {
    List<Map<String, dynamic>> allStudents = [];
    for (var students in classStudents.values) {
      allStudents.addAll(students);
    }
    return allStudents;
  }

  /// Approve a student's enrollment
  Future<bool> approveStudentEnrollment({
    required String studentId,
    required String sectionCode,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return false;

      _log('=== APPROVING STUDENT: $studentId ===');
      _log('Instructor: ${user.uid}');
      _log('Section: $sectionCode');
      _log('Timestamp: ${DateTime.now()}');

      // Update student status in the users collection with additional fields
      await _firestore.collection('users').doc(studentId).update({
        'enrollmentStatus': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': user.uid,
        'approvedByInstructor': instructorName.value,
        'lastStatusUpdate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _log('✅ Student $studentId status updated to approved in Firestore');
      _log('✅ Firestore update completed at: ${DateTime.now()}');

      // Verify the update was successful
      final updatedDoc =
          await _firestore.collection('users').doc(studentId).get();
      if (updatedDoc.exists) {
        final updatedData = updatedDoc.data() as Map<String, dynamic>;
        _log(
          '✅ Verification: enrollmentStatus = ${updatedData['enrollmentStatus']}',
        );
      }

      // Also update the student's online status to true when approved
      await _firestore.collection('users').doc(studentId).update({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });

      _log('✅ Student $studentId online status set to true');

      // Get instructor name (used for notification)
      final instructorNameValue =
          instructorName.value.isNotEmpty
              ? instructorName.value
              : user.displayName ?? 'Your instructor';

      // Get student data from users collection
      final studentDoc =
          await _firestore.collection('users').doc(studentId).get();
      if (studentDoc.exists) {
        final studentData = studentDoc.data() as Map<String, dynamic>;
        final studentName =
            studentData['fullName'] ??
            studentData['name'] ??
            studentData['displayName'] ??
            'Unknown Student';

        // Create student document in instructors/{instructorId}/students collection
        await _firestore
            .collection('instructors')
            .doc(user.uid)
            .collection('students')
            .doc(studentId)
            .set({
              'studentId': studentId,
              'studentName': studentName,
              'email': studentData['email'] ?? '',
              'idNumber': studentData['idNumber'] ?? studentData['studentIdNumber'] ?? '',
              'selectedSectionCode': studentData['selectedSectionCode'] ?? '',
              'corUrl': studentData['corUrl'] ?? '',
              'enrollmentStatus': 'approved',
              'enrolledAt': FieldValue.serverTimestamp(),
              'approvedAt': FieldValue.serverTimestamp(),
              'approvedBy': user.uid,
              'approvedByInstructor': instructorName.value,
              'isActive': true,
              'isOnline': true,
              'lastSeen': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

        _log(
          '✅ Student document created in instructors/{instructorId}/students',
        );

        // Send push notification to student about approval
        try {
          await InAppNotificationService.createIndividualNotification(
            type: 'enrollment_approved',
            instructorId: user.uid,
            instructorName: instructorNameValue,
            itemId: sectionCode, // Use section code as itemId
            title:
                'Your enrollment request has been approved by $instructorNameValue. You can now access the dashboard.',
            targetUserIds: [studentId],
            description:
                'Your enrollment request has been approved by $instructorNameValue. You can now access the dashboard.',
            metadata: {
              'sectionCode': sectionCode,
              'studentId': studentId,
              'studentName': studentName,
              'approvedAt': DateTime.now().toIso8601String(),
            },
          );

          _log('✅ Push notification sent to student: $studentId');
        } catch (e) {
          _log('⚠️ Error sending approval notification: $e');
          // Don't fail the approval if notification fails
        }
      }

      // Update local data - search through all sections
      for (String section in classStudents.keys) {
        final students = classStudents[section]!;
        final studentIndex = students.indexWhere(
          (s) => s['studentId'] == studentId,
        );
        if (studentIndex != -1) {
          students[studentIndex]['enrollmentStatus'] = 'approved';
          students[studentIndex]['approvedAt'] = DateTime.now();
          students[studentIndex]['approvedBy'] = user.uid;
          students[studentIndex]['isOnline'] = true;
          students[studentIndex]['lastSeen'] = DateTime.now();
          break;
        }
      }

      // Force refresh the UI
      classStudents.refresh();

      _log('✅ Local data updated and UI refreshed');

      Get.snackbar(
        'Success',
        'Student enrollment approved successfully! Student will be redirected to dashboard.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      _log('=== APPROVAL COMPLETE FOR STUDENT: $studentId ===');
      return true;
    } catch (e) {
      _log('❌ Error approving student $studentId: $e');
      Get.snackbar(
        'Error',
        'Failed to approve student enrollment: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  /// Reject a student's enrollment
  Future<bool> rejectStudentEnrollment({
    required String studentId,
    required String sectionCode,
    String? reason,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return false;

      // Get instructor name (used for notification)
      final instructorNameValue =
          instructorName.value.isNotEmpty
              ? instructorName.value
              : user.displayName ?? 'Your instructor';

      // Build rejection reason
      final rejectionReason = reason ?? 'No reason provided';

      // Update student status in the users collection
      await _firestore.collection('users').doc(studentId).update({
        'enrollmentStatus': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': user.uid,
        'rejectionReason': rejectionReason,
      });

      // Get student data for notification
      try {
        final studentDoc =
            await _firestore.collection('users').doc(studentId).get();
        if (studentDoc.exists) {
          final studentData = studentDoc.data() as Map<String, dynamic>;
          final studentName =
              studentData['fullName'] ??
              studentData['name'] ??
              studentData['displayName'] ??
              'Student';

          // Build rejection message
          final rejectionMessage =
              rejectionReason.isNotEmpty &&
                      rejectionReason != 'No reason provided'
                  ? 'Your enrollment request has been rejected by $instructorNameValue. Reason: $rejectionReason'
                  : 'Your enrollment request has been rejected by $instructorNameValue.';

          // Send push notification to student about rejection
          await InAppNotificationService.createIndividualNotification(
            type: 'enrollment_rejected',
            instructorId: user.uid,
            instructorName: instructorNameValue,
            itemId: sectionCode, // Use section code as itemId
            title: rejectionMessage,
            targetUserIds: [studentId],
            description: rejectionMessage,
            metadata: {
              'sectionCode': sectionCode,
              'studentId': studentId,
              'studentName': studentName,
              'rejectionReason': rejectionReason,
              'rejectedAt': DateTime.now().toIso8601String(),
            },
          );

          _log('✅ Push notification sent to student: $studentId');
        }
      } catch (e) {
        _log('⚠️ Error sending rejection notification: $e');
        // Don't fail the rejection if notification fails
      }

      // Update local data - search through all sections
      for (String section in classStudents.keys) {
        final students = classStudents[section]!;
        final studentIndex = students.indexWhere(
          (s) => s['studentId'] == studentId,
        );
        if (studentIndex != -1) {
          students[studentIndex]['enrollmentStatus'] = 'rejected';
          students[studentIndex]['rejectedAt'] = DateTime.now();
          students[studentIndex]['rejectedBy'] = user.uid;
          students[studentIndex]['rejectionReason'] = rejectionReason;
          break;
        }
      }

      // Force refresh the UI
      classStudents.refresh();

      Get.snackbar(
        'Success',
        'Student enrollment rejected successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to reject student enrollment: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  /// Get students by enrollment status
  List<Map<String, dynamic>> getStudentsByStatus(
    String sectionCode,
    String status,
  ) {
    final students = getStudentsForSection(sectionCode);
    return students
        .where(
          (student) => (student['enrollmentStatus'] ?? 'pending') == status,
        )
        .toList();
  }

  /// Get enrollment statistics for a section
  Map<String, int> getEnrollmentStats(String sectionCode) {
    final students = getStudentsForSection(sectionCode);
    final stats = {
      'total': students.length,
      'pending': 0,
      'approved': 0,
      'rejected': 0,
    };

    for (var student in students) {
      final status = student['enrollmentStatus'] ?? 'pending';
      if (stats.containsKey(status)) {
        stats[status] = stats[status]! + 1;
      }
    }

    return stats;
  }

  /// Update student's online status
  Future<void> updateStudentOnlineStatus(
    String studentId,
    bool isOnline,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Update in users collection
      await _firestore.collection('users').doc(studentId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });

      // Update local data
      for (var sectionCode in classStudents.keys) {
        final students = classStudents[sectionCode]!;
        final studentIndex = students.indexWhere(
          (s) => s['studentId'] == studentId,
        );
        if (studentIndex != -1) {
          students[studentIndex]['isOnline'] = isOnline;
          students[studentIndex]['lastSeen'] = DateTime.now();
          classStudents.refresh();
        }
      }
    } catch (e) {
      _log('Error updating student online status: $e');
    }
  }

  /// Set up real-time listener for student online status
  void setupStudentStatusListener(String sectionCode) {
    final students = getStudentsForSection(sectionCode);

    for (var student in students) {
      final studentId = student['studentId'];
      if (studentId != null) {
        // Listen to users collection first
        _firestore
            .collection('users')
            .doc(studentId)
            .snapshots()
            .listen((snapshot) {
              if (snapshot.exists) {
                final data = snapshot.data() as Map<String, dynamic>;
                final isOnline = data['isOnline'] ?? false;
                final lastSeen = data['lastSeen'];

                // Update local data safely
                _updateStudentStatus(studentId, isOnline, lastSeen);
              }
            })
            .onError((error) {
              _log(
                'Error listening to users collection for $studentId: $error',
              );
              // If user not found in users collection, try instructors collection
              _firestore
                  .collection('instructors')
                  .doc(studentId)
                  .snapshots()
                  .listen((snapshot) {
                    if (snapshot.exists) {
                      final data = snapshot.data() as Map<String, dynamic>;
                      final isOnline = data['isOnline'] ?? false;
                      final lastSeen = data['lastSeen'];

                      // Update local data safely
                      _updateStudentStatus(studentId, isOnline, lastSeen);
                    }
                  })
                  .onError((error2) {
                    _log(
                      'Error listening to instructors collection for $studentId: $error2',
                    );
                  });
            });
      }
    }
  }

  /// Safely update student status to avoid GetX errors
  void _updateStudentStatus(String studentId, bool isOnline, dynamic lastSeen) {
    try {
      // Check if controller is still active
      if (!isClosed) {
        // Find the student in all sections
        for (var sectionCode in classStudents.keys) {
          final students = classStudents[sectionCode];
          if (students != null) {
            final studentIndex = students.indexWhere(
              (s) => s['studentId'] == studentId,
            );
            if (studentIndex != -1) {
              // Update the student data
              students[studentIndex]['isOnline'] = isOnline;
              students[studentIndex]['lastSeen'] = lastSeen;
            }
          }
        }

        // Debounce UI refresh to prevent too frequent updates
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 100), () {
          if (!isClosed && classStudents.isNotEmpty) {
            classStudents.refresh();
          }
        });
      }
    } catch (e) {
      _log('Error updating student status: $e');
    }
  }

  /// Get online status for a student
  bool isStudentOnline(Map<String, dynamic> student) {
    final isOnline = student['isOnline'] ?? false;
    final lastSeen = student['lastSeen'];

    if (isOnline) return true;

    // Consider offline if last seen is more than 1 minute ago
    if (lastSeen != null) {
      try {
        DateTime lastSeenTime;
        if (lastSeen is DateTime) {
          lastSeenTime = lastSeen;
        } else if (lastSeen is Timestamp) {
          lastSeenTime = lastSeen.toDate();
        } else {
          return false;
        }

        final now = DateTime.now();
        final difference = now.difference(lastSeenTime).inMinutes;
        return difference <= 1; // Online if last seen within 1 minute
      } catch (e) {
        return false;
      }
    }

    return false;
  }

  /// Get formatted last seen time
  String getLastSeenTime(Map<String, dynamic> student) {
    final lastSeen = student['lastSeen'];
    if (lastSeen == null) return 'Never';

    try {
      DateTime lastSeenTime;
      if (lastSeen is DateTime) {
        lastSeenTime = lastSeen;
      } else if (lastSeen is Timestamp) {
        lastSeenTime = lastSeen.toDate();
      } else {
        return 'Unknown';
      }

      final now = DateTime.now();
      final difference = now.difference(lastSeenTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Refresh student status for a specific section
  Future<void> refreshStudentStatus(String sectionCode) async {
    try {
      final students = getStudentsForSection(sectionCode);

      for (var student in students) {
        final studentId = student['studentId'];
        if (studentId != null) {
          // Try to get current status from users collection
          try {
            final userDoc =
                await _firestore.collection('users').doc(studentId).get();
            if (userDoc.exists) {
              final data = userDoc.data() as Map<String, dynamic>;
              final isOnline = data['isOnline'] ?? false;
              final lastSeen = data['lastSeen'];

              // Update local data safely
              _updateStudentStatus(studentId, isOnline, lastSeen);
            }
          } catch (e) {
            // If user not found in users collection, try instructors collection
            try {
              final instructorDoc =
                  await _firestore
                      .collection('instructors')
                      .doc(studentId)
                      .get();
              if (instructorDoc.exists) {
                final data = instructorDoc.data() as Map<String, dynamic>;
                final isOnline = data['isOnline'] ?? false;
                final lastSeen = data['lastSeen'];

                // Update local data safely
                _updateStudentStatus(studentId, isOnline, lastSeen);
              }
            } catch (e2) {
              _log('Error refreshing status for student $studentId: $e2');
            }
          }
        }
      }

      // Refresh the UI safely only if controller is still active
      if (!isClosed && classStudents.isNotEmpty) {
        classStudents.refresh();
      }
    } catch (e) {
      _log('Error refreshing student status: $e');
    }
  }

  /// Debug method to simulate student online status (for testing)
  Future<void> simulateStudentStatus(String studentId, bool isOnline) async {
    try {
      await _firestore.collection('users').doc(studentId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
      _log(
        'Simulated student $studentId status: ${isOnline ? "Online" : "Offline"}',
      );
    } catch (e) {
      _log('Error simulating student status: $e');
    }
  }

  /// Clean up resources when controller is disposed
  @override
  void onClose() {
    // Cancel debounce timer
    _debounceTimer?.cancel();
    // Clear all student data
    classStudents.clear();
    super.onClose();
  }
}
