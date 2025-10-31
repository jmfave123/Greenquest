import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:greenquest/user/submit/assignment/assignment_controller.dart';
import 'package:greenquest/shared/services/file_upload_service.dart';
import 'package:greenquest/user/submit/student_submission_controller.dart';
import 'package:greenquest/user/submit/file_picker_screen.dart';
import 'package:greenquest/shared/controllers/file_submission_controller.dart';

class QuizDetailScreen extends StatefulWidget {
  final Map<String, dynamic> assignment;

  const QuizDetailScreen({super.key, required this.assignment});

  @override
  State<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen>
    with WidgetsBindingObserver {
  AssignmentController? controller;
  FileSubmissionController? fileController;
  StudentSubmissionController? submissionController;
  bool submitted = false;
  List<Map<String, dynamic>> submittedFiles = [];
  Map<String, dynamic>? existingSubmission;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    try {
      // Try to find existing controller first, if not found create new one
      try {
        controller = Get.find<AssignmentController>();
      } catch (e) {
        // Controller not found, create new one
        controller = Get.put(AssignmentController(), permanent: true);
      }
      fileController = Get.put(FileSubmissionController());
      submissionController = Get.put(StudentSubmissionController());
      _initializeSubmissionData();
    } catch (e) {
      print('Error finding controllers: $e');
      // Create a fallback controller if all else fails
      try {
        controller = Get.put(AssignmentController(), permanent: true);
      } catch (fallbackError) {
        print('Error creating fallback controller: $fallbackError');
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh submission data when app resumes
      _initializeSubmissionData();
    }
  }

  Future<void> _initializeSubmissionData() async {
    // Load submission data with real-time updates
    if (submissionController != null) {
      await submissionController!.loadSubmissionData(
        activityId: widget.assignment['id'],
        activityType: 'quiz',
      );
    }

    // Also check existing submission for file display
    if (fileController != null) {
      final submission = await fileController!.getQuizSubmission(
        widget.assignment['id'],
      );
      setState(() {
        existingSubmission = submission;
        submitted = submission != null;
        if (submission != null && submission['files'] != null) {
          submittedFiles = List<Map<String, dynamic>>.from(submission['files']);
        }
      });
    }
  }

  Future<void> _openFilePicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => FilePickerScreen(
              quizId: widget.assignment['id'],
              type: 'quiz',
              itemData: widget.assignment,
            ),
      ),
    );

    // If submission was successful, refresh the status
    if (result == true) {
      await _initializeSubmissionData();
    }
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
    final assignment = widget.assignment;

    // Validate assignment data
    if (assignment.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        backgroundColor: Colors.white,
        body: const Center(
          child: Text(
            'Invalid Quiz',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with title
            Text(
              assignment['title'] ?? 'No Title',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            const SizedBox(height: 16),

            // Instructor info, creation date, points, and due date in vertical layout
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      'Instructor Name: ${assignment['instructorName'] ?? 'Unknown Instructor'}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Created: ${_formatDisplayDate(assignment['createdAt'])}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.stars, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      'Points: ${assignment['points'] ?? 0}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      'Due: ${_formatDisplayDate(assignment['dueDate'])}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Description section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🔷 ', style: TextStyle(fontSize: 18)),
                Expanded(
                  child: Text(
                    'Description: ${assignment['instruction'] ?? 'No instructions available'}',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Your work',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Flexible(
                        child:
                            submissionController != null
                                ? Obx(() {
                                  // Show actual status from submission controller if available
                                  if (submissionController != null) {
                                    final status =
                                        submissionController!
                                            .submissionStatus
                                            .value;
                                    final isGraded =
                                        submissionController!.isGraded.value;

                                    Color statusColor;
                                    IconData statusIcon;
                                    String statusText;

                                    if (isGraded) {
                                      statusColor = Colors.green;
                                      statusIcon = Icons.check_circle;
                                      statusText = 'Graded';
                                    } else if (status == 'Submitted' ||
                                        status == 'submitted') {
                                      statusColor = Colors.blue;
                                      statusIcon = Icons.upload;
                                      statusText = 'Submitted';
                                    } else if (status == 'Missing') {
                                      statusColor = Colors.red;
                                      statusIcon = Icons.schedule;
                                      statusText = 'Missing';
                                    } else {
                                      statusColor = Colors.orange;
                                      statusIcon = Icons.help_outline;
                                      statusText =
                                          status.isNotEmpty
                                              ? status
                                              : 'Not Submitted';
                                    }

                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: statusColor,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            statusIcon,
                                            size: 16,
                                            color: statusColor,
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              statusText,
                                              style: TextStyle(
                                                color: statusColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    // Fallback when no submission controller
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.grey,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.help_outline,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              'Loading...',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                })
                                : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Show grade and feedback if graded
                  submissionController != null
                      ? Obx(() {
                        if (submissionController!.isGraded.value) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Graded',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Text(
                                      'Score: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${submissionController!.submissionScore.value.toInt()}/${widget.assignment['points'] ?? 100}',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                if (submissionController!
                                    .submissionFeedback
                                    .value
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Feedback:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    submissionController!
                                        .submissionFeedback
                                        .value,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      })
                      : const SizedBox.shrink(),

                  // Show submission button or submitted files based on status
                  submissionController != null
                      ? Obx(() {
                        final isSubmitted =
                            submissionController!.submissionStatus.value ==
                                'Submitted' ||
                            submissionController!.submissionStatus.value ==
                                'submitted' ||
                            submissionController!.isGraded.value;

                        if (!isSubmitted) {
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _openFilePicker,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Add or Create',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      })
                      : const SizedBox.shrink(),

                  // Show submitted files if assignment is submitted
                  submissionController != null
                      ? Obx(() {
                        final isSubmitted =
                            submissionController!.submissionStatus.value ==
                                'Submitted' ||
                            submissionController!.submissionStatus.value ==
                                'submitted' ||
                            submissionController!.isGraded.value;

                        if (isSubmitted) {
                          if (submittedFiles.isNotEmpty) {
                            return Column(
                              children: [
                                ...submittedFiles.map(
                                  (fileData) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF7F8FA),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.black12),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color:
                                                FileUploadService.getFileColor(
                                                  fileData['type'] ?? '',
                                                ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Icon(
                                            FileUploadService.getFileIcon(
                                              fileData['type'] ?? '',
                                            ),
                                            color:
                                                FileUploadService.getFileColor(
                                                  fileData['type'] ?? '',
                                                ),
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                fileData['name'] ??
                                                    'Unknown file',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              if (fileData['size'] != null)
                                                Text(
                                                  FileUploadService.formatFileSize(
                                                    fileData['size'],
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        if (fileData['url'] != null)
                                          IconButton(
                                            onPressed: () {
                                              Get.snackbar(
                                                'File Link',
                                                'File: ${fileData['name']}',
                                                snackPosition:
                                                    SnackPosition.TOP,
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.open_in_new,
                                              color: Colors.blue,
                                              size: 20,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F8FA),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.black12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.insert_drive_file,
                                    color: Colors.grey,
                                    size: 32,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Quiz submitted successfully',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        } else {
                          return const SizedBox.shrink();
                        }
                      })
                      : const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
