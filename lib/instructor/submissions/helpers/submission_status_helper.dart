import 'package:flutter/material.dart';

class SubmissionStatusHelper {
  static Color getStatusColor(String status) {
    switch (status) {
      case 'submitted':
        return Colors.blue;
      case 'graded':
        return Colors.green;
      case 'late':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static IconData getStatusIcon(String status) {
    switch (status) {
      case 'submitted':
        return Icons.upload_file;
      case 'graded':
        return Icons.check_circle;
      case 'late':
        return Icons.schedule;
      default:
        return Icons.help_outline;
    }
  }

  static Color getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'activity':
        return Colors.blue;
      case 'assignment':
        return Colors.orange;
      case 'pit':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  static String getTypeLabel(String type) {
    switch (type) {
      case 'activity':
        return 'ACTIVITY';
      case 'assignmen:t':
        return 'ASSIGNMENT';
      case 'pit':
        return 'PIT';
      default:
        return 'UNKNOWN';
    }
  }
}
