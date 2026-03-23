import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gal/gal.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import '../utils/file_type_utils.dart';

class FileDownloadService {
  static final Dio _dio = Dio();

  static void _log(Object? message) {
    if (kDebugMode) {
      debugPrint('$message');
    }
  }

  /// Download file and open it
  static Future<void> downloadAndOpenFile({
    required String fileUrl,
    required String fileName,
    required String fileType,
    BuildContext? context,
  }) async {
    try {
      // Show loading indicator
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Downloading file...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Check if running on web
      if (kIsWeb) {
        await _downloadFileForWeb(fileUrl, fileName, fileType, context);
        return;
      }

      // Check if it's an image file
      final isImage = FileTypeUtils.isImageFile(fileType);

      if (isImage) {
        // For images, try to save to gallery/photos
        await _downloadImageToGallery(fileUrl, fileName, context);
        return;
      }

      // For other files, use regular download logic
      await _downloadRegularFile(fileUrl, fileName, fileType, context);
    } catch (e) {
      _log('Error downloading file: $e');
      if (context != null) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to download file: $e'),
              backgroundColor: Colors.red,
            ),
          );
        } catch (snackbarError) {
          // Context may be invalid if screen was closed, ignore silently
          _log('Could not show error snackbar: $snackbarError');
        }
      }
    }
  }

  /// Download file for web platform
  static Future<void> _downloadFileForWeb(
    String fileUrl,
    String fileName,
    String fileType,
    BuildContext? context,
  ) async {
    try {
      // For web, we need to create a download link and trigger it
      await _triggerWebDownload(fileUrl, fileName);

      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File download started'),
            backgroundColor: Color(0xFF22C55E),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _log('Error downloading file on web: $e');
      // Fallback: show URL for manual download
      if (context != null) {
        _showWebDownloadDialog(context, fileUrl, fileName);
      }
    }
  }

  /// Trigger download for web platform
  static Future<void> _triggerWebDownload(
    String fileUrl,
    String fileName,
  ) async {
    if (kIsWeb) {
      try {
        // Fetch the file as bytes
        final response = await _dio.get(
          fileUrl,
          options: Options(responseType: ResponseType.bytes),
        );

        // Create blob from bytes
        final blob = html.Blob([response.data]);

        // Create object URL
        final url = html.Url.createObjectUrl(blob);

        // Create download link
        final anchor =
            html.AnchorElement(href: url)
              ..setAttribute('download', fileName)
              ..style.display = 'none';

        // Add to DOM, click, and remove
        html.document.body?.append(anchor);
        anchor.click();
        anchor.remove();

        // Clean up object URL
        html.Url.revokeObjectUrl(url);

        _log('File downloaded successfully: $fileName');
      } catch (e) {
        _log('Error downloading file: $e');
        throw Exception('Failed to download file: $e');
      }
    } else {
      // For non-web platforms, use URL launcher
      try {
        final uri = Uri.parse(fileUrl);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        await launchUrl(Uri.parse(fileUrl), mode: LaunchMode.platformDefault);
      }
    }
  }

  /// Show image preview dialog
  static void showImagePreviewDialog(
    BuildContext context,
    String imageUrl,
    String fileName,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF34A853),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.image, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fileName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  // Image preview
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: InteractiveViewer(
                        panEnabled: true,
                        boundaryMargin: const EdgeInsets.all(20),
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF34A853),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Failed to load image',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  // Download button
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            // Get the scaffold messenger before popping the dialog
                            final messenger = ScaffoldMessenger.of(context);
                            final dialogContext = context;

                            // Close the dialog first
                            Navigator.of(dialogContext).pop();

                            try {
                              if (kIsWeb) {
                                // For web, download directly
                                await _triggerWebDownload(imageUrl, fileName);
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Image download started'),
                                    backgroundColor: Color(0xFF22C55E),
                                  ),
                                );
                              } else {
                                // For mobile, save to gallery
                                await _downloadImageToGallerySilent(
                                  imageUrl,
                                  fileName,
                                );
                                // Show success message
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Image saved to gallery successfully!',
                                    ),
                                    backgroundColor: Color(0xFF22C55E),
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            } catch (e) {
                              String errorMessage = 'Failed to download image';
                              if (e.toString().contains('Permission denied') ||
                                  e.toString().contains(
                                    'Photo access denied',
                                  )) {
                                errorMessage =
                                    'Permission denied. Please allow photo access in settings.';
                              } else {
                                errorMessage =
                                    'Failed to download image: ${e.toString()}';
                              }
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(errorMessage),
                                  backgroundColor: Colors.red,
                                  action:
                                      errorMessage.contains('Permission denied')
                                          ? SnackBarAction(
                                            label: 'Settings',
                                            textColor: Colors.white,
                                            onPressed: () async {
                                              await openAppSettings();
                                            },
                                          )
                                          : null,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.download),
                          label: const Text('Download Image'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF34A853),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  /// Show download dialog for web
  static void _showWebDownloadDialog(
    BuildContext context,
    String fileUrl,
    String fileName,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Download File'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('File: $fileName'),
                const SizedBox(height: 16),
                const Text('Click the button below to download the file:'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    try {
                      final uri = Uri.parse(fileUrl);
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (e) {
                      // Copy URL to clipboard as fallback
                      Clipboard.setData(ClipboardData(text: fileUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('URL copied to clipboard'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Download File'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  /// Download image to phone gallery/photos
  static Future<void> _downloadImageToGallery(
    String fileUrl,
    String fileName,
    BuildContext? context,
  ) async {
    try {
      // Check if gal has access to photos
      bool hasAccess = await Gal.hasAccess();

      if (!hasAccess) {
        // Request access to photos
        bool granted = await Gal.requestAccess();
        if (!granted) {
          _log('Photo access denied');
          if (context != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Permission denied. Please allow photo access in settings.',
                ),
                backgroundColor: Colors.orange,
                action: SnackBarAction(
                  label: 'Settings',
                  textColor: Colors.white,
                  onPressed: () => openAppSettings(),
                ),
              ),
            );
          }
          return;
        }
      }

      // Download image to temporary directory first
      final tempDir = await getTemporaryDirectory();
      final tempFilePath = '${tempDir.path}/$fileName';

      // Download image to temp location
      await _dio.download(fileUrl, tempFilePath);

      // Save to gallery using gal
      await Gal.putImage(tempFilePath, album: 'GreenQuest');

      // Clean up temp file
      try {
        final tempFile = File(tempFilePath);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (e) {
        _log('Could not delete temp file: $e');
      }

      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image saved to gallery successfully!'),
            backgroundColor: Color(0xFF22C55E),
            duration: Duration(seconds: 3),
          ),
        );
      }
      _log('Image saved to gallery successfully');
    } catch (e) {
      _log('Error downloading image: $e');
      rethrow;
    }
  }

  /// Download image to gallery without showing snackbars (used when context is unavailable)
  static Future<void> _downloadImageToGallerySilent(
    String fileUrl,
    String fileName,
  ) async {
    try {
      // Check if gal has access to photos
      bool hasAccess = await Gal.hasAccess();

      if (!hasAccess) {
        // Request access to photos
        bool granted = await Gal.requestAccess();
        if (!granted) {
          _log('Photo access denied');
          throw Exception(
            'Permission denied. Please allow photo access in settings.',
          );
        }
      }

      // Download image to temporary directory first
      final tempDir = await getTemporaryDirectory();
      final tempFilePath = '${tempDir.path}/$fileName';

      // Download image to temp location
      await _dio.download(fileUrl, tempFilePath);

      // Save to gallery using gal
      await Gal.putImage(tempFilePath, album: 'GreenQuest');

      // Clean up temp file
      try {
        final tempFile = File(tempFilePath);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (e) {
        _log('Could not delete temp file: $e');
      }

      _log('Image saved to gallery successfully');
    } catch (e) {
      _log('Error downloading image: $e');
      rethrow;
    }
  }

  /// Download regular file (non-image)
  static Future<void> _downloadRegularFile(
    String fileUrl,
    String fileName,
    String fileType,
    BuildContext? context,
  ) async {
    // Request multiple permissions for comprehensive access
    Map<Permission, PermissionStatus> permissions =
        await [Permission.storage, Permission.manageExternalStorage].request();

    // Check if any permission is granted
    bool hasPermission = permissions.values.any((status) => status.isGranted);

    // If all permissions denied, try to open directly from URL
    if (!hasPermission) {
      _log('Storage permission denied, trying to open directly from URL');
      try {
        await openFileFromUrl(fileUrl);
        return;
      } catch (e) {
        _log('URL opening failed, showing manual dialog: $e');
        if (context != null) {
          try {
            _showFileOpenDialog(context, fileUrl, fileName);
          } catch (dialogError) {
            // Context may be invalid if screen was closed, fallback to URL
            _log('Could not show dialog: $dialogError');
            try {
              await openFileFromUrl(fileUrl);
            } catch (urlError) {
              _log('All fallbacks failed: $urlError');
            }
          }
        }
        return;
      }
    }

    // Get download directory
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';

    // Download file
    await _dio.download(fileUrl, filePath);

    // Open file
    final result = await OpenFile.open(filePath);

    if (result.type != ResultType.done) {
      // If can't open directly, try with URL launcher
      final uri = Uri.parse(fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Cannot open file: ${result.message}');
      }
    }

    if (context != null) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File opened successfully'),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
      } catch (e) {
        // Context may be invalid if screen was closed, ignore silently
        _log('Could not show success snackbar: $e');
      }
    }
  }

  /// Open file directly from URL (for web or if download fails)
  static Future<void> openFileFromUrl(String fileUrl) async {
    try {
      _log('Attempting to open URL: $fileUrl');

      // Clean and validate URL
      String cleanUrl = fileUrl.trim();
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }

      final uri = Uri.parse(cleanUrl);
      _log('Parsed URI: $uri');

      // Try different launch modes without checking canLaunchUrl first
      // Sometimes canLaunchUrl returns false but the URL can still be opened

      // Try external application first
      try {
        _log('Trying external application...');
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _log('External application succeeded');
        return;
      } catch (e) {
        _log('External application failed: $e');
      }

      // Try platform default
      try {
        _log('Trying platform default...');
        await launchUrl(uri, mode: LaunchMode.platformDefault);
        _log('Platform default succeeded');
        return;
      } catch (e) {
        _log('Platform default failed: $e');
      }

      // Try in-app web view
      try {
        _log('Trying in-app web view...');
        await launchUrl(uri, mode: LaunchMode.inAppWebView);
        _log('In-app web view succeeded');
        return;
      } catch (e) {
        _log('In-app web view failed: $e');
      }

      // Final check with canLaunchUrl
      final canLaunch = await canLaunchUrl(uri);
      _log('Final canLaunch check: $canLaunch');

      if (!canLaunch) {
        throw Exception('URL cannot be launched: $cleanUrl');
      }

      throw Exception('All launch modes failed for URL: $cleanUrl');
    } catch (e) {
      _log('Error opening file URL: $e');
      rethrow;
    }
  }

  /// Check if file can be downloaded locally
  static bool canDownloadLocally(String fileType) {
    // For web, we can download via browser
    if (kIsWeb) return true;
    // For mobile, we can download most file types
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Get appropriate action for file type
  static Future<void> handleFileAction({
    required String fileUrl,
    required String fileName,
    required String fileType,
    BuildContext? context,
  }) async {
    try {
      if (canDownloadLocally(fileType)) {
        // Try to download and open locally
        await downloadAndOpenFile(
          fileUrl: fileUrl,
          fileName: fileName,
          fileType: fileType,
          context: context,
        );
      } else {
        // Open directly from URL
        await openFileFromUrl(fileUrl);
      }
    } catch (e) {
      _log('Download failed, trying to open from URL: $e');
      // Fallback: open directly from URL
      try {
        await openFileFromUrl(fileUrl);
      } catch (urlError) {
        _log('URL opening also failed: $urlError');
        if (context != null) {
          try {
            _showFileOpenDialog(context, fileUrl, fileName);
          } catch (dialogError) {
            // Context may be invalid if screen was closed, ignore silently
            _log('Could not show file open dialog: $dialogError');
          }
        }
      }
    }
  }

  /// Show dialog with file URL for manual opening
  static void _showFileOpenDialog(
    BuildContext context,
    String fileUrl,
    String fileName,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                const Text('Cannot Open File'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'File: $fileName',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The file cannot be opened automatically. Please use one of the options below:',
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
                      const Text(
                        'File URL:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        fileUrl,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Instructions:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                const Text(
                  '1. Copy the URL above\n2. Open your browser\n3. Paste the URL\n4. Download or view the file',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  // Try to open in browser directly
                  try {
                    final uri = Uri.parse(fileUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      throw Exception('Cannot open URL');
                    }
                  } catch (e) {
                    // If direct opening fails, copy to clipboard
                    Clipboard.setData(ClipboardData(text: fileUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Cannot open directly. URL copied: $fileName',
                        ),
                        backgroundColor: Colors.orange,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.open_in_browser, size: 16),
                label: const Text('Open in Browser'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  Clipboard.setData(ClipboardData(text: fileUrl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('URL copied to clipboard: $fileName'),
                      backgroundColor: const Color(0xFF34A853),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy URL'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF34A853),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
    );
  }

  /// Download a specific PDF file (for instructor submissions)
  static Future<String?> downloadSubmissionPDF() async {
    const pdfUrl =
        'https://res.cloudinary.com/dddnu6i5q/raw/upload/v1759553378/greenquest/submissions/activitys/fckx3dknrdfg4misgm6x.pdf';
    const fileName = 'submission_flow.pdf';

    try {
      final permission = await Permission.storage.request();
      if (!permission.isGranted) {
        throw Exception('Storage permission denied');
      }

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';

      await _dio.download(pdfUrl, filePath);
      return filePath;
    } catch (e) {
      _log('Error downloading PDF: $e');
      return null;
    }
  }

  /// Download file from URL with custom filename
  static Future<String?> downloadFileFromUrl({
    required String url,
    String? customFileName,
    Function(int, int)? onProgress,
  }) async {
    try {
      // For web, use web download method
      if (kIsWeb) {
        final fileName = customFileName ?? url.split('/').last;
        await _triggerWebDownload(url, fileName);
        return 'web_download'; // Return a placeholder for web
      }

      // For Android/iOS, use file system download
      final permission = await Permission.storage.request();
      if (!permission.isGranted) {
        throw Exception('Storage permission denied');
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName = customFileName ?? url.split('/').last;
      final filePath = '${directory.path}/$fileName';

      await _dio.download(url, filePath, onReceiveProgress: onProgress);
      return filePath;
    } catch (e) {
      _log('Error downloading file: $e');
      return null;
    }
  }
}
