import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InstructorSelectionFooter extends StatelessWidget {
  final RxString selectedInstructorId;
  final RxString selectedInstructorName;
  final RxString studentName;
  final VoidCallback onContinue;
  final bool isWeb;

  const InstructorSelectionFooter({
    super.key,
    required this.selectedInstructorId,
    required this.selectedInstructorName,
    required this.studentName,
    required this.onContinue,
    this.isWeb = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Show instructor info if selected
        Obx(() {
          if (selectedInstructorId.value.isNotEmpty) {
            return Container(
              margin: EdgeInsets.only(
                top: isWeb ? 0 : 20,
                bottom: 10,
                left: isWeb ? 0 : 20,
                right: isWeb ? 0 : 20,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Color(0xFF34A853), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected: ${selectedInstructorName.value}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          studentName.value.isNotEmpty
                              ? 'Student: ${studentName.value}'
                              : 'Tap to continue to course selection',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }),

        // Continue button
        const SizedBox(height: 10),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isWeb ? 0 : 20),
          child: SizedBox(
            width: double.infinity,
            child: Obx(
              () => ElevatedButton(
                onPressed:
                    selectedInstructorId.value.isNotEmpty ? onContinue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      selectedInstructorId.value.isNotEmpty
                          ? const Color(0xFF43A047)
                          : Colors.grey,
                  foregroundColor: Colors.white,
                  minimumSize: Size.fromHeight(isWeb ? 50 : 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text('Continue'),
              ),
            ),
          ),
        ),
        if (!isWeb) const SizedBox(height: 20),
      ],
    );
  }
}
