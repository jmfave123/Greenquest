import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/services/in_app_notification_service.dart';
import 'dart:developer' as dev;

class NotificationController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable objects
  final RxList<Map<String, dynamic>> notifications =
      <Map<String, dynamic>>[].obs;
  // This is the global badge count (e.g. the "5" on the home screen)
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;
  
  // Stores the latest notification timestamp the user has "seen" in the list
  // This is used to clear the app badge without marking items as "read".
  final Rx<DateTime?> lastViewedAt = Rx<DateTime?>(null);

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
  /// A notification is counted for the "Global Badge" only if:
  /// 1. It is not read (not in readBy array)
  /// 2. It is newer than the 'lastViewedAt' timestamp
  void _updateUnreadCount(List<Map<String, dynamic>> notificationsList) {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        unreadCount.value = 0;
        return;
      }

      int count = 0;
      final seenTime = lastViewedAt.value;

      for (var notification in notificationsList) {
        final readBy = List<String>.from(notification['readBy'] ?? []);
        
        // Already clicked/opened ?
        if (readBy.contains(user.uid)) continue;

        // If we have a 'last viewed' time, check if this is a "new" notification
        if (seenTime != null) {
          final createdAt = notification['createdAt'];
          DateTime? notifyTime;
          
          if (createdAt is Timestamp) {
            notifyTime = createdAt.toDate();
          } else if (createdAt is String) {
            notifyTime = DateTime.tryParse(createdAt);
          } else if (createdAt is DateTime) {
            notifyTime = createdAt;
          }

          // If the notification came after we last visited the page, it's unread
          if (notifyTime != null && notifyTime.isAfter(seenTime)) {
            count++;
          }
        } else {
          // If no seenTime yet, everything not in readBy is unread
          count++;
        }
      }

      unreadCount.value = count;
    } catch (e) {
      dev.log('❌ Error updating unread count: $e');
      unreadCount.value = 0;
    }
  }

  /// Refreshes the unread count locally when the user visits the screen.
  /// This clears the "Badge" count (like 5 -> 0) without marking items as read.
  void markAllAsSeen() {
    if (notifications.isEmpty) return;
    
    // Get the timestamp of the most recent notification
    final latest = notifications.first;
    final createdAt = latest['createdAt'];
    
    DateTime? notifyTime;
    if (createdAt is Timestamp) {
      notifyTime = createdAt.toDate();
    } else if (createdAt is String) {
      notifyTime = DateTime.tryParse(createdAt);
    } else if (createdAt is DateTime) {
      notifyTime = createdAt;
    }

    if (notifyTime != null) {
      lastViewedAt.value = notifyTime;
      // Re-calculate the unread count immediately
      _updateUnreadCount(notifications);
      dev.log('✅ Global badge cleared by updating lastViewedAt to $notifyTime');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Update in Firebase using readBy array
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

      dev.log('✅ Notification marked as read (clicked): $notificationId');
    } catch (e) {
      dev.log('❌ Error marking notification as read: $e');
    }
  }

  Future<void> refreshNotifications() async {
    _setupRealtimeNotifications();
  }

  // Deprecated: No longer marking all as read in DB on exit.
  Future<void> markAllAsRead() async {
    markAllAsSeen();
  }
}
