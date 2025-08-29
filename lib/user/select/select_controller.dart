import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class SelectController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  RxList instructors = [{}].obs;
  RxList courses = [{}].obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    getCourses(); // Automatically fetch courses when controller is created
    getInstructors(); // Automatically fetch instructors when controller is created
  }

  Future<void> getInstructors() async {
    try {
      isLoading.value = true;
      final user = _auth.currentUser;
      if (user == null) {
        return;
      }
      QuerySnapshot querySnapshot =
          await _firestore.collection('instructors').get();
      instructors.value =
          querySnapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
          }).toList();
      // log(instructors.toString());
    } catch (e) {
      log('Error fetching instructors: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getCourses() async {
    try {
      isLoading.value = true;
      final user = _auth.currentUser;
      if (user == null) {
        return;
      }
      QuerySnapshot querySnapshot =
          await _firestore.collection('courses').get();
      courses.value =
          querySnapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
          }).toList();
      log(courses.toString());
    } catch (e) {
      log('Error fetching courses: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
