import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/controllers/file_submission_controller.dart';
import '../../../shared/services/file_upload_service.dart';
import '../../config/web_theme.dart';

class WebFileUploadWidget extends StatelessWidget {
  final FileSubmissionController controller;
  final VoidCallback onUploadComplete;
  final String label;

  const WebFileUploadWidget({
    super.key,
    required this.controller,
    required this.onUploadComplete,
    this.label = 'Submit Files',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(() {
          if (controller.selectedFiles.isEmpty) {
            return _buildEmptyState();
          }
          return _buildFileList();
        }),
        const SizedBox(height: 16),
        Obx(() {
          if (controller.isUploading.value) {
            return _buildUploadProgress();
          }
          if (controller.isSubmitting.value) {
            return _buildSubmittingState();
          }
          return _buildActionButtons();
        }),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: WebTheme.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: WebTheme.borderLight,
          style: BorderStyle.none,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            size: 48,
            color: WebTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No files selected',
            style: TextStyle(
              color: WebTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Supported: PDF, Images, Documents',
            style: TextStyle(
              color: WebTheme.textSecondary.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WebTheme.borderLight),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.selectedFiles.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final file = controller.selectedFiles[index];
          return ListTile(
            leading: Icon(
              FileUploadService.getFileIcon(file.extension ?? ''),
              color: FileUploadService.getFileColor(file.extension ?? ''),
            ),
            title: Text(
              file.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              FileUploadService.formatFileSize(file.size),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => controller.removeFile(index),
              color: Colors.red.withOpacity(0.7),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUploadProgress() {
    return Column(
      children: [
        LinearProgressIndicator(
          value: controller.uploadProgress.value,
          backgroundColor: WebTheme.primaryGreen.withOpacity(0.1),
          valueColor: const AlwaysStoppedAnimation<Color>(
            WebTheme.primaryGreen,
          ),
          borderRadius: BorderRadius.circular(10),
          minHeight: 8,
        ),
        const SizedBox(height: 8),
        Text(
          controller.uploadStatus.value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: WebTheme.primaryGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmittingState() {
    return const Center(
      child: Column(
        children: [
          CircularProgressIndicator(color: WebTheme.primaryGreen),
          SizedBox(height: 12),
          Text(
            'Finalizing submission...',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (controller.selectedFiles.isEmpty)
          _buildPrimaryButton(
            onPressed: controller.pickFiles,
            icon: Icons.add_circle_outline,
            label: 'Select Files',
          )
        else ...[
          _buildPrimaryButton(
            onPressed: onUploadComplete,
            icon: Icons.send_outlined,
            label: label,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: controller.pickFiles,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add More Files'),
            style: TextButton.styleFrom(foregroundColor: WebTheme.primaryGreen),
          ),
        ],
      ],
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: WebTheme.primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
