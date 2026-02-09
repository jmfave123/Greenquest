import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../user/notification/notification_controller.dart';
import '../config/web_theme.dart';
import '../config/web_routes.dart';

class WebNotificationDropdown extends StatefulWidget {
  const WebNotificationDropdown({super.key});

  @override
  State<WebNotificationDropdown> createState() =>
      _WebNotificationDropdownState();
}

class _WebNotificationDropdownState extends State<WebNotificationDropdown> {
  final RxString selectedFilter = 'All'.obs;

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
      case 'announcement':
        return WebTheme.primaryGreen;
      default:
        return WebTheme.primaryGreen;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'assignment':
        return Icons.assignment;
      case 'activity':
        return Icons.task_alt;
      case 'quiz':
        return Icons.quiz;
      case 'pit':
        return Icons.engineering;
      case 'material':
        return Icons.book;
      case 'announcement':
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown time';
    try {
      DateTime date;
      if (timestamp is DateTime) {
        date = timestamp;
      } else if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else {
        return 'Unknown time';
      }
      final now = DateTime.now();
      final difference = now.difference(date);
      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) return 'Just now';
          return '${difference.inMinutes}m';
        }
        return '${difference.inHours}h';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d';
      } else {
        return DateFormat('MMM d').format(date);
      }
    } catch (e) {
      return 'Unknown time';
    }
  }

  bool _isNotificationRead(Map<String, dynamic> notification) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return true;
    final readBy = List<String>.from(notification['readBy'] ?? []);
    return readBy.contains(user.uid);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationController>();

    return Container(
      constraints: const BoxConstraints(maxHeight: 650),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: WebTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_horiz),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              ],
            ),
          ),

          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Obx(
              () => Row(
                children: [
                  _buildFilterPill('All'),
                  const SizedBox(width: 8),
                  _buildFilterPill('Unread'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Notifications List
          Flexible(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(
                      color: WebTheme.primaryGreen,
                    ),
                  ),
                );
              }

              var filteredList = controller.notifications.toList();
              if (selectedFilter.value == 'Unread') {
                filteredList =
                    filteredList.where((n) => !_isNotificationRead(n)).toList();
              }

              if (filteredList.isEmpty) {
                return _buildEmptyState();
              }

              // Categorize
              final now = DateTime.now();
              final newItems =
                  filteredList.where((n) {
                    final ts = n['createdAt'];
                    DateTime? date;
                    if (ts is Timestamp) date = ts.toDate();
                    if (ts is DateTime) date = ts;
                    return date != null && now.difference(date).inHours < 24;
                  }).toList();
              final earlierItems =
                  filteredList.where((n) {
                    final ts = n['createdAt'];
                    DateTime? date;
                    if (ts is Timestamp) date = ts.toDate();
                    if (ts is DateTime) date = ts;
                    return date != null && now.difference(date).inHours >= 24;
                  }).toList();

              return ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 12),
                children: [
                  if (newItems.isNotEmpty) ...[
                    _buildSectionHeader('New'),
                    ...newItems.map(
                      (n) => _buildNotificationItem(n, controller),
                    ),
                  ],
                  if (earlierItems.isNotEmpty) ...[
                    _buildSectionHeader('Earlier'),
                    ...earlierItems.map(
                      (n) => _buildNotificationItem(n, controller),
                    ),
                  ],
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String label) {
    bool isSelected = selectedFilter.value == label;
    return GestureDetector(
      onTap: () => selectedFilter.value = label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? WebTheme.primaryGreen.withOpacity(0.12)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? WebTheme.primaryGreen : WebTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: WebTheme.textPrimary,
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back(); // close dropdown
              Get.toNamed(WebRoutes.announcements);
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'See all',
              style: TextStyle(
                color: WebTheme.primaryGreen,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    Map<String, dynamic> n,
    NotificationController controller,
  ) {
    final type = n['type']?.toString() ?? 'announcement';
    final title = n['title']?.toString() ?? 'New notification';
    final instructorName = n['instructorName']?.toString() ?? 'Instructor';
    final instructorProfileUrl = n['instructorProfileUrl']?.toString() ?? '';
    final createdAt = n['createdAt'];
    final isRead = _isNotificationRead(n);
    final color = _getNotificationColor(type);
    final icon = _getNotificationIcon(type);

    return InkWell(
      onTap: () {
        controller.markAsRead(n['id']);
        Get.back();
        // Since WebRoutes.announcements is currently used for notifications on web,
        // we'll go there. In a more complete implementation, we'd go to specific detail screens.
        Get.toNamed(WebRoutes.announcements);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: isRead ? Colors.white : WebTheme.primaryGreen.withOpacity(0.04),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar with Badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: WebTheme.backgroundLight,
                  backgroundImage:
                      instructorProfileUrl.isNotEmpty
                          ? NetworkImage(instructorProfileUrl)
                          : null,
                  child:
                      instructorProfileUrl.isEmpty
                          ? Text(
                            instructorName[0].toUpperCase(),
                            style: const TextStyle(
                              color: WebTheme.primaryGreen,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                          : null,
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(icon, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: const TextStyle(
                        color: WebTheme.textPrimary,
                        fontSize: 16,
                        height: 1.25,
                      ),
                      children: [
                        TextSpan(
                          text: instructorName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' posted a new '),
                        TextSpan(
                          text: '$type: ',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: title),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTimestamp(createdAt),
                    style: TextStyle(
                      color:
                          isRead
                              ? WebTheme.textSecondary
                              : WebTheme.primaryGreen,
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Unread indicator dot
            if (!isRead)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1877F2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: WebTheme.textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No ${selectedFilter.value.toLowerCase()} notifications',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: WebTheme.textSecondary.withOpacity(0.7),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
