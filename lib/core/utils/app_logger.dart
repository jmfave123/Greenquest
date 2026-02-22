import 'package:flutter/foundation.dart';

/// Application-wide logger following agent.md guidelines (Section 8.2)
/// Provides structured logging with different severity levels
class AppLogger {
  final String tag;

  AppLogger(this.tag);

  /// Log error messages (something failed, needs attention)
  void error(String message, {dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      print('❌ [$tag] ERROR: $message');
      if (error != null) {
        print('   Error: $error');
      }
      if (stackTrace != null) {
        print('   StackTrace: $stackTrace');
      }
    }
    // TODO: In production, send to crash reporting service (Sentry, Firebase Crashlytics)
  }

  /// Log warning messages (unexpected but handled situation)
  void warning(String message, {Map<String, dynamic>? context}) {
    if (kDebugMode) {
      print('⚠️  [$tag] WARNING: $message');
      if (context != null) {
        print('   Context: $context');
      }
    }
  }

  /// Log info messages (important business events)
  void info(String message, {Map<String, dynamic>? context}) {
    if (kDebugMode) {
      print('ℹ️  [$tag] INFO: $message');
      if (context != null) {
        print('   Context: $context');
      }
    }
  }

  /// Log debug messages (detailed diagnostic information - dev only)
  void debug(String message, {Map<String, dynamic>? context}) {
    if (kDebugMode) {
      print('🔍 [$tag] DEBUG: $message');
      if (context != null) {
        print('   Context: $context');
      }
    }
  }

  /// Log success messages for important operations
  void success(String message, {Map<String, dynamic>? context}) {
    if (kDebugMode) {
      print('✅ [$tag] SUCCESS: $message');
      if (context != null) {
        print('   Context: $context');
      }
    }
  }
}
