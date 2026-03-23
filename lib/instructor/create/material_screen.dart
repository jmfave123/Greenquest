import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../shared/instructor/instructor_sidebar.dart';
import '../../shared/instructor/instructor_appbar.dart';
import '../../shared/instructor/instructor_navigation_constants.dart';
import '../../shared/controllers/file_submission_controller.dart';
import '../../shared/services/instructor_class_service.dart';
import '../../shared/widgets/skeleton_loading.dart';
import '../instructor_dashboard_controller.dart';
import 'create_controller.dart';

class MaterialScreen extends StatefulWidget {
  final bool isEdit;
  final String? itemId;
  final Map<String, dynamic>? initialData;

  const MaterialScreen({
    super.key,
    this.isEdit = false,
    this.itemId,
    this.initialData,
  });

  @override
  State<MaterialScreen> createState() => _MaterialScreenState();
}

class _MaterialScreenState extends State<MaterialScreen> {
  final CreateController _createController = Get.find<CreateController>();
  final FileSubmissionController _fileController = Get.put(
    FileSubmissionController(),
  );
  final InstructorController _instructorController = Get.put(
    InstructorController(),
  );
  InstructorNavigationItem _selectedItem = InstructorNavigationItem.create;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _showForDropdown = false;
  bool _showTitleError = false;

  List<String> _classes = [];
  final Map<String, bool> _selectedClasses = {};
  bool _isLoadingClasses = true;
  List<dynamic> _existingAttachments = [];

  void _log(Object? message) {
    if (kDebugMode) {
      debugPrint('$message');
    }
  }

  @override
  void initState() {
    super.initState();

    // Clear files when creating a new item (not editing)
    if (!widget.isEdit) {
      _fileController.clearFiles();
    }

    _loadClasses();

    // Pre-fill data if editing
    if (widget.isEdit && widget.initialData != null) {
      _log('🔄 Pre-filling material edit form');
      _log('📊 Initial data: ${widget.initialData}');
      _log('🆔 Material ID: ${widget.itemId}');

      _titleController.text = widget.initialData!['title'] ?? '';
      _descriptionController.text = widget.initialData!['description'] ?? '';

      _log('📝 Pre-filled title: ${_titleController.text}');
      _log('📝 Pre-filled description: ${_descriptionController.text}');

      // Pre-select classes
      final selectedClasses = List<String>.from(
        widget.initialData!['selectedClasses'] ?? [],
      );
      _log('📚 Pre-selected classes: $selectedClasses');
      for (String className in selectedClasses) {
        _selectedClasses[className] = true;
      }

      // Pre-load existing attachments
      final existingAttachments = List<dynamic>.from(
        widget.initialData!['attachments'] ?? [],
      );
      _log('📎 Existing attachments: $existingAttachments');

      // Store existing attachments for later use
      _existingAttachments = existingAttachments;
    }
  }

