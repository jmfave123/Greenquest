import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/services/file_download_service.dart';
import '../../../shared/utils/file_type_utils.dart';
import '../../config/web_theme.dart';

/// Reusable widget to display instructor-attached files
/// Shows file icons, names, types, and download functionality
class WebInstructorAttachmentsWidget extends StatelessWidget {
  final List<dynamic> attachments;
  final String title;

  const WebInstructorAttachmentsWidget({
    super.key,
    required this.attachments,
    this.title = 'Instructor Attachments',
  });

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 48),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: WebTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...attachments.map((file) => _buildFileItem(context, file)),
      ],
    );
  }

  Widget _buildFileItem(BuildContext context, dynamic file) {
    String fileName;
    String fileUrl;
    String fileType;

    if (file is String) {
      // Handle URL strings (from Firebase)
      fileUrl = file;
      // Extract filename from Cloudinary URL
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        // Get the last segment (filename with extension)
        final lastSegment = pathSegments.last;
        fileName = Uri.decodeComponent(lastSegment);
        // Extract file extension
        final dotIndex = fileName.lastIndexOf('.');
        if (dotIndex != -1) {
          fileType = fileName.substring(dotIndex + 1);
        } else {
          fileType = 'file';
        }
      } else {
        fileName = 'Attachment';
        fileType = 'file';
      }
    } else if (file is Map) {
      // Handle file objects
      fileName = file['name'] ?? 'File';
      fileUrl = file['url'] ?? '';
      fileType = file['type'] ?? 'unknown';
    } else {
      fileName = 'File';
      fileUrl = '';
      fileType = 'unknown';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WebTheme.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WebTheme.borderLight),
      ),
      child: Row(
        children: [
          _getFileIcon(fileType),
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
            onPressed:
                () => _handleFileDownload(context, fileUrl, fileName, fileType),
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

  Widget _getFileIcon(String type) {
    IconData icon;
    Color color;

    final lowerType = type.toLowerCase();
    if (lowerType.contains('pdf')) {
      icon = Icons.picture_as_pdf;
      color = Colors.red.shade400;
    } else if (lowerType.contains('doc') || lowerType.contains('text')) {
      icon = Icons.description;
      color = Colors.blue.shade400;
    } else if (FileTypeUtils.isImageFile(lowerType)) {
      icon = Icons.image;
      color = Colors.purple.shade400;
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

  void _handleFileDownload(
    BuildContext context,
    String url,
    String name,
    String type,
  ) {
    if (url.isEmpty) {
      Get.snackbar(
        'Error',
        'Invalid file URL',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    FileDownloadService.handleFileAction(
      fileUrl: url,
      fileName: name,
      fileType: type,
      context: context,
    );
  }
}
