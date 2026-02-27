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
    } catch (e) {
      studentCount.value = 0;
    }
  }

  /// Load count of planted trees from approved tree planting submissions
  /// Only counts trees from this instructor's students
  Future<void> _loadPlantedTreesCount(String instructorId) async {
    try {
      // Query approved tree planting submissions for this instructor
      final treesQuery =
          await FirebaseFirestore.instance
              .collection('submissions')
              .where('activityType', isEqualTo: 'tree_planting')
              .where('instructorId', isEqualTo: instructorId)
              .where('status', isEqualTo: 'approved')
              .get();

      // Sum up the quantity of all approved tree planting submissions
      int totalTrees = 0;
      for (var doc in treesQuery.docs) {
        final data = doc.data();
        final quantity = data['quantity'];
        if (quantity is num) {
          totalTrees += quantity.toInt();
        } else {
          totalTrees += 1; // Default to 1 if quantity is not specified
        }
      }

      plantedTreesCount.value = totalTrees;
      print('✅ Loaded $totalTrees planted trees from approved submissions');
    } catch (e) {
      print('❌ Error loading planted trees count: $e');
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
  /// Uses optimized approach: gets all students and submissions in minimal queries
  Future<void> _loadTotalLeaderboard(String instructorId) async {
    try {
      // Get enrolled student IDs from instructor's students subcollection
      final enrolledStudentsQuery =
          await FirebaseFirestore.instance
              .collection('instructors')
              .doc(instructorId)
              .collection('students')
              .get();

      if (enrolledStudentsQuery.docs.isEmpty) {
        leaderboardData['Total'] = [];
        return;
      }

      // Get enrolled student IDs
      final enrolledStudentIds =
          enrolledStudentsQuery.docs.map((doc) => doc.id).toSet();

      // Get all students for this instructor (1 query)
      final studentsQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .where('selectedInstructorId', isEqualTo: instructorId)
              .get();

      if (studentsQuery.docs.isEmpty) {
        leaderboardData['Total'] = [];
        return;
      }

      // Get ALL submissions for this instructor in one query
      final allSubmissions =
          await FirebaseFirestore.instance
              .collection('submissions')
              .where('instructorId', isEqualTo: instructorId)
              .get();

      // Build points map for each student
      Map<String, int> studentTotalPoints = {};

      for (var submissionDoc in allSubmissions.docs) {
        final data = submissionDoc.data();
        final studentId = data['studentId'] as String?;
        final grade = data['grade'];

        if (studentId == null || grade == null) continue;

        final points = (grade is num) ? grade.toInt() : 0;

        // Add points to student's total
        studentTotalPoints[studentId] =
            (studentTotalPoints[studentId] ?? 0) + points;
      }

      // Build leaderboard list - only include enrolled students
      List<Map<String, dynamic>> studentsWithPoints = [];

      for (var studentDoc in studentsQuery.docs) {
        final studentData = studentDoc.data();
        final studentId = studentDoc.id;

        // Skip students who are not enrolled
        if (!enrolledStudentIds.contains(studentId)) continue;

        final points = studentTotalPoints[studentId] ?? 0;

        studentsWithPoints.add({
          'name':
              studentData['fullName'] ??
              studentData['name'] ??
              'Unknown Student',
          'class': studentData['selectedSectionCode'] ?? 'Unknown Class',
          'points': points,
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
  /// Uses optimized approach: gets all students and assignment submissions in minimal queries
  Future<void> _loadAssignmentsLeaderboard(String instructorId) async {
    try {
      // Get enrolled student IDs from instructor's students subcollection
      final enrolledStudentsQuery =
          await FirebaseFirestore.instance
              .collection('instructors')
              .doc(instructorId)
              .collection('students')
              .get();

      if (enrolledStudentsQuery.docs.isEmpty) {
        leaderboardData['Assignments'] = [];
        return;
      }

      // Get enrolled student IDs
      final enrolledStudentIds =
          enrolledStudentsQuery.docs.map((doc) => doc.id).toSet();

      // Get all students for this instructor (1 query)
      final studentsQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .where('selectedInstructorId', isEqualTo: instructorId)
              .get();

      if (studentsQuery.docs.isEmpty) {
        leaderboardData['Assignments'] = [];
        return;
      }

      // Get assignment submissions for this instructor in one query
      final assignmentSubmissions =
          await FirebaseFirestore.instance
              .collection('submissions')
              .where('instructorId', isEqualTo: instructorId)
              .where('activityType', isEqualTo: 'assignment')
              .get();

      // Build points map for each student
      Map<String, int> studentAssignmentPoints = {};

      for (var submissionDoc in assignmentSubmissions.docs) {
        final data = submissionDoc.data();
        final studentId = data['studentId'] as String?;
        final grade = data['grade'];

        if (studentId == null || grade == null) continue;

        final points = (grade is num) ? grade.toInt() : 0;

        // Add points to student's total
        studentAssignmentPoints[studentId] =
            (studentAssignmentPoints[studentId] ?? 0) + points;
      }

      // Build leaderboard list - only include enrolled students
      List<Map<String, dynamic>> studentsWithPoints = [];

      for (var studentDoc in studentsQuery.docs) {
        final studentData = studentDoc.data();
        final studentId = studentDoc.id;

        // Skip students who are not enrolled
        if (!enrolledStudentIds.contains(studentId)) continue;

        final points = studentAssignmentPoints[studentId] ?? 0;

        studentsWithPoints.add({
          'name':
              studentData['fullName'] ??
              studentData['name'] ??
              'Unknown Student',
          'class': studentData['selectedSectionCode'] ?? 'Unknown Class',
          'points': points,
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
  /// Uses optimized approach: gets all students and activity submissions in minimal queries
  Future<void> _loadActivitiesLeaderboard(String instructorId) async {
    try {
      // Get enrolled student IDs from instructor's students subcollection
      final enrolledStudentsQuery =
          await FirebaseFirestore.instance
              .collection('instructors')
              .doc(instructorId)
              .collection('students')
              .get();

      if (enrolledStudentsQuery.docs.isEmpty) {
        leaderboardData['Activities'] = [];
        return;
      }

      // Get enrolled student IDs
      final enrolledStudentIds =
          enrolledStudentsQuery.docs.map((doc) => doc.id).toSet();

      // Get all students for this instructor (1 query)
      final studentsQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .where('selectedInstructorId', isEqualTo: instructorId)
              .get();

      if (studentsQuery.docs.isEmpty) {
        leaderboardData['Activities'] = [];
        return;
      }

      // Get activity submissions for this instructor in one query
      final activitySubmissions =
          await FirebaseFirestore.instance
              .collection('submissions')
              .where('instructorId', isEqualTo: instructorId)
              .where('activityType', isEqualTo: 'activity')
              .get();

      // Build points map for each student
      Map<String, int> studentActivityPoints = {};

      for (var submissionDoc in activitySubmissions.docs) {
        final data = submissionDoc.data();
        final studentId = data['studentId'] as String?;
        final grade = data['grade'];

        if (studentId == null || grade == null) continue;

        final points = (grade is num) ? grade.toInt() : 0;

        // Add points to student's total
        studentActivityPoints[studentId] =
            (studentActivityPoints[studentId] ?? 0) + points;
      }

      // Build leaderboard list - only include enrolled students
      List<Map<String, dynamic>> studentsWithPoints = [];

      for (var studentDoc in studentsQuery.docs) {
        final studentData = studentDoc.data();
        final studentId = studentDoc.id;

        // Skip students who are not enrolled
        if (!enrolledStudentIds.contains(studentId)) continue;

        final points = studentActivityPoints[studentId] ?? 0;

        studentsWithPoints.add({
          'name':
              studentData['fullName'] ??
              studentData['name'] ??
              'Unknown Student',
          'class': studentData['selectedSectionCode'] ?? 'Unknown Class',
          'points': points,
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
}
