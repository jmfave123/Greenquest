import 'package:flutter/material.dart';
import '../../../shared/utils/file_type_utils.dart';
import '../../config/web_theme.dart';
import '../../utils/attachment_action_helper.dart';

/// A single attachment row that displays a file icon, name, type badge,
/// a preview (eye) button, and a download button.
class WebAttachmentItemWidget extends StatelessWidget {
  final String fileName;
  final String fileUrl;
  final String fileType;

  const WebAttachmentItemWidget({
    super.key,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
  });

  @override
  Widget build(BuildContext context) {
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
          _buildFileIcon(),
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
                () => AttachmentActionHelper.previewFile(
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
            onPressed:
                () => AttachmentActionHelper.downloadFile(
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

  Widget _buildFileIcon() {
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
}
