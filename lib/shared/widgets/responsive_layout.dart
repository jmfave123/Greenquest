import 'package:flutter/material.dart';

/// A reusable responsive layout component that handles overflow issues
/// and provides consistent spacing across the app
class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool useScrollView;
  final ScrollController? scrollController;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.padding,
    this.useScrollView = true,
    this.scrollController,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate responsive padding
    final responsivePadding =
        padding ??
        EdgeInsets.symmetric(
          horizontal: screenWidth * 0.06, // 6% of screen width
          vertical: screenHeight * 0.02, // 2% of screen height
        );

    if (useScrollView) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    screenHeight -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: responsivePadding,
                  child: Column(
                    mainAxisAlignment: mainAxisAlignment,
                    crossAxisAlignment: crossAxisAlignment,
                    children: [child],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: responsivePadding,
            child: Column(
              mainAxisAlignment: mainAxisAlignment,
              crossAxisAlignment: crossAxisAlignment,
              children: [Expanded(child: child)],
            ),
          ),
        ),
      );
    }
  }
}

/// A responsive container that adapts to screen size
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxDecoration? decoration;
  final double? maxWidth;
  final double? maxHeight;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.decoration,
    this.maxWidth,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width:
          width ??
          (maxWidth != null ? screenWidth.clamp(0.0, maxWidth!) : null),
      height:
          height ??
          (maxHeight != null ? screenHeight.clamp(0.0, maxHeight!) : null),
      padding: padding,
      margin: margin,
      decoration: decoration,
      child: child,
    );
  }
}

/// A responsive text widget that scales with screen size
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontSize,
    this.fontWeight,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate responsive font size
    final responsiveFontSize =
        fontSize ?? (screenWidth * 0.04).clamp(12.0, 24.0);

    return Text(
      text,
      style:
          style ??
          TextStyle(
            fontSize: responsiveFontSize,
            fontWeight: fontWeight,
            color: color,
          ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// A responsive button that adapts to screen size
class ResponsiveButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final double? minHeight;
  final double? minWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveButton({
    super.key,
    required this.child,
    this.onPressed,
    this.style,
    this.minHeight,
    this.minWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate responsive button size
    final responsiveMinHeight =
        minHeight ?? (screenHeight * 0.07).clamp(48.0, 80.0);
    final responsiveMinWidth =
        minWidth ?? (screenWidth * 0.8).clamp(200.0, 400.0);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style:
            style?.copyWith(
              minimumSize: WidgetStateProperty.all(
                Size(responsiveMinWidth, responsiveMinHeight),
              ),
            ) ??
            ElevatedButton.styleFrom(
              minimumSize: Size(responsiveMinWidth, responsiveMinHeight),
            ),
        child: child,
      ),
    );
  }
}

/// A responsive spacing widget
class ResponsiveSpacing extends StatelessWidget {
  final double? height;
  final double? width;
  final double multiplier;

  const ResponsiveSpacing({
    super.key,
    this.height,
    this.width,
    this.multiplier = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height != null ? height! * multiplier : null,
      width: width != null ? width! * multiplier : null,
    );
  }
}

/// A responsive card widget
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? borderRadius;
  final List<BoxShadow>? boxShadow;
  final Border? border;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.boxShadow,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding ?? EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
        boxShadow:
            boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
        border: border,
      ),
      child: child,
    );
  }
}
