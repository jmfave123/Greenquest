import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/controllers/file_submission_controller.dart';
import '../../shared/services/file_upload_service.dart';
import '../../shared/widgets/linkable_text.dart';
import 'submission_success_screen.dart';

class FilePickerScreen extends StatefulWidget {
  final String assignmentId;
  final String activityId;
  final String quizId;
  final String pitId;
  final String type; // 'assignment', 'activity', 'quiz', or 'pit'
  final Map<String, dynamic> itemData;

  const FilePickerScreen({
    super.key,
    this.assignmentId = '',
    this.activityId = '',
    this.quizId = '',
    this.pitId = '',
    required this.type,
    required this.itemData,
  });

  @override
  State<FilePickerScreen> createState() => _FilePickerScreenState();
}

class _FilePickerScreenState extends State<FilePickerScreen> {
  late FileSubmissionController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(FileSubmissionController());
  }

  @override
  void dispose() {
    // Don't delete the controller here as it might be used elsewhere
    super.dispose();
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

  Future<void> _handleSubmission() async {
    if (controller.selectedFiles.isEmpty) {
      Get.snackbar(
        'No Files Selected',
        'Please select at least one file to submit',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // First upload the files
    bool uploadSuccess = await controller.uploadFiles(
      folder: 'greenquest/submissions/${widget.type}s',
      tags: {
        'type': widget.type,
        'id':
            widget.type == 'assignment'
                ? widget.assignmentId
                : widget.type == 'activity'
                ? widget.activityId
                : widget.type == 'quiz'
                ? widget.quizId
                : widget.pitId,
      },
    );

    if (!uploadSuccess) {
      return; // Error already shown in controller
    }

    // Get user section information
    final sectionInfo = await controller.getCurrentUserSection();
    if (sectionInfo == null) {
      Get.snackbar(
        'Error',
        'Unable to get your section information. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Then submit the assignment/activity/quiz
    bool submissionSuccess = false;
    if (widget.type == 'assignment') {
      submissionSuccess = await controller.submitAssignment(
        assignmentId: widget.assignmentId,
        instructorId: sectionInfo['instructorId'] ?? '',
        instructorName: sectionInfo['instructorName'] ?? '',
        sectionId: sectionInfo['sectionId'] ?? '',
        sectionName: sectionInfo['sectionName'] ?? '',
      );
    } else if (widget.type == 'activity') {
      submissionSuccess = await controller.submitActivity(
        activityId: widget.activityId,
        instructorId: sectionInfo['instructorId'] ?? '',
        instructorName: sectionInfo['instructorName'] ?? '',
        sectionId: sectionInfo['sectionId'] ?? '',
        sectionName: sectionInfo['sectionName'] ?? '',
      );
    } else if (widget.type == 'quiz') {
      submissionSuccess = await controller.submitQuiz(
        quizId: widget.quizId,
        instructorId: sectionInfo['instructorId'] ?? '',
        instructorName: sectionInfo['instructorName'] ?? '',
        sectionId: sectionInfo['sectionId'] ?? '',
        sectionName: sectionInfo['sectionName'] ?? '',
      );
    } else if (widget.type == 'pit') {
      submissionSuccess = await controller.submitPit(
        pitId: widget.pitId,
        instructorId: sectionInfo['instructorId'] ?? '',
        instructorName: sectionInfo['instructorName'] ?? '',
        sectionId: sectionInfo['sectionId'] ?? '',
        sectionName: sectionInfo['sectionName'] ?? '',
      );
    }

    if (submissionSuccess) {
      // Navigate to success screen
      Get.off(
        () => SubmissionSuccessScreen(
          submissionType: widget.type,
          itemTitle: widget.itemData['title'] ?? 'No Title',
          instructorName: sectionInfo['instructorName'] ?? 'Unknown Instructor',
          sectionName: sectionInfo['sectionName'] ?? 'Unknown Section',
        ),
      );
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
        title: Text(
          'Submit ${widget.type == 'assignment'
              ? 'Assignment'
              : widget.type == 'activity'
              ? 'Activity'
              : widget.type == 'quiz'
              ? 'Quiz'
              : 'PIT'}',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(
        () => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE9ECEF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.itemData['title'] ?? 'No Title',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinkableText(
                      text:
                          'Description: ${widget.itemData['instruction'] ?? 'No description available'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Instructor: ${widget.itemData['instructorName'] ?? 'Unknown Instructor'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Due: ${_formatDisplayDate(widget.itemData['dueDate'])}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        if (widget.itemData['points'] != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.stars,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Points: ${widget.itemData['points']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // File Selection Section
              const Text(
                'Select Files to Submit',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF4CAF50), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF4CAF50),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You can select multiple files at once! Choose PDF, DOC, images, etc. You can also add more files later.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Pick Files Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed:
                      controller.isUploading.value ||
                              controller.isSubmitting.value
                          ? null
                          : controller.pickFiles,
                  icon: const Icon(Icons.attach_file, color: Colors.green),
                  label: Text(
                    controller.selectedFiles.isEmpty
                        ? 'Choose Files (Multiple Selection)'
                        : 'Add More Files',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.green, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Selected Files Header
              if (controller.selectedFiles.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Selected Files (${controller.selectedFiles.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    if (controller.selectedFiles.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => controller.clearFiles(),
                        icon: const Icon(
                          Icons.clear_all,
                          color: Colors.red,
                          size: 16,
                        ),
                        label: const Text(
                          'Clear All',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Selected Files List
              Expanded(
                child:
                    controller.selectedFiles.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No files selected',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap "Choose Files" to select files for submission',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          itemCount: controller.selectedFiles.length,
                          itemBuilder: (context, index) {
                            final file = controller.selectedFiles[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE9ECEF),
                                ),
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
                                    decoration: BoxDecoration(
                                      color: FileUploadService.getFileColor(
                                        file.extension ?? '',
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      FileUploadService.getFileIcon(
                                        file.extension ?? '',
                                      ),
                                      color: FileUploadService.getFileColor(
                                        file.extension ?? '',
                                      ),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          file.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          FileUploadService.formatFileSize(
                                            file.size,
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed:
                                        () => controller.removeFile(index),
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
              ),

              // Upload Progress
              if (controller.isUploading.value) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE9ECEF)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.green,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              controller.uploadStatus.value,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: controller.uploadProgress.value,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(controller.uploadProgress.value * 100).toInt()}% complete',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      controller.selectedFiles.isEmpty ||
                              controller.isUploading.value ||
                              controller.isSubmitting.value
                          ? null
                          : _handleSubmission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child:
                      controller.isSubmitting.value
                          ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Submitting...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                          : const Text(
                            'Submit Files',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
