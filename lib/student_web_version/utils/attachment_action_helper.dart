import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/services/file_download_service.dart';
import '../../../shared/utils/file_type_utils.dart';

/// Handles preview and download actions for instructor-attached files.
///
/// - [previewFile]: Images open in an in-app dialog; all other file types
///   (PDF, DOC, etc.) are opened in a new browser tab.
/// - [downloadFile]: Delegates to [FileDownloadService.handleFileAction].
class AttachmentActionHelper {
  AttachmentActionHelper._(); // prevent instantiation

  /// Opens a preview for [url].
  ///
  /// Images → in-app dialog with a close button.
  /// Other file types → new browser tab via url_launcher.
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
      await _openInBrowser(url);
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

  static Future<void> _openInBrowser(String url) async {
    if (kIsWeb) {
      html.window.open(url, '_blank');
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
