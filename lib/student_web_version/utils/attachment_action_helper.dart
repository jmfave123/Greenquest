import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/services/file_download_service.dart';
import '../../../shared/utils/file_type_utils.dart';

/// Handles preview and download actions for attached files.
///
/// - [previewFile]: Images open in an in-app dialog; document files
///   (PDF, DOC, XLSX, PPT) open via Google Docs Viewer in a new tab
///   to guarantee a visual preview instead of a download.
/// - [downloadFile]: Delegates to [FileDownloadService.handleFileAction].
class AttachmentActionHelper {
  AttachmentActionHelper._(); // prevent instantiation

  /// File extensions that Google Docs Viewer can render inline.
  static const List<String> _viewerSupportedExtensions = [
    'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
    'csv', 'txt', 'rtf',
  ];

  /// Opens a preview for [url].
  ///
  /// Images → in-app dialog with a close button.
  /// Documents (PDF, DOC, etc.) → Google Docs Viewer in a new tab.
  /// Other file types → raw URL in a new browser tab.
  static Future<void> previewFile({
    required BuildContext context,
    required String url,
    required String name,
    required String type,
  }) async {
    if (url.isEmpty) {
      _showError('Invalid file URL');
      return;
    }

    final lowerType = type.toLowerCase();

    if (FileTypeUtils.isImageFile(lowerType)) {
      await _showImagePreviewDialog(context: context, url: url);
    } else {
      await _openInBrowser(url: url, fileType: lowerType);
    }
  }

  /// Triggers a file download via [FileDownloadService].
  static void downloadFile({
    required BuildContext context,
    required String url,
    required String name,
    required String type,
  }) {
    if (url.isEmpty) {
      _showError('Invalid file URL');
      return;
    }

    FileDownloadService.handleFileAction(
      fileUrl: url,
      fileName: name,
      fileType: type,
      context: context,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static Future<void> _showImagePreviewDialog({
    required BuildContext context,
    required String url,
  }) {
    return showDialog<void>(
      context: context,
      builder:
          (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder:
                        (_, __, ___) => Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.broken_image_outlined,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text('Unable to load image'),
                            ],
                          ),
                        ),
                  ),
                ),
                Positioned(
                  top: -12,
                  right: -12,
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 22),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  /// Builds a Google Docs Viewer URL for supported document types.
  /// Returns `null` if the file type is not supported by the viewer.
  static String? _buildViewerUrl(String rawUrl, String fileType) {
    if (!_viewerSupportedExtensions.contains(fileType)) return null;
    final encodedUrl = Uri.encodeComponent(rawUrl);
    return 'https://docs.google.com/viewer?url=$encodedUrl&embedded=false';
  }

  /// Opens the file in a new browser tab.
  ///
  /// For document types, wraps the URL in Google Docs Viewer so the
  /// browser renders a preview instead of triggering a download.
  static Future<void> _openInBrowser({
    required String url,
    required String fileType,
  }) async {
    if (kIsWeb) {
      final viewerUrl = _buildViewerUrl(url, fileType);
      html.window.open(viewerUrl ?? url, '_blank');
      return;
    }
    // Mobile / desktop
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showError('Could not open the file for preview');
    }
  }

  static void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}
