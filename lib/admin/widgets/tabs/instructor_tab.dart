import 'package:flutter/material.dart';

/// A tab widget that displays a selectable list of instructors.
///
/// Selection state is managed externally (by the parent dialog) and
/// communicated via [selectedIds] and [onSelectionChanged].
class InstructorsTab extends StatelessWidget {
  /// The full list of instructors to display.
  final List<Map<String, dynamic>> instructors;

  /// The currently selected instructor IDs.
  final List<String> selectedIds;

  /// Called whenever a checkbox is toggled.
  /// Provides the updated selection list back to the parent.
  final ValueChanged<List<String>> onSelectionChanged;

  const InstructorsTab({
    super.key,
    required this.instructors,
    required this.selectedIds,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (instructors.isEmpty) {
      return const Center(
        child: Text(
          'No instructors available.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: instructors.length,
      itemBuilder: (context, index) {
        final instructor = instructors[index];
        final String id = instructor['id'] as String? ?? '';
        final bool isSelected = selectedIds.contains(id);

        return CheckboxListTile(
          title: Text(
            instructor['name'] as String? ?? '',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text('Department: ${instructor['department'] ?? 'N/A'}'),
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
