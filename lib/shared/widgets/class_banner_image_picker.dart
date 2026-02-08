import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import '../services/cloudinary_service.dart';
import '../config/cloudinary_config.dart';

/// Reusable widget for uploading class banner images to Cloudinary
/// Supports Flutter Web with file_picker
class ClassBannerImagePicker extends StatefulWidget {
  final String? currentImageUrl;
  final Function(String imageUrl) onImageUploaded;
  final Function()? onImageRemoved;
  final bool showPreview;
  final double previewHeight;

  const ClassBannerImagePicker({
    super.key,
    this.currentImageUrl,
    required this.onImageUploaded,
    this.onImageRemoved,
    this.showPreview = true,
    this.previewHeight = 200,
  });

  @override
  State<ClassBannerImagePicker> createState() => _ClassBannerImagePickerState();
}

class _ClassBannerImagePickerState extends State<ClassBannerImagePicker> {
  final CloudinaryService _cloudinaryService = CloudinaryService();

  Uint8List? _selectedImageBytes;
  String? _selectedFileName;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCloudinary();
  }

  void _initializeCloudinary() {
    if (CloudinaryConfig.isConfigured) {
      _cloudinaryService.initialize(
        cloudName: CloudinaryConfig.cloudName,
        apiKey: CloudinaryConfig.apiKey,
        apiSecret: CloudinaryConfig.apiSecret,
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      setState(() {
        _errorMessage = null;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // Important for web
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Validate file size
        if (file.size > CloudinaryConfig.maxFileSize) {
          setState(() {
            _errorMessage =
                'File size exceeds ${CloudinaryConfig.maxFileSize ~/ (1024 * 1024)}MB limit';
          });
          return;
        }

        // Validate file type
        final extension = file.extension?.toLowerCase();
        if (extension == null ||
            !CloudinaryConfig.allowedFormats.contains(extension)) {
          setState(() {
            _errorMessage =
                'Invalid file type. Allowed: ${CloudinaryConfig.allowedFormats.join(", ")}';
          });
          return;
        }

        setState(() {
          _selectedImageBytes = file.bytes;
          _selectedFileName = file.name;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error selecting image: $e';
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImageBytes == null || _selectedFileName == null) {
      setState(() {
        _errorMessage = 'No image selected';
      });
      return;
    }

    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
        _errorMessage = null;
      });

      // Simulate progress
      setState(() => _uploadProgress = 0.3);

      // Upload to Cloudinary
      final response = await _cloudinaryService.uploadImageFromBytes(
        imageBytes: _selectedImageBytes!,
        fileName: _selectedFileName!,
        folder: 'greenquest/class_banners',
      );

      setState(() => _uploadProgress = 1.0);

      // Notify parent widget
      widget.onImageUploaded(response.secureUrl);

      // Clear selection
      setState(() {
        _selectedImageBytes = null;
        _selectedFileName = null;
      });

      Get.snackbar(
        'Success',
        'Banner image uploaded successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF34A853),
        colorText: Colors.white,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Upload failed: $e';
      });
      Get.snackbar(
        'Error',
        'Failed to upload image: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImageBytes = null;
      _selectedFileName = null;
      _errorMessage = null;
    });

    if (widget.onImageRemoved != null) {
      widget.onImageRemoved!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Preview Section
        if (widget.showPreview) ...[
          Container(
            width: double.infinity,
            height: widget.previewHeight,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildPreview(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Action Buttons
        Row(
          children: [
            // Pick Image Button
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34A853),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.image, size: 20),
              label: Text(
                _selectedImageBytes != null ? 'Change Image' : 'Select Image',
              ),
            ),
            const SizedBox(width: 12),

            // Upload Button (only show if image is selected)
            if (_selectedImageBytes != null) ...[
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                icon:
                    _isUploading
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Icon(Icons.upload, size: 20),
                label: Text(_isUploading ? 'Uploading...' : 'Upload'),
              ),
              const SizedBox(width: 12),
            ],

            // Remove Button (show if custom image exists)
            if (widget.currentImageUrl != null && widget.onImageRemoved != null)
              TextButton.icon(
                onPressed: _isUploading ? null : _removeImage,
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                icon: const Icon(Icons.delete_outline, size: 20),
                label: const Text('Reset to Default'),
              ),
          ],
        ),

        // Upload Progress
        if (_isUploading) ...[
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF34A853)),
          ),
        ],

        // Error Message
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPreview() {
    // Show selected image preview
    if (_selectedImageBytes != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(_selectedImageBytes!, fit: BoxFit.cover),
          // Overlay label
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Preview',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      );
    }

    // Show current uploaded image
    if (widget.currentImageUrl != null) {
      return Image.network(
        widget.currentImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder('Failed to load image');
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
      );
    }

    // Show placeholder
    return _buildPlaceholder('No image selected');
  }

  Widget _buildPlaceholder(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }
}
