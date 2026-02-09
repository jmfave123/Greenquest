import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
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
    if (result != null && result.isNotEmpty)
      setState(() => _selectedFile = result.first);
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
        showProfileDropdown: false,
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
          _buildInfoRow(
            Icons.person,
            'Instructor',
            controller.selectedInstructorName.value,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            Icons.school,
            'Section',
            controller.selectedSectionCode.value,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: WebTheme.primaryGreen, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: WebTheme.bodySmall),
            Text(
              value,
              style: WebTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
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
            ),
            child:
                _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Enrollment'),
          ),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back'),
        ),
      ],
    );
  }
}
