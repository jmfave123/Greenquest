import 'dart:developer';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'cloudinary_service.dart';
import '../config/cloudinary_config.dart';

class FileUploadService {
  static final FileUploadService _instance = FileUploadService._internal();
  factory FileUploadService() => _instance;
  FileUploadService._internal();

  // Strict allowlist: any extension outside this set is blocked.
  static const Set<String> _allowedFileExtensions = {
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'txt',
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'svg',
  };

  static bool isAllowedExtension(String? extension) {
    final normalized = (extension ?? '').trim().toLowerCase();
    return normalized.isNotEmpty && _allowedFileExtensions.contains(normalized);
  }

  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Initialize the service
  void initialize() {
    _cloudinaryService.initialize(
      cloudName: CloudinaryConfig.cloudName,
      apiKey: CloudinaryConfig.apiKey,
      apiSecret: CloudinaryConfig.apiSecret,
    );
  }

  // Pick multiple files with various types
  Future<List<PlatformFile>?> pickFiles({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool allowMultiple = true,
  }) async {
    try {
      log('📁 Opening file picker...');

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
        withData: true, // Important: Load file data for upload
      );

      if (result != null && result.files.isNotEmpty) {
        log('✅ Selected ${result.files.length} files');

        // Validate extensions and file sizes.
        for (PlatformFile file in result.files) {
          final extension = (file.extension ?? '').toLowerCase();

          if (!isAllowedExtension(extension)) {
            Get.snackbar(
              'File Not Supported',
              'Unsupported file type for "${file.name}".',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
            return null;
          }

          if (file.size > CloudinaryConfig.maxFileSize) {
            Get.snackbar(
              'File Too Large',
              'File "${file.name}" exceeds the maximum size limit of ${CloudinaryConfig.maxFileSize ~/ (1024 * 1024)}MB',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
            return null;
          }
        }

        return result.files;
      } else {
        log('❌ No files selected');
        return null;
      }
    } catch (e) {
      log('❌ Error picking files: $e');
      Get.snackbar(
        'Error',
        'Failed to pick files: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
  }

  // Upload a single file to Cloudinary
  Future<CloudinaryUploadResponse?> uploadFile({
    required PlatformFile file,
    String? folder,
    String? publicId,
    Map<String, String>? tags,
    Function(double)? onProgress,
  }) async {
    try {
      if (file.bytes == null) {
        throw Exception('File data not available');
      }

      final extension = (file.extension ?? '').toLowerCase();
      if (!isAllowedExtension(extension)) {
        throw Exception(
          'Unsupported file type: .${file.extension ?? 'unknown'}',
        );
      }

      log('📤 Uploading file: ${file.name} (${file.size} bytes)');

      onProgress?.call(0.1);

      // Determine the resource type based on file extension
      String resourceType = _getResourceType(file.extension ?? '');

      CloudinaryUploadResponse response;

      if (resourceType == 'image') {
        // Use existing image upload method
        response = await _cloudinaryService.uploadImageFromBytes(
          imageBytes: file.bytes!,
          fileName: file.name,
          folder: folder ?? '${CloudinaryConfig.defaultFolder}/submissions',
          publicId: publicId,
          tags: tags,
        );
      } else {
        // Upload as raw file for documents and other non-image allowed files.
        response = await _uploadRawFile(
          fileBytes: file.bytes!,
          fileName: file.name,
          folder: folder ?? '${CloudinaryConfig.defaultFolder}/submissions',
          publicId: publicId,
          tags: tags,
          resourceType: resourceType,
        );
      }

      onProgress?.call(1.0);
      log('✅ File uploaded successfully: ${response.secureUrl}');
      return response;
    } catch (e) {
      log('❌ Error uploading file ${file.name}: $e');
      rethrow;
    }
  }

  // Upload multiple files
  Future<List<Map<String, dynamic>>> uploadMultipleFiles({
    required List<PlatformFile> files,
    String? folder,
    Map<String, String>? tags,
    Function(int, int)? onProgress,
  }) async {
    List<Map<String, dynamic>> uploadedFiles = [];

    try {
      for (int i = 0; i < files.length; i++) {
        PlatformFile file = files[i];
        onProgress?.call(i, files.length);

        CloudinaryUploadResponse? response = await uploadFile(
          file: file,
          folder: folder,
          tags: tags,
        );

        if (response != null) {
          uploadedFiles.add({
            'name': file.name,
            'url': response.secureUrl,
            'publicId': response.publicId,
            'size': file.size,
            'type': file.extension ?? 'unknown',
            'resourceType': _getResourceType(file.extension ?? ''),
            'uploadedAt': DateTime.now().toIso8601String(),
          });
        }
      }

      onProgress?.call(files.length, files.length);
      return uploadedFiles;
    } catch (e) {
      log('❌ Error uploading multiple files: $e');
      rethrow;
    }
  }

  // Upload raw file (non-image) to Cloudinary
  Future<CloudinaryUploadResponse> _uploadRawFile({
    required Uint8List fileBytes,
    required String fileName,
    String? folder,
    String? publicId,
    Map<String, String>? tags,
    String resourceType = 'raw',
  }) async {
    try {
      // Use the proper raw file upload method
      return await _cloudinaryService.uploadRawFile(
        fileBytes: fileBytes,
        fileName: fileName,
        folder: folder,
        publicId: publicId,
        tags: tags,
      );
    } catch (e) {
      log('❌ Error uploading raw file: $e');
      rethrow;
    }
  }

  // Determine resource type based on file extension
  String _getResourceType(String extension) {
    extension = extension.toLowerCase();

    if ([
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'bmp',
      'svg',
    ].contains(extension)) {
      return 'image';
    } else {
      return 'raw'; // Documents, PDFs, etc.
    }
  }

  // Get file icon based on extension
  static IconData getFileIcon(String extension) {
    extension = extension.toLowerCase();

    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_snippet;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.archive;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  // Get file color based on extension
  static Color getFileColor(String extension) {
    extension = extension.toLowerCase();

    switch (extension) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'txt':
        return Colors.grey;
      case 'zip':
      case 'rar':
      case '7z':
        return Colors.brown;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // Format file size
  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
