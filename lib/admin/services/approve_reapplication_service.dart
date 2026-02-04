import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ApproveReapplicationService {
  /// Approve the instructor's reapplication
  Future<void> approveReapplication(
    BuildContext context,
    String instructorId,
    String instructorName,
    String requestId,
  ) async {
    try {
      // Update instructor status to Approved
      await FirebaseFirestore.instance
          .collection('instructors')
          .doc(instructorId)
          .update({
            'isVerified': true,
            'isActive': true,
            'status': 'Approved',
            'verifiedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Update request status to Approved
      await FirebaseFirestore.instance
          .collection('reapplication_requests')
          .doc(requestId)
          .update({
            'status': 'Approved',
            'approvedAt': FieldValue.serverTimestamp(),
          });

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$instructorName has been approved successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve reapplication: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
