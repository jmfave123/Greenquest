import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/services/in_app_notification_service.dart';
import 'dart:developer' as dev;

class NotificationController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable variables
  final RxList<Map<String, dynamic>> notifications =
      <Map<String, dynamic>>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;

  // Stream subscription for real-time updates
  StreamSubscription<List<Map<String, dynamic>>>? _notificationStream;

  @override
  void onInit() {
    super.onInit();
    _setupRealtimeNotifications();
  }

  @override
  void onClose() {
    _notificationStream?.cancel();
    super.onClose();
  }

  /// Set up real-time notification stream
  void _setupRealtimeNotifications() {
    try {
      isLoading.value = true;

      // Cancel existing stream if any
      _notificationStream?.cancel();

      // Set up new stream listener
      _notificationStream =
          InAppNotificationService.getStudentNotificationsStream().listen(
            (notificationsList) {
              notifications.value = notificationsList;
              _updateUnreadCount(notificationsList);
              isLoading.value = false;
              dev.log(
                '📬 Updated: ${notificationsList.length} notifications, ${unreadCount.value} unread',
              );
            },
            onError: (error) {
              dev.log('❌ Notification stream error: $error');
              notifications.value = [];
              unreadCount.value = 0;
              isLoading.value = false;
            },
          );
    } catch (e) {
      dev.log('❌ Error setting up notification stream: $e');
      notifications.value = [];
      unreadCount.value = 0;
      isLoading.value = false;
    }
  }

  /// Update unread count based on notifications
  void _updateUnreadCount(List<Map<String, dynamic>> notificationsList) {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        unreadCount.value = 0;
        return;
      }

      int count = 0;
      for (var notification in notificationsList) {
        final readBy = List<String>.from(notification['readBy'] ?? []);
        if (!readBy.contains(user.uid)) {
          count++;
        }
      }

      unreadCount.value = count;
    } catch (e) {
      dev.log('❌ Error updating unread count: $e');
      unreadCount.value = 0;
    }
  }

  Future<void> loadNotifications() async {
    // This method is kept for backwards compatibility but now uses streams
    // The stream is already set up in onInit, so this is just a refresh
    _setupRealtimeNotifications();
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Update in Firebase using readBy array (matches InAppNotificationService)
      final notificationDoc =
          await _firestore
              .collection('notifications')
              .doc(notificationId)
              .get();

      if (!notificationDoc.exists) {
        dev.log('❌ Notification not found: $notificationId');
        return;
      }

      final data = notificationDoc.data() as Map<String, dynamic>;
      final readBy = List<String>.from(data['readBy'] ?? []);

      // Add user to readBy if not already present
      if (!readBy.contains(user.uid)) {
        readBy.add(user.uid);
        await _firestore.collection('notifications').doc(notificationId).update(
          {'readBy': readBy},
        );
      }

      // Stream will automatically update the local state
      dev.log('✅ Notification marked as read: $notificationId');
    } catch (e) {
      dev.log('❌ Error marking notification as read: $e');
    }
  }

  Future<void> refreshNotifications() async {
    // Stream is already real-time, but we can refresh the stream
    _setupRealtimeNotifications();
  }
}
