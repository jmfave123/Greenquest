import 'dart:developer';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SelectController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  RxList instructors = [].obs;
  RxList courses = [{}].obs;
  RxList departments = [{}].obs;
  RxList sections = [{}].obs;
  RxBool isLoading = false.obs;
  RxString selectedInstructorId = ''.obs;
  RxString selectedInstructorName = ''.obs;
  RxString selectedInstructorProfileImage = ''.obs;
  RxList instructorAssignments = [].obs;
  RxBool isSelectionComplete = false.obs;
  RxString selectedDepartmentId = ''.obs;
  RxString selectedSectionCode = ''.obs;
  RxString studentName = ''.obs; // currently logged-in student name
  RxString searchQuery = ''.obs; // search query for instructors
  RxString nstpComponent = ''.obs; // auto-populated from selected instructor

  StreamSubscription<DocumentSnapshot>? _instructorSubscription;

  @override
  void onInit() {
    super.onInit();
    // Load initial data needed by the selection screens
    getInstructors();
    getCourses();
    getDepartments();
    // Check if the user already has a selection (for navigation purposes only)
    checkUserSelectionStatus();
  }

  // Computed property for filtered instructors
  RxList get filteredInstructors {
    if (searchQuery.value.isEmpty) {
      return instructors;
    }
    return instructors
        .where((instructor) {
          final name = instructor['name']?.toString().toLowerCase() ?? '';
          return name.contains(searchQuery.value.toLowerCase());
        })
        .toList()
        .obs;
  }

  @override
  void onClose() {
    _instructorSubscription?.cancel();
    super.onClose();
  }

  Future<void> getInstructors() async {
    try {
      isLoading.value = true;
      final user = _auth.currentUser;
      if (user == null) {
        return;
      }
      QuerySnapshot querySnapshot =
          await _firestore.collection('instructors').get();

      // Filter out instructors without names and ensure they have required fields
      List<Map<String, dynamic>> instructorsList =
          querySnapshot.docs
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return {
                  'uid': doc.id,
                  ...data,
                  // Ensure profile image URL is available
                  'profileImageUrl':
                      data['profileImageUrl'] ??
                      data['profileImage'] ??
                      data['img'],
                };
              })
              .where((instructor) {
                // Only include instructors that have a name and it's not empty
                String name = instructor['name'] ?? '';
                return name.isNotEmpty && name.trim().isNotEmpty;
              })
              .toList();

      // Check if each instructor has classes
      for (var instructor in instructorsList) {
        final instructorId = instructor['uid'] ?? '';
        if (instructorId.isNotEmpty) {
          try {
            final classesQuery =
                await _firestore
                    .collection('instructors')
                    .doc(instructorId)
                    .collection('classes')
                    .get();
            instructor['hasClasses'] = classesQuery.docs.isNotEmpty;
          } catch (e) {
            log('Error checking classes for instructor $instructorId: $e');
            instructor['hasClasses'] = false;
          }
        } else {
          instructor['hasClasses'] = false;
        }
      }

      instructors.value = instructorsList;
      log('Loaded ${instructors.length} instructors with names');
    } catch (e) {
      log('Error fetching instructors: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getCourses() async {
    try {
      isLoading.value = true;
      final user = _auth.currentUser;
      if (user == null) {
        return;
      }
      QuerySnapshot querySnapshot =
          await _firestore.collection('courses').get();
      courses.value =
          querySnapshot.docs.map((doc) {
            return {'uid': doc.id, ...doc.data() as Map<String, dynamic>};
          }).toList();
      log(courses.toString());
    } catch (e) {
      log('Error fetching courses: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getDepartments() async {
    try {
      isLoading.value = true;
      QuerySnapshot querySnapshot =
          await _firestore.collection('departments').get();
      departments.value =
          querySnapshot.docs.map((doc) {
            return {'uid': doc.id, ...doc.data() as Map<String, dynamic>};
          }).toList();
    } catch (e) {
      log('Error fetching departments: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectInstructor(
    String instructorId,
    String instructorName,
  ) async {
    try {
      log('==================== SELECT INSTRUCTOR ====================');
      log('Instructor ID: $instructorId');
      log('Instructor Name: $instructorName');

      // Check if instructor has classes before allowing selection
      final instructor = instructors.firstWhereOrNull(
        (inst) => inst['uid'] == instructorId,
      );

      if (instructor != null && instructor['hasClasses'] == false) {
        log('Cannot select instructor: Instructor has no classes');
        Get.snackbar(
          'Cannot Select',
          'This instructor does not have any classes yet. Please select another instructor.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      selectedInstructorId.value = instructorId;
      selectedInstructorName.value = instructorName;

      // Store instructor profile image
      if (instructor != null) {
        selectedInstructorProfileImage.value =
            instructor['profileImageUrl'] ??
            instructor['profileImage'] ??
            instructor['img'] ??
            '';
      }

      // Cancel previous subscription
      _instructorSubscription?.cancel();
      log('Cancelled previous subscription');

      // Save instructor selection immediately to user document
      await saveInstructorSelection();
      log('Saved instructor selection to user document');

      // Listen to instructor document changes for real-time updates
      log('Setting up Firestore listener for instructor: $instructorId');
      _instructorSubscription = _firestore
          .collection('instructors')
          .doc(instructorId)
          .snapshots()
          .listen((instructorDoc) {
            log('--- Firestore snapshot received ---');
            if (instructorDoc.exists) {
              Map<String, dynamic> data =
                  instructorDoc.data() as Map<String, dynamic>;
              List<Map<String, dynamic>> newAssignments =
                  List<Map<String, dynamic>>.from(data['assignments'] ?? []);
              log(
                'New assignments from Firestore: ${newAssignments.length} items',
              );
              for (var assignment in newAssignments) {
                log(
                  '  - ${assignment['departmentCode']}-${assignment['sectionCode']}',
                );
              }

              instructorAssignments.value = newAssignments;
              log('Updated instructorAssignments observable');

              // Sections will be loaded on-demand when departments are expanded
            } else {
              log('Instructor document does not exist!');
            }
          });

      // Initial load
      log('Performing initial load of instructor data...');
      DocumentSnapshot instructorDoc =
          await _firestore.collection('instructors').doc(instructorId).get();

      if (instructorDoc.exists) {
        Map<String, dynamic> data =
            instructorDoc.data() as Map<String, dynamic>;
        instructorAssignments.value = List<Map<String, dynamic>>.from(
          data['assignments'] ?? [],
        );
        nstpComponent.value = data['nstpComponent']?.toString() ?? '';
        log('Initial load: ${instructorAssignments.length} assignments');

        // Sections will be loaded on-demand when departments are expanded
      } else {
        log('Instructor document not found on initial load');
      }

      log('==========================================================');
    } catch (e) {
      log('✗ Error selecting instructor: $e');
    }
  }

  Future<void> completeSelection() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Fetch the active period assigned to the selected instructor
      final activePeriod = await _getInstructorActivePeriod(
        selectedInstructorId.value,
      );

      // Save user selection to Firestore (in users collection, not instructors)
      await _firestore.collection('users').doc(user.uid).update({
        'selectedInstructorId': selectedInstructorId.value,
        'selectedInstructorName': selectedInstructorName.value,
        'instructorAssignments': instructorAssignments.toList(),
        'selectionComplete': true,
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (activePeriod != null) 'assignedSemester': activePeriod,
        if (nstpComponent.value.isNotEmpty)
          'nstpComponent': nstpComponent.value,
      });

      isSelectionComplete.value = true;

      // Also save to user document
      await _firestore.collection('users').doc(user.uid).update({
        'selectedInstructorId': selectedInstructorId.value,
        'selectedInstructorName': selectedInstructorName.value,
        'selectedSectionCode': selectedSectionCode.value,
        'selectionComplete': true,
        'enrollmentStatus': 'pending', // Set as pending for instructor approval
        'updatedAt': FieldValue.serverTimestamp(),
        if (activePeriod != null) 'assignedSemester': activePeriod,
        if (nstpComponent.value.isNotEmpty)
          'nstpComponent': nstpComponent.value,
      });

      // NOTE: Students are now only created in instructors/{instructorId}/students
      // AFTER instructor approval. No need to enroll in classes subcollection.
      // await _enrollStudentInInstructorClasses();

      log('Selection completed successfully');
    } catch (e) {
      log('Error completing selection: $e');
    }
  }

  // Method to complete selection with COR upload
  Future<void> completeSelectionWithCor(String corUrl) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get user data
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return;

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String studentName =
          userData['name'] ?? userData['fullName'] ?? 'Unknown Student';
      String studentEmail = userData['email'] ?? '';
      String studentPhone = userData['phoneNumber'] ?? '';
      String idNumber = userData['idNumber'] ?? '';

      // Fetch the active period assigned to the selected instructor
      final activePeriod = await _getInstructorActivePeriod(
        selectedInstructorId.value,
      );

      // Save selection and COR to user document
      await _firestore.collection('users').doc(user.uid).update({
        'selectedInstructorId': selectedInstructorId.value,
        'selectedInstructorName': selectedInstructorName.value,
        'selectedSectionCode': selectedSectionCode.value,
        'instructorAssignments': instructorAssignments.toList(),
        'selectionComplete': true,
        'enrollmentStatus': 'pending',
        'corUrl': corUrl,
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (activePeriod != null) 'assignedSemester': activePeriod,
        if (nstpComponent.value.isNotEmpty)
          'nstpComponent': nstpComponent.value,
      });

      // Create student entry in instructor's students subcollection for approval
      await _firestore
          .collection('instructors')
          .doc(selectedInstructorId.value)
          .collection('students')
          .doc(user.uid)
          .set({
            'studentId': user.uid,
            'studentName': studentName,
            'email': studentEmail,
            'phoneNumber': studentPhone,
            'idNumber': idNumber,
            'sectionCode': selectedSectionCode.value,
            'corUrl': corUrl,
            'enrollmentStatus': 'pending',
            'enrolledAt': FieldValue.serverTimestamp(),
            'isActive': false, // Will be set to true upon approval
            if (activePeriod != null) 'assignedSemester': activePeriod,
            if (nstpComponent.value.isNotEmpty)
              'nstpComponent': nstpComponent.value,
          });

      isSelectionComplete.value = true;

      log('Selection with COR completed successfully');
    } catch (e) {
      log('Error completing selection with COR: $e');
      rethrow;
    }
  }

  // Method to save instructor selection immediately when selected
  Future<void> saveInstructorSelection() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Save to user document immediately
      await _firestore.collection('users').doc(user.uid).update({
        'selectedInstructorId': selectedInstructorId.value,
        'selectedInstructorName': selectedInstructorName.value,
        if (nstpComponent.value.isNotEmpty)
          'nstpComponent': nstpComponent.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      log('Instructor selection saved successfully');
    } catch (e) {
      log('Error saving instructor selection: $e');
    }
  }

  Future<void> checkUserSelectionStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Check user document first for instructor selection
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String enrollmentStatus = userData['enrollmentStatus'] ?? 'none';
        bool selectionComplete = userData['selectionComplete'] ?? false;

        // If user is approved, they don't need to select again
        if (selectionComplete && enrollmentStatus == 'approved') {
          isSelectionComplete.value = true;
          // Navigate directly to home
          Get.offAllNamed('/home');
          return;
        }

        // If user is pending or rejected, show appropriate screen
        if (selectionComplete &&
            (enrollmentStatus == 'pending' || enrollmentStatus == 'rejected')) {
          Get.offAllNamed('/pending-approval');
          return;
        }
      }

      // Check selection completion status from users collection
      // (This is now handled in the user document check above)
    } catch (e) {
      log('Error checking selection status: $e');
    }
  }

  void resetSelection() {
    selectedInstructorId.value = '';
    selectedInstructorName.value = '';
    instructorAssignments.value = [];
    isSelectionComplete.value = false;
    selectedDepartmentId.value = '';
    selectedSectionCode.value = '';
    nstpComponent.value = '';
  }

  /// Fetches the currently active period that the given instructor is assigned to.
  ///
  /// Steps:
  ///   1. Query `periods` for the document with `isActive: true`.
  ///   2. Verify the instructor's `assignedPeriods` array contains that period.
  ///   3. Return `{ periodId, semesterName, type, isActive }` or null.
  Future<Map<String, dynamic>?> _getInstructorActivePeriod(
    String instructorId,
  ) async {
    try {
      if (instructorId.isEmpty) return null;

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

      // Step 3 – Return clean period metadata
      return {
        'periodId': activePeriodId,
        'semesterName': activePeriodData['semesterName'] ?? '',
        'type': activePeriodData['type'] ?? '',
        'isActive': true,
      };
    } catch (e) {
      log('SelectController: Error getting instructor active period: $e');
      return null;
    }
  }

  // Method to manually enroll student if they completed selection but weren't enrolled
  Future<void> enrollStudentManually() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Check if user has completed selection
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return;

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      bool selectionComplete = userData['selectionComplete'] ?? false;
      String instructorId = userData['selectedInstructorId'] ?? '';
      String instructorName = userData['selectedInstructorName'] ?? '';

      if (selectionComplete && instructorId.isNotEmpty) {
        // Set the selected values
        selectedInstructorId.value = instructorId;
        selectedInstructorName.value = instructorName;

        // Try to get the selected section from user data or use a default
        String sectionCode = userData['selectedSectionCode'] ?? 'BSIT-4D';
        selectedSectionCode.value = sectionCode;

        // Get instructor assignments from user data
        instructorAssignments.value = List<Map<String, dynamic>>.from(
          userData['instructorAssignments'] ?? [],
        );

        // Enroll the student
        await _enrollStudentInInstructorClasses();
        log('Student enrolled manually');
      }
    } catch (e) {
      log('Error in manual enrollment: $e');
    }
  }

  // Method to select section
  void selectSection(String departmentId, String sectionCode) {
    selectedDepartmentId.value = departmentId;
    selectedSectionCode.value = sectionCode;
  }

  // Method to enroll student in instructor's classes
  Future<void> _enrollStudentInInstructorClasses() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get user data
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return;

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String studentName =
          userData['name'] ?? userData['displayName'] ?? 'Unknown Student';

      // First, try to find classes in the instructor's classes collection
      QuerySnapshot classesSnapshot =
          await _firestore
              .collection('instructors')
              .doc(selectedInstructorId.value)
              .collection('classes')
              .get();

      bool enrolled = false;

      // Find matching class based on section
      for (QueryDocumentSnapshot classDoc in classesSnapshot.docs) {
        Map<String, dynamic> classData =
            classDoc.data() as Map<String, dynamic>;
        String classSection = classData['section'] ?? '';

        // Extract section code from selectedSectionCode (e.g., "BSIT-4D" -> "4D")
        String selectedSectionOnly = selectedSectionCode.value;
        if (selectedSectionOnly.contains('-')) {
          selectedSectionOnly = selectedSectionOnly.split('-').last;
        }

        // Check if this class matches the selected section
        if (classSection == selectedSectionOnly) {
          // Check if student is already enrolled to avoid duplicates
          DocumentSnapshot existingStudent =
              await _firestore
                  .collection('instructors')
                  .doc(selectedInstructorId.value)
                  .collection('classes')
                  .doc(classDoc.id)
                  .collection('students')
                  .doc(user.uid)
                  .get();

          if (!existingStudent.exists) {
            // Add student to this class
            await _firestore
                .collection('instructors')
                .doc(selectedInstructorId.value)
                .collection('classes')
                .doc(classDoc.id)
                .collection('students')
                .doc(user.uid)
                .set({
                  'studentId': user.uid,
                  'studentName': studentName,
                  'enrolledAt': FieldValue.serverTimestamp(),
                  'isActive': true,
                  'enrollmentStatus':
                      'pending', // Set as pending for instructor approval
                });

            log('Student $studentName enrolled in class $classSection');
            enrolled = true;
          } else {
            log('Student $studentName already enrolled in class $classSection');
            enrolled = true;
          }
        }
      }

      // If no classes found in instructor's classes collection,
      // try to find or create a class based on the selected section
      if (!enrolled) {
        // Extract section code from selectedSectionCode (e.g., "BSIT-4D" -> "4D")
        String selectedSectionOnly = selectedSectionCode.value;
        if (selectedSectionOnly.contains('-')) {
          selectedSectionOnly = selectedSectionOnly.split('-').last;
        }

        // Look for existing class with this section (use section part only)
        QuerySnapshot existingClasses =
            await _firestore
                .collection('instructors')
                .doc(selectedInstructorId.value)
                .collection('classes')
                .where('section', isEqualTo: selectedSectionOnly)
                .get();

        String classId;
        if (existingClasses.docs.isNotEmpty) {
          classId = existingClasses.docs.first.id;
        } else {
          // Create a new class for this section (use section part only)
          DocumentReference newClassRef = await _firestore
              .collection('instructors')
              .doc(selectedInstructorId.value)
              .collection('classes')
              .add({
                'section': selectedSectionOnly,
                'instructorId': selectedInstructorId.value,
                'instructorName': selectedInstructorName.value,
                'createdAt': FieldValue.serverTimestamp(),
                'isActive': true,
              });
          classId = newClassRef.id;
          log('Created new class for section $selectedSectionOnly');
        }

        // Enroll student in this class
        await _firestore
            .collection('instructors')
            .doc(selectedInstructorId.value)
            .collection('classes')
            .doc(classId)
            .collection('students')
            .doc(user.uid)
            .set({
              'studentId': user.uid,
              'studentName': studentName,
              'enrolledAt': FieldValue.serverTimestamp(),
              'isActive': true,
              'enrollmentStatus':
                  'pending', // Set as pending for instructor approval
            });

        log('Student $studentName enrolled in section $selectedSectionOnly');
      }
    } catch (e) {
      log('Error enrolling student in classes: $e');
    }
  }
}
