import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:greenquest/user/submit/pit/pit_controller.dart';
import '../file_picker_screen.dart';
import '../student_submission_controller.dart';
import '../../../shared/controllers/file_submission_controller.dart';
import '../../../shared/services/file_download_service.dart';
import '../../../shared/utils/file_type_utils.dart';
import '../../../shared/widgets/linkable_text.dart';
import '../../../core/utils/date_utils.dart';

class PitDetailScreen extends StatefulWidget {
  final Map<String, dynamic> pit;

  const PitDetailScreen({super.key, required this.pit});

  @override
  State<PitDetailScreen> createState() => _PitDetailScreenState();
}

class _PitDetailScreenState extends State<PitDetailScreen>
    with WidgetsBindingObserver {
  PitController? controller;
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
        controller = Get.find<PitController>();
      } catch (e) {
        // Controller not found, create new one
        controller = Get.put(PitController(), permanent: true);
      }
      fileController = Get.put(FileSubmissionController());
      submissionController = Get.put(StudentSubmissionController());
      _initializeSubmissionData();
    } catch (e) {
      print('Error finding controllers: $e');
      // Create a fallback controller if all else fails
      try {
        controller = Get.put(PitController(), permanent: true);
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
        activityId: widget.pit['id'],
        activityType: 'pit',
      );
    }

    // Also check existing submission for file display
    if (fileController != null) {
      await _checkExistingSubmission();
    }
  }

  Future<void> _checkExistingSubmission() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final submissionDoc =
          await FirebaseFirestore.instance
              .collection('submissions')
              .where('activityType', isEqualTo: 'pit')
              .where('studentId', isEqualTo: user.uid)
              .where('activityId', isEqualTo: widget.pit['id'])
              .limit(1)
              .get();

      if (submissionDoc.docs.isNotEmpty) {
        existingSubmission = submissionDoc.docs.first.data();
        submittedFiles = List<Map<String, dynamic>>.from(
          existingSubmission!['files'] ?? [],
        );
        setState(() {
          submitted = true;
        });
      }
    } catch (e) {
      print('Error checking existing submission: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Submission Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 30,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with title
            Text(
              widget.pit['title'] ?? 'No Title',
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
                      'Instructor Name: ${widget.pit['instructorName'] ?? 'Unknown Instructor'}',
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
                      'Created: ${_formatDisplayDate(widget.pit['createdAt'])}',
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
                      'Points: ${widget.pit['points'] ?? 0}',
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
                      'Due: ${_formatDisplayDate(widget.pit['dueDate'])}',
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
                  child: LinkableText(
                    text:
                        'Description: ${widget.pit['instruction'] ?? 'No instructions available'}',
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
                    offset: const Offset(0, 2),
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
                          final isPastDue = DueDateUtils.isPastDue(
                            widget.pit['dueDate'],
                          );
                          if (isPastDue) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: null,
                                    style: ElevatedButton.styleFrom(
                                      disabledBackgroundColor:
                                          Colors.grey.shade300,
                                      disabledForegroundColor:
                                          Colors.grey.shade500,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.lock_outline),
                                        SizedBox(width: 8),
                                        Text(
                                          'Add or Create',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Work cannot be turned in after the due date.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            );
                          }
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => FilePickerScreen(
                                          pitId: widget.pit['id'],
                                          type: 'pit',
                                          itemData: widget.pit,
                                        ),
                                  ),
                                );
                              },
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
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.attach_file,
                                            color: Colors.blue,
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
                                                  '${(fileData['size'] / 1024).toStringAsFixed(1)} KB',
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
                                            onPressed: () async {
                                              final fileUrl =
                                                  fileData['url']?.toString() ??
                                                  '';
                                              final fileName =
                                                  fileData['name']
                                                      ?.toString() ??
                                                  'file';
                                              String fileType =
                                                  fileData['type']
                                                      ?.toString() ??
                                                  '';

                                              if (fileUrl.isEmpty) {
                                                Get.snackbar(
                                                  'Error',
                                                  'File URL not available',
                                                  snackPosition:
                                                      SnackPosition.TOP,
                                                  backgroundColor: Colors.red,
                                                  colorText: Colors.white,
                                                );
                                                return;
                                              }

                                              // If type is missing or 'unknown', extract from filename
                                              if (fileType.isEmpty ||
                                                  fileType == 'unknown') {
                                                final fileNameParts = fileName
                                                    .split('.');
                                                if (fileNameParts.length > 1) {
                                                  fileType =
                                                      fileNameParts.last
                                                          .toLowerCase();
                                                }
                                              }

                                              try {
                                                // Check if file is an image
                                                if (FileTypeUtils.isImageFile(
                                                  fileType,
                                                )) {
                                                  // Show image preview dialog instead of downloading
                                                  FileDownloadService.showImagePreviewDialog(
                                                    context,
                                                    fileUrl,
                                                    fileName,
                                                  );
                                                } else {
                                                  // Use FileDownloadService to handle non-image file opening
                                                  await FileDownloadService.handleFileAction(
                                                    fileUrl: fileUrl,
                                                    fileName: fileName,
                                                    fileType: fileType,
                                                    context: context,
                                                  );
                                                }
                                              } catch (e) {
                                                Get.snackbar(
                                                  'Error',
                                                  'Failed to open file: ${e.toString()}',
                                                  snackPosition:
                                                      SnackPosition.TOP,
                                                  backgroundColor: Colors.red,
                                                  colorText: Colors.white,
                                                );
                                              }
                                            },
                                            icon: const Icon(
                                              Icons.open_in_new,
                                              color: Colors.blue,
                                              size: 20,
                                            ),
                                            tooltip: 'Open file',
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
                                      'PIT submitted successfully',
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
}
