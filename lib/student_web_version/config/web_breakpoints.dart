/// Web responsive breakpoints for student portal
/// Defines screen size thresholds for mobile, tablet, and desktop layouts
library;

class WebBreakpoints {
  // Breakpoint values
  static const double mobile = 600.0;
  static const double tablet = 1024.0;
  static const double desktop = 1440.0;

  // Layout dimensions
  static const double sidebarWidth = 250.0;
  static const double sidebarCollapsedWidth = 70.0;
  static const double maxContentWidth = 1200.0;
  static const double appBarHeight = 64.0;

  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Card dimensions
  static const double cardBorderRadius = 16.0;
  static const double cardElevation = 2.0;

  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Prevent instantiation
  WebBreakpoints._();
}

/// Device type enum
enum DeviceType { mobile, tablet, desktop }

/// Extension to get device type from screen width
extension DeviceTypeExtension on double {
  DeviceType get deviceType {
    if (this < WebBreakpoints.mobile) {
      return DeviceType.mobile;
    } else if (this < WebBreakpoints.tablet) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }
}
