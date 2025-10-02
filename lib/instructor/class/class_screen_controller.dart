import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class ClassController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  var instructorName = ''.obs;
  var classes = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var classStudents = <String, List<Map<String, dynamic>>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadInstructor();
    loadClasses();
  }

  /// Add class to Firestore under logged-in instructor's document
  Future<void> addClass({
    required String section,
    required String course,
    required String room,
    required String day,
    required String startTime,
    required String endTime,
    String? sectionId,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        Get.snackbar("Error", "No instructor is logged in.");
        return;
      }

      await _firestore
          .collection('instructors')
          .doc(user.uid) // <-- use Firebase user ID
          .collection('classes')
          .add({
            'section': section,
            'course': course,
            'room': room,
            'day': day,
            'startTime': startTime,
            'endTime': endTime,
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

      classes.value =
          snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'course': data['course'] ?? '',
              'section': data['section'] ?? '',
              'room': data['room'] ?? '',
              'day': data['day'] ?? '',
              'startTime': data['startTime'] ?? '',
              'endTime': data['endTime'] ?? '',
              'sectionId': data['sectionId'] ?? '',
              'createdAt': data['createdAt'],
            };
          }).toList();

      // Load students for all classes
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

      // Query users collection for students who selected this instructor
      Query query = _firestore
          .collection('users')
          .where('selectedInstructorId', isEqualTo: user.uid)
          .where('selectionComplete', isEqualTo: true);

      // If a specific section is requested, filter by that section
      if (sectionCode != null && sectionCode.isNotEmpty) {
        query = query.where('selectedSectionCode', isEqualTo: sectionCode);
      }

      QuerySnapshot studentsSnapshot = await query.get();

      List<Map<String, dynamic>> allStudents = [];

      for (QueryDocumentSnapshot doc in studentsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
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
        });
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
        'Loaded ${allStudents.length} students from users collection${sectionCode != null ? ' for section $sectionCode' : ''}',
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
}
