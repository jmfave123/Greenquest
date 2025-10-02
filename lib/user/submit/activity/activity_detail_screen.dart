import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'activity_controller.dart';
import '../file_picker_screen.dart';
import '../../../shared/controllers/file_submission_controller.dart';
import '../../../shared/services/file_upload_service.dart';

class ActivityDetailScreen extends StatefulWidget {
  final Map<String, dynamic> activity;

  const ActivityDetailScreen({super.key, required this.activity});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  ActivityController? controller;
  FileSubmissionController? fileController;
  bool submitted = false;
  List<Map<String, dynamic>> submittedFiles = [];
  Map<String, dynamic>? existingSubmission;

  @override
  void initState() {
    super.initState();
    try {
      controller = Get.find<ActivityController>();
      fileController = Get.put(FileSubmissionController());
      _checkSubmissionStatus();
    } catch (e) {
      print('Error finding controllers: $e');
    }
  }

  Future<void> _checkSubmissionStatus() async {
    if (fileController != null) {
      final submission = await fileController!.getActivitySubmission(
        widget.activity['id'],
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
              activityId: widget.activity['id'],
              type: 'activity',
              itemData: widget.activity,
            ),
      ),
    );

    // If submission was successful, refresh the status
    if (result == true) {
      await _checkSubmissionStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;

    // Validate activity data
    if (activity.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text(
            'Invalid Activity',
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
            Text(
              activity['title'] ?? 'No Title',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${activity['instructorName']} • ${activity['createdAt']}',
                  style: const TextStyle(color: Colors.black54),
                ),
                Text(
                  '${activity['points']} points',
                  style: const TextStyle(color: Colors.black54),
                ),
                const Spacer(),
                Text(
                  'Due ${activity['dueDate']}',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '"${activity['topic']}"',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🔷 ', style: TextStyle(fontSize: 18)),
                Expanded(
                  child: Text(
                    'Activity: ${activity['instruction'] ?? 'No instructions available'}',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('📝 ', style: TextStyle(fontSize: 18)),
                Expanded(
                  child: Text(
                    'Guide Questions:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.only(left: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• What are your strengths that can help others?',
                    style: TextStyle(fontSize: 15),
                  ),
                  Text(
                    '• How do small actions lead to big change?',
                    style: TextStyle(fontSize: 15),
                  ),
                ],
              ),
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
                      Text(
                        submitted ? 'Turned in' : 'Missing',
                        style: TextStyle(
                          color: submitted ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!submitted) ...[
                    OutlinedButton(
                      onPressed: _openFilePicker,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black26),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child:
                          controller?.isSubmitting.value == true
                              ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.green,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Uploading...',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                              : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text(
                                    'Add or Create',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            controller?.isSubmitting.value == true
                                ? null
                                : _openFilePicker,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child:
                            controller?.isSubmitting.value == true
                                ? const Text(
                                  'Uploading...',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                )
                                : const Text(
                                  'Mark as done',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                      ),
                    ),
                  ] else ...[
                    if (submittedFiles.isNotEmpty) ...[
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
                                  color: FileUploadService.getFileColor(
                                    fileData['type'] ?? '',
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  FileUploadService.getFileIcon(
                                    fileData['type'] ?? '',
                                  ),
                                  color: FileUploadService.getFileColor(
                                    fileData['type'] ?? '',
                                  ),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fileData['name'] ?? 'Unknown file',
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
                                    // TODO: Open file URL in browser or viewer
                                    Get.snackbar(
                                      'File Link',
                                      'File: ${fileData['name']}',
                                      snackPosition: SnackPosition.TOP,
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
                    ] else ...[
                      Container(
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
                                'Activity submitted successfully',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            submitted = false;
                            submittedFiles.clear();
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.green),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Unsubmit',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
