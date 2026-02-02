import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Dialog for adding a new section to a department
class AddSectionDialog extends StatefulWidget {
  final String departmentName;
  final String departmentCode;
  final Function(String year, String sectionLetter, String? subCode) onSave;

  const AddSectionDialog({
    super.key,
    required this.departmentName,
    required this.departmentCode,
    required this.onSave,
  });

  @override
  State<AddSectionDialog> createState() => _AddSectionDialogState();
}

class _AddSectionDialogState extends State<AddSectionDialog> {
  String selectedYear = '1st';
  String selectedSectionLetter = 'A';
  String? selectedSubCode;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF34A853).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.group_work_rounded,
                    color: Color(0xFF34A853),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add Section',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add section to ${widget.departmentName}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Year Selection
            const Text(
              'Year Level',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: selectedYear,
                onChanged: (value) => setState(() => selectedYear = value!),
                items:
                    ['1st', '2nd', '3rd', '4th'].map((year) {
                      return DropdownMenuItem<String>(
                        value: year,
                        child: Text(year),
                      );
                    }).toList(),
                underline: const SizedBox(),
                isExpanded: true,
              ),
            ),

            const SizedBox(height: 16),

            // Section Letter Selection
            const Text(
              'Section Letter',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: selectedSectionLetter,
                onChanged:
                    (value) => setState(() => selectedSectionLetter = value!),
                items:
                    ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'].map((letter) {
                      return DropdownMenuItem<String>(
                        value: letter,
                        child: Text(letter),
                      );
                    }).toList(),
                underline: const SizedBox(),
                isExpanded: true,
              ),
            ),

            const SizedBox(height: 16),

            // Sub-Code Selection (Only for BTLED)
            if (widget.departmentCode == 'BTLED') ...[
              const Text(
                'Sub-Code (Required for BTLED)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: selectedSubCode,
                  hint: const Text('Select subcode'),
                  onChanged: (value) => setState(() => selectedSubCode = value),
                  items:
                      ['ICT', 'HE', 'IA'].map((subCode) {
                        return DropdownMenuItem<String>(
                          value: subCode,
                          child: Text(subCode),
                        );
                      }).toList(),
                  underline: const SizedBox(),
                  isExpanded: true,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Preview Section Code
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF34A853).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF34A853).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Section Code Preview:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _generateSectionCode(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF34A853),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black54,
            side: const BorderSide(color: Color(0xFFE5E7EB)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () {
            // Validate BTLED requires subcode
            if (widget.departmentCode == 'BTLED' &&
                (selectedSubCode == null || selectedSubCode!.isEmpty)) {
              Get.snackbar(
                'Validation Error',
                'Sub-code is required for BTLED sections',
                backgroundColor: Colors.orange,
                colorText: Colors.white,
              );
              return;
            }
            Navigator.of(context).pop();
            widget.onSave(selectedYear, selectedSectionLetter, selectedSubCode);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF34A853),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Add Section'),
        ),
      ],
    );
  }

  String _generateSectionCode() {
    final yearNumber = selectedYear
        .replaceAll('st', '')
        .replaceAll('nd', '')
        .replaceAll('rd', '')
        .replaceAll('th', '');

    if (selectedSubCode != null && selectedSubCode!.isNotEmpty) {
      return '${widget.departmentCode}-$selectedSubCode-$yearNumber$selectedSectionLetter';
    }
    return '${widget.departmentCode}-$yearNumber$selectedSectionLetter';
  }
}
