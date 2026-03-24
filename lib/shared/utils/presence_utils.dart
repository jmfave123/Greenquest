import 'package:cloud_firestore/cloud_firestore.dart';

class PresenceUtils {
  // Keep in sync with server-side stale default in api/presence.js.
  static const int onlineThresholdMinutes = 2;

  static DateTime? parseLastSeen(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    return null;
  }

  static bool isActuallyOnline({
    required bool isOnline,
    required dynamic lastSeen,
    int thresholdMinutes = onlineThresholdMinutes,
  }) {
    final parsed = parseLastSeen(lastSeen);
    if (parsed == null) return false;

    final difference = DateTime.now().difference(parsed).inMinutes;
    final withinWindow = difference <= thresholdMinutes;

    // Fresh lastSeen is the source of truth. This prevents stale documents
    // with lingering isOnline=true from appearing online forever.
    if (withinWindow) return true;

    // If lastSeen is stale, always treat as offline even when raw isOnline is true.
    return false;
  }

  static String formatLastSeen(DateTime lastSeenTime) {
    final now = DateTime.now();
    final difference = now.difference(lastSeenTime);

    if (difference.inMinutes < 1) {
      return 'Active just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return 'Active $minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'Active $hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return 'Active $days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Active $weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Active $months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      return 'Active a long time ago';
    }
  }
}
