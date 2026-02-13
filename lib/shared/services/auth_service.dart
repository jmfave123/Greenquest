import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

/// Service to handle authentication state and user role checks
class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current Firebase user
  User? get currentUser => _auth.currentUser;

  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Get the current user's role (admin, instructor, or student)
  Future<String?> getUserRole() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      // Check if user is an admin
      final adminQuery = await _firestore
          .collection('admins')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (adminQuery.docs.isNotEmpty) {
        return 'admin';
      }

      // Check if user is an instructor
      final instructorQuery = await _firestore
          .collection('instructors')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (instructorQuery.docs.isNotEmpty) {
        final instructorData = instructorQuery.docs.first.data();
        final status = instructorData['status']?.toString() ?? 'Pending';
        final isActive = instructorData['isActive'] ?? false;

        // Only return instructor if approved and active
        if (status == 'Approved' && isActive) {
          return 'instructor';
        }
        return null; // Instructor exists but not approved or inactive
      }

      // Check if user is a student
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final studentData = userDoc.data() as Map<String, dynamic>;
        final status = studentData['enrollmentStatus']?.toString() ?? 'none';

        // Only return student if approved
        if (status == 'approved') {
          return 'student';
        }
        return null; // Student exists but not approved
      }

      return null;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  /// Check if current user has admin role
  Future<bool> isAdmin() async {
    final role = await getUserRole();
    return role == 'admin';
  }

  /// Check if current user has instructor role
  Future<bool> isInstructor() async {
    final role = await getUserRole();
    return role == 'instructor';
  }

  /// Check if current user has student role
  Future<bool> isStudent() async {
    final role = await getUserRole();
    return role == 'student';
  }

  /// Check if user has any of the required roles
  Future<bool> hasAnyRole(List<String> requiredRoles) async {
    final role = await getUserRole();
    return role != null && requiredRoles.contains(role);
  }
}
