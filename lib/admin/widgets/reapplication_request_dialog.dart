import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:greenquest/admin/services/approve_reapplication_service.dart';
import 'package:intl/intl.dart';

/// Dialog to display reapplication requests for a rejected instructor
class ReapplicationRequestDialog extends StatelessWidget {
  final String instructorId;
  final String instructorName;
  final ApproveReapplicationService approveReapplicationService =
      ApproveReapplicationService();

  ReapplicationRequestDialog({
    super.key,
    required this.instructorId,
    required this.instructorName,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.message_outlined,
                    color: Colors.blue.shade700,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reapplication Requests',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        instructorName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  color: Colors.black45,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Requests list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('reapplication_requests')
                        .where('instructorId', isEqualTo: instructorId)
                        .orderBy('submittedAt', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF34A853),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading requests: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No reapplication requests',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final statement =
                          data['statement'] ?? 'No statement provided';
                      final submittedAt = data['submittedAt'] as Timestamp?;
                      final requestStatus = data['status'] ?? 'Pending Review';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with date and status
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    submittedAt != null
                                        ? DateFormat(
                                          'MMM dd, yyyy - hh:mm a',
                                        ).format(submittedAt.toDate())
                                        : 'Unknown date',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                        requestStatus,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _getStatusColor(
                                          requestStatus,
                                        ).withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      requestStatus,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _getStatusColor(requestStatus),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Statement
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  statement,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Approve button (only for pending requests)
                              if (requestStatus.toLowerCase() ==
                                  'pending review')
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        () => _showApproveConfirmation(
                                          context,
                                          instructorId,
                                          data['instructorName'] ??
                                              'Instructor',
                                          doc.id,
                                        ),
                                    icon: const Icon(
                                      Icons.check_circle,
                                      size: 18,
                                    ),
                                    label: const Text('Approve Reapplication'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF34A853),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show confirmation dialog before approving reapplication
  void _showApproveConfirmation(
    BuildContext context,
    String instructorId,
    String instructorName,
    String requestId,
  ) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Approve Reapplication',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Are you sure you want to approve "$instructorName"\'s reapplication? Their account status will be changed to Approved.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 15),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text(
                      'Approve',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black54,
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ).then((shouldApprove) {
      if (shouldApprove == true) {
        // _approveReapplication(context, instructorId, instructorName, requestId);
        approveReapplicationService.approveReapplication(
          context,
          instructorId,
          instructorName,
          requestId,
        );
      }
    });
  }

  /// Approve the instructor's reapplication
  // Future<void> _approveReapplication(
  //   BuildContext context,
  //   String instructorId,
  //   String instructorName,
  //   String requestId,
  // ) async {
  //   try {
  //     // Update instructor status to Approved
  //     await FirebaseFirestore.instance
  //         .collection('instructors')
  //         .doc(instructorId)
  //         .update({
  //           'isVerified': true,
  //           'isActive': true,
  //           'status': 'Approved',
  //           'verifiedAt': FieldValue.serverTimestamp(),
  //           'updatedAt': FieldValue.serverTimestamp(),
  //         });

  //     // Update request status to Approved
  //     await FirebaseFirestore.instance
  //         .collection('reapplication_requests')
  //         .doc(requestId)
  //         .update({
  //           'status': 'Approved',
  //           'approvedAt': FieldValue.serverTimestamp(),
  //         });

  //     // Show success message
  //     if (context.mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('$instructorName has been approved successfully!'),
  //           backgroundColor: Colors.green,
  //           behavior: SnackBarBehavior.floating,
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     // Show error message
  //     if (context.mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Failed to approve reapplication: $e'),
  //           backgroundColor: Colors.red,
  //           behavior: SnackBarBehavior.floating,
  //         ),
  //       );
  //     }
  //   }
  // }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending review':
      default:
        return Colors.orange;
    }
  }
}
