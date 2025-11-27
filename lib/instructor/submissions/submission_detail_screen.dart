// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../shared/instructor/instructor_appbar.dart';
import '../../shared/instructor/instructor_sidebar.dart';
import '../../shared/instructor/instructor_navigation_constants.dart';
import '../../shared/services/file_download_service.dart';
import 'submissions_controller.dart';
// Web-specific imports (only used when kIsWeb is true)
import 'package:universal_html/html.dart' as html;

class SubmissionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> activityData;
  final Map<String, dynamic> submissionData;

  const SubmissionDetailScreen({
    super.key,
    required this.activityData,
    required this.submissionData,
  });

  @override
  State<SubmissionDetailScreen> createState() => _SubmissionDetailScreenState();
}

class _SubmissionDetailScreenState extends State<SubmissionDetailScreen> {
  InstructorNavigationItem _selectedItem =
      InstructorNavigationItem.classManagement;

  late TextEditingController _scoreController;
  late TextEditingController _feedbackController;
  late SubmissionsController submissionsController;
  late double _currentScore;
  late bool _isGraded;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    submissionsController = Get.find<SubmissionsController>();
    _currentScore = widget.submissionData['grade']?.toDouble() ?? 0.0;
    _isGraded = widget.submissionData['status'] == 'graded';
    _scoreController = TextEditingController(text: _currentScore.toString());
    _feedbackController = TextEditingController(
      text: widget.submissionData['feedback'] ?? '',
    );
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _handleNavigationSelect(InstructorNavigationItem item) {
    setState(() {
      _selectedItem = item;
    });
    String route = InstructorNavigationHelper.getRoute(item);
    Navigator.of(context).pushReplacementNamed(route);
  }

