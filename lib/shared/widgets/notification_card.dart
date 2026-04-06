import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';

/// A reusable, premium notification card widget.
/// Follows the design aesthetics of Greenquest (vibrant icons, subtle shadows).
class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final String userId;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.userId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isRead = notification.isReadBy(userId);
    final Color typeColor = _getNotificationColor(notification.type);
    final IconData typeIcon = _getNotificationIcon(notification.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? Colors.grey[50] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead ? Colors.grey[200]! : typeColor.withOpacity(0.3),
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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon indicator
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 24),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                fontSize: 15,
                                color: isRead ? Colors.grey[700] : Colors.black87,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 8, top: 4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF34A853),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      if (notification.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          notification.description,
                          style: TextStyle(
                            color: isRead ? Colors.grey[600] : Colors.grey[700],
                            fontSize: 13,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Footer details
                      Row(
                        children: [
                          if (notification.instructorName.isNotEmpty) ...[
                            Flexible(
                              child: Text(
                                'From: ${notification.instructorName}',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text('•', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            _formatTimestamp(notification.createdAt),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Navigation Indicator
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: isRead ? Colors.grey[400] : typeColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Map notification types to specific brand colors.
  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'assignment':
        return const Color(0xFF2886D7); // Brand Blue
      case 'activity':
        return const Color(0xFF43A047); // Brand Green
      case 'quiz':
        return const Color(0xFF8B5CF6); // Purple
      case 'pit':
        return const Color(0xFFFF9800); // Orange
      case 'material':
        return const Color(0xFF34A853); // Success Green
      case 'announcement':
        return Colors.pink;
      case 'tree_approved':
        return const Color(0xFF34A853);
      case 'tree_rejected':
        return Colors.orange;
      case 'graded':
        return const Color(0xFF4285F4);
      default:
        return const Color(0xFF34A853);
    }
  }

  /// Map notification types to specific icons.
  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'assignment':
        return Icons.assignment_outlined;
      case 'activity':
        return Icons.directions_run_outlined;
      case 'quiz':
        return Icons.quiz_outlined;
      case 'pit':
        return Icons.stars_rounded;
      case 'material':
        return Icons.description_outlined;
      case 'announcement':
        return Icons.campaign_outlined;
      case 'tree_approved':
        return Icons.eco_outlined;
      case 'tree_rejected':
        return Icons.eco;
      case 'graded':
        return Icons.grade_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  /// Utility to format Firestore timestamps into readable relative strings.
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';

    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return 'Just now';
    }

    final Duration diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return DateFormat('MMM dd, yyyy').format(date);
  }
}
