import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize notification service (simplified version)
  Future<void> initialize() async {
    try {
      log('✅ Notification service initialized successfully');
    } catch (e) {
      log('❌ Error initializing notification service: $e');
    }
  }

  // Get all users who have selected a specific instructor
  Future<List<String>> getUsersForInstructor(String instructorId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('users')
              .where('selectedInstructorId', isEqualTo: instructorId)
              .get();

      return querySnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      log('❌ Error getting users for instructor: $e');
      return [];
    }
  }

  // Send announcement notification to all students of an instructor
  Future<void> sendAnnouncementNotification({
    required String instructorId,
    required String instructorName,
    required String announcementTitle,
    required String announcementContent,
    String? announcementId,
  }) async {
    try {
      // Get all users who have selected this instructor
      final userIds = await getUsersForInstructor(instructorId);

      if (userIds.isEmpty) {
        log('❌ No users found for instructor: $instructorId');
        return;
      }

      log('✅ Would send announcement notification to ${userIds.length} users');
      log('📢 Title: New Announcement from $instructorName');
      log('📢 Body: $announcementTitle');
    } catch (e) {
      log('❌ Error sending announcement notification: $e');
    }
  }
}
