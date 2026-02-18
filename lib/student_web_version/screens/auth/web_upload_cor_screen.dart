import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import '../../../user/select/select_controller.dart';
import '../../../shared/services/file_upload_service.dart';
import '../../config/web_theme.dart';
import '../../config/web_routes.dart';
import '../../utils/web_responsive_utils.dart';
import '../../widgets/layout/web_app_bar.dart';

class WebUploadCorScreen extends StatefulWidget {
  const WebUploadCorScreen({super.key});

  @override
  State<WebUploadCorScreen> createState() => _WebUploadCorScreenState();
}

class _WebUploadCorScreenState extends State<WebUploadCorScreen> {
  final controller = Get.put(SelectController());
  final _uploadService = FileUploadService();
  PlatformFile? _selectedFile;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _uploadService.initialize();
  }

  Future<void> _pickFile() async {
    final result = await _uploadService.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _selectedFile = result.first);
    }
  }

  Future<void> _submit() async {
    if (_selectedFile == null) return;
    setState(() => _isUploading = true);
    try {
      final res = await _uploadService.uploadFile(
        file: _selectedFile!,
        folder: 'user_cors',
      );
      if (res != null) {
        await controller.completeSelectionWithCor(res.secureUrl);
        Get.offAllNamed(WebRoutes.pendingApproval);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Upload failed: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = WebResponsiveUtils.isMobile(context);
    return Scaffold(
      backgroundColor: WebTheme.backgroundLight,
      appBar: WebAppBar(
        title: 'Upload COR',
        showNotifications: false,
        showProfileDropdown: true,
        logoutOnly: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 20 : 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                _buildSummaryCard(),
                const SizedBox(height: 32),
                _buildUploadArea(),
                const SizedBox(height: 32),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ImageProvider? _getProfileImage() {
    final url = controller.selectedInstructorProfileImage.value;
    if (url.isEmpty) return null;
    if (url.startsWith('data:image/') || url.startsWith('/9j/')) {
      try {
        return MemoryImage(base64Decode(url));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(url);
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF43A047),
      const Color(0xFF2196F3),
      const Color(0xFF9C27B0),
      const Color(0xFFF57C00),
      const Color(0xFFE91E63),
      const Color(0xFF00BCD4),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0]
          .substring(0, parts[0].length > 2 ? 2 : parts[0].length)
          .toUpperCase();
    } else {
      final first = parts[0].isNotEmpty ? parts[0][0] : '';
      final last =
          parts[parts.length - 1].isNotEmpty ? parts[parts.length - 1][0] : '';
      return (first + last).toUpperCase();
    }
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WebTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Enrollment Summary', style: WebTheme.headingSmall),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: _getProfileImage(),
                backgroundColor: _getAvatarColor(
                  controller.selectedInstructorName.value,
                ),
                child:
                    _getProfileImage() == null
                        ? Text(
                          _getInitials(controller.selectedInstructorName.value),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                        : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Instructor', style: WebTheme.bodySmall),
                    Text(
                      controller.selectedInstructorName.value,
                      style: WebTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.school, color: WebTheme.primaryGreen, size: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Section', style: WebTheme.bodySmall),
                    Text(
                      controller.selectedSectionCode.value,
                      style: WebTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadArea() {
    return InkWell(
      onTap: _isUploading ? null : _pickFile,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color:
              _selectedFile != null
                  ? WebTheme.primaryGreen.withOpacity(0.05)
                  : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                _selectedFile != null
                    ? WebTheme.primaryGreen
                    : WebTheme.borderLight,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            if (_selectedFile != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => setState(() => _selectedFile = null),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      foregroundColor: Colors.red,
                    ),
                    tooltip: 'Remove file',
                  ),
                ],
              ),
            Icon(
              _selectedFile != null ? Icons.check_circle : Icons.upload_file,
              size: 64,
              color:
                  _selectedFile != null
                      ? WebTheme.primaryGreen
                      : WebTheme.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFile != null
                  ? 'COR Selected'
                  : 'Tap to Upload COR (PDF)',
              style: WebTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            if (_selectedFile != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_selectedFile!.name, style: WebTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedFile == null || _isUploading ? null : _submit,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: WebTheme.primaryGreen,
            ),
            child:
                _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                      'Submit COR',
                      style: TextStyle(color: Colors.white),
                    ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: WebTheme.primaryGreen),
          label: const Text(
            'Back',
            style: TextStyle(color: WebTheme.primaryGreen),
          ),
        ),
      ],
    );
  }
}
