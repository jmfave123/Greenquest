import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

/// Service class for semester CRUD operations
class SemesterService {
  final FirebaseFirestore _firestore;

  SemesterService(this._firestore);

  /// Create a new semester
  Future<void> createSemester(String year, String semester) async {
    if (year.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter academic year',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      // Check for duplicate semester
      final existingSemester =
          await _firestore
              .collection('semesters')
              .where('year', isEqualTo: year)
              .where('semester', isEqualTo: semester)
              .get();

      if (existingSemester.docs.isNotEmpty) {
        Get.snackbar(
          'Error',
          'This semester already exists',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      await _firestore.collection('semesters').add({
        'year': year,
        'semester': semester,
        'displayName': '$semester $year',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      Get.snackbar(
        'Success',
        'Semester created successfully',
        backgroundColor: const Color(0xFF34A853),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create semester: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Update an existing semester
  Future<void> updateSemester(
    String semesterId,
    String year,
    String semester,
  ) async {
    if (year.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter academic year',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      // Check for duplicate semester (excluding current semester)
      final existingSemester =
          await _firestore
              .collection('semesters')
              .where('year', isEqualTo: year)
              .where('semester', isEqualTo: semester)
              .get();

      // Check if duplicate exists and it's not the current semester
      final duplicateExists = existingSemester.docs.any(
        (doc) => doc.id != semesterId,
      );

      if (duplicateExists) {
        Get.snackbar(
          'Error',
          'This semester already exists',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      await _firestore.collection('semesters').doc(semesterId).update({
        'year': year,
        'semester': semester,
        'displayName': '$semester $year',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Success',
        'Semester updated successfully',
        backgroundColor: const Color(0xFF34A853),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update semester: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Load all semesters
  Future<List<Map<String, dynamic>>> loadSemesters() async {
    try {
      print('Loading semesters...');
      final snapshot =
          await _firestore
              .collection('semesters')
              .orderBy('createdAt', descending: true)
              .get();

      print('Found ${snapshot.docs.length} semesters');

      final semesters =
          snapshot.docs.map((doc) {
            final data = doc.data();
            print('Semester data: $data');
            return {
              'id': doc.id,
              'year': data['year'] ?? '',
              'semester': data['semester'] ?? '',
              'displayName': data['displayName'] ?? '',
              'isActive': data['isActive'] ?? true,
              'createdAt': data['createdAt'],
            };
          }).toList();

      print('Loaded semesters: $semesters');
      return semesters;
    } catch (e) {
      print('Error loading semesters: $e');
      return [];
    }
  }

  Future<void> deleteSemester(String semesterId) async {
    try {
      await _firestore.collection('semesters').doc(semesterId).delete();
      Get.snackbar(
        'Success',
        'Semester deleted successfully',
        backgroundColor: const Color(0xFF34A853),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete semester: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Load all data for a specific semester (departments, instructors, classes)
  Future<Map<String, List<Map<String, dynamic>>>> loadSemesterData(
    String semesterId,
  ) async {
    try {
      final List<Map<String, dynamic>> departments = [];
      final List<Map<String, dynamic>> instructors = [];
      final List<Map<String, dynamic>> classes = [];

      // Load assigned departments
      final assignedDeptsSnapshot =
          await _firestore
              .collection('semesters')
              .doc(semesterId)
              .collection('departments')
              .get();

      for (var assignedDept in assignedDeptsSnapshot.docs) {
        final deptSnapshot =
            await _firestore
                .collection('departments')
                .doc(assignedDept.id)
                .get();

        if (deptSnapshot.exists) {
          final data = deptSnapshot.data()!;
          final name = data['displayName'] ?? data['name'] ?? '';
          if (name.trim().isNotEmpty) {
            departments.add({
              'id': deptSnapshot.id,
              'name': name,
              'code': data['code'] ?? 'N/A',
              'description': data['description'] ?? '',
            });
          }
        }
      }

      // Load assigned instructors
      final assignedInstructorsSnapshot =
          await _firestore
              .collection('semesters')
              .doc(semesterId)
              .collection('instructors')
              .get();

      for (var assignedInstructor in assignedInstructorsSnapshot.docs) {
        final instructorSnapshot =
            await _firestore
                .collection('instructors')
                .doc(assignedInstructor.id)
                .get();

        if (instructorSnapshot.exists) {
          final data = instructorSnapshot.data()!;
          final name = data['name'] ?? '';
          if (name.trim().isNotEmpty && name.toLowerCase() != 'unknown') {
            // Resolve department names from assignments
            final assignments = data['assignments'];
            final Set<String> departmentNames = {};
            if (assignments != null &&
                assignments is List &&
                assignments.isNotEmpty) {
              for (var assignment in assignments) {
                if (assignment is Map) {
                  final departmentId = assignment['departmentId']?.toString();
                  if (departmentId != null && departmentId.isNotEmpty) {
                    try {
                      final deptDoc =
                          await _firestore
                              .collection('departments')
                              .doc(departmentId)
                              .get();
                      if (deptDoc.exists) {
                        final deptData = deptDoc.data();
                        final deptName =
                            deptData?['displayName'] ??
                            deptData?['name'] ??
                            deptData?['code'];
                        if (deptName != null &&
                            deptName.toString().trim().isNotEmpty) {
                          final code = (deptData?['code'] ?? '').toString();
                          if (code.isNotEmpty && code != deptName) {
                            departmentNames.add(
                              '${deptName.toString()} ($code)',
                            );
                          } else {
                            departmentNames.add(deptName.toString());
                          }
                        }
                      }
                    } catch (e) {
                      // Ignore per-department fetch errors
                    }
                  }
                }
              }
            }

            final resolvedDepartment =
                departmentNames.isNotEmpty
                    ? departmentNames.join(', ')
                    : (data['department']?.toString() ?? 'N/A');

            instructors.add({
              'id': instructorSnapshot.id,
              'name': name,
              'email': data['email'] ?? 'N/A',
              'department': resolvedDepartment,
            });
          }
        }
      }

      // Load assigned classes
      final assignedClassesSnapshot =
          await _firestore
              .collection('semesters')
              .doc(semesterId)
              .collection('classes')
              .get();

      for (var assignedClass in assignedClassesSnapshot.docs) {
        // Find the class in instructors collection
        for (var instructor in instructors) {
          final classSnapshot =
              await _firestore
                  .collection('instructors')
                  .doc(instructor['id'])
                  .collection('classes')
                  .doc(assignedClass.id)
                  .get();

          if (classSnapshot.exists) {
            final classData = classSnapshot.data()!;
            final sectionName = classData['section']?.toString().trim() ?? '';
            if (sectionName.isNotEmpty) {
              // Load students for this class
              List<Map<String, dynamic>> students = [];
              try {
                final studentsSnapshot =
                    await _firestore
                        .collection('instructors')
                        .doc(instructor['id'])
                        .collection('students')
                        .where('selectedSectionCode', isEqualTo: sectionName)
                        .get();

                for (var studentDoc in studentsSnapshot.docs) {
                  final studentData = studentDoc.data();
                  String studentProgramCode = 'N/A';
                  final studentSectionCode =
                      studentData['selectedSectionCode']?.toString().trim() ??
                      '';
                  if (studentSectionCode.isNotEmpty) {
                    final studentSectionMatch = RegExp(
                      r'^([A-Z]+)',
                    ).firstMatch(studentSectionCode);
                    if (studentSectionMatch != null) {
                      studentProgramCode =
                          studentSectionMatch.group(1) ?? 'N/A';
                    }
                  }

                  // Fetch idNumber from users collection
                  String idNumber = '';
                  try {
                    final userDoc =
                        await _firestore
                            .collection('users')
                            .doc(studentDoc.id)
                            .get();
                    if (userDoc.exists) {
                      final userData = userDoc.data() ?? {};
                      idNumber = userData['idNumber']?.toString() ?? '';
                    } else {
                      // Fallback: try matching by studentId
                      final studentId =
                          studentData['studentId']?.toString() ?? '';
                      if (studentId.isNotEmpty) {
                        final userQuery =
                            await _firestore
                                .collection('users')
                                .where('studentId', isEqualTo: studentId)
                                .limit(1)
                                .get();
                        if (userQuery.docs.isNotEmpty) {
                          final userData = userQuery.docs.first.data();
                          idNumber = userData['idNumber']?.toString() ?? '';
                        }
                      }
                    }
                  } catch (e) {
                    // Ignore idNumber fetch errors
                  }

                  students.add({
                    'name': studentData['studentName']?.toString() ?? 'Unknown',
                    'email': studentData['email']?.toString() ?? '',
                    'studentId': studentData['studentId']?.toString() ?? '',
                    'idNumber': idNumber,
                    'program': studentProgramCode,
                  });
                }
              } catch (e) {
                print(
                  'Error loading students for class ${classSnapshot.id}: $e',
                );
              }

              classes.add({
                'id': classSnapshot.id,
                'section': sectionName,
                'instructorName': instructor['name'],
                'instructorId': instructor['id'],
                'department': instructor['department'],
                'students': students,
              });
              break; // Found the class, no need to continue searching
            }
          }
        }
      }

      return {
        'departments': departments,
        'instructors': instructors,
        'classes': classes,
      };
    } catch (e) {
      print('Error loading semester data: $e');
      return {'departments': [], 'instructors': [], 'classes': []};
    }
  }
}
