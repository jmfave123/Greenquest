import 'package:flutter/material.dart';
import '../helpers/submission_status_helper.dart';

/// Card widget for displaying a student's submission
class SubmissionCard extends StatelessWidget {
  final Map<String, dynamic> submission;
  final Map<String, dynamic> activityData;
  final VoidCallback onTap;
  final String Function(dynamic) formatDate;

  const SubmissionCard({
    super.key,
    required this.submission,
    required this.activityData,
    required this.onTap,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final files = submission['files'] as List<dynamic>? ?? [];
    final submittedAt = submission['submittedAt'];
    final studentName = submission['studentName'] ?? 'Unknown Student';
    final studentId =
        submission['idNumber'] ??
        submission['studentIdNumber'] ??
        submission['studentId'] ??
        'N/A';
    final status = submission['status'] ?? 'submitted';
    final grade = submission['grade'];
    final maxScore = activityData['points'] ?? 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Student Avatar
            CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFF34A853).withOpacity(0.1),
              child: Text(
                studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF34A853),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Student Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        studentName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '($studentId)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: SubmissionStatusHelper.getTypeColor(
                            submission['type'] ?? 'activity',
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          SubmissionStatusHelper.getTypeLabel(
                            submission['type'] ?? 'activity',
                          ),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: SubmissionStatusHelper.getTypeColor(
                              submission['type'] ?? 'activity',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Submitted: ${formatDate(submittedAt)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.attach_file,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${files.length} file(s)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Status and Score
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: SubmissionStatusHelper.getStatusColor(
                      status,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        SubmissionStatusHelper.getStatusIcon(status),
                        size: 12,
                        color: SubmissionStatusHelper.getStatusColor(status),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: SubmissionStatusHelper.getStatusColor(status),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (grade != null)
                  Text(
                    '$grade/$maxScore',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  )
                else
                  const Text(
                    'Not graded',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),

            const SizedBox(width: 16),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
