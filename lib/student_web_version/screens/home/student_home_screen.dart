import 'package:flutter/material.dart';
import '../../config/web_theme.dart';
import '../../config/web_routes.dart';
import '../../utils/web_responsive_utils.dart';
import '../../widgets/layout/web_app_bar.dart';
import '../../widgets/layout/web_sidebar.dart';

/// Main home screen for student web portal
/// Displays dashboard with progress, tasks, and quick actions

class WebStudentHomeScreen extends StatelessWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  WebStudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = WebResponsiveUtils.isDesktop(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: WebAppBar(
        title: 'GreenQuest Student Portal',
        onMenuPressed:
            isDesktop
                ? null
                : () {
                  _scaffoldKey.currentState?.openDrawer();
                },
      ),
      drawer:
          !isDesktop
              ? const Drawer(child: WebSidebar(currentRoute: WebRoutes.home))
              : null,
      body: Row(
        children: [
          // Sidebar for desktop
          if (isDesktop) const WebSidebar(currentRoute: WebRoutes.home),

          // Main content
          Expanded(child: _buildContent(context)),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Container(
      color: WebTheme.backgroundLight,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            padding: WebResponsiveUtils.getResponsivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome header
                _buildWelcomeHeader(context),

                const SizedBox(height: 24),

                // Placeholder for progress card
                _buildPlaceholderCard(
                  context,
                  title: 'Your Progress',
                  subtitle:
                      'Seedling growth and grade tracking will appear here',
                  icon: Icons.eco,
                  color: WebTheme.successGreen,
                ),

                const SizedBox(height: 16),

                // Placeholder for category completion
                _buildPlaceholderCard(
                  context,
                  title: 'Category Completion',
                  subtitle: 'Activities, assignments, and quizzes progress',
                  icon: Icons.checklist,
                  color: WebTheme.infoBlue,
                ),

                const SizedBox(height: 16),

                // Placeholder for submit work
                _buildPlaceholderCard(
                  context,
                  title: 'Submit Your Work',
                  subtitle:
                      'Quick access to submit activities, assignments, and quizzes',
                  icon: Icons.upload_file,
                  color: WebTheme.warningOrange,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, Student! 👋',
          style: WebTheme.headingLarge.copyWith(
            fontSize: WebResponsiveUtils.getResponsiveFontSize(
              context: context,
              baseSize: 32,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Track your progress and complete your tasks',
          style: WebTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildPlaceholderCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: WebTheme.headingSmall),
                  const SizedBox(height: 4),
                  Text(subtitle, style: WebTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
