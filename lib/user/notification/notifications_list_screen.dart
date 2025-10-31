import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../submit/assignment/assignment_detail_screen.dart';
import '../submit/activity/activity_detail_screen.dart';
import '../submit/quiz_new/quiz_detail_screen.dart';
import '../submit/pit/pit_detail_screen.dart';
import '../materials/materials_detail_screen.dart';
import 'notification_controller.dart';

class NotificationsListScreen extends StatefulWidget {
  const NotificationsListScreen({super.key});

  @override
  State<NotificationsListScreen> createState() =>
      _NotificationsListScreenState();
}

class _NotificationsListScreenState extends State<NotificationsListScreen> {
  late NotificationController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(NotificationController());
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

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown time';

    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        return 'Unknown time';
      }

      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes} minutes ago';
        }
        return '${difference.inHours} hours ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Unknown time';
    }
  }

  Future<void> _markNotificationAsRead(
    Map<String, dynamic> notification,
  ) async {
    final notificationId = notification['id']?.toString();
    if (notificationId == null) return;

    // Use controller to mark as read
    await controller.markAsRead(notificationId);
  }

  void _navigateToRelatedScreen(
    String type,
    Map<String, dynamic> notification,
  ) async {
    // Mark notification as read first
    await _markNotificationAsRead(notification);

    // Show loading indicator
    Get.dialog(
      const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF34A853)),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      final itemId = notification['itemId']?.toString();
      final instructorId = notification['instructorId']?.toString();

      if (itemId == null || instructorId == null) {
        Get.back(); // Close loading dialog
        Get.snackbar(
          'Error',
          'Missing document information',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Fetch the specific document
      DocumentSnapshot doc;
      switch (type.toLowerCase()) {
        case 'assignment':
          doc =
              await FirebaseFirestore.instance
                  .collection('instructors')
                  .doc(instructorId)
                  .collection('assignments')
                  .doc(itemId)
                  .get();
          break;
        case 'activity':
          doc =
              await FirebaseFirestore.instance
                  .collection('instructors')
                  .doc(instructorId)
                  .collection('activities')
                  .doc(itemId)
                  .get();
          break;
        case 'quiz':
          doc =
              await FirebaseFirestore.instance
                  .collection('instructors')
                  .doc(instructorId)
                  .collection('quizzes')
                  .doc(itemId)
                  .get();
          break;
        case 'pit':
          doc =
              await FirebaseFirestore.instance
                  .collection('instructors')
                  .doc(instructorId)
                  .collection('pits')
                  .doc(itemId)
                  .get();
          break;
        case 'material':
          doc =
              await FirebaseFirestore.instance
                  .collection('instructors')
                  .doc(instructorId)
                  .collection('materials')
                  .doc(itemId)
                  .get();
          break;
        default:
          Get.back(); // Close loading dialog
          Get.snackbar(
            'Navigation',
            'No specific screen available for this notification type',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
          return;
      }

      Get.back(); // Close loading dialog

      if (!doc.exists) {
        Get.snackbar(
          'Error',
          'Document not found or has been deleted',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Navigate to the specific detail screen
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Add document ID to the data

      switch (type.toLowerCase()) {
        case 'assignment':
          Get.to(() => AssignmentDetailScreen(assignment: data));
          break;
        case 'activity':
          Get.to(() => ActivityDetailScreen(activity: data));
          break;
        case 'quiz':
          Get.to(() => QuizDetailScreen(assignment: data));
          break;
        case 'pit':
          Get.to(() => PitDetailScreen(pit: data));
          break;
        case 'material':
          Get.to(() => MaterialsDetailScreen(material: data));
          break;
      }
    } catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Error',
        'Failed to load document: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Obx(
          () => Row(
            children: [
              const Text(
                'Notifications',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (controller.unreadCount.value > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34A853),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${controller.unreadCount.value}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: controller.refreshNotifications,
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF34A853)),
            ),
          );
        }

        if (controller.notifications.isEmpty) {
          return _buildEmptyState();
        }

        return _buildNotificationsList();
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF34A853).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none,
              size: 64,
              color: Color(0xFF34A853),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF34A853),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You\'ll see important updates here',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new notifications',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return Obx(
      () => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: controller.notifications.length,
        itemBuilder: (context, index) {
          final notification = controller.notifications[index];
          final type = notification['type']?.toString() ?? 'activity';
          final title = notification['title']?.toString() ?? 'New notification';
          final description = notification['description']?.toString() ?? '';
          final instructorName =
              notification['instructorName']?.toString() ?? '';
          final isRead = notification['isRead'] ?? false;
          final timestamp = notification['createdAt'];
          final color = _getNotificationColor(type);
          final icon = _getNotificationIcon(type);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isRead ? Colors.grey[50] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isRead ? Colors.grey[200]! : color.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _navigateToRelatedScreen(type, notification),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon container
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      const SizedBox(width: 12),
                      // Content area
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title and unread indicator
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      fontWeight:
                                          isRead
                                              ? FontWeight.w600
                                              : FontWeight.bold,
                                      fontSize: 15,
                                      color:
                                          isRead
                                              ? Colors.grey[700]
                                              : Colors.black87,
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (!isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF34A853),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            // Description
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                description,
                                style: TextStyle(
                                  color:
                                      isRead
                                          ? Colors.grey[600]
                                          : Colors.grey[700],
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 8),
                            // Footer info
                            Wrap(
                              children: [
                                if (instructorName.isNotEmpty) ...[
                                  Text(
                                    'From: $instructorName',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '•',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Flexible(
                                  child: Text(
                                    _formatTimestamp(timestamp),
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Navigation indicator
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: isRead ? Colors.grey[400] : color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
