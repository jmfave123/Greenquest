import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class ReportController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  var instructorName = ''.obs;
  var profileImageUrl = ''.obs;
  var classes = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  // Debounce timer to prevent too frequent updates
  Timer? _debounceTimer;

  @override
  void onInit() {
    super.onInit();
    loadInstructor();
    loadClasses();
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    super.onClose();
  }

  /// Load instructor name using email query (same pattern as login flow)
  Future<void> loadInstructor() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        instructorName.value = 'No user logged in';
        return;
      }

      // Reload user to ensure token is fresh (same as login flow)
      try {
        await user.reload();
      } catch (e) {
        // If reload fails, user might still be valid
      }

      final refreshedUser = FirebaseAuth.instance.currentUser;
      if (refreshedUser == null || refreshedUser.email == null) {
        instructorName.value = 'User session expired';
        return;
      }

      // Query instructor by email (same pattern as login flow for reliability)
      final instructorQuery =
          await FirebaseFirestore.instance
              .collection('instructors')
              .where('email', isEqualTo: refreshedUser.email)
              .limit(1)
              .get();

      if (instructorQuery.docs.isNotEmpty) {
        final instructorData = instructorQuery.docs.first.data();
        instructorName.value = instructorData['name'] ?? 'Unknown Instructor';
        // Safely access profileUrl - use get() to avoid errors if field doesn't exist
        profileImageUrl.value =
            instructorData['profileUrl'] ??
            instructorData['profileImageUrl'] ??
            '';
      } else {
        // Fallback: Try by UID if email query fails
        final doc =
            await FirebaseFirestore.instance
                .collection('instructors')
                .doc(refreshedUser.uid)
                .get();

        if (doc.exists) {
          final data = doc.data() ?? {};
          instructorName.value = data['name'] ?? 'Unknown Instructor';
          // Safely access profileUrl - use data map to avoid errors
          profileImageUrl.value =
              data['profileUrl'] ?? data['profileImageUrl'] ?? '';
        } else {
          instructorName.value = 'Instructor not found';
        }
      }
    } catch (e) {
      instructorName.value = 'Error loading name';
      errorMessage.value = 'Failed to load instructor: $e';
    }
  }

  /// Load classes from Firestore for the logged-in instructor
  Future<void> loadClasses() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final User? user = _auth.currentUser;
      if (user == null) {
        errorMessage.value = 'No instructor is logged in.';
        return;
      }

      // Get instructor's assignments to find their assigned sections
      final instructorDoc =
          await _firestore.collection('instructors').doc(user.uid).get();

      if (!instructorDoc.exists) {
        errorMessage.value = 'Instructor document not found.';
        return;
      }

      final instructorData = instructorDoc.data()!;
      final assignments = List<Map<String, dynamic>>.from(
        instructorData['assignments'] ?? [],
      );

      // Get all department IDs from instructor's assignments
      final departmentIds =
          assignments
              .map((assignment) => assignment['departmentId'])
              .where((id) => id != null && id.toString().isNotEmpty)
              .toSet();

      if (departmentIds.isEmpty) {
        // If no assignments, try to get from classes collection
        await _loadClassesFromClassesCollection(user.uid);
        return;
      }

      // Load sections for assigned departments
      final List<Map<String, dynamic>> allSections = [];

      for (String departmentId in departmentIds) {
        final sectionsSnapshot =
            await _firestore
                .collection('sections')
                .where('departmentId', isEqualTo: departmentId)
                .get();

        final sections =
            sectionsSnapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'sectionCode': data['sectionCode'] ?? '',
                'departmentId': data['departmentId'] ?? '',
                'departmentName': data['departmentName'] ?? '',
                'courseName': data['courseName'] ?? '',
                'courseCode': data['courseCode'] ?? '',
                'students': data['students'] ?? 0,
                'isActive': data['isActive'] ?? true,
              };
            }).toList();

        allSections.addAll(sections);
      }

      // Transform sections to match the UI format and get dynamic student counts
      final List<Map<String, dynamic>> classesList = [];

      for (var section in allSections) {
        // Get the actual student count for this section
        final studentCount = await _getStudentCountForSection(
          section['sectionCode'],
        );

        classesList.add({
          'id': section['id'],
          'name': section['sectionCode'] ?? 'Unknown Section',
          'desc': section['courseName'] ?? 'Unknown Course',
          'students': studentCount, // Use dynamic count instead of static field
          'active': section['isActive'] ?? true,
          'departmentName': section['departmentName'] ?? '',
          'courseCode': section['courseCode'] ?? '',
        });
      }

      classes.value = classesList;
    } catch (e) {
      errorMessage.value = 'Failed to load classes: $e';
      Get.snackbar("Error", "Failed to load classes: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Get student count for a specific section code
  Future<int> _getStudentCountForSection(String sectionCode) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null || sectionCode.isEmpty) return 0;

      // Query instructor's students subcollection for approved students in this section
      final snapshot =
          await _firestore
              .collection('instructors')
              .doc(user.uid)
              .collection('students')
              .where('selectedSectionCode', isEqualTo: sectionCode)
              .where('enrollmentStatus', isEqualTo: 'approved')
              .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting student count for section $sectionCode: $e');
      return 0;
    }
  }

  /// Fallback method to load classes from the classes collection
  Future<void> _loadClassesFromClassesCollection(String instructorId) async {
    try {
      final QuerySnapshot snapshot =
          await _firestore
              .collection('instructors')
              .doc(instructorId)
              .collection('classes')
              .orderBy('createdAt', descending: true)
              .get();

      // Transform classes to match the UI format and get dynamic student counts
      final List<Map<String, dynamic>> classesList = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Get the sectionId from the class document
        final sectionId = data['sectionId'] ?? '';
        String sectionCode = '';

        if (sectionId.isNotEmpty) {
          // Get the sectionCode from the sections collection using sectionId
          try {
            final sectionDoc =
                await _firestore.collection('sections').doc(sectionId).get();
            if (sectionDoc.exists) {
              final sectionData = sectionDoc.data()!;
              sectionCode = sectionData['sectionCode'] ?? '';
            }
          } catch (e) {
            print('Error getting section code for sectionId $sectionId: $e');
          }
        }

        // Get the actual student count for this section
        final studentCount = await _getStudentCountForSection(sectionCode);

        classesList.add({
          'id': doc.id,
          'name': data['section'] ?? 'Unknown Section',
          'desc': data['course'] ?? 'Unknown Course',
          'students': studentCount, // Use dynamic count instead of hardcoded 0
          'active': true,
          'room': data['room'] ?? '',
          'day': data['day'] ?? '',
          'startTime': data['startTime'] ?? '',
          'endTime': data['endTime'] ?? '',
        });
      }

      classes.value = classesList;
    } catch (e) {
      errorMessage.value = 'Failed to load classes from classes collection: $e';
    }
  }

  /// Refresh classes data
  Future<void> refreshClasses() async {
    await loadClasses();
  }

  /// Get class details for a specific class
  Future<Map<String, dynamic>?> getClassDetails(String classId) async {
    try {
      final doc = await _firestore.collection('sections').doc(classId).get();

      if (doc.exists) {
        final data = doc.data()!;
        return {
          'id': doc.id,
          'sectionCode': data['sectionCode'] ?? '',
          'courseName': data['courseName'] ?? '',
          'courseCode': data['courseCode'] ?? '',
          'departmentName': data['departmentName'] ?? '',
          'students': data['students'] ?? 0,
          'isActive': data['isActive'] ?? true,
        };
      }
      return null;
    } catch (e) {
      errorMessage.value = 'Failed to get class details: $e';
      return null;
    }
  }

  /// Get student count for a specific class from instructor's students subcollection
  Future<int> getStudentCount(String classId) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return 0;

      // First get the sectionId from the instructor's classes subcollection
      final classDoc =
          await _firestore
              .collection('instructors')
              .doc(user.uid)
              .collection('classes')
              .doc(classId)
              .get();

      if (!classDoc.exists) return 0;

      final classData = classDoc.data()!;
      final sectionId = classData['sectionId'] ?? '';

      if (sectionId.isEmpty) return 0;

      // Get the sectionCode from the sections collection using sectionId
      final sectionDoc =
          await _firestore.collection('sections').doc(sectionId).get();
      if (!sectionDoc.exists) return 0;

      final sectionData = sectionDoc.data()!;
      final sectionCode = sectionData['sectionCode'] ?? '';

      if (sectionCode.isEmpty) return 0;

      // Query instructor's students subcollection for approved students in this section
      final snapshot =
          await _firestore
              .collection('instructors')
              .doc(user.uid)
              .collection('students')
              .where('selectedSectionCode', isEqualTo: sectionCode)
              .where('enrollmentStatus', isEqualTo: 'approved')
              .get();

      return snapshot.docs.length;
    } catch (e) {
      errorMessage.value = 'Failed to get student count: $e';
      return 0;
    }
  }
}
