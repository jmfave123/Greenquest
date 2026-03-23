import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer';

/// Service to handle student data fetching and caching for scalability
/// Resolves repeated Firestore queries to lower reads and improve load times.
class StudentDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // In-memory cache
  static Map<String, dynamic>? _cachedUserData;
  static DateTime? _lastUserFetch;

  static int? _cachedTotalPoints;
  static DateTime? _lastPointsFetch;

  // Cache duration (e.g., 5 minutes)
  static const Duration cacheDuration = Duration(minutes: 5);

  /// Get the current student's data.
  /// Uses cache if not forced to refresh and cache is still valid.
  static Future<Map<String, dynamic>?> getStudentData({
    bool forceRefresh = false,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Check cache validity
      if (!forceRefresh && _cachedUserData != null && _lastUserFetch != null) {
        if (DateTime.now().difference(_lastUserFetch!) < cacheDuration) {
          log('StudentDataService: Returning CACHED user data for ${user.uid}');
          return _cachedUserData;
        }
      }

      log('StudentDataService: Fetching fresh user data from Firestore for ${user.uid}');
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        _cachedUserData = doc.data() as Map<String, dynamic>;
        _lastUserFetch = DateTime.now();
        return _cachedUserData;
      }

      return null;
    } catch (e, stacktrace) {
      log('Error getting student data: $e\n$stacktrace');
      // Fallback to old cache if network strictly fails, even if expired
      return _cachedUserData;
    }
  }

  /// Calculates total points for the logged-in student from all submissions.
  /// Uses a cache if not forced to refresh.
  static Future<int> getTotalPoints({bool forceRefresh = false}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      // Ensure we have user data to get the instructor ID
      final userData = await getStudentData(forceRefresh: forceRefresh);
      if (userData == null) return 0;

      final instructorId = userData['selectedInstructorId'] as String?;
      if (instructorId == null || instructorId.isEmpty) {
        return 0;
      }

      // Check cache validity
      if (!forceRefresh &&
          _cachedTotalPoints != null &&
          _lastPointsFetch != null) {
        if (DateTime.now().difference(_lastPointsFetch!) < cacheDuration) {
          log('StudentDataService: Returning CACHED total points');
          return _cachedTotalPoints!;
        }
      }

      log('StudentDataService: Fetching fresh total points from Firestore');
      int points = 0;

      final allSubmissions =
          await _firestore
              .collection('submissions')
              .where('studentId', isEqualTo: user.uid)
              .where('instructorId', isEqualTo: instructorId)
              .get();

      for (var doc in allSubmissions.docs) {
        final data = doc.data();
        final grade = data['grade'];
        if (grade != null && grade is num) {
          points += grade.toInt();
        }
      }

      _cachedTotalPoints = points;
      _lastPointsFetch = DateTime.now();

      return _cachedTotalPoints!;
    } catch (e, stacktrace) {
      log('Error calculating total points: $e\n$stacktrace');
      // Fallback to cached points if network fails
      return _cachedTotalPoints ?? 0;
    }
  }

  /// Updates student profile data in Firestore and refreshes cache.
  static Future<void> updateStudentProfile(Map<String, dynamic> newData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No logged-in user');

      await _firestore.collection('users').doc(user.uid).update(newData);

      // Instantly update the local cache without needing another read
      if (_cachedUserData != null) {
        _cachedUserData!.addAll(newData);
        _lastUserFetch = DateTime.now(); // Renew cache timer
      } else {
        // If cache was null, fetch it cleanly.
        await getStudentData(forceRefresh: true);
      }
    } catch (e) {
      log('Error updating student profile data: $e');
      rethrow;
    }
  }

  /// Update just a specific field locally in cache if needed (like image URL)
  static void updateCacheField(String key, dynamic value) {
    if (_cachedUserData != null) {
      _cachedUserData![key] = value;
    }
  }

  /// Invalidate/Clear the cache (helpful on logout).
  static void clearCache() {
    _cachedUserData = null;
    _lastUserFetch = null;
    _cachedTotalPoints = null;
    _lastPointsFetch = null;
    log('StudentDataService cache cleared');
  }
}
