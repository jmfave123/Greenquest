import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../submit/assignment/assignment_detail_screen.dart';
import '../submit/activity/activity_detail_screen.dart';
import '../submit/quiz_new/quiz_detail_screen.dart';
import '../submit/pit/pit_detail_screen.dart';
import '../materials/materials_detail_screen.dart';
import 'notification_controller.dart';
import 'announcement_controller.dart';
import '../../shared/services/in_app_notification_service.dart';
import '../../shared/widgets/skeleton_loading.dart';

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
      case 'tree_approved':
        return const Color(0xFF34A853);
      case 'tree_rejected':
        return Colors.orange;
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
      case 'tree_approved':
        return Icons.eco;
      case 'tree_rejected':
        return Icons.eco;
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

  /// Format material date to match the format used in materials list
  String _formatMaterialDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown Date';

    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        return 'Unknown Date';
      }

      // Format as "January 1, 2025" to match the UI design
      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];

      final month = months[date.month - 1];
      return '$month ${date.day}, ${date.year}';
    } catch (e) {
      print('Error formatting material date: $e');
      return 'Unknown Date';
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
      // For graded notifications, extract activity type from metadata
      String notificationType = type.toLowerCase();
      String? itemId = notification['itemId']?.toString();
      final instructorId = notification['instructorId']?.toString();
      final metadata = notification['metadata'] as Map<String, dynamic>?;

      // If it's a graded notification, use the activityType from metadata
      if (notificationType == 'graded' && metadata != null) {
        final activityType = metadata['activityType']?.toString() ?? '';
        if (activityType.isNotEmpty) {
          notificationType = activityType.toLowerCase();
        }
        // Use itemId from notification (which should be activityId)
        // or fallback to metadata if needed
        if (itemId == null || itemId.isEmpty) {
          // itemId should already be set from the notification, but just in case
          itemId = metadata['activityId']?.toString();
        }
      }

      if (itemId == null ||
          itemId.isEmpty ||
          instructorId == null ||
          instructorId.isEmpty) {
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
      switch (notificationType) {
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
        case 'announcement':
          doc =
              await FirebaseFirestore.instance
                  .collection('instructors')
                  .doc(instructorId)
                  .collection('announcements')
                  .doc(itemId)
                  .get();
          break;
        case 'tree_approved':
        case 'tree_rejected':
          // For tree notifications, get from submissions collection
          doc =
              await FirebaseFirestore.instance
                  .collection('submissions')
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
      // This will show the student their graded submission with score and feedback
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Add document ID to the data

      // For materials, we need to format the data properly
      if (notificationType == 'material') {
        // Fetch instructor name
        try {
          final instructorDoc =
              await FirebaseFirestore.instance
                  .collection('instructors')
                  .doc(instructorId)
                  .get();

          if (instructorDoc.exists) {
            final instructorData = instructorDoc.data() as Map<String, dynamic>;
            data['instructorName'] =
                instructorData['name']?.toString() ?? 'Unknown Instructor';
          } else {
            data['instructorName'] = 'Unknown Instructor';
          }
        } catch (e) {
          print('Error fetching instructor name: $e');
          data['instructorName'] = 'Unknown Instructor';
        }

        // Format the createdAt timestamp
        if (data['createdAt'] != null) {
          data['createdAt'] = _formatMaterialDate(data['createdAt']);
        }
      }

      switch (notificationType) {
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
        case 'announcement':
          // Show announcement dialog and update views
          _showAnnouncementDialogFromNotification(data, instructorId);
          break;
        case 'tree_approved':
        case 'tree_rejected':
          // Show tree submission details dialog
          _showTreeSubmissionDialog(data);
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

  // Show announcement dialog from notification click
  void _showAnnouncementDialogFromNotification(
    Map<String, dynamic> announcementData,
    String instructorId,
  ) async {
    // Mark notification as read when opening dialog
    final notificationId = announcementData['id']?.toString();
    if (notificationId != null && notificationId.isNotEmpty) {
      await _markNotificationAsRead(announcementData);
    }
    // Update views for the announcement
    try {
      final announcementId = announcementData['id']?.toString();
      if (announcementId != null && announcementId.isNotEmpty) {
        // Get or create announcement controller to update views
        UserAnnouncementController? announcementController;
        try {
          announcementController = Get.find<UserAnnouncementController>();
        } catch (e) {
          // Controller not found, create it temporarily just to update views
          announcementController = Get.put(UserAnnouncementController());
        }

        if (announcementController != null) {
          // Update the instructor ID in controller if needed
          announcementController.selectedInstructorId.value = instructorId;
          // Update views
          await announcementController.updateViews(announcementId);
        }
      }
    } catch (e) {
      print('Error updating announcement views: $e');
    }

    // Show the announcement dialog
    _showAnnouncementDialogInNotifications(announcementData);
  }

  // Show tree submission details dialog
  void _showTreeSubmissionDialog(Map<String, dynamic> submission) {
    final status = submission['status'] ?? 'submitted';
    final quantity = submission['quantity'] ?? 0;
    final location = submission['location'] ?? 'Unknown location';
    final feedback = submission['feedback'] ?? '';
    final plantDate = submission['plantDate'];
    final files = submission['files'] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: 500,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          status == 'approved'
                              ? [
                                const Color(0xFF34A853),
                                const Color(0xFF28863D),
                              ]
                              : [Colors.orange, Colors.deepOrange],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        status == 'approved'
                            ? Icons.check_circle
                            : Icons.info_outline,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status == 'approved'
                                  ? '🌳 Tree Planting Approved!'
                                  : '🌳 Tree Planting Needs Revision',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$quantity tree(s)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Location
                        _buildDetailRow(
                          Icons.location_on,
                          'Location',
                          location,
                        ),
                        const SizedBox(height: 16),
                        // Plant Date
                        if (plantDate != null)
                          _buildDetailRow(
                            Icons.calendar_today,
                            'Plant Date',
                            _formatTimestamp(plantDate),
                          ),
                        if (plantDate != null) const SizedBox(height: 16),
                        // Feedback
                        if (feedback.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  status == 'approved'
                                      ? Colors.green.shade50
                                      : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    status == 'approved'
                                        ? Colors.green.shade200
                                        : Colors.orange.shade200,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.feedback,
                                      size: 20,
                                      color:
                                          status == 'approved'
                                              ? Colors.green
                                              : Colors.orange,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      status == 'approved'
                                          ? 'Feedback'
                                          : 'Reason for Revision',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            status == 'approved'
                                                ? Colors.green.shade900
                                                : Colors.orange.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  feedback,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Evidence Photos
                        if (files.isNotEmpty) ...[
                          const Text(
                            'Evidence Photos',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                            itemCount: files.length,
                            itemBuilder: (context, index) {
                              final file = files[index];
                              final fileUrl = file['url'] ?? '';
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  fileUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.broken_image),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Close button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF34A853),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF34A853)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Show announcement dialog (extracted from announcement_screen_wrapper)
  void _showAnnouncementDialogInNotifications(
    Map<String, dynamic> announcement,
  ) {
    final title = announcement['title'] ?? 'No Title';
    final content = announcement['content'] ?? 'No content available';
    final timestamp = announcement['createdAt'] ?? announcement['timestamp'];
    final instructorName = announcement['instructorName'] ?? 'Instructor';
    final instructorProfileUrl = announcement['instructorProfileUrl'] ?? '';
    final imageUrl = announcement['imageUrl'] ?? '';

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
              maxWidth: 600,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF34A853), Color(0xFF2E7D32)],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.campaign_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (timestamp != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatTimestamp(timestamp),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main content area
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Instructor info card
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF34A853,
                                  ).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF34A853,
                                    ).withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    _buildInstructorAvatar(
                                      instructorProfileUrl,
                                      instructorName,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            instructorName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Color(0xFF34A853),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.person_outline_rounded,
                                                size: 14,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Instructor',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Content section
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF34A853),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Announcement',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  content,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.7,
                                    color: Colors.black87,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              // Announcement image (if available) - At bottom
                              if (imageUrl.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                Container(
                                  width: double.infinity,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.network(
                                          imageUrl,
                                          width: double.infinity,
                                          height: 220,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (
                                            context,
                                            child,
                                            loadingProgress,
                                          ) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return Container(
                                              color: Colors.grey[100],
                                              child: Center(
                                                child: CircularProgressIndicator(
                                                  value:
                                                      loadingProgress
                                                                  .expectedTotalBytes !=
                                                              null
                                                          ? loadingProgress
                                                                  .cumulativeBytesLoaded /
                                                              loadingProgress
                                                                  .expectedTotalBytes!
                                                          : null,
                                                  color: const Color(
                                                    0xFF34A853,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return Container(
                                              color: Colors.grey[200],
                                              child: const Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .broken_image_outlined,
                                                      size: 56,
                                                      color: Colors.grey,
                                                    ),
                                                    SizedBox(height: 12),
                                                    Text(
                                                      'Failed to load image',
                                                      style: TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Footer with buttons
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(24),
                              bottomRight: Radius.circular(24),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.grey[700],
                                    side: BorderSide(color: Colors.grey[300]!),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Close',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    // Mark notification as read
                                    await _markNotificationAsRead(announcement);
                                    Navigator.of(context).pop();
                                    Get.snackbar(
                                      'Marked as Read',
                                      'Announcement has been marked as read',
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: const Color(0xFF34A853),
                                      colorText: Colors.white,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF34A853),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        size: 18,
                                      ),
                                      SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          'Mark as Read',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Build instructor avatar (matching announcement_screen_wrapper)
  Widget _buildInstructorAvatar(String profileUrl, String name) {
    final hasImage = profileUrl.isNotEmpty;
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'I';

    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFF34A853),
      backgroundImage: hasImage ? NetworkImage(profileUrl) : null,
      child:
          hasImage
              ? null
              : Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: StreamBuilder<List<Map<String, dynamic>>>(
          stream: InAppNotificationService.getStudentNotificationsStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Text(
                'Notifications',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              );
            }

            final notifications = snapshot.data ?? [];
            final user = FirebaseAuth.instance.currentUser;
            final userId = user?.uid ?? '';
            int unreadCount = 0;

            for (var notification in notifications) {
              final readBy = List<String>.from(notification['readBy'] ?? []);
              if (!readBy.contains(userId)) {
                unreadCount++;
              }
            }

            return Row(
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (unreadCount > 0) ...[
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
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
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
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: InAppNotificationService.getStudentNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: 6,
              itemBuilder: (context, index) => const SkeletonListItem(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading notifications: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return _buildNotificationsList(notifications);
        },
      ),
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

  Widget _buildNotificationsList(List<Map<String, dynamic>> notifications) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        final type = notification['type']?.toString() ?? 'activity';
        final title = notification['title']?.toString() ?? 'New notification';
        final description = notification['description']?.toString() ?? '';
        final instructorName = notification['instructorName']?.toString() ?? '';
        // Check if notification is read by checking readBy array
        final readBy = List<String>.from(notification['readBy'] ?? []);
        final isRead = userId.isNotEmpty && readBy.contains(userId);
        final timestamp = notification['createdAt'];
        final color = _getNotificationColor(type);
        final icon = _getNotificationIcon(type);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          constraints: const BoxConstraints(minHeight: 80),
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
                  mainAxisSize: MainAxisSize.min,
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title and unread indicator
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
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
                                  margin: const EdgeInsets.only(top: 4),
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
                          Row(
                            children: [
                              if (instructorName.isNotEmpty) ...[
                                Flexible(
                                  child: Text(
                                    'From: $instructorName',
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
                                  maxLines: 1,
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
    );
  }
}
