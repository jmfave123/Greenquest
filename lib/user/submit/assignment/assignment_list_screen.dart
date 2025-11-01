import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:greenquest/user/submit/assignment/assignment_controller.dart';
import 'package:greenquest/user/submit/assignment/assignment_detail_screen.dart';
import 'package:greenquest/shared/widgets/skeleton_loading.dart';

class AssignmentListScreen extends StatefulWidget {
  const AssignmentListScreen({super.key});

  @override
  State<AssignmentListScreen> createState() => _AssignmentListScreenState();
}

class _AssignmentListScreenState extends State<AssignmentListScreen> {
  AssignmentController? controller;

  @override
  void initState() {
    super.initState();
    try {
      // Try to find existing controller first, if not found create new one
      try {
        controller = Get.find<AssignmentController>();
      } catch (e) {
        // Controller not found, create new one
        controller = Get.put(AssignmentController(), permanent: true);
      }
    } catch (e) {
      print('Error initializing AssignmentController: $e');
    }
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

    // If it's already a formatted string from the controller, return as is
    if (dateData is String) {
      // Check if it's already in a readable format (like "July 28")
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
        // Handle different string formats
        if (dateData.contains('T')) {
          // ISO format with T
          date = DateTime.parse(dateData);
        } else if (dateData.contains('-')) {
          // Date format YYYY-MM-DD
          date = DateTime.parse(dateData);
        } else {
          // Try parsing as is
          date = DateTime.parse(dateData);
        }
      } else if (dateData is Timestamp) {
        date = dateData.toDate();
      } else {
        return 'Unknown Date';
      }

      // Format as "MMM dd, yyyy hh:mm AM/PM"
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

      // Format time in 12-hour format
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
  void dispose() {
    // Don't delete the controller since it's permanent and might be used elsewhere
    super.dispose();
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
                  'Choose Assignment',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                )
                : Obx(
                  () => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Assignments',
                        style: TextStyle(
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
          //   icon: const Icon(Icons.person, color: Colors.black),
          //   onPressed: () async {
          //     if (controller != null) {
          //       await controller!.setInstructorForTesting();
          //     }
          //   },
          //   tooltip: 'Set rolan gwapo instructor',
          // ),
          // IconButton(
          //   icon: const Icon(Icons.bug_report, color: Colors.black),
          //   onPressed: () async {
          //     if (controller != null) {
          //       await controller!.debugInstructorSelection();
          //     }
          //   },
          //   tooltip: 'Debug instructor selection',
          // ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () async {
              if (controller != null) {
                await controller!.refreshAssignments();
              }
            },
            tooltip: 'Refresh assignments',
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body:
          controller == null
              ? ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                itemCount: 5,
                itemBuilder: (context, i) => const SkeletonListItem(),
              )
              : Obx(() {
                if (controller == null || controller!.isLoading.value) {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    itemCount: 5,
                    itemBuilder: (context, i) => const SkeletonListItem(),
                  );
                }

                if (controller!.assignments.isEmpty) {
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
                          (controller?.currentInstructorUid.value.isNotEmpty ??
                                  false)
                              ? 'No assignments posted yet'
                              : 'Please select an instructor first',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          (controller?.currentInstructorUid.value.isNotEmpty ??
                                  false)
                              ? 'This instructor has not posted any assignments yet'
                              : 'Go to Course Selection to choose your instructor',
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
                  itemCount: controller?.assignments.length ?? 0,
                  itemBuilder: (context, i) {
                    final assignment = controller?.assignments[i] ?? {};

                    // Validate assignment data before navigation
                    if (assignment.isEmpty) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Invalid Assignment',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    return GestureDetector(
                      onTap: () {
                        // Double-check assignment is valid before navigation
                        if (assignment.isNotEmpty && controller != null) {
                          controller!.setSelectedAssignment(assignment);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => AssignmentDetailScreen(
                                    assignment: assignment,
                                  ),
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
                                    '${assignment['instructorName']} posted new assignment: ${assignment['title']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatDisplayDate(assignment['createdAt']),
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
                              final assignmentId = assignment['id']?.toString();
                              final status =
                                  controller?.submissionStatus[assignmentId] ??
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
