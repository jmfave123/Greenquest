import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper class for department and section validation
class DepartmentValidationHelper {
  final FirebaseFirestore _firestore;

  DepartmentValidationHelper(this._firestore);

  /// Check for duplicate department names (case-insensitive)
  Future<bool> isDuplicateDepartmentName(String name) async {
    final allDepartmentsQuery =
        await _firestore.collection('departments').get();
    final normalizedName = name.trim().toLowerCase();

    for (var doc in allDepartmentsQuery.docs) {
      final data = doc.data();
      final existingName = data['name']?.toString().toLowerCase() ?? '';
      final existingDisplayName =
          data['displayName']?.toString().toLowerCase() ?? '';

      if (existingName == normalizedName ||
          existingDisplayName == normalizedName) {
        return true;
      }
    }
    return false;
  }

  /// Check for duplicate department codes (case-insensitive)
  Future<bool> isDuplicateDepartmentCode(String code) async {
    final allDepartmentsQuery =
        await _firestore.collection('departments').get();
    final normalizedCode = code.trim().toUpperCase();

    for (var doc in allDepartmentsQuery.docs) {
      final data = doc.data();
      final existingCode = data['code']?.toString().toUpperCase() ?? '';

      if (existingCode == normalizedCode) {
        return true;
      }
    }
    return false;
  }

  /// Check for duplicate section codes across all departments
  Future<bool> isDuplicateSectionCode(String sectionCode) async {
    final allSectionsQuery = await _firestore.collection('sections').get();
    final normalizedSectionCode = sectionCode.trim().toUpperCase();

    for (var doc in allSectionsQuery.docs) {
      final data = doc.data();
      final existingSectionCode =
          data['sectionCode']?.toString().toUpperCase() ?? '';

      if (existingSectionCode == normalizedSectionCode) {
        return true;
      }
    }
    return false;
  }

  /// Check for duplicate section codes within a specific department
  Future<bool> isDuplicateSectionCodeInDepartment(
    String sectionCode,
    String departmentId,
  ) async {
    final sectionsQuery =
        await _firestore
            .collection('sections')
            .where('departmentId', isEqualTo: departmentId)
            .get();
    final normalizedSectionCode = sectionCode.trim().toUpperCase();

    for (var doc in sectionsQuery.docs) {
      final data = doc.data();
      final existingSectionCode =
          data['sectionCode']?.toString().toUpperCase() ?? '';

      if (existingSectionCode == normalizedSectionCode) {
        return true;
      }
    }
    return false;
  }

  /// Check for duplicate section codes when updating (excludes current section)
  Future<bool> isDuplicateSectionCodeForUpdate(
    String sectionCode,
    String currentSectionId,
  ) async {
    final allSectionsQuery = await _firestore.collection('sections').get();
    final normalizedSectionCode = sectionCode.trim().toUpperCase();

    for (var doc in allSectionsQuery.docs) {
      // Skip the current section being updated
      if (doc.id == currentSectionId) {
        continue;
      }

      final data = doc.data();
      final existingSectionCode =
          data['sectionCode']?.toString().toUpperCase() ?? '';

      if (existingSectionCode == normalizedSectionCode) {
        return true;
      }
    }
    return false;
  }
}
