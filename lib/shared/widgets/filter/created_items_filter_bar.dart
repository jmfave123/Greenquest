import 'package:flutter/material.dart';
import '../../utils/date_range_filter.dart';

class CreatedItemsFilterBar extends StatelessWidget {
  final List<String> typeOptions;
  final String? selectedType;
  final ValueChanged<String?> onTypeChanged;

  final List<String>? classOptions;
  final String? selectedClass;
  final ValueChanged<String?>? onClassChanged;
  final String classLabel;

  final List<String>? periodOptions;
  final String? selectedPeriod;
  final ValueChanged<String?>? onPeriodChanged;
  final String periodLabel;

  final DateRangePreset datePreset;
  final DateTimeRange? customRange;
  final ValueChanged<DateRangePreset> onPresetChanged;
  final Future<DateTimeRange?> Function()? onRequestCustomRange;

  const CreatedItemsFilterBar({
    super.key,
    required this.typeOptions,
    required this.selectedType,
    required this.onTypeChanged,
    this.classOptions,
    this.selectedClass,
    this.onClassChanged,
    this.classLabel = 'Class / Section',
    this.periodOptions,
    this.selectedPeriod,
    this.onPeriodChanged,
    this.periodLabel = 'Period',
    required this.datePreset,
    required this.customRange,
    required this.onPresetChanged,
    required this.onRequestCustomRange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chips = <_FilterChipData>[
      _FilterChipData('All Time', DateRangePreset.all),
      _FilterChipData('Today', DateRangePreset.today),
      _FilterChipData('Yesterday', DateRangePreset.yesterday),
      _FilterChipData('Last 7 Days', DateRangePreset.last7Days),
      _FilterChipData('Last 30 Days', DateRangePreset.last30Days),
      _FilterChipData(_customLabel, DateRangePreset.custom),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildTypeDropdown(theme)),
            if (classOptions != null && classOptions!.isNotEmpty) ...[
              const SizedBox(width: 12),
              Expanded(child: _buildClassDropdown(theme)),
            ],
            if (periodOptions != null && periodOptions!.isNotEmpty) ...[
              const SizedBox(width: 12),
              Expanded(child: _buildPeriodDropdown(theme)),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chips.map((chip) => _buildChip(context, chip)).toList(),
        ),
      ],
    );
  }

  Widget _buildPeriodDropdown(ThemeData theme) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: periodLabel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          value: selectedPeriod ?? 'All Periods',
          focusColor: Colors.transparent,
          dropdownColor: Colors.white,
          items:
              ['All Periods', ...periodOptions!]
                  .map(
                    (period) => DropdownMenuItem<String?>(
                      value: period == 'All Periods' ? 'All Periods' : period,
                      child: Text(period),
                    ),
                  )
                  .toList(),
          onChanged: (value) {
            if (onPeriodChanged == null) return;
            if (value == 'All Periods') {
              onPeriodChanged!(null);
            } else {
              onPeriodChanged!(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildClassDropdown(ThemeData theme) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: classLabel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          value: selectedClass ?? 'All Classes',
          focusColor: Colors.transparent,
          dropdownColor: Colors.white,
          items:
              ['All Classes', ...classOptions!]
                  .map(
                    (cls) => DropdownMenuItem<String?>(
                      value: cls == 'All Classes' ? 'All Classes' : cls,
                      child: Text(cls),
                    ),
                  )
                  .toList(),
          onChanged: (value) {
            if (onClassChanged == null) return;
            if (value == 'All Classes') {
              onClassChanged!(null);
            } else {
              onClassChanged!(value);
            }
          },
        ),
      ),
    );
  }

  String get _customLabel {
    if (customRange == null) {
      return 'Custom Range';
    }
    final start = customRange!.start;
    final end = customRange!.end;
    return '${_formatDate(start)} - ${_formatDate(end)}';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Widget _buildTypeDropdown(ThemeData theme) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Item Type',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          value: selectedType ?? 'All Types',
          focusColor: Colors.transparent,
          dropdownColor: Colors.white,
          items:
              ['All Types', ...typeOptions]
                  .map(
                    (type) => DropdownMenuItem<String?>(
                      value: type == 'All Types' ? 'All Types' : type,
                      child: Text(type),
                    ),
                  )
                  .toList(),
          onChanged: (value) {
            if (value == 'All Types') {
              onTypeChanged(null);
            } else {
              onTypeChanged(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, _FilterChipData chip) {
    final isSelected = datePreset == chip.preset;
    return ChoiceChip(
      label: Text(chip.label, overflow: TextOverflow.ellipsis),
      selected: isSelected,
      selectedColor: const Color(0xFF34A853),
      backgroundColor: const Color(0xFFF1F5F9),
      pressElevation: 0,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF34A853) : const Color(0xFFE2E8F0),
        ),
      ),
      onSelected: (_) async {
        if (chip.preset == DateRangePreset.custom) {
          final range = await onRequestCustomRange?.call();
          if (range != null) {
            onPresetChanged(DateRangePreset.custom);
          }
        } else {
          onPresetChanged(chip.preset);
        }
      },
    );
  }
}

class _FilterChipData {
  final String label;
  final DateRangePreset preset;
  const _FilterChipData(this.label, this.preset);
}
