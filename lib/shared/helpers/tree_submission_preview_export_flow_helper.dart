import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/tree_submission_export_service.dart';
import '../widgets/nstp_export_preview_dialog.dart';

/// Result status for shared tree submission preview/export flow.
enum TreeSubmissionPreviewExportFlowStatus {
  accessDenied,
  previewFailed,
  opened,
}

/// Structured result used by screens to handle success and failure states.
class TreeSubmissionPreviewExportFlowResult {
  final TreeSubmissionPreviewExportFlowStatus status;
  final String submissionId;
  final bool canExport;

  const TreeSubmissionPreviewExportFlowResult({
    required this.status,
    required this.submissionId,
    required this.canExport,
  });
}

class TreeSubmissionPreviewExportFlowHelper {
  const TreeSubmissionPreviewExportFlowHelper._();

  /// Validates access, builds export payload, and opens preview dialog.
  static Future<TreeSubmissionPreviewExportFlowResult> run({
    required BuildContext context,
    required FirebaseFirestore firestore,
    required Map<String, dynamic> submission,
    required Future<void> Function(Map<String, dynamic> formData) onExport,
    String? currentUserId,
    bool enforceOwnership = false,
    Future<void> Function(String submissionId)? onPreviewStart,
    Future<void> Function(String submissionId)? onPreviewEnd,
  }) async {
    final submissionId = (submission['id'] ?? '').toString();

    if (enforceOwnership) {
      final hasUserId =
          currentUserId != null && currentUserId.trim().isNotEmpty;
      if (!hasUserId) {
        return TreeSubmissionPreviewExportFlowResult(
          status: TreeSubmissionPreviewExportFlowStatus.accessDenied,
          submissionId: submissionId,
          canExport: false,
        );
      }

      final isOwner = TreeSubmissionExportService.isOwnedByUser(
        submission: submission,
        userId: currentUserId.trim(),
      );
      if (!isOwner) {
        return TreeSubmissionPreviewExportFlowResult(
          status: TreeSubmissionPreviewExportFlowStatus.accessDenied,
          submissionId: submissionId,
          canExport: false,
        );
      }
    }

    if (submissionId.isNotEmpty) {
      await onPreviewStart?.call(submissionId);
    }

    try {
      final formData = await TreeSubmissionExportService.buildNstpExportData(
        firestore: firestore,
        submission: submission,
      );

      final status = (submission['status'] ?? 'submitted').toString();
      final canExport = status == 'approved';

      await NstpExportPreviewDialog.show(
        context: context,
        formData: formData,
        canExport: canExport,
        exportDisabledMessage:
            canExport
                ? null
                : 'This submission is still pending review. You can preview it now and export after it is approved.',
        onExport: () async {
          await onExport(formData);
        },
      );

      return TreeSubmissionPreviewExportFlowResult(
        status: TreeSubmissionPreviewExportFlowStatus.opened,
        submissionId: submissionId,
        canExport: canExport,
      );
    } catch (_) {
      return TreeSubmissionPreviewExportFlowResult(
        status: TreeSubmissionPreviewExportFlowStatus.previewFailed,
        submissionId: submissionId,
        canExport: false,
      );
    } finally {
      if (submissionId.isNotEmpty) {
        await onPreviewEnd?.call(submissionId);
      }
    }
  }
}
