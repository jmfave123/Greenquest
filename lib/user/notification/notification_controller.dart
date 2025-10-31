import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/services/in_app_notification_service.dart';
import 'dart:developer' as dev;

class NotificationController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable variables
  final RxList<Map<String, dynamic>> notifications =
      <Map<String, dynamic>>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    try {
      isLoading.value = true;

      final notificationsList =
          await InAppNotificationService.getStudentNotifications();

      notifications.value = notificationsList;
      unreadCount.value =
          notificationsList.where((n) => !(n['isRead'] ?? false)).length;

      dev.log(
        '📬 Loaded ${notificationsList.length} notifications, ${unreadCount.value} unread',
      );
    } catch (e) {
      dev.log('❌ Error loading notifications: $e');
      notifications.value = [];
      unreadCount.value = 0;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      // Update in Firebase
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });

      // Update local state
      final index = notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        notifications[index]['isRead'] = true;
        notifications.refresh();

        // Recalculate unread count
        unreadCount.value =
            notifications.where((n) => !(n['isRead'] ?? false)).length;
      }

      dev.log('✅ Notification marked as read: $notificationId');
    } catch (e) {
      dev.log('❌ Error marking notification as read: $e');
    }
  }

  Future<void> refreshNotifications() async {
    await loadNotifications();
  }
}
