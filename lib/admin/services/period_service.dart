import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to manage grading periods in Firestore
///
/// Firestore Structure:
/// ```
/// periods/
///   {periodId}/
///     - semesterId: String (reference to semesters collection)
///     - semesterName: String (e.g., "First Semester 2024-2025")
///     - type: String ("Midterm" | "Final")
///     - isActive: bool (only one period should be active at a time)
///     - createdAt: Timestamp
///     - updatedAt: Timestamp
/// ```
class PeriodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all semesters
  Future<List<Map<String, dynamic>>> getSemesters() async {
    try {
      final snapshot =
          await _firestore
              .collection('semesters')
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'displayName': data['displayName'] ?? '',
          'year': data['year'] ?? '',
          'semester': data['semester'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('Error getting semesters: $e');
      return [];
    }
  }

  /// Get all periods ordered by created date
  Stream<QuerySnapshot> getPeriodsStream() {
    return _firestore
        .collection('periods')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  /// Get active period
  Future<Map<String, dynamic>?> getActivePeriod() async {
    try {
      final snapshot =
          await _firestore
              .collection('periods')
              .where('isActive', isEqualTo: true)
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) return null;

      return {'id': snapshot.docs.first.id, ...snapshot.docs.first.data()};
    } catch (e) {
      print('Error getting active period: $e');
      return null;
    }
  }

  /// Create a new period
  Future<void> createPeriod({
    required String semesterId,
    required String semesterName,
    required String type, // 'Midterm' or 'Final'
  }) async {
    try {
      // Validate type
      if (type != 'Midterm' && type != 'Final') {
        throw Exception('Period type must be either "Midterm" or "Final"');
      }

      // Check if period already exists for this semester and type
      final existingPeriod =
          await _firestore
              .collection('periods')
              .where('semesterId', isEqualTo: semesterId)
              .where('type', isEqualTo: type)
              .get();

      if (existingPeriod.docs.isNotEmpty) {
        throw Exception('$type period already exists for this semester');
      }

      await _firestore.collection('periods').add({
        'semesterId': semesterId,
        'semesterName': semesterName,
        'type': type,
        'isActive': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating period: $e');
      rethrow;
    }
  }

  /// Set a period as active (deactivates all other periods automatically)
  /// This allows swapping between Midterm and Final periods
  Future<void> setActivePeriod(String periodId) async {
    try {
      final batch = _firestore.batch();

      // Deactivate all periods (this allows swapping)
      final allPeriods = await _firestore.collection('periods').get();
      for (var doc in allPeriods.docs) {
        batch.update(doc.reference, {
          'isActive': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Activate the selected period
      final periodRef = _firestore.collection('periods').doc(periodId);
      batch.update(periodRef, {
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      print('Error setting active period: $e');
      rethrow;
    }
  }

  /// Delete a period
  Future<void> deletePeriod(String periodId) async {
    try {
      // Check if period is active
      final periodDoc =
          await _firestore.collection('periods').doc(periodId).get();
      if (periodDoc.exists && periodDoc.data()?['isActive'] == true) {
        throw Exception('Cannot delete an active period');
      }

      await _firestore.collection('periods').doc(periodId).delete();
    } catch (e) {
      print('Error deleting period: $e');
      rethrow;
    }
  }

  /// Update period details
  Future<void> updatePeriod({
    required String periodId,
    String? semesterId,
    String? semesterName,
    String? type,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (semesterId != null) updates['semesterId'] = semesterId;
      if (semesterName != null) updates['semesterName'] = semesterName;
      if (type != null) {
        if (type != 'Midterm' && type != 'Final') {
          throw Exception('Period type must be either "Midterm" or "Final"');
        }
        updates['type'] = type;
      }

      await _firestore.collection('periods').doc(periodId).update(updates);
    } catch (e) {
      print('Error updating period: $e');
      rethrow;
    }
  }
}
