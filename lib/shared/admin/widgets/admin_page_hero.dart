import 'package:flutter/material.dart';

/// Reusable hero/header section for admin pages to keep branding consistent.
class AdminPageHero extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final String heroTitle;
  final String heroDescription;
  final Widget? action;
  final EdgeInsetsGeometry headerPadding;
  final EdgeInsetsGeometry heroMargin;
  final EdgeInsetsGeometry heroPadding;
  final List<Color> gradientColors;

  const AdminPageHero({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.heroTitle,
    required this.heroDescription,
    this.action,
    this.headerPadding = const EdgeInsets.symmetric(
      horizontal: 24,
      vertical: 20,
    ),
    this.heroMargin = const EdgeInsets.all(24),
    this.heroPadding = const EdgeInsets.all(24),
    this.gradientColors = const [Color(0xFF34A853), Color(0xFF1B5E20)],
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 768;
    final bool isTablet = width >= 768 && width < 1024;

    final headerContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize:
                isMobile
                    ? 20
                    : isTablet
                    ? 22
                    : 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(color: Colors.black54, fontSize: isMobile ? 13 : 14),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: headerPadding,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
          ),
          child:
              isMobile
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          leading,
                          const SizedBox(width: 12),
                          Expanded(child: headerContent),
                        ],
                      ),
                      if (action != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: action!,
                          ),
                        ),
                    ],
                  )
                  : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      leading,
                      const SizedBox(width: 16),
                      Expanded(child: headerContent),
                      if (action != null) action!,
                    ],
                  ),
        ),
        Container(
          margin: heroMargin,
          padding: heroPadding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                heroTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                heroDescription,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
