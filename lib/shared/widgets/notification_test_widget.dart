import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../utils/notification_helper.dart';

class NotificationTestWidget extends StatelessWidget {
  const NotificationTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notification Test',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Test notification functionality:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _testLocalNotification(notificationService),
                  icon: const Icon(Icons.notifications, size: 18),
                  label: const Text('Test Local'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      () => _testAnnouncementNotification(notificationService),
                  icon: const Icon(Icons.announcement, size: 18),
                  label: const Text('Test Announcement'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF34A853),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _clearNotifications(notificationService),
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Clear All'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showFCMToken(notificationService),
                  icon: const Icon(Icons.info, size: 18),
                  label: const Text('Show Token'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => NotificationHelper.testAllNotificationTypes(),
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Test All Notification Types'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.purple,
                side: const BorderSide(color: Colors.purple),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _testLocalNotification(NotificationService service) {
    NotificationHelper.showTestNotification(
      title: 'Test Local Notification',
      message: 'This is a test local notification!',
      backgroundColor: Colors.blue,
      icon: Icons.notifications,
    );
  }

  void _testAnnouncementNotification(NotificationService service) {
    NotificationHelper.showAnnouncementNotification(
      instructorName: 'Test Instructor',
      announcementTitle: 'Test Announcement',
      announcementContent: 'This is a test announcement notification!',
    );
  }

  void _clearNotifications(NotificationService service) async {
    await NotificationHelper.clearAllNotifications();
  }

  void _showFCMToken(NotificationService service) {
    NotificationHelper.showFCMToken();
  }
}
