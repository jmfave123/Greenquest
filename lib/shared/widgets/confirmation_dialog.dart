import 'package:flutter/material.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? warningMessage;
  final String confirmText;
  final String cancelText;
  final IconData icon;
  final Color iconColor;
  final Color confirmButtonColor;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.warningMessage,
    this.confirmText = 'Delete',
    this.cancelText = 'Cancel',
    this.icon = Icons.warning,
    this.iconColor = Colors.red,
    this.confirmButtonColor = Colors.red,
    required this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Message
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 15),
          ),

          // Warning message (optional)
          if (warningMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              warningMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Action buttons
          Row(
            children: [
              // Cancel button
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onCancel?.call();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: Text(cancelText),
                ),
              ),
              const SizedBox(width: 12),

              // Confirm button
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onConfirm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmButtonColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: Text(confirmText),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Show a confirmation dialog for deleting a department
  static Future<bool?> showDeleteDepartmentDialog(
    BuildContext context, {
    required String departmentName,
    required VoidCallback onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => ConfirmationDialog(
            title: 'Delete Department',
            message: 'Are you sure you want to delete "$departmentName"?',
            warningMessage:
                'This will also delete all sections under this department. This action cannot be undone.',
            icon: Icons.business_outlined,
            iconColor: Colors.red,
            onConfirm: onConfirm,
          ),
    );
  }

  /// Show a confirmation dialog for deleting a section
  static Future<bool?> showDeleteSectionDialog(
    BuildContext context, {
    required String sectionCode,
    required VoidCallback onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => ConfirmationDialog(
            title: 'Delete Section',
            message: 'Are you sure you want to delete section "$sectionCode"?',
            warningMessage: 'This action cannot be undone.',
            icon: Icons.class_outlined,
            iconColor: Colors.red,
            onConfirm: onConfirm,
          ),
    );
  }

  /// Show a confirmation dialog for deleting a semester
  static Future<bool?> showDeleteSemesterDialog(
    BuildContext context, {
    required String semesterName,
    required VoidCallback onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => ConfirmationDialog(
            title: 'Delete Semester',
            message: 'Are you sure you want to delete "$semesterName"?',
            warningMessage: 'This action cannot be undone.',
            icon: Icons.calendar_today_outlined,
            iconColor: Colors.red,
            onConfirm: onConfirm,
          ),
    );
  }
}
