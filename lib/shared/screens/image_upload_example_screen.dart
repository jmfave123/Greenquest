import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/image_upload_controller.dart';
import '../widgets/image_upload_widget.dart';
import '../config/cloudinary_config.dart';

class ImageUploadExampleScreen extends StatelessWidget {
  const ImageUploadExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ImageUploadController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Upload Example'),
        backgroundColor: Get.theme.colorScheme.primary,
        foregroundColor: Get.theme.colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Configuration status
            _buildConfigStatus(),
            const SizedBox(height: 24),

            // Main upload widget
            ImageUploadWidget(
              title: 'Upload Profile Picture',
              subtitle: 'Choose an image from your gallery or take a new photo',
              folder: 'profiles',
              onImageUploaded: (imageUrl) {
                Get.snackbar(
                  'Success',
                  'Image uploaded successfully!',
                  snackPosition: SnackPosition.TOP,
                );
              },
              onError: (error) {
                Get.snackbar(
                  'Error',
                  error,
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Get.theme.colorScheme.error,
                  colorText: Get.theme.colorScheme.onError,
                );
              },
            ),
            const SizedBox(height: 24),

            // Compact upload widget
            Row(
              children: [
                const Text('Compact Upload: '),
                const SizedBox(width: 16),
                CompactImageUploadWidget(
                  folder: 'thumbnails',
                  onImageUploaded: (imageUrl) {
                    Get.snackbar(
                      'Success',
                      'Thumbnail uploaded successfully!',
                      snackPosition: SnackPosition.TOP,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Upload button
            ElevatedButton.icon(
              onPressed: () {
                if (CloudinaryConfig.cloudName.isNotEmpty &&
                    CloudinaryConfig.apiKey.isNotEmpty) {
                  controller.uploadSelectedImage(
                    folder: 'examples',
                    tags: {
                      'uploaded_by': 'example_screen',
                      'timestamp': DateTime.now().toIso8601String(),
                    },
                  );
                } else {
                  Get.snackbar(
                    'Configuration Required',
                    'Please configure your Cloudinary credentials in cloudinary_config.dart',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Get.theme.colorScheme.error,
                    colorText: Get.theme.colorScheme.onError,
                  );
                }
              },
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Upload to Cloudinary'),
            ),
            const SizedBox(height: 16),

            // Clear button
            OutlinedButton.icon(
              onPressed: controller.clearAll,
              icon: const Icon(Icons.clear),
              label: const Text('Clear All'),
            ),
            const SizedBox(height: 24),

            // Current status
            _buildCurrentStatus(controller),
            const SizedBox(height: 24),

            // Instructions
            _buildInstructions(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  CloudinaryConfig.isConfigured
                      ? Icons.check_circle
                      : Icons.warning,
                  color:
                      CloudinaryConfig.isConfigured
                          ? Colors.green
                          : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cloudinary Configuration',
                  style: Get.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              CloudinaryConfig.cloudName.isNotEmpty &&
                      CloudinaryConfig.apiKey.isNotEmpty
                  ? '✅ Cloudinary is configured (${CloudinaryConfig.cloudName})'
                  : '⚠️ Please configure your Cloudinary credentials in lib/shared/config/cloudinary_config.dart',
              style: Get.textTheme.bodyMedium,
            ),
            if (CloudinaryConfig.cloudName.isNotEmpty &&
                CloudinaryConfig.apiKey.isNotEmpty &&
                CloudinaryConfig.apiSecret == 'your_api_secret_here')
              Text(
                '⚠️ API Secret not configured - using unsigned uploads (requires upload preset)',
                style: Get.textTheme.bodySmall?.copyWith(color: Colors.orange),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatus(ImageUploadController controller) {
    return Obx(
      () => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Status',
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildStatusRow(
                'Uploading',
                controller.isUploading ? 'Yes' : 'No',
              ),
              _buildStatusRow('Progress', controller.uploadProgress),
              _buildStatusRow(
                'Selected Image',
                controller.selectedImage != null ? 'Yes' : 'No',
              ),
              _buildStatusRow(
                'Uploaded URL',
                controller.uploadedImageUrl.isNotEmpty
                    ? controller.uploadedImageUrl
                    : 'None',
              ),
              if (controller.uploadError.isNotEmpty)
                _buildStatusRow('Error', controller.uploadError, isError: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Get.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Get.textTheme.bodyMedium?.copyWith(
                color: isError ? Get.theme.colorScheme.error : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Setup Instructions',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '1. Get your Cloudinary credentials from https://cloudinary.com/console',
            ),
            const SizedBox(height: 8),
            const Text(
              '2. Update lib/shared/config/cloudinary_config.dart with your credentials',
            ),
            const SizedBox(height: 8),
            const Text('3. Run flutter pub get to install dependencies'),
            const SizedBox(height: 8),
            const Text(
              '4. Use ImageUploadWidget or CompactImageUploadWidget in your screens',
            ),
            const SizedBox(height: 8),
            const Text(
              '5. Handle upload events with onImageUploaded and onError callbacks',
            ),
          ],
        ),
      ),
    );
  }
}
