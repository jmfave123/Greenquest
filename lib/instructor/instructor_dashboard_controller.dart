import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InstructorController extends GetxController {
  var instructorName = ''.obs;
  var profileImageUrl = ''.obs;

  // Dashboard statistics
  var studentCount = 0.obs;
  var plantedTreesCount = 0.obs;
  var activeClassesCount = 0.obs;
  var isLoadingStats = true.obs;

  // Leaderboard data
  var leaderboardData =
      <String, List<Map<String, dynamic>>>{
        'Total': [],
        'Assignments': [],
        'Activities': [],
      }.obs;
  var isLoadingLeaderboard = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadInstructor();
    // Load dashboard data once when controller is first created (when screen is first shown)
    // This is NOT auto-loading on every lifecycle change - it only happens once
    _initializeDashboard(); // Load stats first, then conditionally load leaderboard
  }

  /// Initialize dashboard - load stats first, then conditionally load leaderboard
  Future<void> _initializeDashboard() async {
    // Load stats first to get activeClassesCount
    await loadDashboardStats();
    // Only load leaderboard if instructor has classes
    loadLeaderboardData();
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
        // Safely access profileUrl - handles cases where field doesn't exist
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
    }
  }

  /// Load dashboard statistics
  Future<void> loadDashboardStats() async {
    try {
      isLoadingStats.value = true;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Load student count
      await _loadStudentCount(user.uid);

      // Load planted trees count
      await _loadPlantedTreesCount(user.uid);

      // Load active classes count
      await _loadActiveClassesCount(user.uid);
    } catch (e) {
      print('Error loading dashboard stats: $e');
    } finally {
      isLoadingStats.value = false;
    }
  }

  /// Load count of students enrolled with this instructor
  /// Only counts APPROVED students from instructors/{instructorId}/students
  Future<void> _loadStudentCount(String instructorId) async {
    try {
      // Count approved students from instructors/{instructorId}/students
      final approvedStudentsQuery =
          await FirebaseFirestore.instance
              .collection('instructors')
              .doc(instructorId)
              .collection('students')
              .get();

      studentCount.value = approvedStudentsQuery.docs.length;
      print(
        '✅ Loaded ${studentCount.value} approved students from instructors/{instructorId}/students',
      );
    } catch (e) {
      print('❌ Error loading student count: $e');
      studentCount.value = 0;
    }
  }

  /// Load count of planted trees (from trees collection with instructorId filter)
  Future<void> _loadPlantedTreesCount(String instructorId) async {
    try {
      final treesQuery =
          await FirebaseFirestore.instance
              .collection('instructors')
              .doc(instructorId)
              .collection('trees')
              .where('instructorId', isEqualTo: instructorId)
              .get();

      // Sum up the quantity of all trees
      int totalTrees = 0;
      for (var doc in treesQuery.docs) {
        final data = doc.data();
        final quantity = data['quantity'] ?? 1;
        totalTrees += quantity is int ? quantity : 1;
      }

      plantedTreesCount.value = totalTrees;
    } catch (e) {
      print('Error loading planted trees count: $e');
      plantedTreesCount.value = 0;
    }
  }

  /// Load count of active classes for this instructor
  Future<void> _loadActiveClassesCount(String instructorId) async {
    try {
      final classesQuery =
          await FirebaseFirestore.instance
              .collection('instructors')
              .doc(instructorId)
              .collection('classes')
              .get();

      activeClassesCount.value = classesQuery.docs.length;
    } catch (e) {
      print('Error loading active classes count: $e');
      activeClassesCount.value = 0;
    }
  }

  /// Get instructor's class section codes for filtering students
  /// Returns a set of section codes that match the instructor's classes
  Future<Set<String>> _getInstructorClassSectionCodes(
    String instructorId,
  ) async {
    try {
      final classesQuery =
          await FirebaseFirestore.instance
              .collection('instructors')
              .doc(instructorId)
              .collection('classes')
              .get();

      Set<String> sectionCodes = {};

      for (var classDoc in classesQuery.docs) {
        final classData = classDoc.data();
        final section = classData['section']?.toString() ?? '';
        final sectionId = classData['sectionId']?.toString() ?? '';

        // Add both section and sectionId to the set
        if (section.isNotEmpty) {
          sectionCodes.add(section);
        }
        if (sectionId.isNotEmpty) {
          sectionCodes.add(sectionId);
        }

        // Also handle full section codes (e.g., "BSIT-4D")
        // Extract the section part if it contains a dash
        if (section.contains('-')) {
          final sectionPart = section.split('-').last;
          if (sectionPart.isNotEmpty) {
            sectionCodes.add(sectionPart);
          }
        }
      }

      return sectionCodes;
    } catch (e) {
      print('Error getting instructor class section codes: $e');
      return {};
    }
  }

  /// Check if a student's section code matches any of the instructor's classes
  bool _matchesInstructorClass(
    String studentSectionCode,
    Set<String> instructorSectionCodes,
  ) {
    if (studentSectionCode.isEmpty) return false;

    // Direct match
    if (instructorSectionCodes.contains(studentSectionCode)) {
      return true;
    }

    // Extract section part if it contains a dash (e.g., "BSIT-4D" -> "4D")
    if (studentSectionCode.contains('-')) {
      final sectionPart = studentSectionCode.split('-').last;
      if (instructorSectionCodes.contains(sectionPart)) {
        return true;
      }
    }

    // Check if any instructor section code matches the student's section
    for (var instructorSection in instructorSectionCodes) {
      if (studentSectionCode.contains(instructorSection) ||
          instructorSection.contains(studentSectionCode)) {
        return true;
      }
    }

    return false;
  }

  /// Load leaderboard data for students
  /// Only loads if instructor has at least one class
  Future<void> loadLeaderboardData() async {
    try {
      isLoadingLeaderboard.value = true;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        isLoadingLeaderboard.value = false;
        return;
      }

      // Check if instructor has any classes - if not, skip loading leaderboard
      if (activeClassesCount.value == 0) {
        print('No classes found for instructor. Skipping leaderboard load.');
        // Clear leaderboard data
        leaderboardData['Total'] = [];
        leaderboardData['Assignments'] = [];
        leaderboardData['Activities'] = [];
        isLoadingLeaderboard.value = false;
        return;
      }

      // Load total points leaderboard
      await _loadTotalLeaderboard(user.uid);

      // Load assignments leaderboard
      await _loadAssignmentsLeaderboard(user.uid);

      // Load activities leaderboard
      await _loadActivitiesLeaderboard(user.uid);
    } catch (e) {
      print('Error loading leaderboard data: $e');
    } finally {
      isLoadingLeaderboard.value = false;
    }
  }

  /// Load total points leaderboard
  /// Only loads approved students enrolled in instructor's classes
  Future<void> _loadTotalLeaderboard(String instructorId) async {
    try {
      // Get instructor's class section codes for filtering
      final instructorSectionCodes = await _getInstructorClassSectionCodes(
        instructorId,
      );

      if (instructorSectionCodes.isEmpty) {
        print('No class sections found for instructor. Skipping leaderboard.');
        leaderboardData['Total'] = [];
        return;
      }

      // Get approved students from instructors/{instructorId}/students
      final approvedStudentsQuery =
          await FirebaseFirestore.instance
              .collection('instructors')
              .doc(instructorId)
              .collection('students')
              .get();

      List<Map<String, dynamic>> studentsWithPoints = [];

      for (var studentDoc in approvedStudentsQuery.docs) {
        final studentData = studentDoc.data();
        final studentId = studentData['studentId'] ?? studentDoc.id;
        final studentSectionCode =
            studentData['selectedSectionCode']?.toString() ?? '';

        // Filter: Only include students whose section matches instructor's classes
        if (!_matchesInstructorClass(
          studentSectionCode,
          instructorSectionCodes,
        )) {
          continue; // Skip students not enrolled in any class
        }

        // Calculate total points from all submissions
        int totalPoints = await _calculateTotalPoints(studentId, instructorId);

        studentsWithPoints.add({
          'name':
              studentData['studentName'] ??
              studentData['name'] ??
              'Unknown Student',
          'class':
              studentSectionCode.isNotEmpty
                  ? studentSectionCode
                  : 'Unknown Class',
          'points': totalPoints,
        });
      }

      // Sort by points (highest first)
      studentsWithPoints.sort(
        (a, b) => (b['points'] as int).compareTo(a['points'] as int),
      );

      leaderboardData['Total'] = studentsWithPoints;
    } catch (e) {
      print('Error loading total leaderboard: $e');
      leaderboardData['Total'] = [];
    }
  }

  /// Load assignments leaderboard
  /// Only loads approved students enrolled in instructor's classes
  Future<void> _loadAssignmentsLeaderboard(String instructorId) async {
    try {
      // Get instructor's class section codes for filtering
      final instructorSectionCodes = await _getInstructorClassSectionCodes(
        instructorId,
      );

      if (instructorSectionCodes.isEmpty) {
        print('No class sections found for instructor. Skipping leaderboard.');
        leaderboardData['Assignments'] = [];
        return;
      }

      // Get approved students from instructors/{instructorId}/students
      final approvedStudentsQuery =
          await FirebaseFirestore.instance
              .collection('instructors')
              .doc(instructorId)
              .collection('students')
              .get();

      List<Map<String, dynamic>> studentsWithPoints = [];

      for (var studentDoc in approvedStudentsQuery.docs) {
        final studentData = studentDoc.data();
        final studentId = studentData['studentId'] ?? studentDoc.id;
        final studentSectionCode =
            studentData['selectedSectionCode']?.toString() ?? '';

        // Filter: Only include students whose section matches instructor's classes
        if (!_matchesInstructorClass(
          studentSectionCode,
          instructorSectionCodes,
        )) {
          continue; // Skip students not enrolled in any class
        }

        // Calculate points from assignment submissions only
        int assignmentPoints = await _calculateAssignmentPoints(
          studentId,
          instructorId,
        );

        studentsWithPoints.add({
          'name':
              studentData['studentName'] ??
              studentData['name'] ??
              'Unknown Student',
          'class':
              studentSectionCode.isNotEmpty
                  ? studentSectionCode
                  : 'Unknown Class',
          'points': assignmentPoints,
        });
      }

      // Sort by points (highest first)
      studentsWithPoints.sort(
        (a, b) => (b['points'] as int).compareTo(a['points'] as int),
      );

      leaderboardData['Assignments'] = studentsWithPoints;
    } catch (e) {
      print('Error loading assignments leaderboard: $e');
      leaderboardData['Assignments'] = [];
    }
  }

  /// Load activities leaderboard
  /// Only loads approved students enrolled in instructor's classes
  Future<void> _loadActivitiesLeaderboard(String instructorId) async {
    try {
      // Get instructor's class section codes for filtering
      final instructorSectionCodes = await _getInstructorClassSectionCodes(
        instructorId,
      );

      if (instructorSectionCodes.isEmpty) {
        print('No class sections found for instructor. Skipping leaderboard.');
        leaderboardData['Activities'] = [];
        return;
      }

      // Get approved students from instructors/{instructorId}/students
      final approvedStudentsQuery =
          await FirebaseFirestore.instance
              .collection('instructors')
              .doc(instructorId)
              .collection('students')
              .get();

      List<Map<String, dynamic>> studentsWithPoints = [];

      for (var studentDoc in approvedStudentsQuery.docs) {
        final studentData = studentDoc.data();
        final studentId = studentData['studentId'] ?? studentDoc.id;
        final studentSectionCode =
            studentData['selectedSectionCode']?.toString() ?? '';

        // Filter: Only include students whose section matches instructor's classes
        if (!_matchesInstructorClass(
          studentSectionCode,
          instructorSectionCodes,
        )) {
          continue; // Skip students not enrolled in any class
        }

        // Calculate points from activity submissions only
        int activityPoints = await _calculateActivityPoints(
          studentId,
          instructorId,
        );

        studentsWithPoints.add({
          'name':
              studentData['studentName'] ??
              studentData['name'] ??
              'Unknown Student',
          'class':
              studentSectionCode.isNotEmpty
                  ? studentSectionCode
                  : 'Unknown Class',
          'points': activityPoints,
        });
      }

      // Sort by points (highest first)
      studentsWithPoints.sort(
        (a, b) => (b['points'] as int).compareTo(a['points'] as int),
      );

      leaderboardData['Activities'] = studentsWithPoints;
    } catch (e) {
      print('Error loading activities leaderboard: $e');
      leaderboardData['Activities'] = [];
    }
  }

  /// Calculate total points for a student from all submissions
  Future<int> _calculateTotalPoints(
    String studentId,
    String instructorId,
  ) async {
    try {
      int totalPoints = 0;

      // Get all submissions from unified collection (single query)
      final allSubmissions =
          await FirebaseFirestore.instance
              .collection('submissions')
              .where('studentId', isEqualTo: studentId)
              .where('instructorId', isEqualTo: instructorId)
              .get();

      for (var doc in allSubmissions.docs) {
        final data = doc.data();
        final grade = data['grade'];
        if (grade != null && grade is num) {
          totalPoints += grade.toInt();
        }
      }

      return totalPoints;
    } catch (e) {
      print('Error calculating total points: $e');
      return 0;
    }
  }

  /// Calculate points from assignment submissions only
  Future<int> _calculateAssignmentPoints(
    String studentId,
    String instructorId,
  ) async {
    try {
      int points = 0;

      final assignmentSubmissions =
          await FirebaseFirestore.instance
              .collection('submissions')
              .where('activityType', isEqualTo: 'assignment')
              .where('studentId', isEqualTo: studentId)
              .where('instructorId', isEqualTo: instructorId)
              .get();

      for (var doc in assignmentSubmissions.docs) {
        final data = doc.data();
        final grade = data['grade'];
        if (grade != null && grade is num) {
          points += grade.toInt();
        }
      }

      return points;
    } catch (e) {
      print('Error calculating assignment points: $e');
      return 0;
    }
  }

  /// Calculate points from activity submissions only
  Future<int> _calculateActivityPoints(
    String studentId,
    String instructorId,
  ) async {
    try {
      int points = 0;

      final activitySubmissions =
          await FirebaseFirestore.instance
              .collection('submissions')
              .where('activityType', isEqualTo: 'activity')
              .where('studentId', isEqualTo: studentId)
              .where('instructorId', isEqualTo: instructorId)
              .get();

      for (var doc in activitySubmissions.docs) {
        final data = doc.data();
        final grade = data['grade'];
        if (grade != null && grade is num) {
          points += grade.toInt();
        }
      }

      return points;
    } catch (e) {
      print('Error calculating activity points: $e');
      return 0;
    }
  }
}
