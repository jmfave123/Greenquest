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
              final screenWidth = MediaQuery.of(context).size.width;
              final horizontalInset = screenWidth < 600 ? 8.0 : 24.0;
              final verticalInset = screenWidth < 600 ? 8.0 : 16.0;

              return Dialog(
                backgroundColor: Colors.white,
                insetPadding: EdgeInsets.symmetric(
                  horizontal: horizontalInset,
                  vertical: verticalInset,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
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
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            const basePreviewWidth = 920.0;
                            const ultraNarrowBreakpoint = 320.0;

                            // Fallback: for extremely narrow viewports, keep horizontal pan.
                            if (constraints.maxWidth < ultraNarrowBreakpoint) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SizedBox(
                                  width: basePreviewWidth,
                                  child: SingleChildScrollView(
                                    child: NstpFormWidget(data: formData),
                                  ),
                                ),
                              );
                            }

                            // Phase 2: keep web arrangement but scale down on phones.
                            if (constraints.maxWidth < basePreviewWidth) {
                              return SingleChildScrollView(
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: SizedBox(
                                    width: constraints.maxWidth,
                                    child: FittedBox(
                                      fit: BoxFit.fitWidth,
                                      alignment: Alignment.topCenter,
                                      child: SizedBox(
                                        width: basePreviewWidth,
                                        child: NstpFormWidget(data: formData),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }

                            return SingleChildScrollView(
                              child: SizedBox(
                                width: constraints.maxWidth,
                                child: NstpFormWidget(data: formData),
                              ),
                            );
                          },
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
