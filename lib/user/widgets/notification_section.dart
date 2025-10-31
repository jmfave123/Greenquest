import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../notification/notification_controller.dart';

class NotificationSection extends StatefulWidget {
  const NotificationSection({super.key});

  @override
  State<NotificationSection> createState() => _NotificationSectionState();
}

class _NotificationSectionState extends State<NotificationSection> {
  NotificationController? controller;

  @override
  void initState() {
    super.initState();
    // Try to find existing controller, if not found create new one
    try {
      controller = Get.find<NotificationController>();
    } catch (e) {
      controller = Get.put(NotificationController());
    }
  }

  void refreshNotifications() {
    controller?.refreshNotifications();
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'assignment':
        return const Color(0xFF2886D7);
      case 'activity':
        return const Color(0xFF43A047);
      case 'quiz':
        return const Color(0xFF8B5CF6);
      case 'pit':
        return const Color(0xFFFF9800);
      case 'material':
        return const Color(0xFF34A853);
      default:
        return const Color(0xFF34A853);
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'assignment':
        return Icons.assignment;
      case 'activity':
        return Icons.quiz;
      case 'quiz':
        return Icons.quiz;
      case 'pit':
        return Icons.engineering;
      case 'material':
        return Icons.book;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      if (controller!.isLoading.value) {
        return const SizedBox.shrink();
      }

      if (controller!.notifications.isEmpty) {
        return const SizedBox.shrink();
      }

      // Show only first 5 notifications
      final displayNotifications = controller!.notifications.take(5).toList();

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF70E774), Color(0xFF28863D)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: const Icon(
                    Icons.notifications_active,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Notifications',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Stay updated with your classes',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...(displayNotifications.map((notification) {
              final type = notification['type']?.toString() ?? 'activity';
              final title =
                  notification['title']?.toString() ?? 'New notification';
              final instructorName =
                  notification['instructorName']?.toString() ?? '';
              final color = _getNotificationColor(type);
              final icon = _getNotificationIcon(type);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            instructorName.isNotEmpty
                                ? 'From: $instructorName'
                                : 'New $type',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList()),
          ],
        ),
      );
    });
  }
}
