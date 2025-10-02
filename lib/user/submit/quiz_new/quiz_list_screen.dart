import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenquest/user/submit/assignment/assignment_controller.dart';
import 'package:greenquest/user/submit/assignment/assignment_detail_screen.dart';

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({Key? key}) : super(key: key);

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  AssignmentController? controller;

  @override
  void initState() {
    super.initState();
    try {
      controller = Get.put(AssignmentController(), permanent: false);
    } catch (e) {
      print('Error initializing AssignmentController: $e');
    }
  }

  @override
  void dispose() {
    try {
      if (controller != null) {
        Get.delete<AssignmentController>();
      }
    } catch (e) {
      print('Error disposing AssignmentController: $e');
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
                  'Choose Quiz',
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
                        'Quizzes',
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
            tooltip: 'Refresh quizzes',
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

                if (controller!.assignments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.quiz_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          controller!.currentInstructorUid.value.isNotEmpty
                              ? 'No quizzes posted yet'
                              : 'Please select an instructor first',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          controller!.currentInstructorUid.value.isNotEmpty
                              ? 'This instructor has not posted any quizzes yet'
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
                  itemCount: controller!.assignments.length,
                  itemBuilder: (context, i) {
                    final assignment = controller!.assignments[i];

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
                            'Invalid Quiz',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    return GestureDetector(
                      onTap: () {
                        // Double-check assignment is valid before navigation
                        if (assignment.isNotEmpty) {
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
                                Icons.quiz_outlined,
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
                                    '${assignment['instructorName']} posted new quiz: ${assignment['title']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    assignment['createdAt'] ?? 'Unknown Date',
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
