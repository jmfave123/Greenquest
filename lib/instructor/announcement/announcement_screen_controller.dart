import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/services/notification_service.dart';

class AnnouncementScreenController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // Observable variables
  final RxBool showCreate = false.obs;
  final RxList<Map<String, dynamic>> announcements =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxString instructorName = ''.obs;

  // Form controllers
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final RxBool pinToTop = false.obs;
  final RxBool urgent = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAnnouncements();

    loadInstructor();
  }

  @override
  void onClose() {
    titleController.dispose();
    contentController.dispose();
    super.onClose();
  }

  // Load announcements from Firestore
  Future<void> loadAnnouncements() async {
    try {
      isLoading.value = true;
      final user = _auth.currentUser;
      if (user == null) return;

      final QuerySnapshot snapshot =
          await _firestore
              .collection('instructors')
              .doc(user.uid)
              .collection('announcements')
              .orderBy('createdAt', descending: true)
              .get();

      announcements.value =
          snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'title': data['title'] ?? '',
              'content': data['content'] ?? '',
              'date': _formatDate(data['createdAt']),
              'views': data['views'] ?? 0,
              'pinned': data['pinned'] ?? false,
              'urgent': data['urgent'] ?? false,
              'createdAt': data['createdAt'],
            };
          }).toList();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load announcements: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Show create announcement form
  void showCreateAnnouncement() {
    showCreate.value = true;
  }

  // Cancel create announcement
  void cancelCreate() {
    showCreate.value = false;
    titleController.clear();
    contentController.clear();
    pinToTop.value = false;
    urgent.value = false;
  }

  // Post new announcement to Firestore
  Future<void> postAnnouncement() async {
    if (titleController.text.trim().isEmpty ||
        contentController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill in both title and content',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;
      final user = _auth.currentUser;
      if (user == null) {
        Get.snackbar(
          'Error',
          'User not authenticated',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final announcementData = {
        'title': titleController.text.trim(),
        'content': contentController.text.trim(),
        'pinned': pinToTop.value,
        'urgent': urgent.value,
        'views': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'instructorId': user.uid,
        'instructorName': user.displayName ?? 'Unknown Instructor',
      };

      // Add to Firestore
      final docRef = await _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('announcements')
          .add(announcementData);

      // Send notification to all students of this instructor
      await _notificationService.sendAnnouncementNotification(
        instructorId: user.uid,
        instructorName: instructorName.value,
        announcementTitle: titleController.text.trim(),
        announcementContent: contentController.text.trim(),
        announcementId: docRef.id,
      );

      // Clear form and hide create form
      cancelCreate();

      // Reload announcements
      await loadAnnouncements();

      Get.snackbar(
        'Success',
        'Announcement posted and notifications sent!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to post announcement: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Update announcement views
  Future<void> updateViews(String announcementId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('announcements')
          .doc(announcementId)
          .update({'views': FieldValue.increment(1)});

      // Update local data
      final index = announcements.indexWhere(
        (announcement) => announcement['id'] == announcementId,
      );
      if (index != -1) {
        announcements[index]['views'] =
            (announcements[index]['views'] as int) + 1;
        announcements.refresh();
      }
    } catch (e) {
      print('Error updating views: $e');
    }
  }

  // Delete announcement
  Future<void> deleteAnnouncement(String announcementId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('announcements')
          .doc(announcementId)
          .delete();

      // Remove from local list
      announcements.removeWhere(
        (announcement) => announcement['id'] == announcementId,
      );

      Get.snackbar(
        'Success',
        'Announcement deleted successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete announcement: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Toggle pin status
  Future<void> togglePin(String announcementId, bool currentPinStatus) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('announcements')
          .doc(announcementId)
          .update({'pinned': !currentPinStatus});

      // Update local data
      final index = announcements.indexWhere(
        (announcement) => announcement['id'] == announcementId,
      );
      if (index != -1) {
        announcements[index]['pinned'] = !currentPinStatus;
        announcements.refresh();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update pin status: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Helper method to format date
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';

    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return 'Unknown date';
    }

    return '${date.month}/${date.day}/${date.year}';
  }

  /// Load instructor name using FirebaseAuth user.uid
  Future<void> loadInstructor() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        instructorName.value = 'No user logged in';
        return;
      }

      final doc =
          await FirebaseFirestore.instance
              .collection('instructors')
              .doc(user.uid) // 👈 use user.uid here
              .get();

      if (doc.exists) {
        instructorName.value = doc['name'] ?? 'Unknown Instructor';
      } else {
        instructorName.value = 'Instructor not found';
      }
    } catch (e) {
      instructorName.value = 'Error loading name';
    }
  }
}
