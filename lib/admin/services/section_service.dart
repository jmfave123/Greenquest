import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../helpers/department_validation_helper.dart';

/// Service class for section CRUD operations
class SectionService {
  final FirebaseFirestore _firestore;
  final DepartmentValidationHelper _validationHelper;

  SectionService(this._firestore)
    : _validationHelper = DepartmentValidationHelper(_firestore);

  /// Create a new section
  Future<void> createSection(
    String departmentId,
    String year,
    String sectionLetter,
    String departmentCode,
    String? subCode,
  ) async {
    try {
      // Generate section code with or without subCode
      final sectionCode =
          subCode != null && subCode.isNotEmpty
              ? '$departmentCode-$subCode-${year.replaceAll('st', '').replaceAll('nd', '').replaceAll('rd', '').replaceAll('th', '')}$sectionLetter'
              : '$departmentCode-${year.replaceAll('st', '').replaceAll('nd', '').replaceAll('rd', '').replaceAll('th', '')}$sectionLetter';

      // Check for duplicate section code across all departments
      if (await _validationHelper.isDuplicateSectionCode(sectionCode)) {
        Get.snackbar(
          'Duplicate Section Error',
          'Section "$sectionCode" already exists in the system! Please choose a different year, section letter, or sub-code.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // Check for duplicate section code within the same department
      if (await _validationHelper.isDuplicateSectionCodeInDepartment(
        sectionCode,
        departmentId,
      )) {
        Get.snackbar(
          'Duplicate Section Error',
          'Section "$sectionCode" already exists in this department! Please choose a different year, section letter, or sub-code.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      await _firestore.collection('sections').add({
        'departmentId': departmentId,
        'year': year,
        'sectionLetter': sectionLetter,
        'subCode': subCode,
        'sectionCode': sectionCode,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Success',
        'Section $sectionCode added successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add section: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Update an existing section
  Future<void> updateSection(
    String sectionId,
    String year,
    String sectionLetter,
    String? subCode,
    String departmentCode,
  ) async {
    try {
      // Get the section's department to regenerate section code
      final sectionDoc =
          await _firestore.collection('sections').doc(sectionId).get();
      final sectionData = sectionDoc.data();

      if (sectionData == null) {
        Get.snackbar(
          'Error',
          'Section not found',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Generate new section code with or without subCode
      final sectionCode =
          subCode != null && subCode.isNotEmpty
              ? '$departmentCode-$subCode-${year.replaceAll('st', '').replaceAll('nd', '').replaceAll('rd', '').replaceAll('th', '')}$sectionLetter'
              : '$departmentCode-${year.replaceAll('st', '').replaceAll('nd', '').replaceAll('rd', '').replaceAll('th', '')}$sectionLetter';

      // Check for duplicate section code (excluding current section)
      if (await _validationHelper.isDuplicateSectionCodeForUpdate(
        sectionCode,
        sectionId,
      )) {
        Get.snackbar(
          'Duplicate Section Error',
          'Section "$sectionCode" already exists in the system! Please choose a different year, section letter, or sub-code.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // Update the section
      await _firestore.collection('sections').doc(sectionId).update({
        'year': year,
        'sectionLetter': sectionLetter,
        'subCode': subCode,
        'sectionCode': sectionCode,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Success',
        'Section $sectionCode updated successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update section: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Delete a section
  Future<void> deleteSection(String sectionId) async {
    try {
      await _firestore.collection('sections').doc(sectionId).delete();

      Get.snackbar(
        'Success',
        'Section deleted successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete section: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
