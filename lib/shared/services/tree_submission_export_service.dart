import 'package:cloud_firestore/cloud_firestore.dart';

/// Reusable helper for preparing student tree submissions for NSTP PDF export.
class TreeSubmissionExportService {
  const TreeSubmissionExportService._();

  /// Ensures the provided [submission] belongs to the current [userId].
  static bool isOwnedByUser({
    required Map<String, dynamic> submission,
    required String userId,
  }) {
    final studentId = (submission['studentId'] ?? '').toString();
    return studentId.isNotEmpty && studentId == userId;
  }

  /// Builds a payload compatible with [NstpPdfExportService.exportToPdf].
  ///
  /// Adds fallback values from the user's Firestore document when legacy
  /// submissions are missing `nstpComponent` or `treeNames`.
  static Future<Map<String, dynamic>> buildNstpExportData({
    required FirebaseFirestore firestore,
    required Map<String, dynamic> submission,
  }) async {
    final studentId = (submission['studentId'] ?? '').toString();

    var nstpComponent = (submission['nstpComponent'] ?? '').toString().trim();
    var treeNames = _toStringList(submission['treeNames']);

    if ((nstpComponent.isEmpty || treeNames.isEmpty) && studentId.isNotEmpty) {
      final userDoc = await firestore.collection('users').doc(studentId).get();
      final userData = userDoc.data();
      if (userData != null) {
        if (nstpComponent.isEmpty) {
          nstpComponent = (userData['nstpComponent'] ?? '').toString().trim();
        }
        if (treeNames.isEmpty) {
          treeNames = _toStringList(userData['treeNames']);
        }
      }
    }

    return {
      'studentName': (submission['studentName'] ?? '').toString(),
      'sectionName': (submission['sectionName'] ?? '').toString(),
      'nstpComponent': nstpComponent,
      'quantity': _toInt(submission['quantity']),
      'treeNames': treeNames,
      'location': (submission['location'] ?? '').toString(),
      'submittedAt': submission['submittedAt'],
      'files': _toMapList(submission['files']),
      // Optional flags used by the PDF service remain pass-through.
      'notifiedBarangay': submission['notifiedBarangay'],
      'signagePlaced': submission['signagePlaced'],
      'certificationObtained': submission['certificationObtained'],
    };
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '0').toString()) ?? 0;
  }

  static List<String> _toStringList(dynamic value) {
    if (value is! List) return <String>[];
    return value
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static List<Map<String, dynamic>> _toMapList(dynamic value) {
    if (value is! List) return <Map<String, dynamic>>[];
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
