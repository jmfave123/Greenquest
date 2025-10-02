import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenquest/user/submit/activity/activity_detail_screen.dart';
import 'activity_controller.dart';

class ActivityListScreen extends StatefulWidget {
  const ActivityListScreen({Key? key}) : super(key: key);

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
      controller = Get.put(ActivityController(), permanent: false);
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
    try {
      if (controller != null) {
        Get.delete<ActivityController>();
      }
    } catch (e) {
      print('Error disposing controller: $e');
    }
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
                                    activity['createdAt'] ?? 'Unknown Date',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
