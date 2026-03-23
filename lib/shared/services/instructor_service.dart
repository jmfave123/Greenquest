import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'student_data_service.dart';

/// Service to handle instructor-related operations
class InstructorService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the selected instructor for the current user
  static Future<Map<String, dynamic>?> getSelectedInstructor() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Get user from cache to find selected instructor
      final userData = await StudentDataService.getStudentData();
      if (userData == null) return null;

      final selectedInstructorId = userData['selectedInstructorId'] as String?;
      final selectedInstructorName =
          userData['selectedInstructorName'] as String?;

      if (selectedInstructorId == null || selectedInstructorId.isEmpty) {
        return null;
      }

      // Get instructor details from instructors collection
      final instructorDoc =
          await _firestore
              .collection('instructors')
              .doc(selectedInstructorId)
              .get();

      if (!instructorDoc.exists) {
        // If instructor document doesn't exist, return basic info from user data
        return {
          'id': selectedInstructorId,
          'name': selectedInstructorName ?? 'Unknown Instructor',
          'email': '',
          'phone': '',
          'profileImage': null,
          'isOnline': false,
        };
      }

      final instructorData = instructorDoc.data() as Map<String, dynamic>;

      return {
        'id': selectedInstructorId,
        'name':
            instructorData['name'] ??
            selectedInstructorName ??
            'Unknown Instructor',
        'email': instructorData['email'] ?? '',
        'phone': instructorData['phone'] ?? '',
        'profileImage':
            instructorData['profileImageUrl'] ?? instructorData['profileImage'],
        'profileImageUrl': instructorData['profileImageUrl'],
        'isOnline': instructorData['isOnline'] ?? false,
        'lastSeen': instructorData['lastSeen'],
      };
    } catch (e) {
      print('Error getting selected instructor: $e');
      return null;
    }
  }

  /// Get instructor initials from name
  static String getInitials(String name) {
    if (name.isEmpty) return '?';

    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0][0].toUpperCase();
    }

    final firstInitial = words[0][0].toUpperCase();
    final lastInitial = words[words.length - 1][0].toUpperCase();

    return '$firstInitial$lastInitial';
  }

  /// Check if instructor is online
  static Future<bool> isInstructorOnline(String instructorId) async {
    try {
      final instructorDoc =
          await _firestore.collection('instructors').doc(instructorId).get();

      if (!instructorDoc.exists) return false;

      final data = instructorDoc.data() as Map<String, dynamic>;
      return data['isOnline'] ?? false;
    } catch (e) {
      print('Error checking instructor online status: $e');
      return false;
    }
  }

  /// Get instructor's last seen timestamp
  static Future<DateTime?> getInstructorLastSeen(String instructorId) async {
    try {
      final instructorDoc =
          await _firestore.collection('instructors').doc(instructorId).get();

      if (!instructorDoc.exists) return null;

      final data = instructorDoc.data() as Map<String, dynamic>;
      final lastSeen = data['lastSeen'];

      if (lastSeen is Timestamp) {
        return lastSeen.toDate();
      }

      return null;
    } catch (e) {
      print('Error getting instructor last seen: $e');
      return null;
    }
  }

  /// Format last seen time for display
  static String formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'Offline';

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Online';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return 'Last seen ${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
    }
  }
}
