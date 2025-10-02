import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class SelectController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  RxList instructors = [{}].obs;
  RxList courses = [{}].obs;
  RxList departments = [{}].obs;
  RxList sections = [{}].obs;
  RxBool isLoading = false.obs;
  RxString selectedInstructorId = ''.obs;
  RxString selectedInstructorName = ''.obs;
  RxList instructorAssignments = [].obs;
  RxBool isSelectionComplete = false.obs;
  RxString selectedDepartmentId = ''.obs;
  RxString selectedSectionCode = ''.obs;
  RxString studentName = ''.obs; // currently logged-in student name

  @override
  void onInit() {
    super.onInit();
    getCourses(); // Automatically fetch courses when controller is created
    getInstructors(); // Automatically fetch instructors when controller is created
    getDepartments(); // Fetch departments
    _loadCurrentStudentName(); // Load current student name
    checkUserSelectionStatus(); // Check if user has already completed selection
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
      instructors.value =
          querySnapshot.docs.map((doc) {
            return {'uid': doc.id, ...doc.data() as Map<String, dynamic>};
          }).toList();
      // log(instructors.toString());
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

  Future<void> getSectionsByDepartment(String departmentId) async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore
              .collection('sections')
              .where('departmentId', isEqualTo: departmentId)
              .get();
      sections.value =
          querySnapshot.docs.map((doc) {
            return {'uid': doc.id, ...doc.data() as Map<String, dynamic>};
          }).toList();
    } catch (e) {
      log('Error fetching sections: $e');
    }
  }

  Future<void> selectInstructor(
    String instructorId,
    String instructorName,
  ) async {
    try {
      selectedInstructorId.value = instructorId;
      selectedInstructorName.value = instructorName;

      // Save instructor selection immediately to user document
      await saveInstructorSelection();

      // Get instructor assignments
      DocumentSnapshot instructorDoc =
          await _firestore.collection('instructors').doc(instructorId).get();

      if (instructorDoc.exists) {
        Map<String, dynamic> data =
            instructorDoc.data() as Map<String, dynamic>;
        instructorAssignments.value = List<Map<String, dynamic>>.from(
          data['assignments'] ?? [],
        );

        // Load sections for each assignment
        for (var assignment in instructorAssignments) {
          await getSectionsByDepartment(assignment['departmentId']);
        }
      }
    } catch (e) {
      log('Error selecting instructor: $e');
    }
  }

  Future<void> completeSelection() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Save user selection to Firestore
      await _firestore.collection('instructors').doc(user.uid).set({
        'instructorId': selectedInstructorId.value,
        'instructorName': selectedInstructorName.value,
        'assignments': instructorAssignments.toList(),
        'isComplete': true,
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      isSelectionComplete.value = true;

      // Also save to user document
      await _firestore.collection('users').doc(user.uid).update({
        'selectedInstructorId': selectedInstructorId.value,
        'selectedInstructorName': selectedInstructorName.value,
        'selectedSectionCode': selectedSectionCode.value,
        'selectionComplete': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Enroll student in instructor's classes
      await _enrollStudentInInstructorClasses();

      log('Selection completed successfully');
    } catch (e) {
      log('Error completing selection: $e');
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
        'updatedAt': FieldValue.serverTimestamp(),
      });

      log('Instructor selection saved successfully');
    } catch (e) {
      log('Error saving instructor selection: $e');
    }
  }

  // Loads the currently authenticated student's display name for UI
  Future<void> _loadCurrentStudentName() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return;
      final data = userDoc.data() as Map<String, dynamic>;
      studentName.value =
          data['name'] ?? data['displayName'] ?? data['fullName'] ?? '';
    } catch (e) {
      log('Error loading student name: $e');
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
        String instructorId = userData['selectedInstructorId'] ?? '';
        String instructorName = userData['selectedInstructorName'] ?? '';

        if (instructorId.isNotEmpty) {
          selectedInstructorId.value = instructorId;
          selectedInstructorName.value = instructorName;
        }
      }

      // Check selection completion status
      DocumentSnapshot selectionDoc =
          await _firestore.collection('instructors').doc(user.uid).get();

      if (selectionDoc.exists) {
        Map<String, dynamic> data = selectionDoc.data() as Map<String, dynamic>;
        bool isComplete = data['isComplete'] ?? false;

        if (isComplete) {
          isSelectionComplete.value = true;
          instructorAssignments.value = List<Map<String, dynamic>>.from(
            data['assignments'] ?? [],
          );
        }
      }
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
        // Look for existing class with this section
        QuerySnapshot existingClasses =
            await _firestore
                .collection('instructors')
                .doc(selectedInstructorId.value)
                .collection('classes')
                .where('section', isEqualTo: selectedSectionCode.value)
                .get();

        String classId;
        if (existingClasses.docs.isNotEmpty) {
          classId = existingClasses.docs.first.id;
        } else {
          // Create a new class for this section
          DocumentReference newClassRef = await _firestore
              .collection('instructors')
              .doc(selectedInstructorId.value)
              .collection('classes')
              .add({
                'section': selectedSectionCode.value,
                'instructorId': selectedInstructorId.value,
                'instructorName': selectedInstructorName.value,
                'createdAt': FieldValue.serverTimestamp(),
                'isActive': true,
              });
          classId = newClassRef.id;
          log('Created new class for section ${selectedSectionCode.value}');
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
            });

        log(
          'Student $studentName enrolled in section ${selectedSectionCode.value}',
        );
      }
    } catch (e) {
      log('Error enrolling student in classes: $e');
    }
  }
}
