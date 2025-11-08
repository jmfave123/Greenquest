import 'package:flutter/material.dart';
import '../../shared/services/file_download_service.dart';
import '../../shared/widgets/linkable_text.dart';

class MaterialsDetailScreen extends StatelessWidget {
  final Map<String, dynamic>? material;

  const MaterialsDetailScreen({super.key, required this.material});

  @override
  Widget build(BuildContext context) {
    // Handle null material case
    if (material == null || material!.isEmpty) {
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Material not found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'This material may have been removed or is no longer available',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
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
        title: const Text(
          'Material Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              material!['title']?.toString() ?? 'No Title',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            const SizedBox(height: 16),
            LinkableText(
              text:
                  material!['description']?.toString() ??
                  'No description available',
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Text(
                  'Instructor: ',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
                Flexible(
                  child: Text(
                    material!['instructorName']?.toString() ??
                        'Unknown Instructor',
                    style: const TextStyle(
                      color: Color(0xFF2886D7),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Uploaded Date: ',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
                Text(
                  material!['createdAt']?.toString() ?? 'Unknown Date',
                  style: const TextStyle(color: Colors.black38, fontSize: 12),
                ),
              ],
            ),
            if (material!['attachments'] != null &&
                (material!['attachments'] as List).isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text(
                'Attachments:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              ...((material!['attachments'] as List).map((attachment) {
                // Extract attachment data properly
                Map<String, dynamic> attachmentData;
                if (attachment is Map<String, dynamic>) {
                  attachmentData = attachment;
                } else {
                  // If it's a string (URL), convert to map
                  attachmentData = {
                    'url': attachment.toString(),
                    'name': attachment.toString().split('/').last,
                    'type': _getFileType(attachment.toString()),
                  };
                }

                final fileUrl = attachmentData['url']?.toString() ?? '';
                final fileName =
                    attachmentData['name']?.toString() ?? 'Unknown File';
                final fileType =
                    attachmentData['type']?.toString() ?? _getFileType(fileUrl);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap:
                        () => _handleAttachmentTap(
                          fileUrl,
                          fileName,
                          fileType,
                          context,
                        ),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34A853).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF34A853).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getFileIcon(fileUrl),
                            size: 20,
                            color: const Color(0xFF34A853),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fileName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF34A853),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tap to download',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: const Color(
                                      0xFF34A853,
                                    ).withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.download,
                            size: 18,
                            color: Color(0xFF34A853),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              })),
            ],
          ],
        ),
      ),
    );
  }

  /// Handle attachment tap and download
  static void _handleAttachmentTap(
    String attachmentUrl,
    String fileName,
    String fileType,
    BuildContext context,
  ) async {
    try {
      print('📥 Downloading file: $fileName');
      print('📥 File URL: $attachmentUrl');
      print('📥 File Type: $fileType');

      await FileDownloadService.handleFileAction(
        fileUrl: attachmentUrl,
        fileName: fileName,
        fileType: fileType,
        context: context,
      );
    } catch (e) {
      print('❌ Error downloading file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Get file icon based on file type
  static IconData _getFileIcon(String fileUrl) {
    final fileType = _getFileType(fileUrl).toLowerCase();

    if (fileType.contains('pdf')) {
      return Icons.picture_as_pdf;
    } else if (fileType.contains('doc') || fileType.contains('docx')) {
      return Icons.description;
    } else if (fileType.contains('ppt') || fileType.contains('pptx')) {
      return Icons.slideshow;
    } else if (fileType.contains('xls') || fileType.contains('xlsx')) {
      return Icons.table_chart;
    } else if (fileType.contains('image') ||
        fileType.contains('jpg') ||
        fileType.contains('jpeg') ||
        fileType.contains('png') ||
        fileType.contains('gif')) {
      return Icons.image;
    } else if (fileType.contains('video') ||
        fileType.contains('mp4') ||
        fileType.contains('avi') ||
        fileType.contains('mov')) {
      return Icons.video_file;
    } else if (fileType.contains('audio') ||
        fileType.contains('mp3') ||
        fileType.contains('wav')) {
      return Icons.audio_file;
    } else if (fileType.contains('zip') || fileType.contains('rar')) {
      return Icons.archive;
    } else {
      return Icons.attach_file;
    }
  }

  /// Extract file name from URL
  static String _getFileName(String fileUrl) {
    try {
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        return pathSegments.last;
      }
      return 'Download';
    } catch (e) {
      return 'Download';
    }
  }

  /// Extract file type from URL
  static String _getFileType(String fileUrl) {
    try {
      final uri = Uri.parse(fileUrl);
      final path = uri.path.toLowerCase();
      if (path.contains('.')) {
        return path.split('.').last;
      }
      return 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }
}
