import 'package:flutter/material.dart';

/// Reusable Excel Export Preview Dialog
/// Shows a preview of data before exporting to Excel
class ExcelExportPreviewDialog extends StatelessWidget {
  final String title;
  final String fileName;
  final Widget previewContent; // The actual data preview (table, etc.)
  final List<ExcelExportOption> exportOptions;
  final VoidCallback onExport;
  final VoidCallback? onCancel;
  final String? summaryText; // Optional summary information

  const ExcelExportPreviewDialog({
    super.key,
    required this.title,
    required this.fileName,
    required this.previewContent,
    this.exportOptions = const [],
    required this.onExport,
    this.onCancel,
    this.summaryText,
  });

  /// Show the Excel export preview dialog
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String fileName,
    required Widget previewContent,
    List<ExcelExportOption> exportOptions = const [],
    required VoidCallback onExport,
    VoidCallback? onCancel,
    String? summaryText,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => ExcelExportPreviewDialog(
            title: title,
            fileName: fileName,
            previewContent: previewContent,
            exportOptions: exportOptions,
            onExport: onExport,
            onCancel: onCancel,
            summaryText: summaryText,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200, maxHeight: 800),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            // Content area with preview and options
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side: Preview content
                  Expanded(flex: 3, child: _buildPreviewSection(context)),
                  // Right side: Export options
                  Container(
                    width: 300,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: _buildExportOptionsSection(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          const Icon(Icons.table_chart, color: Color(0xFF34A853), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                if (summaryText != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    summaryText!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).pop(false);
              onCancel?.call();
            },
            icon: const Icon(Icons.close),
            color: Colors.grey[600],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview label
          Row(
            children: [
              Icon(Icons.preview, size: 18, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                'Preview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Preview content (scrollable)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: previewContent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOptionsSection(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Export title
              const Text(
                'Export',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Export options - Scrollable if needed
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (exportOptions.isEmpty)
                        _buildDefaultExportOptions(context)
                      else
                        ...exportOptions.map(
                          (option) => _buildExportOption(
                            context,
                            option.label,
                            option.value,
                            option.onChanged,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // File name display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.insert_drive_file,
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fileName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Action buttons - Fixed at bottom and responsive
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                          onCancel?.call();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: constraints.maxWidth < 250 ? 10 : 12,
                            horizontal: 8,
                          ),
                          minimumSize: const Size(0, 44),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                          onExport();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF34A853),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: constraints.maxWidth < 250 ? 10 : 12,
                            horizontal: 8,
                          ),
                          minimumSize: const Size(0, 44),
                        ),
                        child: const Text(
                          'Export',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDefaultExportOptions(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildExportOption(context, 'Destination', 'Export as Excel', null),
        const SizedBox(height: 12),
        _buildExportOption(context, 'Data Range', 'All Data', null),
        const SizedBox(height: 12),
        _buildExportOption(context, 'Format', 'Excel (.xlsx)', null),
      ],
    );
  }

  Widget _buildExportOption(
    BuildContext context,
    String label,
    String value,
    ValueChanged<String>? onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              if (onChanged != null)
                Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
            ],
          ),
        ),
      ],
    );
  }
}

/// Export option configuration
class ExcelExportOption {
  final String label;
  final String value;
  final ValueChanged<String>? onChanged;

  const ExcelExportOption({
    required this.label,
    required this.value,
    this.onChanged,
  });
}
