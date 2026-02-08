import 'package:flutter/material.dart';
import '../config/web_breakpoints.dart';

/// Responsive utility functions for web layouts
/// Provides helpers for detecting device type and responsive sizing

class WebResponsiveUtils {
  /// Check if current screen is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < WebBreakpoints.mobile;
  }

  /// Check if current screen is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= WebBreakpoints.mobile && width < WebBreakpoints.tablet;
  }

  /// Check if current screen is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= WebBreakpoints.tablet;
  }

  /// Get current device type
  static DeviceType getDeviceType(BuildContext context) {
    return MediaQuery.of(context).size.width.deviceType;
  }

  /// Get responsive value based on device type
  static T getResponsiveValue<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  /// Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    return EdgeInsets.all(
      getResponsiveValue(
        context: context,
        mobile: WebBreakpoints.paddingMedium,
        tablet: WebBreakpoints.paddingLarge,
        desktop: WebBreakpoints.paddingXLarge,
      ),
    );
  }

  /// Get responsive horizontal padding
  static EdgeInsets getResponsiveHorizontalPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: getResponsiveValue(
        context: context,
        mobile: WebBreakpoints.paddingMedium,
        tablet: WebBreakpoints.paddingLarge,
        desktop: WebBreakpoints.paddingXLarge,
      ),
    );
  }

  /// Calculate responsive font size
  static double getResponsiveFontSize({
    required BuildContext context,
    required double baseSize,
  }) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return baseSize;
      case DeviceType.tablet:
        return baseSize * 1.1;
      case DeviceType.desktop:
        return baseSize * 1.2;
    }
  }

  /// Get number of grid columns based on screen size
  static int getGridColumns(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );
  }

  /// Alias for getGridColumns to match SliverGridDelegate nomenclature
  static int getGridCrossAxisCount(BuildContext context) {
    return getGridColumns(context);
  }

  /// Check if sidebar should be shown
  static bool shouldShowSidebar(BuildContext context) {
    return isDesktop(context);
  }

  /// Check if bottom navigation should be shown
  static bool shouldShowBottomNav(BuildContext context) {
    return !isDesktop(context);
  }

  // Prevent instantiation
  WebResponsiveUtils._();
}
