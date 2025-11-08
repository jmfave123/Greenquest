import 'package:flutter/material.dart';

// Success Snackbar
void showSuccessSnackBar(
  BuildContext context, {
  required String message,
  Duration duration = const Duration(seconds: 3),
  SnackBarBehavior behavior = SnackBarBehavior.floating,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.green,
      duration: duration,
      behavior: behavior,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
      elevation: 6,
    ),
  );
}

// Error Snackbar
void showErrorSnackBar(
  BuildContext context, {
  required String message,
  Duration duration = const Duration(seconds: 4),
  SnackBarBehavior behavior = SnackBarBehavior.floating,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.red,
      duration: duration,
      behavior: behavior,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
      elevation: 6,
      dismissDirection: DismissDirection.endToStart,
      action: SnackBarAction(
        label: 'Dismiss',
        textColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    ),
  );
}

// Warning Snackbar
void showWarningSnackBar(
  BuildContext context, {
  required String message,
  Duration duration = const Duration(seconds: 3),
  SnackBarBehavior behavior = SnackBarBehavior.floating,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.orange,
      duration: duration,
      behavior: behavior,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
      elevation: 6,
    ),
  );
}

// Info Snackbar
void showInfoSnackBar(
  BuildContext context, {
  required String message,
  Duration duration = const Duration(seconds: 3),
  SnackBarBehavior behavior = SnackBarBehavior.floating,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.blue,
      duration: duration,
      behavior: behavior,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
      elevation: 6,
    ),
  );
}

// Custom Snackbar with custom color
void showCustomSnackBar(
  BuildContext context, {
  required String message,
  required Color backgroundColor,
  IconData? icon,
  Duration duration = const Duration(seconds: 3),
  SnackBarBehavior behavior = SnackBarBehavior.floating,
  SnackBarAction? action,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      duration: duration,
      behavior: behavior,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
      elevation: 6,
      action: action,
    ),
  );
}

// Loading Snackbar
void showLoadingSnackBar(
  BuildContext context, {
  required String message,
  SnackBarBehavior behavior = SnackBarBehavior.floating,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey[700],
      duration: const Duration(days: 365), // Long duration for loading
      behavior: behavior,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
      elevation: 6,
    ),
  );
}

// Hide current snackbar
void hideSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
}

// Clear all snackbars
void clearSnackBars(BuildContext context) {
  ScaffoldMessenger.of(context).clearSnackBars();
}

// Success Snackbar with action button
void showSuccessSnackBarWithAction(
  BuildContext context, {
  required String message,
  required String actionLabel,
  required VoidCallback onActionPressed,
  Duration duration = const Duration(seconds: 5),
  SnackBarBehavior behavior = SnackBarBehavior.floating,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.green,
      duration: duration,
      behavior: behavior,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
      elevation: 6,
      action: SnackBarAction(
        label: actionLabel,
        textColor: Colors.white,
        onPressed: onActionPressed,
      ),
    ),
  );
}

// Error Snackbar with retry action
void showErrorSnackBarWithRetry(
  BuildContext context, {
  required String message,
  required VoidCallback onRetry,
  Duration duration = const Duration(seconds: 5),
  SnackBarBehavior behavior = SnackBarBehavior.floating,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.red,
      duration: duration,
      behavior: behavior,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
      elevation: 6,
      action: SnackBarAction(
        label: 'Retry',
        textColor: Colors.white,
        onPressed: onRetry,
      ),
    ),
  );
}
