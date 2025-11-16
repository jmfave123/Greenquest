import 'package:flutter/material.dart';

/// Preset date range filters used across admin/instructor screens.
enum DateRangePreset { all, today, yesterday, last7Days, last30Days, custom }

/// Helper that resolves preset selections to concrete [DateTimeRange] objects.
/// Returns `null` for [DateRangePreset.all].
DateTimeRange? resolveDateRange(
  DateRangePreset preset, {
  DateTimeRange? customRange,
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  DateTime start;
  DateTime end;

  switch (preset) {
    case DateRangePreset.all:
      return null;
    case DateRangePreset.today:
      start = DateTime(reference.year, reference.month, reference.day);
      end = start
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1));
      break;
    case DateRangePreset.yesterday:
      end = DateTime(
        reference.year,
        reference.month,
        reference.day,
      ).subtract(const Duration(milliseconds: 1));
      start = end
          .subtract(const Duration(days: 1))
          .add(const Duration(milliseconds: 1));
      break;
    case DateRangePreset.last7Days:
      end = DateTime(
        reference.year,
        reference.month,
        reference.day,
        23,
        59,
        59,
        999,
      );
      start = end.subtract(const Duration(days: 6));
      break;
    case DateRangePreset.last30Days:
      end = DateTime(
        reference.year,
        reference.month,
        reference.day,
        23,
        59,
        59,
        999,
      );
      start = end.subtract(const Duration(days: 29));
      break;
    case DateRangePreset.custom:
      return customRange;
  }

  return DateTimeRange(start: start, end: end);
}
