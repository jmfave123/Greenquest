import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to manage NSTP components in Firestore.
///
/// Firestore Structure:
/// ```
/// nstp_components/
///   {componentId}/
///     - name: String        (e.g., "CWTS", "ROTC", "LTS")
///     - description: String (optional — short label shown in dropdowns)
///     - isActive: bool      (whether this component is available for selection)
///     - createdAt: Timestamp
///     - updatedAt: Timestamp
/// ```
class NstpComponentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── streams ──────────────────────────────────────────────────────────────

  /// Live stream of all NSTP components, ordered by name ascending.
  Stream<QuerySnapshot> getComponentsStream() {
    return _firestore
        .collection('nstp_components')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // ── queries ───────────────────────────────────────────────────────────────

  /// Returns all active NSTP components as plain maps (for dropdowns, etc.).
  Future<List<Map<String, dynamic>>> getActiveComponents() async {
    try {
      final snapshot =
          await _firestore
              .collection('nstp_components')
              .where('isActive', isEqualTo: true)
              .orderBy('createdAt', descending: false)
              .get();

      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    } catch (e) {
      print('Error getting active NSTP components: $e');
      return [];
    }
  }

  // ── mutations ─────────────────────────────────────────────────────────────

  /// Creates a new NSTP component.
  ///
  /// Throws [Exception] if a component with the same [name] (case-insensitive)
  /// already exists.
  Future<void> createComponent({
    required String name,
    String description = '',
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Component name cannot be empty');
    }

    // Duplicate check (case-insensitive by comparing lowercase stored value)
    final existing = await _firestore.collection('nstp_components').get();
    final duplicate = existing.docs.any(
      (doc) =>
          (doc.data()['name'] as String? ?? '').toLowerCase() ==
          trimmedName.toLowerCase(),
    );
    if (duplicate) {
      throw Exception('"$trimmedName" already exists as an NSTP component');
    }

    try {
      await _firestore.collection('nstp_components').add({
        'name': trimmedName,
        'description': description.trim(),
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating NSTP component: $e');
      rethrow;
    }
  }

  /// Toggles the [isActive] flag of a component.
  Future<void> toggleActive(
    String componentId, {
    required bool isActive,
  }) async {
    try {
      await _firestore.collection('nstp_components').doc(componentId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error toggling NSTP component active state: $e');
      rethrow;
    }
  }

  /// Permanently deletes a component.
  ///
  /// Throws [Exception] if the component is currently active, as it may be
  /// in use by existing student submissions.
  Future<void> deleteComponent(String componentId) async {
    try {
      final doc =
          await _firestore.collection('nstp_components').doc(componentId).get();

      if (doc.exists && (doc.data()?['isActive'] as bool? ?? false)) {
        throw Exception(
          'Cannot delete an active NSTP component. '
          'Deactivate it first.',
        );
      }

      await _firestore.collection('nstp_components').doc(componentId).delete();
    } catch (e) {
      print('Error deleting NSTP component: $e');
      rethrow;
    }
  }

  /// Updates the name and/or description of a component.
  Future<void> updateComponent({
    required String componentId,
    String? name,
    String? description,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) {
        final trimmed = name.trim();
        if (trimmed.isEmpty) throw Exception('Component name cannot be empty');
        updates['name'] = trimmed;
      }

      if (description != null) {
        updates['description'] = description.trim();
      }

      await _firestore
          .collection('nstp_components')
          .doc(componentId)
          .update(updates);
    } catch (e) {
      print('Error updating NSTP component: $e');
      rethrow;
    }
  }
}
