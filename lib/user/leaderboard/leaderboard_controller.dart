import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/services/student_data_service.dart';

class LeaderboardController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Leaderboard data
  var leaderboardData =
      <String, List<Map<String, dynamic>>>{
        'All': [],
        'Quizzes': [],
        'Activities': [],
        'PIT': [],
        'Assignments': [],
      }.obs;
  var isLoadingLeaderboard = true.obs;
  var currentInstructorId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadLeaderboardData();
  }

  /// Load leaderboard data for students
  Future<void> loadLeaderboardData() async {
    try {
      isLoadingLeaderboard.value = true;
      final user = _auth.currentUser;
      if (user == null) return;

      // Get current user's instructor
      final instructorInfo = await _getCurrentInstructor();
      if (instructorInfo == null) {
        print('No instructor found for current user');
        return;
      }

      final instructorId = instructorInfo['instructorId']!;
      currentInstructorId.value = instructorId;

      // Load all leaderboards in parallel using optimized queries
      await _loadAllLeaderboardsOptimized(instructorId);
    } catch (e) {
      print('Error loading leaderboard data: $e');
    } finally {
      isLoadingLeaderboard.value = false;
    }
  }

  /// Get current user's instructor information from cache
  Future<Map<String, String>?> _getCurrentInstructor() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userData = await StudentDataService.getStudentData();
      if (userData != null) {
        final instructorId = userData['selectedInstructorId'] as String?;

        if (instructorId != null && instructorId.isNotEmpty) {
          return {
            'instructorId': instructorId,
            'instructorName':
                (userData['selectedInstructorName'] as String?) ??
                'Unknown Instructor',
          };
        }
      }
      return null;
    } catch (e) {
      print('Error getting current instructor: $e');
      return null;
    }
  }

  /// Optimized method to load all leaderboards with minimal queries
  Future<void> _loadAllLeaderboardsOptimized(String instructorId) async {
    try {
      // Step 1: Get enrolled student IDs from instructor's students subcollection
      final enrolledStudentsQuery =
          await _firestore
              .collection('instructors')
              .doc(instructorId)
              .collection('students')
              .get();

      if (enrolledStudentsQuery.docs.isEmpty) {
        leaderboardData['All'] = [];
        leaderboardData['Quizzes'] = [];
        leaderboardData['Activities'] = [];
        leaderboardData['PIT'] = [];
        leaderboardData['Assignments'] = [];
        return;
      }

      // Get enrolled student IDs
      final enrolledStudentIds =
          enrolledStudentsQuery.docs.map((doc) => doc.id).toSet();

      // Step 2: Get all students for this instructor (1 query)
      final studentsQuery =
          await _firestore
              .collection('users')
              .where('selectedInstructorId', isEqualTo: instructorId)
              .get();

      if (studentsQuery.docs.isEmpty) {
        leaderboardData['All'] = [];
        leaderboardData['Quizzes'] = [];
        leaderboardData['Activities'] = [];
        leaderboardData['PIT'] = [];
        leaderboardData['Assignments'] = [];
        return;
      }

      // Step 3: Get ALL submissions for this instructor in one query
      final allSubmissions =
          await _firestore
              .collection('submissions')
              .where('instructorId', isEqualTo: instructorId)
              .get();

      // Step 3: Build points map for each student by category
      Map<String, Map<String, int>> studentPoints = {};

      for (var submissionDoc in allSubmissions.docs) {
        final data = submissionDoc.data();
        final studentId = data['studentId'] as String?;
        final activityType = data['activityType'] as String?;
        final grade = data['grade'];

        if (studentId == null || grade == null) continue;

        final points = (grade is num) ? grade.toInt() : 0;

        // Initialize student entry if not exists
        if (!studentPoints.containsKey(studentId)) {
          studentPoints[studentId] = {
            'total': 0,
            'quiz': 0,
            'activity': 0,
            'pit': 0,
            'assignment': 0,
          };
        }

        // Add points to total
        studentPoints[studentId]!['total'] =
            (studentPoints[studentId]!['total'] ?? 0) + points;

        // Add points to specific category
        if (activityType == 'quiz') {
          studentPoints[studentId]!['quiz'] =
              (studentPoints[studentId]!['quiz'] ?? 0) + points;
        } else if (activityType == 'activity') {
          studentPoints[studentId]!['activity'] =
              (studentPoints[studentId]!['activity'] ?? 0) + points;
        } else if (activityType == 'pit') {
          studentPoints[studentId]!['pit'] =
              (studentPoints[studentId]!['pit'] ?? 0) + points;
        } else if (activityType == 'assignment') {
          studentPoints[studentId]!['assignment'] =
              (studentPoints[studentId]!['assignment'] ?? 0) + points;
        }
      }

      // Step 4: Build leaderboard lists - only include enrolled students
      List<Map<String, dynamic>> allLeaderboard = [];
      List<Map<String, dynamic>> quizLeaderboard = [];
      List<Map<String, dynamic>> activityLeaderboard = [];
      List<Map<String, dynamic>> pitLeaderboard = [];
      List<Map<String, dynamic>> assignmentLeaderboard = [];

      for (var studentDoc in studentsQuery.docs) {
        final studentData = studentDoc.data();
        final studentId = studentDoc.id;

        // Skip students who are not enrolled
        if (!enrolledStudentIds.contains(studentId)) continue;

        final studentName =
            (studentData['fullName'] as String?) ??
            (studentData['name'] as String?) ??
            'Unknown Student';

        final studentClass =
            (studentData['selectedSectionCode'] as String?) ??
            (studentData['sectionCode'] as String?) ??
            'Unknown Class';

        final profileImageUrl =
            (studentData['profileImage'] as String?) ??
            (studentData['profileImageUrl'] as String?) ??
            (studentData['profileUrl'] as String?);

        final initials = _getInitials(studentName);

        // Get points for this student (default to 0 if no submissions)
        final totalPoints = studentPoints[studentId]?['total'] ?? 0;
        final quizPoints = studentPoints[studentId]?['quiz'] ?? 0;
        final activityPoints = studentPoints[studentId]?['activity'] ?? 0;
        final pitPoints = studentPoints[studentId]?['pit'] ?? 0;
        final assignmentPoints = studentPoints[studentId]?['assignment'] ?? 0;

        // Add to all leaderboard
        allLeaderboard.add({
          'name': studentName,
          'class': studentClass,
          'points': totalPoints,
          'profileImageUrl': profileImageUrl,
          'initials': initials,
        });

        // Add to quiz leaderboard
        quizLeaderboard.add({
          'name': studentName,
          'class': studentClass,
          'points': quizPoints,
          'profileImageUrl': profileImageUrl,
          'initials': initials,
        });

        // Add to activity leaderboard
        activityLeaderboard.add({
          'name': studentName,
          'class': studentClass,
          'points': activityPoints,
          'profileImageUrl': profileImageUrl,
          'initials': initials,
        });

        // Add to pit leaderboard
        pitLeaderboard.add({
          'name': studentName,
          'class': studentClass,
          'points': pitPoints,
          'profileImageUrl': profileImageUrl,
          'initials': initials,
        });

        // Add to assignment leaderboard
        assignmentLeaderboard.add({
          'name': studentName,
          'class': studentClass,
          'points': assignmentPoints,
          'profileImageUrl': profileImageUrl,
          'initials': initials,
        });
      }

      // Step 5: Sort all leaderboards by points (highest first)
      allLeaderboard.sort(
        (a, b) => (b['points'] as int).compareTo(a['points'] as int),
      );
      quizLeaderboard.sort(
        (a, b) => (b['points'] as int).compareTo(a['points'] as int),
      );
      activityLeaderboard.sort(
        (a, b) => (b['points'] as int).compareTo(a['points'] as int),
      );
      pitLeaderboard.sort(
        (a, b) => (b['points'] as int).compareTo(a['points'] as int),
      );
      assignmentLeaderboard.sort(
        (a, b) => (b['points'] as int).compareTo(a['points'] as int),
      );

      // Step 6: Update observable data
      leaderboardData['All'] = allLeaderboard;
      leaderboardData['Quizzes'] = quizLeaderboard;
      leaderboardData['Activities'] = activityLeaderboard;
      leaderboardData['PIT'] = pitLeaderboard;
      leaderboardData['Assignments'] = assignmentLeaderboard;
    } catch (e) {
      print('Error loading optimized leaderboards: $e');
      leaderboardData['All'] = [];
      leaderboardData['Quizzes'] = [];
      leaderboardData['Activities'] = [];
      leaderboardData['PIT'] = [];
      leaderboardData['Assignments'] = [];
    }
  }

  /// Refresh leaderboard data
  Future<void> refreshLeaderboard() async {
    await loadLeaderboardData();
  }

  /// Get top 3 students for podium display
  List<Map<String, dynamic>> getTopThree(String category) {
    final data = leaderboardData[category] ?? [];
    return data.take(3).toList();
  }

  /// Get remaining students (after top 3)
  List<Map<String, dynamic>> getRemainingStudents(String category) {
    final data = leaderboardData[category] ?? [];
    return data.skip(3).toList();
  }

  /// Generate initials from full name
  String _getInitials(String fullName) {
    if (fullName.isEmpty) return 'U'; // Default to 'U' for User

    final names = fullName.trim().split(' ');
    if (names.length >= 2) {
      // Get first letter of first name and first letter of last name
      return '${names[0][0].toUpperCase()}${names[names.length - 1][0].toUpperCase()}';
    } else if (names.length == 1) {
      // If only one name, use first two letters
      return names[0].length >= 2
          ? names[0].substring(0, 2).toUpperCase()
          : names[0][0].toUpperCase();
    }
    return 'U';
  }
}
