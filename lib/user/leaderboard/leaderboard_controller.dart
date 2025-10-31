import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaderboardController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Leaderboard data
  var leaderboardData =
      <String, List<Map<String, dynamic>>>{
        'All': [],
        'Quizzes': [],
        'Activities': [],
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

      // Load total points leaderboard (All)
      await _loadTotalLeaderboard(instructorId);

      // Load quizzes leaderboard
      await _loadQuizzesLeaderboard(instructorId);

      // Load activities leaderboard
      await _loadActivitiesLeaderboard(instructorId);
    } catch (e) {
      print('Error loading leaderboard data: $e');
    } finally {
      isLoadingLeaderboard.value = false;
    }
  }

  /// Get current user's instructor information
  Future<Map<String, String>?> _getCurrentInstructor() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
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

  /// Load total points leaderboard (All submissions)
  Future<void> _loadTotalLeaderboard(String instructorId) async {
    try {
      // Get all students enrolled with this instructor
      final studentsQuery =
          await _firestore
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
              (studentData['fullName'] as String?) ??
              (studentData['name'] as String?) ??
              'Unknown Student',
          'class':
              (studentData['selectedSectionCode'] as String?) ??
              (studentData['sectionCode'] as String?) ??
              'Unknown Class',
          'points': totalPoints,
          'profileImageUrl':
              (studentData['profileImage'] as String?) ??
              (studentData['profileImageUrl'] as String?) ??
              (studentData['profileUrl']
                  as String?), // Will use initials fallback
          'initials': _getInitials(
            studentData['fullName'] ?? studentData['name'] ?? 'Unknown Student',
          ),
        });
      }

      // Sort by points (highest first)
      studentsWithPoints.sort(
        (a, b) => (b['points'] as int).compareTo(a['points'] as int),
      );

      leaderboardData['All'] = studentsWithPoints;
    } catch (e) {
      print('Error loading total leaderboard: $e');
      leaderboardData['All'] = [];
    }
  }

  /// Load quizzes leaderboard
  Future<void> _loadQuizzesLeaderboard(String instructorId) async {
    try {
      // Get all students enrolled with this instructor
      final studentsQuery =
          await _firestore
              .collection('users')
              .where('selectedInstructorId', isEqualTo: instructorId)
              .get();

      List<Map<String, dynamic>> studentsWithPoints = [];

      for (var studentDoc in studentsQuery.docs) {
        final studentData = studentDoc.data();
        final studentId = studentDoc.id;

        // Calculate points from quiz submissions only
        int quizPoints = await _calculateQuizPoints(studentId, instructorId);

        studentsWithPoints.add({
          'name':
              (studentData['fullName'] as String?) ??
              (studentData['name'] as String?) ??
              'Unknown Student',
          'class':
              (studentData['selectedSectionCode'] as String?) ??
              (studentData['sectionCode'] as String?) ??
              'Unknown Class',
          'points': quizPoints,
          'profileImageUrl':
              (studentData['profileImage'] as String?) ??
              (studentData['profileImageUrl'] as String?) ??
              (studentData['profileUrl']
                  as String?), // Will use initials fallback
          'initials': _getInitials(
            studentData['fullName'] ?? studentData['name'] ?? 'Unknown Student',
          ),
        });
      }

      // Sort by points (highest first)
      studentsWithPoints.sort(
        (a, b) => (b['points'] as int).compareTo(a['points'] as int),
      );

      leaderboardData['Quizzes'] = studentsWithPoints;
    } catch (e) {
      print('Error loading quizzes leaderboard: $e');
      leaderboardData['Quizzes'] = [];
    }
  }

  /// Load activities leaderboard
  Future<void> _loadActivitiesLeaderboard(String instructorId) async {
    try {
      // Get all students enrolled with this instructor
      final studentsQuery =
          await _firestore
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
              (studentData['fullName'] as String?) ??
              (studentData['name'] as String?) ??
              'Unknown Student',
          'class':
              (studentData['selectedSectionCode'] as String?) ??
              (studentData['sectionCode'] as String?) ??
              'Unknown Class',
          'points': activityPoints,
          'profileImageUrl':
              (studentData['profileImage'] as String?) ??
              (studentData['profileImageUrl'] as String?) ??
              (studentData['profileUrl']
                  as String?), // Will use initials fallback
          'initials': _getInitials(
            studentData['fullName'] ?? studentData['name'] ?? 'Unknown Student',
          ),
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

      // Get assignment submissions
      final assignmentSubmissions =
          await _firestore
              .collection('assignment_submissions')
              .where('studentId', isEqualTo: studentId)
              .where('instructorId', isEqualTo: instructorId)
              .get();

      for (var doc in assignmentSubmissions.docs) {
        final data = doc.data();
        final grade = data['grade'];
        if (grade != null && grade is num) {
          totalPoints += grade.toInt();
        }
      }

      // Get activity submissions
      final activitySubmissions =
          await _firestore
              .collection('activity_submissions')
              .where('studentId', isEqualTo: studentId)
              .where('instructorId', isEqualTo: instructorId)
              .get();

      for (var doc in activitySubmissions.docs) {
        final data = doc.data();
        final grade = data['grade'];
        if (grade != null && grade is num) {
          totalPoints += grade.toInt();
        }
      }

      // Get quiz submissions
      final quizSubmissions =
          await _firestore
              .collection('quiz_submissions')
              .where('studentId', isEqualTo: studentId)
              .where('instructorId', isEqualTo: instructorId)
              .get();

      for (var doc in quizSubmissions.docs) {
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

  /// Calculate points from quiz submissions only
  Future<int> _calculateQuizPoints(
    String studentId,
    String instructorId,
  ) async {
    try {
      int points = 0;

      final quizSubmissions =
          await _firestore
              .collection('quiz_submissions')
              .where('studentId', isEqualTo: studentId)
              .where('instructorId', isEqualTo: instructorId)
              .get();

      for (var doc in quizSubmissions.docs) {
        final data = doc.data();
        final grade = data['grade'];
        if (grade != null && grade is num) {
          points += grade.toInt();
        }
      }

      return points;
    } catch (e) {
      print('Error calculating quiz points: $e');
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
          await _firestore
              .collection('activity_submissions')
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
