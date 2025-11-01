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
    loadDashboardStats();
    loadLeaderboardData();
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
        // Try profileUrl first, then fall back to profileImageUrl
        profileImageUrl.value =
            doc['profileUrl'] ?? doc['profileImageUrl'] ?? '';
      } else {
        instructorName.value = 'Instructor not found';
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

  /// Load leaderboard data for students
  Future<void> loadLeaderboardData() async {
    try {
      isLoadingLeaderboard.value = true;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

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
  Future<void> _loadTotalLeaderboard(String instructorId) async {
    try {
      // Get all students enrolled with this instructor
      final studentsQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .where('selectedInstructorId', isEqualTo: instructorId)
              .get();

      List<Map<String, dynamic>> studentsWithPoints = [];

      for (var studentDoc in studentsQuery.docs) {
        final studentData = studentDoc.data();
        final studentId = studentDoc.id;

        // Calculate total points from all submissions
        int totalPoints = await _calculateTotalPoints(studentId, instructorId);

        studentsWithPoints.add({
          'name':
              studentData['fullName'] ??
              studentData['name'] ??
              'Unknown Student',
          'class':
              studentData['selectedSectionCode'] ??
              studentData['sectionCode'] ??
              'Unknown Class',
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
  Future<void> _loadAssignmentsLeaderboard(String instructorId) async {
    try {
      // Get all students enrolled with this instructor
      final studentsQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .where('selectedInstructorId', isEqualTo: instructorId)
              .get();

      List<Map<String, dynamic>> studentsWithPoints = [];

      for (var studentDoc in studentsQuery.docs) {
        final studentData = studentDoc.data();
        final studentId = studentDoc.id;

        // Calculate points from assignment submissions only
        int assignmentPoints = await _calculateAssignmentPoints(
          studentId,
          instructorId,
        );

        studentsWithPoints.add({
          'name':
              studentData['fullName'] ??
              studentData['name'] ??
              'Unknown Student',
          'class':
              studentData['selectedSectionCode'] ??
              studentData['sectionCode'] ??
              'Unknown Class',
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
  Future<void> _loadActivitiesLeaderboard(String instructorId) async {
    try {
      // Get all students enrolled with this instructor
      final studentsQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .where('selectedInstructorId', isEqualTo: instructorId)
              .get();

      List<Map<String, dynamic>> studentsWithPoints = [];

      for (var studentDoc in studentsQuery.docs) {
        final studentData = studentDoc.data();
        final studentId = studentDoc.id;

        // Calculate points from activity submissions only
        int activityPoints = await _calculateActivityPoints(
          studentId,
          instructorId,
        );

        studentsWithPoints.add({
          'name':
              studentData['fullName'] ??
              studentData['name'] ??
              'Unknown Student',
          'class':
              studentData['selectedSectionCode'] ??
              studentData['sectionCode'] ??
              'Unknown Class',
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
