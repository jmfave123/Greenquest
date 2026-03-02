import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

/// Service class for semester assignment operations
class SemesterAssignmentService {
  final FirebaseFirestore _firestore;

  SemesterAssignmentService(this._firestore);

  /// Load all assignment data (departments, instructors, classes)
  Future<Map<String, dynamic>> loadAssignmentData() async {
    try {
      // Load departments
      final departmentsSnapshot =
          await _firestore.collection('departments').get();
      final departments =
          departmentsSnapshot.docs
              .map((doc) {
                final data = doc.data();
                return {
                  'id': doc.id,
                  'name': data['displayName'] ?? data['name'] ?? '',
                  'code': data['code'] ?? 'N/A',
                };
              })
              .where((dept) => dept['name'].toString().trim().isNotEmpty)
              .toList();

      // Load instructors
      final instructorsSnapshot =
          await _firestore.collection('instructors').get();
      // Enrich instructors with department names resolved from assignments
      final List<Map<String, dynamic>> instructors = [];
      for (var doc in instructorsSnapshot.docs) {
        final data = doc.data();
        final name = (data['name'] ?? '').toString();
        if (name.trim().isEmpty) continue;

        // Only include approved instructors - exclude pending and rejected
        final instructorStatus = data['status']?.toString() ?? 'Pending';
        if (instructorStatus != 'Approved') {
          continue;
        }

        // Collect department names from assignments → departments collection
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
                      // Prefer "Name (CODE)" if code is available and different
                      if (code.isNotEmpty && code != deptName) {
                        departmentNames.add('${deptName.toString()} ($code)');
                      } else {
                        departmentNames.add(deptName.toString());
                      }
                    }
                  }
                } catch (e) {
                  // Ignore individual department fetch errors
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
          'id': doc.id,
          'name': name,
          'email': data['email'] ?? 'N/A',
          'department': resolvedDepartment,
        });
      }

      // Load classes from all instructors
      final List<Map<String, dynamic>> classes = [];
      for (var instructor in instructors) {
        final classesSnapshot =
            await _firestore
                .collection('instructors')
                .doc(instructor['id'])
                .collection('classes')
                .get();

        for (var classDoc in classesSnapshot.docs) {
          final classData = classDoc.data();
          final sectionName = classData['section']?.toString().trim() ?? '';
          if (sectionName.isNotEmpty) {
            classes.add({
              'id': classDoc.id,
              'section': sectionName,
              'instructorName': instructor['name'],
              'instructorId': instructor['id'],
              'department': instructor['department'],
            });
          }
        }
      }

      return {
        'departments': departments,
        'instructors': instructors,
        'classes': classes,
      };
    } catch (e) {
      print('Error loading assignment data: $e');
      return {'departments': [], 'instructors': [], 'classes': []};
    }
  }

  /// Load existing assignments for a semester
  Future<Map<String, List<String>>> loadExistingAssignments(
    String semesterId,
  ) async {
    try {
      // Load assigned departments
      final assignedDeptsSnapshot =
          await _firestore
              .collection('semesters')
              .doc(semesterId)
              .collection('departments')
              .get();
      final selectedDepartments =
          assignedDeptsSnapshot.docs.map((doc) => doc.id).toList();

      // Load assigned instructors
      final assignedInstructorsSnapshot =
          await _firestore
              .collection('semesters')
              .doc(semesterId)
              .collection('instructors')
              .get();
      final selectedInstructors =
          assignedInstructorsSnapshot.docs.map((doc) => doc.id).toList();

      // Load assigned classes
      final assignedClassesSnapshot =
          await _firestore
              .collection('semesters')
              .doc(semesterId)
              .collection('classes')
              .get();
      final selectedClasses =
          assignedClassesSnapshot.docs.map((doc) => doc.id).toList();

      return {
        'departments': selectedDepartments,
        'instructors': selectedInstructors,
        'classes': selectedClasses,
      };
    } catch (e) {
      print('Error loading existing assignments: $e');
      return {'departments': [], 'instructors': [], 'classes': []};
    }
  }

  /// Save department assignments for a semester
  Future<void> saveDepartmentAssignments(
    String semesterId,
    List<String> selectedDepartments,
  ) async {
    // Remove all existing department assignments
    final existingDeptsSnapshot =
        await _firestore
            .collection('semesters')
            .doc(semesterId)
            .collection('departments')
            .get();

    for (var doc in existingDeptsSnapshot.docs) {
      await doc.reference.delete();
    }

    // Add new department assignments
    for (var deptId in selectedDepartments) {
      await _firestore
          .collection('semesters')
          .doc(semesterId)
          .collection('departments')
          .doc(deptId)
          .set({'assignedAt': FieldValue.serverTimestamp()});
    }
  }

  /// Save instructor assignments for a semester
  Future<void> saveInstructorAssignments(
    String semesterId,
    Map<String, dynamic> semesterData,
    List<String> selectedInstructors,
  ) async {
    // Remove all existing instructor assignments from subcollection
    final existingInstructorsSnapshot =
        await _firestore
            .collection('semesters')
            .doc(semesterId)
            .collection('instructors')
            .get();

    // Get list of previously assigned instructors
    final previouslyAssignedInstructors =
        existingInstructorsSnapshot.docs.map((doc) => doc.id).toList();

    // Remove semester from instructors who are no longer selected
    for (var instructorId in previouslyAssignedInstructors) {
      if (!selectedInstructors.contains(instructorId)) {
        // Remove from subcollection
        await _firestore
            .collection('semesters')
            .doc(semesterId)
            .collection('instructors')
            .doc(instructorId)
            .delete();

        // Remove semester from instructor's assignedSemesters array
        final instructorRef = _firestore
            .collection('instructors')
            .doc(instructorId);
        final instructorDoc = await instructorRef.get();

        if (instructorDoc.exists) {
          final instructorData = instructorDoc.data() as Map<String, dynamic>;
          final assignedSemesters =
              (instructorData['assignedSemesters'] as List<dynamic>?) ?? [];

          // Remove this semester from the array
          final updatedSemesters =
              assignedSemesters
                  .where((sem) => sem['semesterId'] != semesterId)
                  .toList();

          await instructorRef.update({
            'assignedSemesters': updatedSemesters,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    }

    // Add new instructor assignments
    for (var instructorId in selectedInstructors) {
      // Add to semester subcollection
      await _firestore
          .collection('semesters')
          .doc(semesterId)
          .collection('instructors')
          .doc(instructorId)
          .set({'assignedAt': FieldValue.serverTimestamp()});

      // Add semester to instructor's assignedSemesters array
      final instructorRef = _firestore
          .collection('instructors')
          .doc(instructorId);
      final instructorDoc = await instructorRef.get();

      if (instructorDoc.exists) {
        final instructorData = instructorDoc.data() as Map<String, dynamic>;
        final assignedSemesters =
            (instructorData['assignedSemesters'] as List<dynamic>?) ?? [];

        // Check if semester already exists in array
        final semesterExists = assignedSemesters.any(
          (sem) => sem['semesterId'] == semesterId,
        );

        if (!semesterExists) {
          // Add semester to array
          assignedSemesters.add(semesterData);

          await instructorRef.update({
            'assignedSemesters': assignedSemesters,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        // If instructor document doesn't exist, create it with the semester array
        await instructorRef.set({
          'assignedSemesters': [semesterData],
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }
  }

  /// Save class assignments for a semester
  Future<void> saveClassAssignments(
    String semesterId,
    List<String> selectedClasses,
  ) async {
    // Remove all existing class assignments
    final existingClassesSnapshot =
        await _firestore
            .collection('semesters')
            .doc(semesterId)
            .collection('classes')
            .get();

    for (var doc in existingClassesSnapshot.docs) {
      await doc.reference.delete();
    }

    // Add new class assignments
    for (var classId in selectedClasses) {
      await _firestore
          .collection('semesters')
          .doc(semesterId)
          .collection('classes')
          .doc(classId)
          .set({'assignedAt': FieldValue.serverTimestamp()});
    }
  }

  /// Save all assignments (departments, instructors, classes) for a semester
  Future<void> saveAllAssignments(
    String semesterId,
    Map<String, dynamic> semesterData,
    List<String> selectedDepartments,
    List<String> selectedInstructors,
    List<String> selectedClasses,
  ) async {
    try {
      // Save department assignments
      await saveDepartmentAssignments(semesterId, selectedDepartments);

      // Save instructor assignments
      await saveInstructorAssignments(
        semesterId,
        semesterData,
        selectedInstructors,
      );

      // Save class assignments
      await saveClassAssignments(semesterId, selectedClasses);

      Get.snackbar(
        'Success',
        'Assignments saved successfully',
        backgroundColor: const Color(0xFF34A853),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save assignments: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      rethrow;
    }
  }

  /// Update which semesters a single instructor is assigned to.
  ///
  /// Performs a bidirectional sync:
  /// - `semesters/{semesterId}/instructors/{instructorId}` subcollection
  /// - `instructors/{instructorId}.assignedSemesters` array
  ///
  /// Parameters:
  ///   - [instructorId]: The Firestore document ID of the instructor
  ///   - [newSemesterIds]: The complete list of semester IDs the instructor
  ///     should be assigned to after this operation
  ///   - [allSemesters]: All available semesters (used to build semester metadata)
  Future<void> updateInstructorSemesters({
    required String instructorId,
    required List<String> newSemesterIds,
    required List<Map<String, dynamic>> allSemesters,
  }) async {
    try {
      final instructorRef = _firestore
          .collection('instructors')
          .doc(instructorId);

      final instructorDoc = await instructorRef.get();
      if (!instructorDoc.exists) {
        throw Exception('Instructor not found: $instructorId');
      }

      final instructorData = instructorDoc.data() as Map<String, dynamic>;
      final currentAssigned =
          (instructorData['assignedSemesters'] as List<dynamic>?) ?? [];
      final currentIds =
          currentAssigned
              .map(
                (s) =>
                    (s as Map<String, dynamic>)['semesterId']?.toString() ?? '',
              )
              .where((id) => id.isNotEmpty)
              .toSet();

      final toAdd =
          newSemesterIds.where((id) => !currentIds.contains(id)).toList();
      final toRemove =
          currentIds.where((id) => !newSemesterIds.contains(id)).toList();

      // Add instructor to newly selected semester subcollections
      for (final semesterId in toAdd) {
        await _firestore
            .collection('semesters')
            .doc(semesterId)
            .collection('instructors')
            .doc(instructorId)
            .set({'assignedAt': FieldValue.serverTimestamp()});
      }

      // Remove instructor from deselected semester subcollections
      for (final semesterId in toRemove) {
        await _firestore
            .collection('semesters')
            .doc(semesterId)
            .collection('instructors')
            .doc(instructorId)
            .delete();
      }

      // Build the updated assignedSemesters array, preserving existing metadata
      final updatedSemesters =
          newSemesterIds.map<Map<String, dynamic>>((id) {
            // Preserve existing entry if present (keeps original assignedAt, etc.)
            final existing = currentAssigned.firstWhereOrNull(
              (s) => (s as Map<String, dynamic>)['semesterId'] == id,
            );
            if (existing != null) {
              return Map<String, dynamic>.from(
                existing as Map<String, dynamic>,
              );
            }

            // Build metadata from allSemesters list for newly added entries
            final semesterMeta = allSemesters.firstWhereOrNull(
              (s) => s['id'] == id,
            );
            return {
              'semesterId': id,
              'displayName': semesterMeta?['displayName'] ?? '',
              'year': semesterMeta?['year'] ?? '',
              'semester': semesterMeta?['semester'] ?? '',
            };
          }).toList();

      await instructorRef.update({
        'assignedSemesters': updatedSemesters,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Success',
        'Semester assignments updated successfully',
        backgroundColor: const Color(0xFF34A853),
        colorText: Colors.white,
      );
    } catch (e, stackTrace) {
      debugPrint(
        'SemesterAssignmentService: Error updating instructor semesters: $e\n$stackTrace',
      );
      Get.snackbar(
        'Error',
        'Failed to update semester assignments. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      rethrow;
    }
  }

  /// Update which periods (from the `periods` collection) a single instructor
  /// is assigned to.
  ///
  /// The `periods` collection is the source of truth shown in the admin
  /// Firestore console (fields: semesterId, semesterName, type, isActive).
  ///
  /// Sync targets:
  /// - `instructors/{instructorId}.assignedPeriods` array — stores period
  ///   metadata for quick reads without extra queries
  ///
  /// Parameters:
  ///   - [instructorId]: Firestore document ID of the instructor
  ///   - [newPeriodIds]: Complete desired set of period document IDs
  ///   - [allPeriods]: All loaded periods (used to hydrate metadata)
  Future<void> updateInstructorPeriods({
    required String instructorId,
    required List<String> newPeriodIds,
    required List<Map<String, dynamic>> allPeriods,
  }) async {
    try {
      final instructorRef = _firestore
          .collection('instructors')
          .doc(instructorId);

      final instructorDoc = await instructorRef.get();
      if (!instructorDoc.exists) {
        throw Exception('Instructor not found: $instructorId');
      }

      final instructorData = instructorDoc.data() as Map<String, dynamic>;
      final currentAssigned =
          (instructorData['assignedPeriods'] as List<dynamic>?) ?? [];

      // Build the updated assignedPeriods array, preserving existing entries
      final updatedPeriods =
          newPeriodIds.map<Map<String, dynamic>>((id) {
            // Keep existing entry so we don't lose any extra fields
            final existing = currentAssigned.firstWhereOrNull(
              (p) => (p as Map<String, dynamic>)['periodId'] == id,
            );
            if (existing != null) {
              return Map<String, dynamic>.from(
                existing as Map<String, dynamic>,
              );
            }

            // Hydrate from the allPeriods list for newly selected entries
            final meta = allPeriods.firstWhereOrNull((p) => p['id'] == id);
            return {
              'periodId': id,
              'semesterName': meta?['semesterName'] ?? '',
              'type': meta?['type'] ?? '',
              'isActive': meta?['isActive'] ?? false,
            };
          }).toList();

      await instructorRef.update({
        'assignedPeriods': updatedPeriods,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Success',
        'Period assignments updated successfully',
        backgroundColor: const Color(0xFF34A853),
        colorText: Colors.white,
      );
    } catch (e, stackTrace) {
      debugPrint(
        'SemesterAssignmentService: Error updating instructor periods: $e\n$stackTrace',
      );
      Get.snackbar(
        'Error',
        'Failed to update period assignments. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      rethrow;
    }
  }
}
