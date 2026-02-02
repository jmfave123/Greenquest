import 'package:flutter/material.dart';

/// Reusable Year Filter Dropdown Widget
/// Provides a dropdown to filter data by year with an "All Years" option
class YearFilterDropdown extends StatelessWidget {
  const YearFilterDropdown({
    super.key,
    required this.selectedYear,
    required this.onYearChanged,
    this.startYear,
    this.endYear,
    this.includeAllOption = true,
  });

  /// Currently selected year (null means "All Years")
  final int? selectedYear;

  /// Callback when year selection changes
  final ValueChanged<int?> onYearChanged;

  /// Start year for the range (defaults to 2020)
  final int? startYear;

  /// End year for the range (defaults to current year)
  final int? endYear;

  /// Whether to include "All Years" option
  final bool includeAllOption;

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final start = startYear ?? 2020;
    final end = endYear ?? currentYear;

    // Generate year list from start to end (descending order)
    final years = List.generate(end - start + 1, (index) => end - index);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today, size: 18, color: Color(0xFF34A853)),
          const SizedBox(width: 8),
          DropdownButton<int?>(
            value: selectedYear,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF34A853)),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            items: [
              if (includeAllOption)
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('All Years'),
                ),
              ...years.map((year) {
                return DropdownMenuItem<int?>(
                  value: year,
                  child: Text(year.toString()),
                );
              }),
            ],
            onChanged: onYearChanged,
          ),
        ],
      ),
    );
  }
}
