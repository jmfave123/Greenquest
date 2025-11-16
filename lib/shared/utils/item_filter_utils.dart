import 'package:flutter/material.dart';

/// Filters a list of created item maps by optional type, date range, and search query.
/// Each item is expected to contain a `type` string and a `createdAtRaw` DateTime.
List<Map<String, dynamic>> filterCreatedItems({
  required List<Map<String, dynamic>> items,
  String? typeFilter,
  DateTimeRange? dateRange,
  String? searchQuery,
  String? classFilter,
  String? periodFilter,
}) {
  final normalizedSearch = searchQuery?.trim().toLowerCase();

  return items.where((item) {
    final itemType = item['type']?.toString();
    final createdAt = item['createdAtRaw'] as DateTime?;
    final title = item['title']?.toString().toLowerCase() ?? '';
    final selectedClasses =
        (item['selectedClasses'] as List?)?.map((c) => c.toString()).toList() ??
        const <String>[];
    final itemPeriod = item['period']?.toString();

    final matchesType =
        typeFilter == null || typeFilter.isEmpty || itemType == typeFilter;

    final matchesSearch =
        normalizedSearch == null || normalizedSearch.isEmpty
            ? true
            : title.contains(normalizedSearch);

    final matchesDate =
        dateRange == null
            ? true
            : (createdAt != null &&
                !createdAt.isBefore(dateRange.start) &&
                !createdAt.isAfter(dateRange.end));

    final matchesClass =
        classFilter == null || classFilter.isEmpty
            ? true
            : selectedClasses.contains(classFilter);

    final matchesPeriod =
        periodFilter == null || periodFilter.isEmpty
            ? true
            : (itemPeriod != null && itemPeriod == periodFilter);

    return matchesType &&
        matchesSearch &&
        matchesDate &&
        matchesClass &&
        matchesPeriod;
  }).toList();
}
