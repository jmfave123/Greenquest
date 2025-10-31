import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'models/class_schedule.dart';

class ClassController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
    loadClasses();
    // Delete the "4D" class on initialization
    delete4DClass();
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
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        Get.snackbar("Error", "No instructor is logged in.");
        return;
      }

      // Convert schedules to list of maps
      final schedulesData =
          schedules.map((schedule) => schedule.toMap()).toList();

      await _firestore
          .collection('instructors')
          .doc(user.uid) // <-- use Firebase user ID
          .collection('classes')
          .add({
            'section': section,
            'course': course,
            'room': room,
            'schedules': schedulesData, // Store as array
            'sectionId': sectionId,
            'createdAt': FieldValue.serverTimestamp(),
          });

      Get.snackbar("Success", "Class created successfully!");
      // Reload classes after creating a new one
      loadClasses();
    } catch (e) {
      Get.snackbar("Error", "Failed to create class: $e");
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
      print('Error loading students for class $classId: $e');
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
      print('Error loading all class students: $e');
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

      print(
        'Loaded ${allStudents.length} students (pending/rejected from users, approved from instructor/students)${sectionCode != null ? ' for section $sectionCode' : ''}',
      );
    } catch (e) {
      print('Error loading students from users collection: $e');
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

      print('=== APPROVING STUDENT: $studentId ===');
      print('Instructor: ${user.uid}');
      print('Section: $sectionCode');
      print('Timestamp: ${DateTime.now()}');

      // Update student status in the users collection with additional fields
      await _firestore.collection('users').doc(studentId).update({
        'enrollmentStatus': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': user.uid,
        'approvedByInstructor': instructorName.value,
        'lastStatusUpdate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Student $studentId status updated to approved in Firestore');
      print('✅ Firestore update completed at: ${DateTime.now()}');

      // Verify the update was successful
      final updatedDoc =
          await _firestore.collection('users').doc(studentId).get();
      if (updatedDoc.exists) {
        final updatedData = updatedDoc.data() as Map<String, dynamic>;
        print(
          '✅ Verification: enrollmentStatus = ${updatedData['enrollmentStatus']}',
        );
      }

      // Also update the student's online status to true when approved
      await _firestore.collection('users').doc(studentId).update({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });

      print('✅ Student $studentId online status set to true');

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
              'selectedSectionCode': studentData['selectedSectionCode'] ?? '',
              'enrollmentStatus': 'approved',
              'enrolledAt': FieldValue.serverTimestamp(),
              'approvedAt': FieldValue.serverTimestamp(),
              'approvedBy': user.uid,
              'approvedByInstructor': instructorName.value,
              'isActive': true,
              'isOnline': true,
              'lastSeen': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

        print(
          '✅ Student document created in instructors/{instructorId}/students',
        );
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

      print('✅ Local data updated and UI refreshed');

      Get.snackbar(
        'Success',
        'Student enrollment approved successfully! Student will be redirected to dashboard.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      print('=== APPROVAL COMPLETE FOR STUDENT: $studentId ===');
      return true;
    } catch (e) {
      print('❌ Error approving student $studentId: $e');
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

      // Update student status in the users collection
      await _firestore.collection('users').doc(studentId).update({
        'enrollmentStatus': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': user.uid,
        'rejectionReason': reason ?? 'No reason provided',
      });

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
          students[studentIndex]['rejectionReason'] =
              reason ?? 'No reason provided';
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
      print('Error updating student online status: $e');
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
              print(
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
                    print(
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
      print('Error updating student status: $e');
    }
  }

  /// Get online status for a student
  bool isStudentOnline(Map<String, dynamic> student) {
    final isOnline = student['isOnline'] ?? false;
    final lastSeen = student['lastSeen'];

    if (isOnline) return true;

    // Consider offline if last seen is more than 5 minutes ago
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
        return difference <= 5; // Online if last seen within 5 minutes
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
              print('Error refreshing status for student $studentId: $e2');
            }
          }
        }
      }

      // Refresh the UI safely only if controller is still active
      if (!isClosed && classStudents.isNotEmpty) {
        classStudents.refresh();
      }
    } catch (e) {
      print('Error refreshing student status: $e');
    }
  }

  /// Debug method to simulate student online status (for testing)
  Future<void> simulateStudentStatus(String studentId, bool isOnline) async {
    try {
      await _firestore.collection('users').doc(studentId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
      print(
        'Simulated student $studentId status: ${isOnline ? "Online" : "Offline"}',
      );
    } catch (e) {
      print('Error simulating student status: $e');
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