  Future<void> _loadClasses() async {
    try {
      setState(() => _isLoadingClasses = true);
      final classes = await InstructorClassService.getInstructorSectionCodes();
      setState(() {
        _classes = classes;
        _isLoadingClasses = false;
      });
    } catch (e) {
      setState(() => _isLoadingClasses = false);
      Get.snackbar(
        'Error',
        'Failed to load classes: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _handleNavigationSelect(InstructorNavigationItem item) {
    setState(() {
      _selectedItem = item;
    });
    String route = InstructorNavigationHelper.getRoute(item);
    Navigator.of(context).pushNamed(route);
  }

  void _toggleForDropdown() {
    setState(() {
      _showForDropdown = !_showForDropdown;
    });
  }

  void _toggleClassSelection(String className) {
    setState(() {
      _selectedClasses[className] = !(_selectedClasses[className] ?? false);
    });
  }

  void _removeExistingAttachment(int index) {
    _log('🗑️ Removing attachment at index $index');
    _log('📎 Before removal: $_existingAttachments');

    // Check if this would be the last attachment
    if (_existingAttachments.length == 1 &&
        _fileController.selectedFiles.isEmpty) {
      Get.snackbar(
        'Cannot Remove',
        'Material must have at least one attachment. You cannot remove the last file.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    setState(() {
      _existingAttachments.removeAt(index);
    });

    _log('🗑️ Removed existing attachment at index $index');
    _log('📎 After removal: $_existingAttachments');
    _log('📎 Remaining count: ${_existingAttachments.length}');
  }

  Future<void> _pickFilesWithValidation() async {
    try {
      await _fileController.pickFiles();

      // For create mode, show validation feedback
      if (!widget.isEdit) {
        if (_fileController.selectedFiles.isEmpty) {
          Get.snackbar(
            'No Files Selected',
            'Please select at least one file to create this material',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        } else {
          Get.snackbar(
            'Files Selected',
            '${_fileController.selectedFiles.length} file(s) selected. You can now create the material.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick files: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  String _getAttachmentDisplayName(dynamic attachment) {
    // Handle new format (file object with name and url)
    if (attachment is Map<String, dynamic>) {
      return attachment['name'] ?? 'Unknown File';
    }

    // Handle old format (just URL string)
    if (attachment is String && attachment.startsWith('http')) {
      // For Cloudinary URLs, try to extract filename from URL
      final uri = Uri.parse(attachment);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        final lastSegment = pathSegments.last;
        // If it's a random string, try to get original name from query params or use a generic name
        if (lastSegment.length > 20 && !lastSegment.contains('.')) {
          return 'Document.pdf'; // Generic name for random filenames
        }
        return lastSegment;
      }
      return 'File';
    }

    // If it's not a URL, return as is
    return attachment.toString();
  }

  Future<void> _submitMaterial() async {
    // Validate inputs
    if (_titleController.text.trim().isEmpty) {
      setState(() => _showTitleError = true);
      return;
    }

    final selectedClasses =
        _selectedClasses.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();

    if (selectedClasses.isEmpty) {
      Get.snackbar(
        'Error',
        'Please select at least one class',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Different validation for create vs edit
    if (widget.isEdit) {
      // For editing: Check if we would end up with zero attachments total
      final totalAttachments =
          _existingAttachments.length + _fileController.selectedFiles.length;
      if (totalAttachments == 0) {
        Get.snackbar(
          'Error',
          'Material must have at least one attachment. You cannot remove all files.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
    } else {
      // For creating: Check if we would end up with zero attachments total
      final totalAttachments = _fileController.selectedFiles.length;
      if (totalAttachments == 0) {
        Get.snackbar(
          'Error',
          'Material must have at least one attachment. Please select at least one file.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
    }

    // Upload files if any are selected (like other content types)
    List<dynamic> attachmentUrls = [];
    if (_fileController.selectedFiles.isNotEmpty) {
      try {
        // Show loading indicator
        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );

        // Upload files
        final uploadSuccess = await _fileController.uploadFiles(
          folder: 'greenquest/materials',
          tags: {'type': 'material'},
        );

        // Close loading dialog
        Get.back();

        if (uploadSuccess) {
          // Get uploaded file objects (with name and URL)
          attachmentUrls =
              _fileController.uploadedFiles
                  .map((file) => file) // Store the full file object
                  .toList();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload files. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      } catch (e) {
        // Close loading dialog
        Get.back();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading files: $e'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (widget.isEdit) {
      // Update existing material
      _log('🔄 Updating material with ID: ${widget.itemId}');
      _log('📝 Title: ${_titleController.text.trim()}');
      _log('📝 Description: ${_descriptionController.text.trim()}');
      _log('📝 Selected Classes: $selectedClasses');
      _log('📎 New attachments: $attachmentUrls');
      _log('📎 Existing attachments: $_existingAttachments');

      // Combine existing and new attachments
      List<dynamic> finalAttachments = [];

      // Always start with the current state of existing attachments (after any removals)
      finalAttachments = List.from(_existingAttachments);
      _log('📎 Starting with existing attachments: $finalAttachments');

      if (attachmentUrls.isNotEmpty) {
        // If new files were uploaded, add them to the existing ones
        finalAttachments.addAll(attachmentUrls);
        _log('📎 Added new attachments: $attachmentUrls');
        _log('📎 Final combined attachments: $finalAttachments');
      } else {
        _log('📎 No new attachments, keeping only existing: $finalAttachments');
      }

      _log('📎 Final attachments to save: $finalAttachments');
      _log('📎 Final attachments count: ${finalAttachments.length}');

      final success = await _createController.updateMaterial(
        itemId: widget.itemId!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        selectedClasses: selectedClasses,
        attachments: finalAttachments.isEmpty ? [] : finalAttachments,
      );

      if (success) {
        _log('✅ Material updated successfully');
        // Clear files after successful update
        _fileController.clearFiles();
        // Return true to trigger refresh in create screen
        Navigator.of(context).pop(true);
      } else {
        _log('❌ Material update failed');
      }
    } else {
      // Create new material
      try {
        final success = await _createController.createMaterial(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          selectedClasses: selectedClasses,
          attachments: attachmentUrls,
        );

        if (success) {
          // Clear files after successful creation
          _fileController.clearFiles();

          // Ensure we're still mounted before navigating
          if (!mounted) return;

          // Navigate back to create screen (item list)
          // This will trigger the .then() callback in create_screen.dart
          // which will refresh the data and show success message
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        _log('❌ Error in material creation flow: $e');
        // Show error if something went wrong
        Get.snackbar(
          'Error',
          'Failed to create material: $e',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          InstructorSidebar(
            selectedItem: _selectedItem,
            onItemSelected: _handleNavigationSelect,
          ),
          // Main Content
          Expanded(
            child: Column(
              children: [
                // App Bar
                Obx(
                  () => InstructorAppBar(
                    instructorName: _instructorController.instructorName.value,
                    instructorRole: 'Instructor',
                    profileImageUrl:
                        _instructorController.profileImageUrl.value,
                  ),
                ),
                // Main Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.isEdit
                                  ? 'Edit Material'
                                  : 'Create Material',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Form Content
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title Field
                                const Text(
                                  'Material Title *',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _titleController,
                                  decoration: InputDecoration(
                                    hintText: 'Enter material title',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color:
                                            _showTitleError
                                                ? Colors.red
                                                : Colors.grey,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF34A853),
                                        width: 2,
                                      ),
                                    ),
                                    errorText:
                                        _showTitleError
                                            ? 'Title is required'
                                            : null,
                                  ),
                                  onChanged: (value) {
                                    if (_showTitleError && value.isNotEmpty) {
                                      setState(() => _showTitleError = false);
                                    }
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Description Field
                                const Text(
                                  'Description',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _descriptionController,
                                  maxLines: 4,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Enter material description (optional)',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF34A853),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // For Dropdown
                                const Text(
                                  'For Classes *',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _toggleForDropdown,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _selectedClasses.entries
                                                    .where(
                                                      (entry) => entry.value,
                                                    )
                                                    .map((entry) => entry.key)
                                                    .join(', ')
                                                    .isEmpty
                                                ? 'Select classes'
                                                : _selectedClasses.entries
                                                    .where(
                                                      (entry) => entry.value,
                                                    )
                                                    .map((entry) => entry.key)
                                                    .join(', '),
                                            style: TextStyle(
                                              color:
                                                  _selectedClasses.entries
                                                          .where(
                                                            (entry) =>
                                                                entry.value,
                                                          )
                                                          .isEmpty
                                                      ? Colors.grey
                                                      : Colors.black,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          _showForDropdown
                                              ? Icons.keyboard_arrow_up
                                              : Icons.keyboard_arrow_down,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Class Selection Dropdown
                                if (_showForDropdown)
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child:
                                        _isLoadingClasses
                                            ? const Padding(
                                              padding: EdgeInsets.all(16),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SkeletonListItem(),
                                                  SizedBox(height: 8),
                                                  SkeletonListItem(),
                                                  SizedBox(height: 8),
                                                  SkeletonListItem(),
                                                ],
                                              ),
                                            )
                                            : Column(
                                              children:
                                                  _classes.map((className) {
                                                    return CheckboxListTile(
                                                      title: Text(className),
                                                      value:
                                                          _selectedClasses[className] ??
                                                          false,
                                                      onChanged:
                                                          (value) =>
                                                              _toggleClassSelection(
                                                                className,
                                                              ),
                                                      activeColor: const Color(
                                                        0xFF34A853,
                                                      ),
                                                    );
                                                  }).toList(),
                                            ),
                                  ),
                                const SizedBox(height: 24),

                                // File Upload Section
                                const Text(
                                  'Upload Files *',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),

                                // Show existing attachments if editing
                                if (widget.isEdit &&
                                    _existingAttachments.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.blue.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Current Attachments:',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...(_existingAttachments.asMap().entries.map((
                                          entry,
                                        ) {
                                          final index = entry.key;
                                          final attachment = entry.value;
                                          return Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 4,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: Colors.blue.withOpacity(
                                                  0.2,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.attach_file,
                                                  size: 16,
                                                  color: Colors.blue,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    _getAttachmentDisplayName(
                                                      attachment,
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed:
                                                      _existingAttachments
                                                                      .length ==
                                                                  1 &&
                                                              _fileController
                                                                  .selectedFiles
                                                                  .isEmpty
                                                          ? null // Disable if it's the last attachment
                                                          : () =>
                                                              _removeExistingAttachment(
                                                                index,
                                                              ),
                                                  icon: Icon(
                                                    Icons.remove_circle,
                                                    size: 16,
                                                    color:
                                                        _existingAttachments
                                                                        .length ==
                                                                    1 &&
                                                                _fileController
                                                                    .selectedFiles
                                                                    .isEmpty
                                                            ? Colors
                                                                .grey // Grey out if disabled
                                                            : Colors.red,
                                                  ),
                                                  constraints:
                                                      const BoxConstraints(
                                                        minWidth: 24,
                                                        minHeight: 24,
                                                      ),
                                                  padding: EdgeInsets.zero,
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList()),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Note: You can add more files or remove existing ones',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Obx(
                                  () =>
                                      _fileController.isUploading.value
                                          ? const Center(
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Color(0xFF34A853),
                                                  ),
                                            ),
                                          )
                                          : Column(
                                            children: [
                                              // Upload Button
                                              Container(
                                                width: double.infinity,
                                                height: 120,
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: Colors.grey,
                                                    style: BorderStyle.solid,
                                                    width: 2,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: InkWell(
                                                  onTap:
                                                      _pickFilesWithValidation,
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .cloud_upload_outlined,
                                                        size: 32,
                                                        color: Colors.grey[600],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        'Click to upload files',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          color:
                                                              Colors.grey[600],
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'PDF, DOC, DOCX, PPT, PPTX, Images',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.grey[500],
                                                        ),
                                                      ),
                                                      if (!widget.isEdit) ...[
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Text(
                                                          '⚠️ At least one file is required',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                Colors
                                                                    .orange[700],
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 16),

                                              // Uploaded Files List - Always visible
                                              Container(
                                                width: double.infinity,
                                                constraints:
                                                    const BoxConstraints(
                                                      maxHeight: 200,
                                                    ),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: Colors.grey[300]!,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child:
                                                    _fileController
                                                            .selectedFiles
                                                            .isEmpty
                                                        ? Container(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                20,
                                                              ),
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .folder_open,
                                                                size: 32,
                                                                color:
                                                                    Colors
                                                                        .grey[400],
                                                              ),
                                                              const SizedBox(
                                                                height: 8,
                                                              ),
                                                              Text(
                                                                'No files selected',
                                                                style: TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .grey[600],
                                                                  fontSize: 14,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        )
                                                        : ListView.builder(
                                                          shrinkWrap: true,
                                                          itemCount:
                                                              _fileController
                                                                  .selectedFiles
                                                                  .length,
                                                          itemBuilder: (
                                                            context,
                                                            index,
                                                          ) {
                                                            final file =
                                                                _fileController
                                                                    .selectedFiles[index];
                                                            return Container(
                                                              margin:
                                                                  const EdgeInsets.only(
                                                                    left: 8,
                                                                    right: 8,
                                                                    top: 4,
                                                                    bottom: 4,
                                                                  ),
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    12,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    Colors
                                                                        .grey[50],
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      6,
                                                                    ),
                                                                border: Border.all(
                                                                  color:
                                                                      Colors
                                                                          .grey[300]!,
                                                                ),
                                                              ),
                                                              child: Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .attach_file,
                                                                    color:
                                                                        Colors
                                                                            .grey[600],
                                                                    size: 20,
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 8,
                                                                  ),
                                                                  Expanded(
                                                                    child: Text(
                                                                      file.name,
                                                                      style: const TextStyle(
                                                                        fontSize:
                                                                            14,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                      ),
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                  ),
                                                                  IconButton(
                                                                    onPressed: () {
                                                                      _fileController
                                                                          .removeFile(
                                                                            index,
                                                                          );
                                                                    },
                                                                    icon: const Icon(
                                                                      Icons
                                                                          .close,
                                                                      color:
                                                                          Colors
                                                                              .red,
                                                                      size: 20,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          },
                                                        ),
                                              ),
                                            ],
                                          ),
                                ),
                                const SizedBox(height: 32),

                                // Submit Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _submitMaterial,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF34A853),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      widget.isEdit
                                          ? 'Update Material'
                                          : 'Create Material',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
