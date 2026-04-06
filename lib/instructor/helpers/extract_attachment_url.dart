import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenquest/shared/services/file_download_service.dart';
import 'package:url_launcher/url_launcher.dart';

String? extractAttachmentUrl(dynamic attachment) {
  if (attachment is Map<String, dynamic>) {
    final url = attachment['url']?.toString();
    if (url != null && url.isNotEmpty) {
      return url;
    }
  }
  if (attachment is String && attachment.startsWith('http')) {
    return attachment;
  }
  return null;
}

Future<void> previewAttachment(dynamic attachment) async {
  final url = extractAttachmentUrl(attachment);
  if (url == null) {
    Get.snackbar(
      'Preview Unavailable',
      'This attachment has no preview URL',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
    return;
  }
  final uri = Uri.tryParse(url);
  if (uri == null) {
    Get.snackbar(
      'Invalid URL',
      'Could not open attachment preview',
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
    return;
  }
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched) {
    Get.snackbar(
      'Preview Failed',
      'Could not open the attachment',
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}

String getAttachmentDisplayName(dynamic attachment) {
  if (attachment is Map<String, dynamic>) {
    return attachment['name']?.toString() ?? 'Attachment';
  }

  if (attachment is String && attachment.startsWith('http')) {
    final uri = Uri.tryParse(attachment);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    return 'Attachment';
  }

  return attachment?.toString() ?? 'Attachment';
}

Future<void> downloadAttachment(dynamic attachment) async {
  final url = extractAttachmentUrl(attachment);
  if (url == null) {
    Get.snackbar(
      'Download Unavailable',
      'This attachment has no download URL',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
    return;
  }

  final fileName = getAttachmentDisplayName(attachment);
  final result = await FileDownloadService.downloadFileFromUrl(
    url: url,
    customFileName: fileName,
  );

  if (result != null) {
    Get.snackbar(
      'Download Started',
      fileName,
      backgroundColor: const Color(0xFF34A853),
      colorText: Colors.white,
    );
  } else {
    Get.snackbar(
      'Download Failed',
      'Unable to download attachment',
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}




// Future<void> _previewAttachment(dynamic attachment) async {
//     final url = _extractAttachmentUrl(attachment);
//     if (url == null) {
//       Get.snackbar(
//         'Preview Unavailable',
//         'This attachment has no preview URL',
//         backgroundColor: Colors.orange,
//         colorText: Colors.white,
//       );
//       return;
//     }

//     final uri = Uri.tryParse(url);
//     if (uri == null) {
//       Get.snackbar(
//         'Invalid URL',
//         'Could not open attachment preview',
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//       return;
//     }

//     final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

//     if (!launched) {
//       Get.snackbar(
//         'Preview Failed',
//         'Could not open the attachment',
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//     }
//   }

