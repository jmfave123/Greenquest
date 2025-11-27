# Custom Dialogs Usage Guide

This guide shows how to use the reusable `CustomDialogs` class throughout the app.

## Import

```dart
import '../../shared/widgets/custom_dialogs.dart';
```

## Available Dialogs

### 1. Confirmation Dialog

Simple yes/no confirmation with custom colors and icons.

```dart
final confirmed = await CustomDialogs.showConfirmationDialog(
  context: context,
  title: 'Delete Item',
  message: 'Are you sure you want to delete this item?',
  icon: Icons.warning,
  iconColor: Colors.orange,
  confirmText: 'Delete',
  cancelText: 'Cancel',
  confirmButtonColor: Colors.red,
);

if (confirmed) {
  // User confirmed
}
```

### 2. Approval Dialog

Approval dialog with optional feedback field.

```dart
final result = await CustomDialogs.showApprovalDialog(
  context: context,
  title: 'Approve Submission',
  message: 'Approve this student submission?',
  feedbackLabel: 'Feedback (optional)',
  feedbackHint: 'Add your feedback here...',
  confirmText: 'Approve',
  iconColor: const Color(0xFF34A853),
  confirmButtonColor: const Color(0xFF34A853),
  icon: Icons.check_circle,
);

if (result['confirmed'] == true) {
  String feedback = result['feedback'];
  // Process approval with feedback
}
```

### 3. Rejection Dialog

Rejection dialog with required reason field (validates before closing).

```dart
final result = await CustomDialogs.showRejectionDialog(
  context: context,
  title: 'Reject Submission',
  message: 'Are you sure you want to reject this submission?',
  reasonLabel: 'Reason for rejection (required)',
  reasonHint: 'Explain why this is being rejected...',
  confirmText: 'Reject',
  iconColor: Colors.red,
  confirmButtonColor: Colors.red,
  icon: Icons.cancel,
  errorMessage: 'Please provide a reason for rejection',
);

if (result['confirmed'] == true) {
  String reason = result['feedback'];
  // Process rejection with reason
}
```

### 4. Delete Dialog

Pre-configured delete confirmation dialog.

```dart
final confirmed = await CustomDialogs.showDeleteDialog(
  context: context,
  title: 'Delete Announcement',
  itemName: 'Important Notice',
  message: 'This action cannot be undone.', // Optional custom message
);

if (confirmed) {
  // Delete the item
}
```

### 5. Input Dialog

Dialog with a single input field and validation.

```dart
final result = await CustomDialogs.showInputDialog(
  context: context,
  title: 'Add Tree',
  label: 'Quantity',
  hint: 'Enter number of trees',
  icon: Icons.eco,
  iconColor: const Color(0xFF34A853),
  confirmText: 'Add',
  keyboardType: TextInputType.number,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a quantity';
    }
    final quantity = int.tryParse(value);
    if (quantity == null || quantity <= 0) {
      return 'Please enter a valid number';
    }
    return null; // No error
  },
);

if (result != null) {
  // User entered: result
}
```

### 6. Loading Dialog

Non-dismissible loading dialog.

```dart
// Show loading
CustomDialogs.showLoadingDialog(
  context: context,
  message: 'Uploading files...',
);

// Do async work...
await uploadFiles();

// Close loading
Navigator.of(context).pop();
```

### 7. Info Dialog

Information dialog with custom icon and color.

```dart
await CustomDialogs.showInfoDialog(
  context: context,
  title: 'Success',
  message: 'Your submission has been recorded successfully!',
  icon: Icons.check_circle_outline,
  iconColor: const Color(0xFF34A853),
);
```

## Real-World Examples

### Example 1: Tree Planting Approval (from class_detail_screen.dart)

```dart
Future<void> _approveTreeSubmission(Map<String, dynamic> submission) async {
  final result = await CustomDialogs.showApprovalDialog(
    context: context,
    title: 'Approve Tree Planting',
    message:
        'Are you sure you want to approve ${submission['quantity']} tree(s) planted by ${submission['studentName']}?',
    feedbackLabel: 'Feedback (optional)',
    feedbackHint: 'Add your feedback here...',
    confirmText: 'Approve',
    iconColor: const Color(0xFF34A853),
    confirmButtonColor: const Color(0xFF34A853),
    icon: Icons.check_circle,
  );

  if (result['confirmed'] == true) {
    try {
      await FirebaseFirestore.instance
          .collection('submissions')
          .doc(submission['id'])
          .update({
            'status': 'approved',
            'feedback': result['feedback'].isEmpty ? null : result['feedback'],
            'gradedAt': FieldValue.serverTimestamp(),
          });

      Get.snackbar(
        'Success',
        'Tree planting approved',
        backgroundColor: const Color(0xFF34A853),
        colorText: Colors.white,
      );

      setState(() {});
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to approve: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
```

### Example 2: Student Enrollment Rejection

```dart
Future<void> _rejectStudent(Map<String, dynamic> student) async {
  final result = await CustomDialogs.showRejectionDialog(
    context: context,
    title: 'Reject Student Enrollment',
    message: 'Reject ${student['studentName']}\'s enrollment request?',
    reasonLabel: 'Reason (optional)',
    reasonHint: 'Provide a reason...',
    confirmText: 'Reject',
  );

  if (result['confirmed'] == true) {
    await _controller.rejectEnrollment(
      studentId: student['id'],
      reason: result['feedback'],
    );
  }
}
```

### Example 3: Delete with Confirmation

```dart
Future<void> _deleteAnnouncement(String id, String title) async {
  final confirmed = await CustomDialogs.showDeleteDialog(
    context: context,
    title: 'Delete Announcement',
    itemName: title,
  );

  if (confirmed) {
    await _controller.deleteAnnouncement(id);
  }
}
```

## Benefits

✅ **Consistent UI**: All dialogs follow the same design pattern
✅ **Less Code**: Reuse instead of copying 50+ lines of dialog code
✅ **Easier Maintenance**: Update dialog style in one place
✅ **Type Safety**: Structured return values with Maps
✅ **Validation**: Built-in validation for input and rejection dialogs
✅ **Customizable**: Many parameters to customize appearance

## Color Scheme

The dialogs use your app's color scheme:
- **Green** (`0xFF34A853`): Approvals, success actions
- **Red**: Rejections, deletions, errors
- **Orange**: Warnings
- **Grey**: Cancel/neutral actions
