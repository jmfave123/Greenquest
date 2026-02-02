import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

/// Service class for semester CRUD operations
class SemesterService {
  final FirebaseFirestore _firestore;

  SemesterService(this._firestore);

  /// Create a new semester
  Future<void> createSemester(String year, String semester) async {
    if (year.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter academic year',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      // Check for duplicate semester
      final existingSemester =
          await _firestore
              .collection('semesters')
              .where('year', isEqualTo: year)
              .where('semester', isEqualTo: semester)
              .get();

      if (existingSemester.docs.isNotEmpty) {
        Get.snackbar(
          'Error',
          'This semester already exists',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      await _firestore.collection('semesters').add({
        'year': year,
        'semester': semester,
        'displayName': '$semester $year',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      Get.snackbar(
        'Success',
        'Semester created successfully',
        backgroundColor: const Color(0xFF34A853),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create semester: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Update an existing semester
  Future<void> updateSemester(
    String semesterId,
    String year,
    String semester,
  ) async {
    if (year.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter academic year',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      // Check for duplicate semester (excluding current semester)
      final existingSemester =
          await _firestore
              .collection('semesters')
              .where('year', isEqualTo: year)
              .where('semester', isEqualTo: semester)
              .get();

      // Check if duplicate exists and it's not the current semester
      final duplicateExists = existingSemester.docs.any(
        (doc) => doc.id != semesterId,
      );

      if (duplicateExists) {
        Get.snackbar(
          'Error',
          'This semester already exists',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      await _firestore.collection('semesters').doc(semesterId).update({
        'year': year,
        'semester': semester,
        'displayName': '$semester $year',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Success',
        'Semester updated successfully',
        backgroundColor: const Color(0xFF34A853),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update semester: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Load all semesters
  Future<List<Map<String, dynamic>>> loadSemesters() async {
    try {
      print('Loading semesters...');
      final snapshot =
          await _firestore
              .collection('semesters')
              .orderBy('createdAt', descending: true)
              .get();

      print('Found ${snapshot.docs.length} semesters');

      final semesters =
          snapshot.docs.map((doc) {
            final data = doc.data();
            print('Semester data: $data');
            return {
              'id': doc.id,
              'year': data['year'] ?? '',
              'semester': data['semester'] ?? '',
              'displayName': data['displayName'] ?? '',
              'isActive': data['isActive'] ?? true,
              'createdAt': data['createdAt'],
            };
          }).toList();

      print('Loaded semesters: $semesters');
      return semesters;
    } catch (e) {
      print('Error loading semesters: $e');
      return [];
    }
  }
}
