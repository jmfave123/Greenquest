import 'package:flutter/material.dart';

import '../../instructor/planted_trees/nstp_form_widget.dart';

/// Reusable preview dialog for NSTP monitoring form exports.
class NstpExportPreviewDialog {
  const NstpExportPreviewDialog._();

  /// Shows a preview-first NSTP form dialog with an Export PDF action.
  static Future<void> show({
    required BuildContext context,
    required Map<String, dynamic> formData,
    required Future<void> Function() onExport,
    bool canExport = true,
    String? exportDisabledMessage,
  }) async {
    var isExporting = false;

    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                backgroundColor: Colors.white,
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        color: const Color(0xFF1A237E),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'NSTP Monitoring Form Preview',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed:
                                  (!canExport || isExporting)
                                      ? null
                                      : () async {
                                        try {
                                          setState(() => isExporting = true);
                                          await onExport();
                                        } catch (_) {
                                          if (!dialogContext.mounted) return;
                                          ScaffoldMessenger.of(
                                            dialogContext,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Failed to export PDF.',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        } finally {
                                          if (dialogContext.mounted) {
                                            setState(() => isExporting = false);
                                          }
                                        }
                                      },
                              icon:
                                  !canExport
                                      ? const Icon(
                                        Icons.lock_outline,
                                        color: Colors.white,
                                        size: 18,
                                      )
                                      : isExporting
                                      ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                      : const Icon(
                                        Icons.picture_as_pdf,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                              label: Text(
                                !canExport
                                    ? 'Export Locked'
                                    : (isExporting
                                        ? 'Exporting...'
                                        : 'Export PDF'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(
                                  canExport ? 0.15 : 0.09,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed:
                                  isExporting
                                      ? null
                                      : () => Navigator.of(dialogContext).pop(),
                            ),
                          ],
                        ),
                      ),
                      if (!canExport)
                        Container(
                          width: double.infinity,
                          color: const Color(0xFFFFF3CD),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            exportDisabledMessage ??
                                'Export is available after instructor approval.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7A5B00),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      Flexible(
                        child: SingleChildScrollView(
                          child: NstpFormWidget(data: formData),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }
}
