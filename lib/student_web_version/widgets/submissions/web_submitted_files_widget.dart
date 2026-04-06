import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../user/submit/student_submission_controller.dart';
import '../../config/web_theme.dart';
import '../../utils/attachment_action_helper.dart';
import '../../../shared/utils/file_type_utils.dart';

/// Displays the student's own submitted files with preview and download
/// actions, visible only after a successful submission.
///
/// Each file row renders a type icon, file name, and action buttons
/// delegating to [AttachmentActionHelper] for consistent behavior.
class WebSubmittedFilesWidget extends StatelessWidget {
  final StudentSubmissionController submissionController;

  const WebSubmittedFilesWidget({
    super.key,
    required this.submissionController,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final data = submissionController.submissionData;
      final files = data['files'] as List<dynamic>? ?? [];
      final isSubmitted =
          submissionController.submissionStatus.value
              .toLowerCase()
              .contains('submitted') ||
          submissionController.isGraded.value;

      if (!isSubmitted || files.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.folder_outlined,
                size: 18,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              const Text(
                'Your Submitted Files',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: WebTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...files.map<Widget>((file) => _buildFileRow(context, file)),
        ],
      );
    });
  }

  Widget _buildFileRow(BuildContext context, dynamic file) {
    final String fileName = _extractFileName(file);
    final String fileUrl = _extractFileUrl(file);
    final String fileType = _extractFileType(fileName);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WebTheme.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WebTheme.borderLight),
      ),
      child: Row(
        children: [
          _buildFileIcon(fileType),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  fileType.toUpperCase(),
                  style: const TextStyle(
                    color: WebTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => AttachmentActionHelper.previewFile(
              context: context,
              url: fileUrl,
              name: fileName,
              type: fileType,
            ),
            icon: const Icon(
              Icons.visibility_outlined,
              color: WebTheme.primaryGreen,
            ),
            tooltip: 'Preview',
          ),
          IconButton(
            onPressed: () => AttachmentActionHelper.downloadFile(
              context: context,
              url: fileUrl,
              name: fileName,
              type: fileType,
            ),
            icon: const Icon(
              Icons.file_download_outlined,
              color: WebTheme.primaryGreen,
            ),
            tooltip: 'Download',
          ),
        ],
      ),
    );
  }

  Widget _buildFileIcon(String fileType) {
    IconData icon;
    Color color;

    final lowerType = fileType.toLowerCase();

    if (lowerType.contains('pdf')) {
      icon = Icons.picture_as_pdf;
      color = Colors.red.shade400;
    } else if (lowerType.contains('doc') || lowerType.contains('text')) {
      icon = Icons.description;
      color = Colors.blue.shade400;
    } else if (FileTypeUtils.isImageFile(lowerType)) {
      icon = Icons.image;
      color = Colors.purple.shade400;
    } else if (FileTypeUtils.isSpreadsheetFile(lowerType)) {
      icon = Icons.table_chart;
      color = Colors.green.shade400;
    } else if (FileTypeUtils.isPresentationFile(lowerType)) {
      icon = Icons.slideshow;
      color = Colors.orange.shade400;
    } else {
      icon = Icons.insert_drive_file;
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  // ---------------------------------------------------------------------------
  // Parsing helpers — handles both String and Map file entries
  // ---------------------------------------------------------------------------

  String _extractFileName(dynamic file) {
    if (file is Map) return file['name'] as String? ?? 'File';
    if (file is String) {
      final uri = Uri.tryParse(file);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        return Uri.decodeComponent(uri.pathSegments.last);
      }
    }
    return 'File';
  }

  String _extractFileUrl(dynamic file) {
    if (file is Map) return file['url'] as String? ?? '';
    if (file is String) return file;
    return '';
  }

  String _extractFileType(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    return dotIndex != -1 ? fileName.substring(dotIndex + 1) : 'file';
  }
}
