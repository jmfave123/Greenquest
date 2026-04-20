import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../services/file_upload_service.dart';

import '../../student_web_version/config/web_theme.dart';
import '../../student_web_version/helpers/tree_submission_edit_helper.dart';

class TreeSubmissionEditDialog extends StatefulWidget {
  final Map<String, dynamic> submission;

  const TreeSubmissionEditDialog({super.key, required this.submission});

  static Future<TreeSubmissionEditData?> show({
    required BuildContext context,
    required Map<String, dynamic> submission,
  }) {
    return showDialog<TreeSubmissionEditData>(
      context: context,
      builder: (_) => TreeSubmissionEditDialog(submission: submission),
    );
  }

  @override
  State<TreeSubmissionEditDialog> createState() =>
      _TreeSubmissionEditDialogState();
}

class _TreeSubmissionEditDialogState extends State<TreeSubmissionEditDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _quantityController;
  late final TextEditingController _locationController;
  late final List<TextEditingController> _treeNameControllers;
  late DateTime _selectedDate;
  late List<Map<String, dynamic>> _retainedFiles;
  final List<PlatformFile> _newFiles = <PlatformFile>[];
  bool _isPickingFiles = false;

  @override
  void initState() {
    super.initState();

    final quantity = (widget.submission['quantity'] ?? 0).toString();
    final location = (widget.submission['location'] ?? '').toString();
    final treeNames = TreeSubmissionEditHelper.extractTreeNames(
      widget.submission,
    );

    _selectedDate = TreeSubmissionEditHelper.resolvePlantDate(
      widget.submission['plantDate'],
    );

    _quantityController = TextEditingController(text: quantity);
    _locationController = TextEditingController(text: location);

    _treeNameControllers = List.generate(
      TreeSubmissionEditHelper.maxTreeNameFields,
      (index) => TextEditingController(
        text: index < treeNames.length ? treeNames[index] : '',
      ),
    );

    _retainedFiles = TreeSubmissionEditHelper.extractAttachedFiles(
      widget.submission,
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _locationController.dispose();
    for (final controller in _treeNameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickPhotos() async {
    final remaining = TreeSubmissionEditHelper.remainingAttachmentSlots(
      retainedCount: _retainedFiles.length,
      newCount: _newFiles.length,
    );

    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Maximum of ${TreeSubmissionEditHelper.maxAttachmentFiles} photos reached.',
          ),
        ),
      );
      return;
    }

    setState(() => _isPickingFiles = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
        allowMultiple: true,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final picked = result.files.take(remaining).toList();
      final truncated = result.files.length > remaining;

      setState(() {
        _newFiles.addAll(picked);
      });

      if (truncated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Only $remaining photo(s) were added due to the limit.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingFiles = false);
      }
    }
  }

  void _removeRetainedFile(int index) {
    setState(() {
      _retainedFiles.removeAt(index);
    });
  }

  void _removeNewFile(int index) {
    setState(() {
      _newFiles.removeAt(index);
    });
  }

  void _save() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final quantity = int.parse(_quantityController.text.trim());
    final location = _locationController.text.trim();
    final treeNames =
        _treeNameControllers
            .map((controller) => controller.text.trim())
            .where((name) => name.isNotEmpty)
            .toList();

    final fileValidation = TreeSubmissionEditHelper.validateAttachmentCount(
      retainedCount: _retainedFiles.length,
      newCount: _newFiles.length,
    );
    if (fileValidation != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(fileValidation)));
      return;
    }

    Navigator.of(context).pop(
      TreeSubmissionEditData(
        quantity: quantity,
        plantDate: _selectedDate,
        location: location,
        treeNames: treeNames,
        retainedFiles: _retainedFiles,
        newFiles: List<PlatformFile>.from(_newFiles),
      ),
    );
  }

  Widget _buildFilePreview(String? url, String extension) {
    final isImage =
        extension == 'jpg' ||
        extension == 'jpeg' ||
        extension == 'png' ||
        extension == 'webp';

    if (isImage && url != null && url.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.broken_image_outlined, size: 20),
            );
          },
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        FileUploadService.getFileIcon(extension),
        color: FileUploadService.getFileColor(extension),
      ),
    );
  }

  Widget _buildNewFilePreview(PlatformFile file) {
    final extension = (file.extension ?? '').toLowerCase();
    final isImage =
        extension == 'jpg' ||
        extension == 'jpeg' ||
        extension == 'png' ||
        extension == 'webp';

    if (isImage && file.bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          file.bytes!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.broken_image_outlined, size: 20),
            );
          },
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        FileUploadService.getFileIcon(extension),
        color: FileUploadService.getFileColor(extension),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = (screenSize.width * 0.92).clamp(360.0, 720.0);
    final dialogMaxHeight = (screenSize.height * 0.82).clamp(420.0, 860.0);
    const primary = WebTheme.primaryGreen;
    const primaryDark = WebTheme.primaryGreenDark;
    final primarySoft = WebTheme.hoverGreen;
    final primaryBorder = WebTheme.primaryGreen.withOpacity(0.35);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: primarySoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: primary.withOpacity(0.2)),
            ),
            child: Icon(Icons.edit_note, size: 20, color: primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Tree Submission',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Update details and photo proof',
                  style: TextStyle(
                    fontSize: 12,
                    color: WebTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 340,
          maxWidth: dialogWidth,
          maxHeight: dialogMaxHeight,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Number of Trees',
                  ),
                  validator:
                      (value) => TreeSubmissionEditHelper.validateQuantity(
                        value ?? '',
                      ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Planting Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('MMMM dd, yyyy').format(_selectedDate)),
                        const Icon(Icons.calendar_today_outlined, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                  validator:
                      (value) => TreeSubmissionEditHelper.validateLocation(
                        value ?? '',
                      ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tree Names (Optional)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...List.generate(TreeSubmissionEditHelper.maxTreeNameFields, (
                  index,
                ) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextFormField(
                      controller: _treeNameControllers[index],
                      decoration: InputDecoration(
                        labelText: 'Tree ${index + 1}',
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Photo Evidence (Max 5)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '${_retainedFiles.length + _newFiles.length}/${TreeSubmissionEditHelper.maxAttachmentFiles}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: WebTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isPickingFiles ? null : _pickPhotos,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryDark,
                        side: BorderSide(color: primaryBorder, width: 1.2),
                        backgroundColor: primarySoft,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon:
                          _isPickingFiles
                              ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Add Photos'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_retainedFiles.isEmpty && _newFiles.isEmpty)
                  const Text(
                    'No photos attached. Add at least one photo before saving.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                if (_retainedFiles.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Current Photos',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  ...List.generate(_retainedFiles.length, (index) {
                    final file = _retainedFiles[index];
                    final name = (file['name'] ?? 'Attachment').toString();
                    final url = (file['url'] ?? '').toString();
                    final extension = (file['type'] ?? '')
                        .toString()
                        .toLowerCase()
                        .replaceFirst('.', '');
                    final size = (file['size'] as int?) ?? 0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            _buildFilePreview(url, extension),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    size > 0
                                        ? FileUploadService().formatFileSize(
                                          size,
                                        )
                                        : 'Existing file',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remove photo',
                              onPressed: () => _removeRetainedFile(index),
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
                if (_newFiles.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'New Photos To Upload',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  ...List.generate(_newFiles.length, (index) {
                    final file = _newFiles[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            _buildNewFilePreview(file),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    file.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    FileUploadService().formatFileSize(
                                      file.size,
                                    ),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remove photo',
                              onPressed: () => _removeNewFile(index),
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: primaryDark,
            backgroundColor: primarySoft,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: WebTheme.borderMedium),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: primary.withOpacity(0.45),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: _save,
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: const Text(
            'Save Changes',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
