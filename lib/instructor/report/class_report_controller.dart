import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class ClassReportController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  var instructorName = ''.obs;
  var profileImageUrl = ''.obs;
  var sectionName = ''.obs;
  var courseName = ''.obs;
  var courseCode = ''.obs;
  var departmentName = ''.obs;
  var studentCount = 0.obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var students = <Map<String, dynamic>>[].obs;
  var isLoadingStudents = false.obs;

  // Class ID passed from the reports screen
  String? _classId;

  // Debounce timer to prevent too frequent updates
  Timer? _debounceTimer;

  @override
  void onInit() {
    super.onInit();
    // Load instructor data first
    loadInstructor();

    // Get class ID from arguments if passed
    final arguments = Get.arguments as Map<String, dynamic>?;
    _classId = arguments?['classId'];

    // If we have arguments, we can set some initial values
    if (arguments != null) {
      sectionName.value = arguments['className'] ?? '';
      courseName.value = arguments['courseDescription'] ?? '';
    }

    if (_classId != null) {
      loadClassData();
      loadStudents();
    }
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    super.onClose();
  }

  /// Load instructor name and profile using email query (same pattern as login flow)
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

  /// Load class/section data from Firestore
  Future<void> loadClassData() async {
    if (_classId == null) {
      // Set default values if no class ID is provided
      sectionName.value = 'Unknown Section';
      courseName.value = 'Unknown Course';
      errorMessage.value = 'No class ID provided';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Try to get section data from sections collection first
      final sectionDoc =
          await _firestore.collection('sections').doc(_classId).get();

      if (sectionDoc.exists) {
        final data = sectionDoc.data()!;
        sectionName.value = data['sectionCode'] ?? 'Unknown Section';
        courseName.value = data['courseName'] ?? 'Unknown Course';
        courseCode.value = data['courseCode'] ?? '';
        departmentName.value = data['departmentName'] ?? '';
        studentCount.value = data['students'] ?? 0;
        return;
      }

      // Fallback: try to get from instructor's classes collection
      final user = _auth.currentUser;
      if (user != null) {
        final classDoc =
            await _firestore
                .collection('instructors')
                .doc(user.uid)
                .collection('classes')
                .doc(_classId)
                .get();

        if (classDoc.exists) {
          final data = classDoc.data()!;
          sectionName.value = data['section'] ?? 'Unknown Section';
          courseName.value = data['course'] ?? 'Unknown Course';
          courseCode.value = data['courseCode'] ?? '';
          departmentName.value = data['departmentName'] ?? '';
          studentCount.value =
              0; // Default since we don't have student count in classes
        } else {
          errorMessage.value = 'Class not found';
        }
      } else {
        errorMessage.value = 'No user logged in';
      }
    } catch (e) {
      errorMessage.value = 'Failed to load class data: $e';
      Get.snackbar("Error", "Failed to load class data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Set class ID and load data (called when navigating from reports screen)
  void setClassId(String classId) {
    _classId = classId;
    loadClassData();
  }

  /// Refresh class data
  Future<void> refreshClassData() async {
    await loadClassData();
  }

  /// Get student count for the current class
  /// Handles both sections document ID and classes document ID
  Future<int> getStudentCount() async {
    if (_classId == null) return 0;

    try {
      final User? user = _auth.currentUser;
      if (user == null) return 0;

      String sectionCode = '';

      // First, try to get sectionCode directly from sections collection
      // This handles the case where _classId is a sections document ID
      final sectionDoc =
          await _firestore.collection('sections').doc(_classId).get();

      if (sectionDoc.exists) {
        // _classId is a sections document ID
        final sectionData = sectionDoc.data()!;
        sectionCode = sectionData['sectionCode'] ?? '';
      } else {
        // _classId might be a classes document ID, try to get sectionId first
        final classDoc =
            await _firestore
                .collection('instructors')
                .doc(user.uid)
                .collection('classes')
                .doc(_classId)
                .get();

        if (classDoc.exists) {
          // _classId is a classes document ID
          final classData = classDoc.data()!;
          final sectionId = classData['sectionId'] ?? '';

          if (sectionId.isNotEmpty) {
            // Get the sectionCode from the sections collection using sectionId
            final sectionDocFromId =
                await _firestore.collection('sections').doc(sectionId).get();
            if (sectionDocFromId.exists) {
              final sectionDataFromId = sectionDocFromId.data()!;
              sectionCode = sectionDataFromId['sectionCode'] ?? '';
            }
          }
        }
      }

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

  /// Get formatted section display name (e.g., "BSIT -1A")
  String get formattedSectionName {
    return sectionName.value;
  }

  /// Get formatted course description (e.g., "Bachelor of Science in Information Technology")
  String get formattedCourseDescription {
    return courseName.value;
  }

  /// Get full class title for display
  String get fullClassTitle {
    if (courseCode.value.isNotEmpty && sectionName.value.isNotEmpty) {
      return '$courseCode.value $sectionName.value';
    }
    return sectionName.value;
  }

  /// Get current class ID
  String? get classId => _classId;

  /// Load students for the current section from instructor's students subcollection
  /// Handles both sections document ID and classes document ID
  Future<void> loadStudents() async {
    if (_classId == null) {
      students.value = [];
      return;
    }

    try {
      isLoadingStudents.value = true;

      final User? user = _auth.currentUser;
      if (user == null) {
        errorMessage.value = 'No user logged in';
        return;
      }

      String sectionCode = '';

      print('🔍 DEBUG: Loading students for classId: $_classId');
      print('🔍 DEBUG: Current user UID: ${user.uid}');

      // First, try to get sectionCode directly from sections collection
      // This handles the case where _classId is a sections document ID
      final sectionDoc =
          await _firestore.collection('sections').doc(_classId).get();

      if (sectionDoc.exists) {
        // _classId is a sections document ID
        final sectionData = sectionDoc.data()!;
        sectionCode = sectionData['sectionCode'] ?? '';
        print(
          '✅ DEBUG: Found section document directly. SectionCode: $sectionCode',
        );
      } else {
        print('⚠️ DEBUG: No section document found with ID: $_classId');
        // _classId might be a classes document ID, try to get sectionId first
        final classDoc =
            await _firestore
                .collection('instructors')
                .doc(user.uid)
                .collection('classes')
                .doc(_classId)
                .get();

        if (classDoc.exists) {
          // _classId is a classes document ID
          final classData = classDoc.data()!;
          final sectionId = classData['sectionId'] ?? '';
          print('✅ DEBUG: Found class document. SectionId: $sectionId');

          if (sectionId.isNotEmpty) {
            // Get the sectionCode from the sections collection using sectionId
            final sectionDocFromId =
                await _firestore.collection('sections').doc(sectionId).get();
            if (sectionDocFromId.exists) {
              final sectionDataFromId = sectionDocFromId.data()!;
              sectionCode = sectionDataFromId['sectionCode'] ?? '';
              print(
                '✅ DEBUG: Got sectionCode from sectionId. SectionCode: $sectionCode',
              );
            } else {
              print(
                '❌ DEBUG: No section document found with sectionId: $sectionId',
              );
            }
          } else {
            print('❌ DEBUG: SectionId is empty in class document');
          }
        } else {
          print('❌ DEBUG: No class document found with ID: $_classId');
        }
      }

      if (sectionCode.isEmpty) {
        print('❌ DEBUG: SectionCode is empty, returning empty students list');
        students.value = [];
        studentCount.value = 0;
        return;
      }

      // Query instructor's students subcollection for approved students in this section
      print('🔍 DEBUG: Querying students with sectionCode: $sectionCode');
      print('🔍 DEBUG: Query path: instructors/${user.uid}/students');

      final studentsSnapshot =
          await _firestore
              .collection('instructors')
              .doc(user.uid)
              .collection('students')
              .where('selectedSectionCode', isEqualTo: sectionCode)
              .where('enrollmentStatus', isEqualTo: 'approved')
              .get();

      print(
        '📊 DEBUG: Found ${studentsSnapshot.docs.length} students in query',
      );

      // Debug: Let's also check all students in the subcollection to see what's there
      final allStudentsSnapshot =
          await _firestore
              .collection('instructors')
              .doc(user.uid)
              .collection('students')
              .get();

      print(
        '📊 DEBUG: Total students in instructor subcollection: ${allStudentsSnapshot.docs.length}',
      );

      for (var doc in allStudentsSnapshot.docs) {
        final data = doc.data();
        print(
          '👤 DEBUG: Student ${doc.id} - selectedSectionCode: ${data['selectedSectionCode']}, enrollmentStatus: ${data['enrollmentStatus']}',
        );
      }

      final List<Map<String, dynamic>> studentList = [];

      for (var doc in studentsSnapshot.docs) {
        final data = doc.data();

        // Fetch idNumber from users collection
        String idNumber = '';
        try {
          // The document ID in students subcollection should be the user document ID
          final userDoc =
              await _firestore.collection('users').doc(doc.id).get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            idNumber = userData['idNumber'] ?? '';
            print('✅ DEBUG: Found idNumber for user ${doc.id}: $idNumber');
          } else {
            print('❌ DEBUG: No user document found for ID: ${doc.id}');
          }
        } catch (e) {
          print('Error fetching idNumber for student ${doc.id}: $e');
        }

        studentList.add({
          'id': doc.id, // Keep document ID for internal use
          'studentId': data['studentId'] ?? doc.id,
          'idNumber': idNumber, // Use the idNumber from users collection
          'name': data['studentName'] ?? 'Unknown Student',
          'email': data['email'] ?? '',
          'enrollmentStatus': data['enrollmentStatus'] ?? 'approved',
          'isActive': data['isActive'] ?? true,
          'isOnline': data['isOnline'] ?? false,
          'enrolledAt': data['enrolledAt'] ?? data['createdAt'],
        });
      }

      print('✅ DEBUG: Final student list length: ${studentList.length}');
      students.value = studentList;
      studentCount.value = studentList.length;

      // Load grades for all students
      await loadStudentGrades();
    } catch (e) {
      errorMessage.value = 'Failed to load students: $e';
      students.value = [];
      studentCount.value = 0;
      Get.snackbar("Error", "Failed to load students: $e");
    } finally {
      isLoadingStudents.value = false;
    }
  }

  /// Get real-time stream of students with grades
  Stream<List<Map<String, dynamic>>> getStudentsStream() {
    if (_classId == null) {
      return Stream.value([]);
    }

    final User? user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    // Get section code
    return Stream.periodic(const Duration(milliseconds: 100)).asyncMap((
      _,
    ) async {
      String sectionCode = '';

      // Try to get sectionCode from sections collection
      final sectionDoc =
          await _firestore.collection('sections').doc(_classId).get();
      if (sectionDoc.exists) {
        sectionCode = sectionDoc.data()?['sectionCode'] ?? '';
      } else {
        // Try classes collection
        final classDoc =
            await _firestore
                .collection('instructors')
                .doc(user.uid)
                .collection('classes')
                .doc(_classId)
                .get();
        if (classDoc.exists) {
          final sectionId = classDoc.data()?['sectionId'] ?? '';
          if (sectionId.isNotEmpty) {
            final sectionDocFromId =
                await _firestore.collection('sections').doc(sectionId).get();
            sectionCode = sectionDocFromId.data()?['sectionCode'] ?? '';
          }
        }
      }

      if (sectionCode.isEmpty) {
        return <Map<String, dynamic>>[];
      }

      // Stream from students subcollection
      final studentsSnapshot =
          await _firestore
              .collection('instructors')
              .doc(user.uid)
              .collection('students')
              .where('selectedSectionCode', isEqualTo: sectionCode)
              .where('enrollmentStatus', isEqualTo: 'approved')
              .get();

      final List<Map<String, dynamic>> studentList = [];

      for (var doc in studentsSnapshot.docs) {
        final data = doc.data();

        // Fetch idNumber from users collection
        String idNumber = '';
        try {
          final userDoc =
              await _firestore.collection('users').doc(doc.id).get();
          if (userDoc.exists) {
            idNumber = userDoc.data()?['idNumber'] ?? '';
          }
        } catch (e) {
          print('Error fetching idNumber: $e');
        }

        final student = {
          'id': doc.id,
          'studentId': data['studentId'] ?? doc.id,
          'idNumber': idNumber,
          'name': data['studentName'] ?? 'Unknown Student',
          'email': data['email'] ?? '',
          'enrollmentStatus': data['enrollmentStatus'] ?? 'approved',
          'isActive': data['isActive'] ?? true,
          'isOnline': data['isOnline'] ?? false,
          'enrolledAt': data['enrolledAt'] ?? data['createdAt'],
        };

        // Load grades for this student
        await _loadGradesForStudent(doc.id, student, user.uid, sectionCode);
        studentList.add(student);
      }

      return studentList;
    });
  }

  /// Create a real-time stream that combines students and grades
  Stream<List<Map<String, dynamic>>> createRealTimeStudentsStream() {
    if (_classId == null) {
      return Stream.value([]);
    }

    final User? user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    // First, get section code
    return Stream.fromFuture(_getSectionCode()).asyncExpand((sectionCode) {
      if (sectionCode.isEmpty) {
        return Stream.value(<Map<String, dynamic>>[]);
      }

      // Stream students
      final studentsStream =
          _firestore
              .collection('instructors')
              .doc(user.uid)
              .collection('students')
              .where('selectedSectionCode', isEqualTo: sectionCode)
              .where('enrollmentStatus', isEqualTo: 'approved')
              .snapshots();

      // Stream unified submissions collection for grade updates (single stream)
      final allGradesStream =
          _firestore
              .collection('submissions')
              .where('instructorId', isEqualTo: user.uid)
              .where('sectionName', isEqualTo: sectionCode)
              .snapshots();

      // Combine all streams using StreamController - any change triggers update
      final StreamController<List<Map<String, dynamic>>> controller =
          StreamController<List<Map<String, dynamic>>>.broadcast();

      StreamSubscription? studentsSub;
      StreamSubscription? allGradesSub;

      Future<void> updateStudents() async {
        final students = await _buildStudentsWithGrades(user.uid, sectionCode);
        if (!controller.isClosed) {
          controller.add(students);
        }
      }

      // Listen to students and unified submissions streams
      studentsSub = studentsStream.listen((_) => updateStudents());
      allGradesSub = allGradesStream.listen((_) => updateStudents());

      // Initial load
      updateStudents();

      // Clean up subscriptions when stream is cancelled
      controller.onCancel = () {
        studentsSub?.cancel();
        allGradesSub?.cancel();
      };

      return controller.stream;
    });
  }

  /// Helper to get section code
  Future<String> _getSectionCode() async {
    if (_classId == null) return '';

    final User? user = _auth.currentUser;
    if (user == null) return '';

    // Try sections collection first
    final sectionDoc =
        await _firestore.collection('sections').doc(_classId).get();
    if (sectionDoc.exists) {
      return sectionDoc.data()?['sectionCode'] ?? '';
    }

    // Try classes collection
    final classDoc =
        await _firestore
            .collection('instructors')
            .doc(user.uid)
            .collection('classes')
            .doc(_classId)
            .get();

    if (classDoc.exists) {
      final sectionId = classDoc.data()?['sectionId'] ?? '';
      if (sectionId.isNotEmpty) {
        final sectionDocFromId =
            await _firestore.collection('sections').doc(sectionId).get();
        return sectionDocFromId.data()?['sectionCode'] ?? '';
      }
    }

    return '';
  }

  /// Build complete student list with grades
  Future<List<Map<String, dynamic>>> _buildStudentsWithGrades(
    String instructorId,
    String sectionCode,
  ) async {
    final studentsSnapshot =
        await _firestore
            .collection('instructors')
            .doc(instructorId)
            .collection('students')
            .where('selectedSectionCode', isEqualTo: sectionCode)
            .where('enrollmentStatus', isEqualTo: 'approved')
            .get();

    final List<Map<String, dynamic>> studentList = [];

    for (var doc in studentsSnapshot.docs) {
      final data = doc.data();

      String idNumber = '';
      try {
        final userDoc = await _firestore.collection('users').doc(doc.id).get();
        if (userDoc.exists) {
          idNumber = userDoc.data()?['idNumber'] ?? '';
        }
      } catch (e) {
        print('Error fetching idNumber: $e');
      }

      final student = {
        'id': doc.id,
        'studentId': data['studentId'] ?? doc.id,
        'idNumber': idNumber,
        'name': data['studentName'] ?? 'Unknown Student',
        'email': data['email'] ?? '',
        'enrollmentStatus': data['enrollmentStatus'] ?? 'approved',
        'isActive': data['isActive'] ?? true,
        'isOnline': data['isOnline'] ?? false,
        'enrolledAt': data['enrolledAt'] ?? data['createdAt'],
      };

      // Load all grades for this student
      await _loadGradesForStudent(doc.id, student, instructorId, sectionCode);
      studentList.add(student);
    }

    return studentList;
  }

  /// Load students for a specific section code from instructor's students subcollection
  Future<void> loadStudentsBySectionCode(String sectionCode) async {
    try {
      isLoadingStudents.value = true;

      final User? user = _auth.currentUser;
      if (user == null) {
        errorMessage.value = 'No user logged in';
        return;
      }

      // Query instructor's students subcollection for approved students in this section
      final studentsSnapshot =
          await _firestore
              .collection('instructors')
              .doc(user.uid)
              .collection('students')
              .where('selectedSectionCode', isEqualTo: sectionCode)
              .where('enrollmentStatus', isEqualTo: 'approved')
              .get();

      final List<Map<String, dynamic>> studentList = [];

      for (var doc in studentsSnapshot.docs) {
        final data = doc.data();

        // Fetch idNumber from users collection
        String idNumber = '';
        try {
          // The document ID in students subcollection should be the user document ID
          final userDoc =
              await _firestore.collection('users').doc(doc.id).get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            idNumber = userData['idNumber'] ?? '';
            print('✅ DEBUG: Found idNumber for user ${doc.id}: $idNumber');
          } else {
            print('❌ DEBUG: No user document found for ID: ${doc.id}');
          }
        } catch (e) {
          print('Error fetching idNumber for student ${doc.id}: $e');
        }

        studentList.add({
          'id': doc.id, // Keep document ID for internal use
          'studentId': data['studentId'] ?? doc.id,
          'idNumber': idNumber, // Use the idNumber from users collection
          'name': data['studentName'] ?? 'Unknown Student',
          'email': data['email'] ?? '',
          'enrollmentStatus': data['enrollmentStatus'] ?? 'approved',
          'isActive': data['isActive'] ?? true,
          'isOnline': data['isOnline'] ?? false,
          'enrolledAt': data['enrolledAt'] ?? data['createdAt'],
        });
      }

      students.value = studentList;
      studentCount.value = studentList.length;

      // Load grades for all students
      await loadStudentGrades();
    } catch (e) {
      errorMessage.value =
          'Failed to load students for section $sectionCode: $e';
      students.value = [];
      studentCount.value = 0;
      Get.snackbar("Error", "Failed to load students: $e");
    } finally {
      isLoadingStudents.value = false;
    }
  }

  /// Refresh students data
  Future<void> refreshStudents() async {
    await loadStudents();
  }

  /// Load grades from submissions for all students
  Future<void> loadStudentGrades() async {
    if (_classId == null || students.isEmpty) return;

    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      String sectionCode = sectionName.value;
      if (sectionCode.isEmpty) return;

      print('🔍 Loading student grades for section: $sectionCode');

      // Load grades for each student
      for (var student in students) {
        final studentId = student['id'] as String;

        // Load grades from all submission collections
        await _loadGradesForStudent(studentId, student, user.uid, sectionCode);
      }

      students.refresh();
      print('✅ Loaded grades for ${students.length} students');
    } catch (e) {
      print('❌ Error loading student grades: $e');
    }
  }

  /// Load grades for a specific student from unified submissions collection
  Future<void> _loadGradesForStudent(
    String studentId,
    Map<String, dynamic> student,
    String instructorId,
    String sectionCode,
  ) async {
    try {
      // Load all grades from unified submissions collection (single query)
      Query query = _firestore
          .collection('submissions')
          .where('studentId', isEqualTo: studentId)
          .where('instructorId', isEqualTo: instructorId)
          .where('sectionName', isEqualTo: sectionCode);

      final snapshot = await query.get();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        final activityType = data['activityType'] as String?;
        final activityId = data['activityId'] as String?;
        final grade = data['grade'];

        if (activityType != null && activityId != null && grade != null) {
          // Get item details based on activityType
          final itemDetails = await _getItemDetailsByActivityType(
            activityId,
            activityType,
          );
          if (itemDetails != null) {
            final title = itemDetails['title'] as String?;
            if (title != null) {
              final key = _createGradeKey(title, activityId);
              student[key] = grade.toString();
              print('  ✅ Loaded grade for $key ($activityType): $grade');
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error loading grades for student $studentId: $e');
    }
  }

  /// Load grades from a specific submission collection (legacy method - kept for backwards compatibility)
  @Deprecated('Use _loadGradesForStudent which uses unified collection')
  Future<void> _loadGradesFromCollection(
    String studentId,
    Map<String, dynamic> student,
    String collection,
    String idField,
    String instructorId,
    String sectionCode, {
    String? activityType,
  }) async {
    // This method is deprecated but kept for backwards compatibility
    // It now uses the unified submissions collection
    try {
      Query query = _firestore
          .collection('submissions')
          .where('studentId', isEqualTo: studentId)
          .where('instructorId', isEqualTo: instructorId)
          .where('sectionName', isEqualTo: sectionCode);

      // Map collection to activityType if not provided
      if (activityType == null) {
        if (collection == 'assignment_submissions') {
          activityType = 'assignment';
        } else if (collection == 'activity_submissions') {
          activityType = 'activity';
        } else if (collection == 'quiz_submissions') {
          activityType = 'quiz';
        } else if (collection == 'submissions') {
          activityType = 'pit';
        }
      }

      // Add activityType filter
      if (activityType != null) {
        query = query.where('activityType', isEqualTo: activityType);
      }

      final snapshot = await query.get();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        final activityId = data['activityId'] as String?; // Unified activity ID
        final grade = data['grade'];

        if (activityId != null && grade != null && activityType != null) {
          // Get item details to create the key
          final itemDetails = await _getItemDetailsByActivityType(
            activityId,
            activityType,
          );
          if (itemDetails != null) {
            final title = itemDetails['title'] as String?;
            if (title != null) {
              final key = _createGradeKey(title, activityId);
              student[key] = grade.toString();
              print('  ✅ Loaded grade for $key: $grade');
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error loading from collection $collection: $e');
    }
  }

  /// Get item details to construct the grade key (using activityType)
  Future<Map<String, dynamic>?> _getItemDetailsByActivityType(
    String itemId,
    String activityType,
  ) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return null;

      // Map activityType to item collection type
      String itemCollection = '';
      switch (activityType.toLowerCase()) {
        case 'assignment':
          itemCollection = 'assignments';
          break;
        case 'activity':
          itemCollection = 'activities';
          break;
        case 'quiz':
          itemCollection = 'quizzes';
          break;
        case 'pit':
          itemCollection = 'pits';
          break;
        default:
          return null;
      }

      final doc =
          await _firestore
              .collection('instructors')
              .doc(user.uid)
              .collection(itemCollection)
              .doc(itemId)
              .get();

      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      print('❌ Error getting item details for $itemId ($activityType): $e');
    }
    return null;
  }

  /// Get item details to construct the grade key (legacy method - kept for backwards compatibility)
  @Deprecated('Use _getItemDetailsByActivityType instead')
  Future<Map<String, dynamic>?> _getItemDetails(
    String itemId,
    String collection,
  ) async {
    // Map collection to activityType for backwards compatibility
    String activityType = '';
    if (collection == 'assignment_submissions') {
      activityType = 'assignment';
    } else if (collection == 'activity_submissions') {
      activityType = 'activity';
    } else if (collection == 'quiz_submissions') {
      activityType = 'quiz';
    } else if (collection == 'submissions') {
      activityType = 'pit';
    }

    if (activityType.isEmpty) return null;

    return _getItemDetailsByActivityType(itemId, activityType);
  }

  /// Create the grade key based on title and ID (matches table logic)
  String _createGradeKey(String title, String id) {
    // Convert title to lowercase and remove spaces
    String key = title.toLowerCase().replaceAll(' ', '');
    return '${key}_$id';
  }

  /// Get filtered students based on search query
  List<Map<String, dynamic>> getFilteredStudents(String searchQuery) {
    if (searchQuery.isEmpty) {
      return students;
    }

    final query = searchQuery.toLowerCase();
    return students.where((student) {
      final name = student['name']?.toString().toLowerCase() ?? '';
      final idNumber = student['idNumber']?.toString().toLowerCase() ?? '';
      final email = student['email']?.toString().toLowerCase() ?? '';

      return name.contains(query) ||
          idNumber.contains(query) ||
          email.contains(query);
    }).toList();
  }

  /// Get students with specific enrollment status
  List<Map<String, dynamic>> getStudentsByStatus(String status) {
    if (status == 'All') {
      return students;
    }

    return students.where((student) {
      return student['enrollmentStatus'] == status.toLowerCase();
    }).toList();
  }
}