  Future<void> _saveGrade() async {
    if (_isSaving) return; // Prevent multiple submissions

    if (_scoreController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a score',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    double score = double.tryParse(_scoreController.text) ?? 0.0;
    final maxScore = widget.activityData['points'] ?? 100;

    // Enhanced validation
    if (_scoreController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a score',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (score < 0) {
      Get.snackbar(
        'Error',
        'Score cannot be negative. Please enter a score between 0 and $maxScore',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (score > maxScore) {
      Get.snackbar(
        'Error',
        'Score cannot exceed maximum points of $maxScore. Please enter a score between 0 and $maxScore',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Check both 'type' and 'activityType' fields (unified submissions use 'activityType')
      final submissionType =
          widget.submissionData['type'] ??
          widget.submissionData['activityType'] ??
          'activity';

      final success = await submissionsController.gradeSubmission(
        submissionId: widget.submissionData['id'],
        submissionType: submissionType,
        score: score,
        feedback: _feedbackController.text,
      );

      if (success) {
        setState(() {
          _currentScore = score;
          _isGraded = true;
        });
      } else {
        Get.snackbar(
          'Error',
          'Failed to save grade',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save grade: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    // Check if widget is still mounted before accessing context
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _formatSubmissionDate(dynamic submittedAt) {
    if (submittedAt == null) return 'Unknown';

    try {
      if (submittedAt is Timestamp) {
        final date = submittedAt.toDate();
        return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (submittedAt is String) {
        final date = DateTime.parse(submittedAt);
        return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return 'Invalid date';
    }

    return 'Unknown';
  }

  Color _getFileTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'docx':
      case 'doc':
        return Colors.blue;
      case 'xlsx':
      case 'excel':
        return Colors.green;
      case 'zip':
        return Colors.orange;
      case 'python':
        return Colors.yellow.shade700;
      default:
        return Colors.grey;
    }
  }

  IconData _getFileTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'docx':
      case 'doc':
        return Icons.description;
      case 'xlsx':
      case 'excel':
        return Icons.table_chart;
      case 'zip':
        return Icons.archive;
      case 'python':
        return Icons.code;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getFileTypeFromUrl(String fileName) {
    if (fileName.isEmpty) return 'unknown';
    final extension = fileName.split('.').last.toLowerCase();
    return extension;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _openFilePreview(String url) async {
    if (url.isEmpty) {
      _showSnackBar('File URL not available', Colors.orange);
      return;
    }

    try {
      // Handle web and mobile platforms differently
      if (kIsWeb) {
        // For web: Open in new tab without pausing the app
        // Using window.open() prevents the Flutter app from pausing
        try {
          // Open file in new tab - this won't pause the Flutter app
          html.window.open(url, '_blank');
        } catch (e) {
          // If window.open fails completely, show dialog with link
          print('window.open failed: $e');
          _showSnackBar(
            'Unable to open in new tab. Showing link...',
            Colors.orange,
          );
          _showPreviewDialog(url);
        }
      } else {
        // For mobile: Use URL launcher as before
        final Uri uri = Uri.parse(url);

        // Check if the URL can be launched
        if (await canLaunchUrl(uri)) {
          // Launch the URL in the default browser for preview
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          // Fallback: Show dialog with URL
          _showPreviewDialog(url);
        }
      }
    } catch (e) {
      print('Error in _openFilePreview: $e');
      _showSnackBar('Error opening file: $e', Colors.red);
      // Show fallback dialog
      _showPreviewDialog(url);
    }
  }

  void _showPreviewDialog(String url) {
    // Check if widget is still mounted before showing dialog
    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('File Preview'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Unable to open file directly. Please use the link below:',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SelectableText(
                    url,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Click the link above to open in your browser, or use the download button below.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _downloadFile(url, 'preview_file');
                },
                child: const Text('Download'),
              ),
            ],
          ),
    );
  }

  void _downloadFile(String url, String fileName) async {
    if (url.isEmpty) {
      _showSnackBar('File URL not available', Colors.orange);
      return;
    }

    try {
      // For web, download directly without showing progress dialog
      if (kIsWeb) {
        _showSnackBar('Downloading $fileName...', const Color(0xFF34A853));

        // Use web download method directly
        await FileDownloadService.downloadFileFromUrl(
          url: url,
          customFileName: fileName,
          onProgress: (received, total) {
            // Progress callback - can be used for UI updates if needed
          },
        );

        _showSnackBar(
          'File download started: $fileName',
          const Color(0xFF34A853),
        );
        return;
      }

      // For Android/iOS, show progress dialog
      _showSnackBar('Downloading $fileName...', const Color(0xFF34A853));

      // Show progress dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF34A853)),
                  const SizedBox(height: 16),
                  Text('Downloading $fileName...'),
                ],
              ),
            ),
      );

      // Download the file using the download service
      final filePath = await FileDownloadService.downloadFileFromUrl(
        url: url,
        customFileName: fileName,
        onProgress: (received, total) {
          // Progress callback - can be used for UI updates if needed
        },
      );

      // Close progress dialog
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (filePath != null) {
        _showSnackBar(
          'File downloaded successfully: $fileName',
          const Color(0xFF34A853),
        );
      } else {
        throw Exception('Download failed');
      }
    } catch (e) {
      // Close progress dialog if it's open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      _showSnackBar('Error downloading file: $e', Colors.red);
      // Show fallback dialog
      _showDownloadDialog(url, fileName);
    }
  }

  void _showDownloadDialog(String url, String fileName) {
    // Check if widget is still mounted before showing dialog
    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Download File'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Unable to open download directly. Please use the link below:',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'File: $fileName',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(url, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Right-click the link above and select "Save link as..." to download the file.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Copy URL to clipboard
                  Clipboard.setData(ClipboardData(text: url));
                  _showSnackBar(
                    'URL copied to clipboard',
                    const Color(0xFF34A853),
                  );
                },
                child: const Text('Copy URL'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          InstructorSidebar(
            selectedItem: _selectedItem,
            onItemSelected: _handleNavigationSelect,
          ),
          // Main Content
          Expanded(
            child: Column(
              children: [
                // App Bar
                Obx(
                  () => InstructorAppBar(
                    instructorName: submissionsController.instructorName.value,
                    instructorRole: 'Instructor',
                    profileImageUrl:
                        submissionsController.profileImageUrl.value,
                  ),
                ),
                // Main Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Color(0xFF34A853),
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFF34A853,
                                ).withOpacity(0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Submission Details',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${widget.submissionData['studentName']} - ${widget.activityData['title']}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Content
                        Expanded(
                          child: SingleChildScrollView(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Column - Submission Info
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Student Info Card
                                      _buildStudentInfoCard(),
                                      const SizedBox(height: 16),

                                      // Files Card
                                      _buildFilesCard(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Right Column - Grading Panel
                                Expanded(flex: 1, child: _buildGradingPanel()),
                              ],
                            ),
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
    );
  }

  Widget _buildStudentInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Student Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFF34A853).withOpacity(0.1),
                child: Text(
                  widget.submissionData['studentName']?.toString().isNotEmpty ==
                          true
                      ? widget.submissionData['studentName'][0].toUpperCase()
                      : 'S',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF34A853),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.submissionData['studentName'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Student ID: ${widget.submissionData['studentIdNumber'] ?? widget.submissionData['studentId'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Submitted: ${_formatSubmissionDate(widget.submissionData['submittedAt'])}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Submitted Files',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.submissionData['files'] != null &&
              (widget.submissionData['files'] as List).isNotEmpty)
            ...(widget.submissionData['files'] as List).map<Widget>((file) {
              final fileType = _getFileTypeFromUrl(file['name'] ?? '');
              final fileSize = _formatFileSize(file['size'] ?? 0);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getFileTypeColor(fileType).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getFileTypeIcon(fileType),
                        color: _getFileTypeColor(fileType),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file['name'] ?? 'Unknown file',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            fileSize,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _openFilePreview(file['url'] ?? '');
                      },
                      icon: const Icon(
                        Icons.visibility,
                        color: Color(0xFF34A853),
                      ),
                      tooltip: 'Preview file',
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF34A853,
                        ).withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        _downloadFile(file['url'] ?? '', file['name'] ?? '');
                      },
                      icon: const Icon(
                        Icons.download,
                        color: Color(0xFF34A853),
                      ),
                      tooltip: 'Download file',
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF34A853,
                        ).withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            })
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: const Center(
                child: Text(
                  'No files submitted',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGradingPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Grading',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),

          // Score Input
          const Text(
            'Score',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _scoreController,
            keyboardType: TextInputType.number,
            cursorColor: const Color(0xFF34A853),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            onChanged: (value) {
              // Real-time validation feedback
              final score = double.tryParse(value) ?? 0.0;
              final maxScore = widget.activityData['points'] ?? 100;

              if (value.isNotEmpty && (score < 0 || score > maxScore)) {
                // You could add visual feedback here if needed
                // For now, we'll rely on the save validation
              }
            },
            decoration: InputDecoration(
              hintText:
                  'Enter score (0-${widget.activityData['points'] ?? 100})',
              suffixText: '/${widget.activityData['points'] ?? 100}',
              helperText:
                  'Maximum points: ${widget.activityData['points'] ?? 100}',
              helperStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF34A853),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.all(12),
              fillColor: const Color(0xFFF8F9FA),
              filled: true,
            ),
          ),
          const SizedBox(height: 16),

          // Current Grade Display
          if (_isGraded)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF34A853).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF34A853).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF34A853),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Graded: $_currentScore/${widget.activityData['points'] ?? 100}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF34A853),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // Action Buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveGrade,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34A853),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child:
                  _isSaving
                      ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Saving...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                      : Text(
                        _isGraded ? 'Update Grade' : 'Save Grade',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
