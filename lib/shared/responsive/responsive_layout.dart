import 'package:flutter/material.dart';

/// Responsive layout system for create screens
/// Handles mobile, tablet, and desktop layouts
class ResponsiveLayout extends StatelessWidget {
  final Widget sidebar;
  final Widget mainContent;
  final Widget? rightPanel;
  final String screenTitle;
  final VoidCallback? onBackPressed;
  final Widget? actionButton;
  final bool showRightPanel;

  const ResponsiveLayout({
    super.key,
    required this.sidebar,
    required this.mainContent,
    this.rightPanel,
    required this.screenTitle,
    this.onBackPressed,
    this.actionButton,
    this.showRightPanel = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        // Determine layout type based on screen width
        if (screenWidth < 768) {
          // Mobile layout
          return _buildMobileLayout(context);
        } else if (screenWidth < 1024) {
          // Tablet layout
          return _buildTabletLayout(context);
        } else {
          // Desktop layout
          return _buildDesktopLayout(context);
        }
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Mobile header with hamburger menu
          _buildMobileHeader(context),
          // Main content with bottom sheet for details
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Main form content
                  mainContent,
                  const SizedBox(height: 24),
                  // Action button
                  if (actionButton != null)
                    SizedBox(width: double.infinity, child: actionButton!),
                  const SizedBox(height: 24),
                  // Details section (collapsible)
                  if (showRightPanel && rightPanel != null)
                    _buildMobileDetailsSection(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar (collapsible on tablet)
          SizedBox(width: 200, child: sidebar),
          // Main content area
          Expanded(
            child: Column(
              children: [
                // App bar
                _buildTabletHeader(context),
                // Content with right panel
                Expanded(
                  child:
                      showRightPanel && rightPanel != null
                          ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Main content
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: mainContent,
                                ),
                              ),
                              // Right panel
                              Expanded(
                                flex: 1,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    maxWidth: 400,
                                  ),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      left: BorderSide(
                                        color: Colors.black12,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: rightPanel!,
                                ),
                              ),
                            ],
                          )
                          : Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: mainContent,
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          sidebar,
          // Main content area
          Expanded(
            child: Column(
              children: [
                // App bar
                _buildDesktopHeader(context),
                // Content with right panel
                Expanded(
                  child:
                      showRightPanel && rightPanel != null
                          ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Main content
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: mainContent,
                                ),
                              ),
                              const SizedBox(width: 32),
                              // Right panel
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.15,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    maxWidth: 400,
                                  ),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      left: BorderSide(
                                        color: Colors.black12,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: rightPanel!,
                                ),
                              ),
                            ],
                          )
                          : Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: mainContent,
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Hamburger menu
          IconButton(
            onPressed: () {
              // Show sidebar in drawer
              Scaffold.of(context).openDrawer();
            },
            icon: const Icon(Icons.menu),
          ),
          // Title
          Expanded(
            child: Text(
              screenTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          // Back button
          if (onBackPressed != null)
            IconButton(
              onPressed: onBackPressed,
              icon: const Icon(Icons.arrow_back),
            ),
        ],
      ),
    );
  }

  Widget _buildTabletHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          if (onBackPressed != null)
            GestureDetector(
              onTap: onBackPressed,
              child: const Icon(
                Icons.arrow_back,
                size: 24,
                color: Colors.black,
              ),
            ),
          if (onBackPressed != null) const SizedBox(width: 12),
          // Title
          Text(
            screenTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          // Action button
          if (actionButton != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: actionButton!,
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          if (onBackPressed != null)
            GestureDetector(
              onTap: onBackPressed,
              child: const Icon(
                Icons.arrow_back,
                size: 24,
                color: Colors.black,
              ),
            ),
          if (onBackPressed != null) const SizedBox(width: 12),
          // Title
          Text(
            screenTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          // Action button
          if (actionButton != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: actionButton!,
            ),
        ],
      ),
    );
  }

  Widget _buildMobileDetailsSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collapsible header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.settings, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Details',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.keyboard_arrow_down, size: 20),
              ],
            ),
          ),
          // Details content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: rightPanel!,
          ),
        ],
      ),
    );
  }
}

/// Responsive form field widget
class ResponsiveFormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final bool isRequired;
  final bool showError;
  final String? errorText;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final Function(String)? onChanged;

  const ResponsiveFormField({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    this.isRequired = false,
    this.showError = false,
    this.errorText,
    this.maxLines = 1,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: showError ? Colors.red : const Color(0xFF9E9E9E),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: showError ? Colors.red : const Color(0xFF9E9E9E),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF34A853), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixIcon: suffixIcon,
          ),
        ),
        if (showError && errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              errorText!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

/// Responsive button widget
class ResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsetsGeometry? padding;

  const ResponsiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? const Color(0xFF34A853),
        foregroundColor: textColor ?? Colors.white,
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: const Size(0, 48),
      ),
      child:
          isLoading
              ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
              : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
    );
  }
}

/// Responsive breakpoints utility
class ResponsiveBreakpoints {
  static const double mobile = 768;
  static const double tablet = 1024;
  static const double desktop = 1200;

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < tablet;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tablet;
  }

  static double getResponsiveWidth(
    BuildContext context, {
    double mobile = 0.95,
    double tablet = 0.8,
    double desktop = 0.7,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isMobile(context)) {
      return screenWidth * mobile;
    } else if (isTablet(context)) {
      return screenWidth * tablet;
    } else {
      return screenWidth * desktop;
    }
  }

  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(20);
    } else {
      return const EdgeInsets.all(24);
    }
  }
}
