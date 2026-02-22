import 'package:cloud_firestore/cloud_firestore.dart';

/// Centralised date utilities for the GreenQuest app.
///
/// All controllers store `dueDate` as a pre-formatted string of the form
/// `"MMM DD, YYYY HH:MM AM/PM"` (e.g. `"Feb 28, 2026 11:00 AM"`).
/// This utility normalises every possible representation — Firestore
/// [Timestamp], [DateTime], pre-formatted string, or ISO-8601 string —
/// into a [DateTime] so the rest of the codebase never has to duplicate
/// that logic.
///
/// Usage:
/// ```dart
/// import 'package:greenquest/core/utils/date_utils.dart';
///
/// final isPastDue = DueDateUtils.isPastDue(activity['dueDate']);
/// final dt = DueDateUtils.toDateTime(activity['dueDate']);
/// ```
class DueDateUtils {
  DueDateUtils._(); // prevent instantiation

  // Month abbreviation → 1-based month number
  static const Map<String, int> _monthMap = {
    'Jan': 1,
    'Feb': 2,
    'Mar': 3,
    'Apr': 4,
    'May': 5,
    'Jun': 6,
    'Jul': 7,
    'Aug': 8,
    'Sep': 9,
    'Oct': 10,
    'Nov': 11,
    'Dec': 12,
  };

  /// Parses a pre-formatted due date string produced by any controller.
  ///
  /// Accepts `"MMM DD, YYYY HH:MM AM/PM"` (e.g. `"Feb 28, 2026 11:00 AM"`).
  /// Returns `null` when the string cannot be parsed, rather than throwing.
  static DateTime? parseDueDateString(String dateStr) {
    try {
      final parts = dateStr.split(' ');
      // Minimum tokens: MMM  DD,  YYYY  HH:MM  AM/PM  → 5 parts
      if (parts.length < 5) return null;

      final month = _monthMap[parts[0]];
      final day = int.tryParse(parts[1].replaceAll(',', ''));
      final year = int.tryParse(parts[2]);
      final timeParts = parts[3].split(':');
      final period = parts[4].toUpperCase();

      if (month == null ||
          day == null ||
          year == null ||
          timeParts.length < 2) {
        return null;
      }

      var hour = int.tryParse(timeParts[0]);
      final minute = int.tryParse(timeParts[1]);

      if (hour == null || minute == null) return null;

      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;

      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  /// Converts any due date representation to a [DateTime].
  ///
  /// Handles:
  /// - Firestore [Timestamp]
  /// - [DateTime] (returned as-is)
  /// - Pre-formatted string `"MMM DD, YYYY HH:MM AM/PM"`
  /// - ISO-8601 string (e.g. `"2026-02-28T11:00:00"`)
  /// - Firebase server string `"February 11, 2026 at 11:00:00 AM UTC+8"`
  ///
  /// Returns `null` when the value is null or cannot be converted.
  static DateTime? toDateTime(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;

    if (value is String) {
      if (value.isEmpty) return null;

      // Firebase server-generated format: "February 11, 2026 at 11:00:00 AM UTC+8"
      if (value.contains(' at ') &&
          (value.contains('AM') || value.contains('PM'))) {
        // Strip timezone suffix then parse via DateTime.parse after normalising
        final cleaned = value
            .replaceAll(RegExp(r'\s+UTC[+-]\d+'), '')
            .replaceAll(' at ', ' ');
        try {
          return DateTime.parse(cleaned);
        } catch (_) {
          // Fall through to other parsers
        }
      }

      // Try ISO-8601 first (fast path, no allocation)
      if (value.contains('T') || value.contains('-')) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          // Fall through to pre-formatted parser
        }
      }

      // Pre-formatted controller string: "Feb 28, 2026 11:00 AM"
      return parseDueDateString(value);
    }

    return null;
  }

  /// Returns `true` when the due date has passed **and** a due date exists.
  ///
  /// Gracefully returns `false` (allow submission) when the due date is null,
  /// missing, or cannot be parsed — consistent with the fail-safe principle
  /// described in agent.md §1.4 (Error Handling is Not Optional).
  static bool isPastDue(dynamic dueDate) {
    final dt = toDateTime(dueDate);
    if (dt == null) return false;
    return DateTime.now().isAfter(dt);
  }
}
