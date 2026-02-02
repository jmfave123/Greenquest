import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:greenquest/admin/helpers/department_validation_helper.dart';

/// Service class for department CRUD operations
class DepartmentService {
  final FirebaseFirestore _firestore;
  final DepartmentValidationHelper _validationHelper;

  DepartmentService(this._firestore)
    : _validationHelper = DepartmentValidationHelper(_firestore);

  /// Create a new department
  Future<void> createDepartment(
    String name,
    String code,
    String description,
  ) async {
    try {
      // Validate input
      if (name.trim().isEmpty) {
        Get.snackbar(
          'Validation Error',
          'Department name cannot be empty!',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      if (code.trim().isEmpty) {
        Get.snackbar(
          'Validation Error',
          'Department code cannot be empty!',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Check for duplicate department name (case-insensitive)
      if (await _validationHelper.isDuplicateDepartmentName(name)) {
        Get.snackbar(
          'Duplicate Error',
          'A department with the name "$name" already exists! Please choose a different name.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Check for duplicate department code (case-insensitive)
      if (await _validationHelper.isDuplicateDepartmentCode(code)) {
        Get.snackbar(
          'Duplicate Error',
          'A department with the code "$code" already exists! Please choose a different code.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Create the department if no duplicates found
      await _firestore.collection('departments').add({
        'name':
            name
                .trim()
                .toLowerCase(), // Store in lowercase for consistent comparison
        'displayName': name.trim(), // Store original case for display
        'code': code.trim().toUpperCase(),
        'description': description.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Success',
        'Department "$name" created successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create department: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Update an existing department
  Future<void> updateDepartment(
    String departmentId,
    String name,
    String code,
    String description,
  ) async {
    try {
      // Validate input
      if (name.trim().isEmpty) {
        Get.snackbar(
          'Validation Error',
          'Department name cannot be empty!',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      if (code.trim().isEmpty) {
        Get.snackbar(
          'Validation Error',
          'Department code cannot be empty!',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Get existing department data to compare
      final existingDoc =
          await _firestore.collection('departments').doc(departmentId).get();
      final existingData = existingDoc.data();

      // Check for duplicate department name (case-insensitive) if name changed
      if (existingData?['displayName']?.toString().toLowerCase() !=
          name.trim().toLowerCase()) {
        if (await _validationHelper.isDuplicateDepartmentName(name)) {
          Get.snackbar(
            'Duplicate Error',
            'A department with the name "$name" already exists! Please choose a different name.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }
      }

      // Check for duplicate department code (case-insensitive) if code changed
      if (existingData?['code']?.toString().toUpperCase() !=
          code.trim().toUpperCase()) {
        if (await _validationHelper.isDuplicateDepartmentCode(code)) {
          Get.snackbar(
            'Duplicate Error',
            'A department with the code "$code" already exists! Please choose a different code.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }
      }

      // Update the department
      await _firestore.collection('departments').doc(departmentId).update({
        'name': name.trim().toLowerCase(),
        'displayName': name.trim(),
        'code': code.trim().toUpperCase(),
        'description': description.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Success',
        'Department "$name" updated successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update department: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Delete a department and all its sections
  Future<void> deleteDepartment(String departmentId) async {
    try {
      // First delete all sections under this department
      final sectionsQuery =
          await _firestore
              .collection('sections')
              .where('departmentId', isEqualTo: departmentId)
              .get();

      for (var doc in sectionsQuery.docs) {
        await doc.reference.delete();
      }

      // Then delete the department
      await _firestore.collection('departments').doc(departmentId).delete();

      Get.snackbar(
        'Success',
        'Department and all its sections deleted successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete department: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
