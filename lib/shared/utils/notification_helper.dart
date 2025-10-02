import 'dart:developer';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class NotificationHelper {
  /// Show a test notification using GetX snackbar
  static void showTestNotification({
    required String title,
    required String message,
    Color? backgroundColor,
    IconData? icon,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: backgroundColor ?? Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: icon != null ? Icon(icon, color: Colors.white) : null,
      shouldIconPulse: true,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
    );
  }

  /// Show announcement notification
  static void showAnnouncementNotification({
    required String instructorName,
    required String announcementTitle,
    required String announcementContent,
  }) {
    showTestNotification(
      title: 'New Announcement from $instructorName',
      message: announcementTitle,
      backgroundColor: const Color(0xFF34A853),
      icon: Icons.announcement,
    );
  }

  /// Show urgent announcement notification
  static void showUrgentAnnouncementNotification({
    required String instructorName,
    required String announcementTitle,
    required String announcementContent,
  }) {
    showTestNotification(
      title: '🚨 URGENT: $instructorName',
      message: announcementTitle,
      backgroundColor: Colors.red,
      icon: Icons.warning,
    );
  }

  /// Show pinned announcement notification
  static void showPinnedAnnouncementNotification({
    required String instructorName,
    required String announcementTitle,
    required String announcementContent,
  }) {
    showTestNotification(
      title: '📌 Pinned: $instructorName',
      message: announcementTitle,
      backgroundColor: Colors.orange,
      icon: Icons.push_pin,
    );
  }

  /// Log notification activity
  static void logNotificationActivity(String message) {
    log('🔔 NOTIFICATION: $message');
  }

  /// Show notification permission status
  static void showPermissionStatus() {
    // This would check actual permission status in a real implementation
    showTestNotification(
      title: 'Notification Status',
      message: 'Notifications are enabled and working!',
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
    );
  }

  /// Show FCM token for debugging (simplified version)
  static void showFCMToken() {
    showTestNotification(
      title: 'FCM Token',
      message: 'FCM functionality has been simplified',
      backgroundColor: Colors.blue,
      icon: Icons.info,
    );
  }

  /// Clear all notifications (simplified version)
  static Future<void> clearAllNotifications() async {
    showTestNotification(
      title: 'Notifications Cleared',
      message: 'All notifications have been removed',
      backgroundColor: Colors.grey,
      icon: Icons.clear_all,
    );
  }

  /// Test different notification types
  static void testAllNotificationTypes() {
    // Test regular announcement
    Future.delayed(const Duration(seconds: 1), () {
      showAnnouncementNotification(
        instructorName: 'Test Instructor',
        announcementTitle: 'Regular Announcement Test',
        announcementContent: 'This is a test announcement',
      );
    });

    // Test urgent announcement
    Future.delayed(const Duration(seconds: 3), () {
      showUrgentAnnouncementNotification(
        instructorName: 'Test Instructor',
        announcementTitle: 'Urgent Announcement Test',
        announcementContent: 'This is an urgent test announcement',
      );
    });

    // Test pinned announcement
    Future.delayed(const Duration(seconds: 5), () {
      showPinnedAnnouncementNotification(
        instructorName: 'Test Instructor',
        announcementTitle: 'Pinned Announcement Test',
        announcementContent: 'This is a pinned test announcement',
      );
    });
  }
}
