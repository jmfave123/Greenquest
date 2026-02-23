import 'package:flutter/material.dart';
import '../../config/web_theme.dart';
import 'web_attachment_item_widget.dart';

/// Displays a titled list of instructor-attached files.
///
/// Each item is rendered by [WebAttachmentItemWidget] which handles
/// preview and download actions via [AttachmentActionHelper].
///
/// Accepts attachments as either:
/// - `String` — a raw Cloudinary/Firebase URL
/// - `Map`    — a map with `name`, `url`, and `type` keys
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
    if (attachments.isEmpty) return const SizedBox.shrink();

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
        ...attachments.map((file) {
          final parsed = _parseAttachment(file);
          return WebAttachmentItemWidget(
            fileName: parsed.name,
            fileUrl: parsed.url,
            fileType: parsed.type,
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Parsing — converts raw Firebase/Cloudinary data into typed fields
  // ---------------------------------------------------------------------------

  _AttachmentData _parseAttachment(dynamic file) {
    if (file is String) return _parseFromUrl(file);
    if (file is Map) {
      return _AttachmentData(
        name: file['name'] as String? ?? 'File',
        url: file['url'] as String? ?? '',
        type: file['type'] as String? ?? 'unknown',
      );
    }
    return const _AttachmentData(name: 'File', url: '', type: 'unknown');
  }

  _AttachmentData _parseFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.pathSegments.isEmpty) {
      return _AttachmentData(name: 'Attachment', url: url, type: 'file');
    }
    final lastSegment = Uri.decodeComponent(uri.pathSegments.last);
    final dotIndex = lastSegment.lastIndexOf('.');
    final ext = dotIndex != -1 ? lastSegment.substring(dotIndex + 1) : 'file';
    return _AttachmentData(name: lastSegment, url: url, type: ext);
  }
}

// -----------------------------------------------------------------------------
// Internal value object — keeps parsing results typed and immutable
// -----------------------------------------------------------------------------

class _AttachmentData {
  final String name;
  final String url;
  final String type;

  const _AttachmentData({
    required this.name,
    required this.url,
    required this.type,
  });
}
