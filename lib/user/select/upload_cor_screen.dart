import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:greenquest/admin/widgets/row/build_info_row.dart';
import 'package:greenquest/user/select/select_controller.dart';
import 'package:greenquest/shared/services/file_upload_service.dart';

class UploadCorScreen extends StatefulWidget {
  const UploadCorScreen({super.key});

  @override
  State<UploadCorScreen> createState() => _UploadCorScreenState();
}

class _UploadCorScreenState extends State<UploadCorScreen> {
  final SelectController controller = Get.find<SelectController>();
  final FileUploadService _fileUploadService = FileUploadService();

  PlatformFile? _selectedCorFile;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fileUploadService.initialize();
  }

  Future<void> _pickCorFile() async {
    final result = await _fileUploadService.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        _selectedCorFile = result.first;
      });
    }
  }

  Future<void> _submitEnrollment() async {
    if (_selectedCorFile == null) {
      Get.snackbar(
        'Error',
        'Please upload your Certificate of Registration (COR)',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Upload COR to Cloudinary
      final uploadResult = await _fileUploadService.uploadFile(
        file: _selectedCorFile!,
        folder: 'user_cors',
      );

      if (uploadResult != null && uploadResult.secureUrl.isNotEmpty) {
        // Complete enrollment with COR URL
        await controller.completeSelectionWithCor(uploadResult.secureUrl);

        // Navigate to pending approval screen
        Get.offAllNamed('/pending-approval');
      } else {
        Get.snackbar(
          'Error',
          'Failed to upload COR. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'An error occurred: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Upload COR',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enrollment Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enrollment Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => Column(
                      children: [
                        buildInfoRow(
                          Icons.person,
                          'Instructor',
                          controller.selectedInstructorName.value,
                          isLoading: false,
                        ),
                        const SizedBox(height: 8),
                        buildInfoRow(
                          Icons.school,
                          'Section',
                          controller.selectedSectionCode.value,
                          isLoading: false,
                        ),
                        const SizedBox(height: 8),
                        buildInfoRow(
                          Icons.person_outline,
                          'Student',
                          controller.studentName.value,
                          isLoading: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // COR Upload Section
            const Text(
              'Certificate of Registration (COR)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please upload your COR as a PDF file to complete your enrollment.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 24),

            // Upload Area
            GestureDetector(
              onTap: _isUploading ? null : _pickCorFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color:
                      _selectedCorFile != null
                          ? const Color(0xFFE8F5E8)
                          : const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        _selectedCorFile != null
                            ? const Color(0xFF43A047)
                            : const Color(0xFFE0E0E0),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _selectedCorFile != null
                          ? Icons.check_circle
                          : Icons.upload_file,
                      size: 64,
                      color:
                          _selectedCorFile != null
                              ? const Color(0xFF43A047)
                              : Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _selectedCorFile != null
                          ? 'COR Uploaded'
                          : 'Tap to Upload COR (PDF)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            _selectedCorFile != null
                                ? const Color(0xFF43A047)
                                : Colors.black87,
                      ),
                    ),
                    if (_selectedCorFile != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _selectedCorFile!.name,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (_selectedCorFile == null) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'PDF files only',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _submitEnrollment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF43A047),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  disabledBackgroundColor: Colors.grey,
                ),
                child:
                    _isUploading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Text(
                          'Submit Enrollment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),

            const SizedBox(height: 16),

            // Info Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your enrollment will be pending until your instructor approves it. You will be notified once approved.',
                      style: TextStyle(fontSize: 13, color: Colors.blue[900]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
