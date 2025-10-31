import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:greenquest/user/submit/activity/activity_detail_screen.dart';
import 'activity_controller.dart';

class ActivityListScreen extends StatefulWidget {
  const ActivityListScreen({super.key});

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  ActivityController? controller;

  @override
  void initState() {
    super.initState();
    // Initialize controller with proper error handling
    try {
      // Try to find existing controller first, if not found create new one
      try {
        controller = Get.find<ActivityController>();
      } catch (e) {
        // Controller not found, create new one
        controller = Get.put(ActivityController(), permanent: true);
      }
    } catch (e) {
      print('Error initializing controller: $e');
      // Fallback: try to find existing controller
      try {
        controller = Get.find<ActivityController>();
      } catch (e2) {
        print('Error finding existing controller: $e2');
        controller = null;
      }
    }
  }

  @override
  void dispose() {
    // Don't delete the controller as it's permanent
    super.dispose();
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (status.toLowerCase()) {
      case 'submitted':
        badgeColor = const Color(0xFF2196F3); // Blue
        badgeText = 'Submitted';
        badgeIcon = Icons.check_circle;
        break;
      case 'draft':
        badgeColor = const Color(0xFFFF9800); // Orange
        badgeText = 'Draft';
        badgeIcon = Icons.edit;
        break;
      case 'graded':
        badgeColor = const Color(0xFF34A853); // Green
        badgeText = 'Graded';
        badgeIcon = Icons.star;
        break;
      case 'needs_revision':
        badgeColor = const Color(0xFFF44336); // Red
        badgeText = 'Revise';
        badgeIcon = Icons.refresh;
        break;
      default: // 'not_submitted'
        badgeColor = const Color(0xFF9E9E9E); // Gray
        badgeText = 'Not Started';
        badgeIcon = Icons.radio_button_unchecked;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDisplayDate(dynamic dateData) {
    if (dateData == null) return 'Unknown Date';

    if (dateData is String) {
      if (dateData.contains(' ') &&
          !dateData.contains('T') &&
          !dateData.contains('-')) {
        return dateData;
      }
    }

    try {
      DateTime date;
      if (dateData is DateTime) {
        date = dateData;
      } else if (dateData is String) {
        if (dateData.contains('T')) {
          date = DateTime.parse(dateData);
        } else if (dateData.contains('-')) {
          date = DateTime.parse(dateData);
        } else {
          date = DateTime.parse(dateData);
        }
      } else if (dateData is Timestamp) {
        date = dateData.toDate();
      } else {
        return 'Unknown Date';
      }

      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      final month = months[date.month - 1];
      final day = date.day.toString().padLeft(2, '0');
      final year = date.year;

      int hour = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';

      if (hour == 0) {
        hour = 12;
      } else if (hour > 12) {
        hour -= 12;
      }

      return '$month $day, $year ${hour.toString().padLeft(2, '0')}:$minute $period';
    } catch (e) {
      print('Error formatting date: $e');
      return 'Unknown Date';
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
        title:
            controller == null
                ? const Text(
                  'Choose Activity',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                )
                : Obx(
                  () => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        controller!.currentInstructorUid.value.isNotEmpty
                            ? 'Activities'
                            : 'All Activities',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (controller!.currentInstructorUid.value.isNotEmpty &&
                          controller!.currentInstructorName.value.isNotEmpty)
                        Text(
                          'by ${controller!.currentInstructorName.value}',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                ),
        centerTitle: true,
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.swap_horiz, color: Colors.black),
          //   onPressed: () {
          //     if (controller != null) {
          //       if (controller!.currentInstructorUid.value.isNotEmpty) {
          //         // Switch to all activities
          //         controller!.currentInstructorUid.value = '';
          //         controller!.currentInstructorName.value = '';
          //         controller!.loadAllActivities();
          //       } else {
          //         // Switch to selected instructor activities
          //         controller!.loadCurrentInstructorActivities();
          //       }
          //     }
          //   },
          //   tooltip:
          //       'Toggle between Selected Instructor Activities and All Activities',
          // ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              if (controller != null) {
                controller!.refreshActivities();
              }
            },
            tooltip: 'Refresh Activities',
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body:
          controller == null
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF34A853),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Initializing...',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              )
              : Obx(() {
                if (controller!.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF34A853),
                      ),
                    ),
                  );
                }

                if (controller!.activities.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          controller!.currentInstructorUid.value.isNotEmpty
                              ? 'No activities posted yet'
                              : 'No activities available',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          controller!.currentInstructorUid.value.isNotEmpty
                              ? 'This instructor has not posted any activities yet'
                              : 'Activities will appear here when instructors post them',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  itemCount: controller!.activities.length,
                  itemBuilder: (context, i) {
                    final activity = controller!.activities[i];

                    // Validate activity data before navigation
                    if (activity.isEmpty) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Invalid Activity',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    return GestureDetector(
                      onTap: () {
                        // Double-check activity is valid before navigation
                        if (activity.isNotEmpty) {
                          controller!.setSelectedActivity(activity);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      ActivityDetailScreen(activity: activity),
                            ),
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Color(0xFF34A853),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.assignment,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${activity['instructorName']} posted new activity: ${activity['title']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatDisplayDate(activity['createdAt']),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Status Badge
                            Obx(() {
                              final activityId = activity['id']?.toString();
                              final status =
                                  controller?.submissionStatus[activityId] ??
                                  'not_submitted';
                              return _buildStatusBadge(status);
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
    );
  }
}
