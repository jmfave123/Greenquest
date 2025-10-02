import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenquest/user/submit/assignment/assignment_controller.dart';

class QuizDetailScreen extends StatefulWidget {
  final Map<String, dynamic> assignment;

  const QuizDetailScreen({Key? key, required this.assignment})
    : super(key: key);

  @override
  State<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen> {
  AssignmentController? controller;
  bool submitted = false;
  List<String> submittedFiles = [];

  @override
  void initState() {
    super.initState();
    try {
      controller = Get.find<AssignmentController>();
      _checkSubmissionStatus();
    } catch (e) {
      print('Error finding AssignmentController: $e');
    }
  }

  Future<void> _checkSubmissionStatus() async {
    if (controller != null) {
      final status = await controller!.getSubmissionStatus(
        widget.assignment['id'],
      );
      setState(() {
        submitted = status == 'submitted';
      });
    }
  }

  Future<void> _pickAndSubmitFiles() async {
    if (controller != null) {
      final files = await controller!.pickFiles();
      if (files.isNotEmpty) {
        await controller!.submitAssignment(widget.assignment['id'], files);
        setState(() {
          submitted = true;
          submittedFiles = files.map((f) => f['name'] as String).toList();
        });
      }
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
            Text(
              assignment['title'] ?? 'No Title',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${assignment['instructorName'] ?? 'Unknown Instructor'} • ${assignment['createdAt'] ?? 'Unknown Date'}',
                  style: const TextStyle(color: Colors.black54),
                ),
                Text(
                  '${assignment['points'] ?? 0} points',
                  style: const TextStyle(color: Colors.black54),
                ),
                const Spacer(),
                Text(
                  'Due ${assignment['dueDate'] ?? 'Unknown Date'}',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '"${assignment['topic'] ?? 'No Topic'}"',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🔷 ', style: TextStyle(fontSize: 18)),
                Expanded(
                  child: Text(
                    'Quiz Instructions: ${assignment['instruction'] ?? 'No instructions available'}',
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
                    'Quiz Questions:',
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
                    '• Multiple choice questions will be displayed here',
                    style: TextStyle(fontSize: 15),
                  ),
                  Text(
                    '• Select the best answer for each question',
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
                      onPressed:
                          controller?.isSubmitting.value == true
                              ? null
                              : _pickAndSubmitFiles,
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
                                    'Start Quiz',
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
                                : _pickAndSubmitFiles,
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
                                  'Submit Quiz',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                      ),
                    ),
                  ] else ...[
                    if (submittedFiles.isNotEmpty) ...[
                      ...submittedFiles.map(
                        (fileName) => Container(
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
                              const Icon(
                                Icons.insert_drive_file,
                                color: Colors.grey,
                                size: 32,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  fileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    submitted = false;
                                    submittedFiles.clear();
                                  });
                                },
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.black45,
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
                                'Quiz submitted successfully',
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
