import 'package:flutter/material.dart';

/// Card widget for displaying students who haven't submitted
class NotSubmittedCard extends StatelessWidget {
  final Map<String, dynamic> student;

  const NotSubmittedCard({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final studentName = student['studentName'] ?? 'Unknown Student';
    final studentId =
        student['idNumber'] ??
        student['studentIdNumber'] ??
        student['studentId'] ??
        'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Student Avatar - Greyed out
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey.shade300,
            child: Text(
              studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
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
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '($studentId)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'No submission yet',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          // Not Submitted Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cancel_outlined,
                  size: 16,
                  color: Colors.red.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  'Not Submitted',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
