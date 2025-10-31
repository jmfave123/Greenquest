import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/image_upload_controller.dart';

class ImageUploadWidget extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? folder;
  final String? publicId;
  final Map<String, String>? tags;
  final Function(String imageUrl)? onImageUploaded;
  final Function(String error)? onError;
  final double? width;
  final double? height;
  final bool showPreview;
  final bool allowCamera;
  final bool allowGallery;

  const ImageUploadWidget({
    super.key,
    this.title,
    this.subtitle,
    this.folder,
    this.publicId,
    this.tags,
    this.onImageUploaded,
    this.onError,
    this.width,
    this.height,
    this.showPreview = true,
    this.allowCamera = true,
    this.allowGallery = true,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ImageUploadController());

    return Obx(
      () => SizedBox(
        width: width ?? double.infinity,
        height: height ?? 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title and subtitle
            if (title != null || subtitle != null) ...[
              if (title != null)
                Text(
                  title!,
                  style: Get.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: Get.theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 16),
            ],

            // Upload area
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color:
                        controller.selectedImage != null
                            ? Get.theme.colorScheme.primary
                            : Get.theme.colorScheme.outline,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _buildUploadContent(controller),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Action buttons
            _buildActionButtons(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadContent(ImageUploadController controller) {
    // Show error if any
    if (controller.uploadError.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Get.theme.colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'Error',
              style: Get.textTheme.titleMedium?.copyWith(
                color: Get.theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              controller.uploadError,
              style: Get.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Show uploading progress
    if (controller.isUploading) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              value: _getProgressValue(controller.uploadProgress),
            ),
            const SizedBox(height: 16),
            Text(
              'Uploading...',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(controller.uploadProgress, style: Get.textTheme.bodySmall),
          ],
        ),
      );
    }

    // Show uploaded image
    if (controller.uploadedImageUrl.isNotEmpty && showPreview) {
      return Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              controller.uploadedImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Get.theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.broken_image,
                    size: 48,
                    color: Get.theme.colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Get.theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  controller.clearAll();
                },
              ),
            ),
          ),
        ],
      );
    }

    // Show selected image preview
    if (controller.selectedImage != null && showPreview) {
      return Stack(
        children: [
          Positioned.fill(
            child: Image.file(controller.selectedImage!, fit: BoxFit.cover),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Get.theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  controller.clearAll();
                },
              ),
            ),
          ),
        ],
      );
    }

    // Show upload prompt
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            size: 48,
            color: Get.theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'Upload Image',
            style: Get.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap to select an image from gallery or camera',
            style: Get.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ImageUploadController controller) {
    return Row(
      children: [
        if (allowGallery)
          Expanded(
            child: ElevatedButton.icon(
              onPressed:
                  controller.isUploading
                      ? null
                      : controller.pickImageFromGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('Gallery'),
            ),
          ),
        if (allowGallery && allowCamera) const SizedBox(width: 8),
        if (allowCamera)
          Expanded(
            child: ElevatedButton.icon(
              onPressed:
                  controller.isUploading
                      ? null
                      : controller.pickImageFromCamera,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Camera'),
            ),
          ),
      ],
    );
  }

  double _getProgressValue(String progress) {
    final progressNum = int.tryParse(progress.replaceAll('%', '')) ?? 0;
    return progressNum / 100;
  }
}

// Compact version for smaller spaces
class CompactImageUploadWidget extends StatelessWidget {
  final String? folder;
  final String? publicId;
  final Map<String, String>? tags;
  final Function(String imageUrl)? onImageUploaded;
  final Function(String error)? onError;

  const CompactImageUploadWidget({
    super.key,
    this.folder,
    this.publicId,
    this.tags,
    this.onImageUploaded,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ImageUploadController());

    return Obx(
      () => SizedBox(
        width: 120,
        height: 120,
        child: Stack(
          children: [
            // Main container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(
                  color:
                      controller.selectedImage != null
                          ? Get.theme.colorScheme.primary
                          : Get.theme.colorScheme.outline,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: _buildContent(controller),
              ),
            ),

            // Upload button overlay
            if (!controller.isUploading && controller.selectedImage == null)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => _showUploadOptions(controller),
                    child: Icon(
                      Icons.add_a_photo,
                      color: Get.theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),

            // Close button for selected image
            if (controller.selectedImage != null)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => controller.clearAll(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Get.theme.colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ImageUploadController controller) {
    if (controller.isUploading) {
      return Container(
        color: Get.theme.colorScheme.surfaceContainerHighest,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.selectedImage != null) {
      return Image.file(controller.selectedImage!, fit: BoxFit.cover);
    }

    return Container(
      color: Get.theme.colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.add_a_photo)),
    );
  }

  void _showUploadOptions(ImageUploadController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Get.back();
                controller.pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Get.back();
                controller.pickImageFromCamera();
              },
            ),
          ],
        ),
      ),
      backgroundColor: Get.theme.colorScheme.surface,
    );
  }
}
