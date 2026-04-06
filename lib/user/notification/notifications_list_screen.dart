import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../submit/assignment/assignment_detail_screen.dart';
import '../submit/activity/activity_detail_screen.dart';
import '../submit/quiz_new/quiz_detail_screen.dart';
import '../submit/pit/pit_detail_screen.dart';
import '../materials/materials_detail_screen.dart';
import '../plant_trees/plant_trees_screen.dart';
import 'notification_controller.dart';
import '../../shared/services/in_app_notification_service.dart';
import '../../shared/widgets/pull_to_refresh_wrapper.dart';
import '../../shared/widgets/skeleton_loading.dart';
import '../../shared/models/notification_model.dart';
import '../../shared/widgets/notification_card.dart';

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

  @override
  void dispose() {
    // Mark all as read when leaving the screen
    controller.markAllAsRead();
    super.dispose();
  }

  Future<void> _markNotificationAsRead(NotificationModel notification) async {
    // Use controller to mark as read
    await controller.markAsRead(notification.id);
  }

  void _navigateToRelatedScreen(NotificationModel notification) async {
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
      String notificationType = notification.type.toLowerCase();
      String? itemId = notification.itemId;
      final instructorId = notification.instructorId;
      final metadata = notification.metadata;

      // If it's a graded notification, use the activityType from metadata
      if (notificationType == 'graded' && metadata.isNotEmpty) {
        final activityType = metadata['activityType']?.toString() ?? '';
        if (activityType.isNotEmpty) {
          notificationType = activityType.toLowerCase();
        }
        // Use itemId or fallback to metadata if needed
        if (itemId.isEmpty) {
          itemId = metadata['activityId']?.toString() ?? '';
        }
      }

      if (itemId.isEmpty || instructorId.isEmpty) {
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
          _showAnnouncementDialogFromNotification(data, instructorId, notification);
          break;
        case 'tree_approved':
        case 'tree_rejected':
          // Navigate to the Plant Trees screen, then show details
          Get.to(() => const PlantTreesScreen())?.then((_) {});
          // Show the tree submission details dialog after navigation
          Future.delayed(const Duration(milliseconds: 300), () {
            _showTreeSubmissionDialog(data, notification.createdAt);
          });
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
    NotificationModel notification,
  ) async {
    // Show the announcement dialog
    _showAnnouncementDialogInNotifications(announcementData, notification);
  }

  // Show tree submission details dialog
  void _showTreeSubmissionDialog(Map<String, dynamic> submission, dynamic plantDateOverride) {
    final status = submission['status'] ?? 'submitted';
    final quantity = submission['quantity'] ?? 0;
    final location = submission['location'] ?? 'Unknown location';
    final feedback = submission['feedback'] ?? '';
    final plantDate = submission['plantDate'] ?? plantDateOverride;
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
                            _formatSimpleTimestamp(plantDate),
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
    NotificationModel notification,
  ) {
    final title = announcement['title'] ?? notification.title;
    final content = announcement['content'] ?? announcement['description'] ?? notification.description;
    final timestamp = announcement['createdAt'] ?? announcement['timestamp'] ?? notification.createdAt;
    final instructorName = announcement['instructorName'] ?? notification.instructorName;
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
                                    _formatSimpleTimestamp(timestamp),
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
                                    await _markNotificationAsRead(notification);
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
      ),
      backgroundColor: Colors.white,
      body: PullToRefreshWrapper(
        onRefresh: () async {
          await controller.refreshNotifications();
        },
        wrapContent: false,
        child: Obx(() {
          if (controller.isLoading.value) {
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: 6,
              itemBuilder: (context, index) => const SkeletonListItem(),
            );
          }

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: InAppNotificationService.getStudentNotificationsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, index) => const SkeletonListItem(),
                );
              }

              if (snapshot.hasError) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading notifications: ${snapshot.error}',
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }

              final notifications = snapshot.data ?? [];

              if (notifications.isEmpty) {
                return _buildEmptyState();
              }

              return _buildNotificationsList(notifications);
            },
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationsList(List<Map<String, dynamic>> notifications) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final data = notifications[index];
        final notification = NotificationModel.fromMap(data, data['id'] ?? '');

        return NotificationCard(
          notification: notification,
          userId: userId,
          onTap: () => _navigateToRelatedScreen(notification),
        );
      },
    );
  }

  /// Simplified timestamp formatter for internal dialogs
  String _formatSimpleTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return 'Unknown';
    }
    return DateFormat('MMM dd, yyyy').format(date);
  }
}
