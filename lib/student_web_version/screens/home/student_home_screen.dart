import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/web_theme.dart';
import '../../config/web_routes.dart';
import '../../utils/web_responsive_utils.dart';
import '../../widgets/layout/web_app_bar.dart';
import '../../widgets/layout/web_sidebar.dart';
import '../../controllers/web_home_controller.dart';

/// Main home screen for student web portal
/// Displays dashboard with progress, tasks, and quick actions

class WebStudentHomeScreen extends StatelessWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final WebHomeController controller = Get.find<WebHomeController>();

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
              ? Drawer(child: WebSidebar(currentRoute: WebRoutes.home))
              : null,
      body: Row(
        children: [
          // Sidebar for desktop
          if (isDesktop) const WebSidebar(currentRoute: WebRoutes.home),

          // Main content
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              return _buildContent(context);
            }),
          ),
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

                // Active Period Indicator (Matching Mobile)
                Obx(() {
                  if (controller.activePeriodName.value.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final isMidterm =
                      controller.activePeriodType.value == 'Midterm';
                  final baseColor = isMidterm ? Colors.blue : Colors.purple;

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: baseColor.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: baseColor.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: baseColor.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Period: ${controller.activePeriodType.value}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: baseColor.shade900,
                              ),
                            ),
                            Text(
                              controller.activePeriodName.value,
                              style: TextStyle(
                                fontSize: 12,
                                color: baseColor.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

                // Your Progress Card
                Obx(
                  () => _buildProgressCard(
                    context,
                    progress: controller.treeProgress.value,
                    isLoading: controller.isLoadingProgress.value,
                    grade: controller.computedGrade.value,
                  ),
                ),

                const SizedBox(height: 16),

                // Category Completion Card
                Obx(() => _buildCompletionCard(context)),

                const SizedBox(height: 16),

                // Quick Actions / Submit Work
                _buildQuickActions(context),
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
        Obx(
          () => Text(
            'Welcome back, ${controller.firstName}! 👋',
            style: WebTheme.headingLarge.copyWith(
              fontSize: WebResponsiveUtils.getResponsiveFontSize(
                context: context,
                baseSize: 32,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Text(
            controller.fullName.value,
            style: WebTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Track your progress and complete your tasks',
          style: WebTheme.bodyMedium,
        ),
      ],
    );
  }

  String _getPlantImage(double progress) {
    if (progress < 0.25) return 'assets/images/image_304-removebg-preview.png';
    if (progress < 0.5) return 'assets/images/image_307-removebg-preview.png';
    if (progress < 0.75) return 'assets/images/image_309-removebg-preview.png';
    if (progress < 1.0) return 'assets/images/image_310-removebg-preview.png';
    if (progress >= 1.0) return 'assets/images/image_311-removebg-preview.png';
    return 'assets/images/image_311-removebg-preview.png';
  }

  String _getProgressMessage(double progress) {
    if (progress < 0.25) return 'Just starting to grow!';
    if (progress < 0.5) return 'Growing steadily!';
    if (progress < 0.75) return 'Growing strong and healthy!';
    if (progress < 1.0) return 'Almost fully grown!';
    return 'Fully grown and thriving!';
  }

  Widget _buildProgressCard(
    BuildContext context, {
    required double progress,
    required bool isLoading,
    required double grade,
  }) {
    final gradeColor =
        grade <= 3.00 ? const Color(0xFF34A853) : const Color(0xFFE53935);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: WebTheme.borderLight),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Loading Progress Percentage at the Top Right (Matching Mobile)
          Positioned(
            right: 0,
            top: 0,
            child:
                isLoading
                    ? const SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          WebTheme.primaryGreen,
                        ),
                      ),
                    )
                    : Text(
                      '${(progress * 100).round()}%\nComplete',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: WebTheme.textPrimary,
                      ),
                    ),
          ),

          Column(
            children: [
              // Circular Progress Section
              Stack(
                alignment: Alignment.center,
                children: [
                  // Circular Progress
                  SizedBox(
                    width: 250,
                    height: 250,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 20,
                      backgroundColor: const Color(0xFFE0E0E0),
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xFF34A853),
                      ),
                    ),
                  ),

                  // Tree image + Grade
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        _getPlantImage(progress),
                        height: 140,
                        fit: BoxFit.contain,
                        errorBuilder:
                            (context, error, stackTrace) => const Icon(
                              Icons.eco,
                              size: 80,
                              color: Color(0xFF34A853),
                            ),
                      ),
                      const SizedBox(height: 8),
                      // Grade display inside circle (Matching Mobile)
                      Column(
                        children: [
                          Text(
                            'Current Grade:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            grade.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: gradeColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                isLoading
                    ? 'Loading progress...'
                    : _getProgressMessage(progress),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: WebTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tasks Overview', style: WebTheme.headingSmall),
            const SizedBox(height: 16),
            ...controller.midtermCompletions.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCompletionRow(
                  context,
                  label: item['displayName'] as String,
                  completed: item['completed'] as int,
                  total: item['total'] as int,
                  percentage: item['percentage'] as double,
                ),
              ),
            ),
            if (controller.midtermCompletions.isEmpty)
              const Text('No tasks recorded yet.', style: WebTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionRow(
    BuildContext context, {
    required String label,
    required int completed,
    required int total,
    required double percentage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: WebTheme.bodyMedium),
            Text('$completed/$total', style: WebTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total > 0 ? completed / total : 0,
            minHeight: 6,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage >= 100 ? WebTheme.successGreen : WebTheme.infoBlue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: WebTheme.headingSmall),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                title: 'Activities',
                icon: Icons.assignment,
                color: WebTheme.successGreen,
                onTap: () => Get.toNamed(WebRoutes.activities),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                context,
                title: 'Assignments',
                icon: Icons.task,
                color: WebTheme.infoBlue,
                onTap: () => Get.toNamed(WebRoutes.assignments),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                context,
                title: 'Quizzes',
                icon: Icons.quiz,
                color: WebTheme.warningOrange,
                onTap: () => Get.toNamed(WebRoutes.quizzes),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(
                title,
                style: WebTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
