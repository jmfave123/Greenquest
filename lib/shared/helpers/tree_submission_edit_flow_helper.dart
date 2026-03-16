import 'package:flutter/material.dart';

import '../../student_web_version/helpers/tree_submission_edit_helper.dart';
import '../services/tree_submission_export_service.dart';
import '../widgets/tree_submission_edit_dialog.dart';

/// Result status for the shared tree submission edit flow.
enum TreeSubmissionEditFlowStatus {
  cancelled,
  accessDenied,
  notEditable,
  updateFailed,
  updated,
}

/// Structured result used by mobile/web screens for consistent handling.
class TreeSubmissionEditFlowResult {
  final TreeSubmissionEditFlowStatus status;
  final String submissionId;
  final String originalStatus;

  const TreeSubmissionEditFlowResult({
    required this.status,
    required this.submissionId,
    required this.originalStatus,
  });

  bool get isUpdated => status == TreeSubmissionEditFlowStatus.updated;
}

class TreeSubmissionEditFlowHelper {
  const TreeSubmissionEditFlowHelper._();

  /// Validates edit access, opens the shared edit dialog, and performs update.
  static Future<TreeSubmissionEditFlowResult> run({
    required BuildContext context,
    required Map<String, dynamic> submission,
    required Future<bool> Function(
      TreeSubmissionEditData editData,
      String submissionId,
    )
    onUpdate,
    String? currentUserId,
    bool enforceOwnership = false,
    Future<void> Function(String submissionId)? onUpdateStart,
    Future<void> Function(String submissionId)? onUpdateEnd,
  }) async {
    final submissionId = (submission['id'] ?? '').toString();
    final status = (submission['status'] ?? 'submitted').toString();

    if (enforceOwnership) {
      final hasUserId =
          currentUserId != null && currentUserId.trim().isNotEmpty;
      if (!hasUserId) {
        return TreeSubmissionEditFlowResult(
          status: TreeSubmissionEditFlowStatus.accessDenied,
          submissionId: submissionId,
          originalStatus: status,
        );
      }

      final isOwner = TreeSubmissionExportService.isOwnedByUser(
        submission: submission,
        userId: currentUserId!.trim(),
      );
      if (!isOwner) {
        return TreeSubmissionEditFlowResult(
          status: TreeSubmissionEditFlowStatus.accessDenied,
          submissionId: submissionId,
          originalStatus: status,
        );
      }
    }

    if (!TreeSubmissionEditHelper.isEditableStatus(status)) {
      return TreeSubmissionEditFlowResult(
        status: TreeSubmissionEditFlowStatus.notEditable,
        submissionId: submissionId,
        originalStatus: status,
      );
    }

    final editData = await TreeSubmissionEditDialog.show(
      context: context,
      submission: submission,
    );

    if (editData == null) {
      return TreeSubmissionEditFlowResult(
        status: TreeSubmissionEditFlowStatus.cancelled,
        submissionId: submissionId,
        originalStatus: status,
      );
    }

    await onUpdateStart?.call(submissionId);
    try {
      final success = await onUpdate(editData, submissionId);
      return TreeSubmissionEditFlowResult(
        status:
            success
                ? TreeSubmissionEditFlowStatus.updated
                : TreeSubmissionEditFlowStatus.updateFailed,
        submissionId: submissionId,
        originalStatus: status,
      );
    } finally {
      await onUpdateEnd?.call(submissionId);
    }
  }
}
