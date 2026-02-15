import 'package:flutter/material.dart';

/// Dialog for creating a new semester
class CreateSemesterDialog extends StatefulWidget {
  final Function(String year, String semester) onSave;

  const CreateSemesterDialog({super.key, required this.onSave});

  @override
  State<CreateSemesterDialog> createState() => _CreateSemesterDialogState();
}

class _CreateSemesterDialogState extends State<CreateSemesterDialog> {
  final TextEditingController yearController = TextEditingController();
  String selectedSemester = '1st Semester';

  @override
  void dispose() {
    yearController.dispose();
    super.dispose();
  }

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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34A853).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_month,
                    color: Color(0xFF34A853),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Create New Semester',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: yearController,
              decoration: InputDecoration(
                labelText: 'Academic Year',
                hintText: 'e.g., 2024-2025',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF34A853)),
                ),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedSemester,
              decoration: InputDecoration(
                labelText: 'Semester',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF34A853)),
                ),
              ),
              items:
                  ['1st Semester', '2nd Semester', 'Summer'].map((
                    String semester,
                  ) {
                    return DropdownMenuItem<String>(
                      value: semester,
                      child: Text(semester),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedSemester = newValue!;
                });
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onSave(yearController.text.trim(), selectedSemester);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF34A853),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Create Semester'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
