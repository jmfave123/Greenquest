import 'package:flutter/material.dart';

/// A tab widget that displays a selectable list of classes.
///
/// Selection state is managed externally (by the parent dialog) and
/// communicated via [selectedIds] and [onSelectionChanged].
class ClassesTab extends StatelessWidget {
  /// The full list of classes to display.
  final List<Map<String, dynamic>> classes;

  /// The currently selected class IDs.
  final List<String> selectedIds;

  /// Called whenever a checkbox is toggled.
  /// Provides the updated selection list back to the parent.
  final ValueChanged<List<String>> onSelectionChanged;

  const ClassesTab({
    super.key,
    required this.classes,
    required this.selectedIds,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (classes.isEmpty) {
      return const Center(
        child: Text(
          'No classes available.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final classItem = classes[index];
        final String id = classItem['id'] as String? ?? '';
        final bool isSelected = selectedIds.contains(id);

        return CheckboxListTile(
          title: Text(
            classItem['section'] as String? ?? '',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            'Instructor: ${classItem['instructorName'] ?? 'N/A'}',
          ),
          value: isSelected,
          activeColor: const Color(0xFF34A853),
          onChanged: (bool? value) {
            final updated = List<String>.from(selectedIds);
            if (value == true) {
              updated.add(id);
            } else {
              updated.remove(id);
            }
            onSelectionChanged(updated);
          },
        );
      },
    );
  }
}
