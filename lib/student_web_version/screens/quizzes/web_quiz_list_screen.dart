import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../user/submit/quiz_new/quiz_controller.dart';
import 'web_quiz_detail_screen.dart';
import '../../config/web_theme.dart';
import '../../config/web_routes.dart';
import '../../utils/web_responsive_utils.dart';
import '../../widgets/layout/web_app_bar.dart';
import '../../widgets/layout/web_sidebar.dart';
import '../../../shared/widgets/skeleton_loading.dart';

class WebQuizListScreen extends StatefulWidget {
  const WebQuizListScreen({super.key});

  @override
  State<WebQuizListScreen> createState() => _WebQuizListScreenState();
}

class _WebQuizListScreenState extends State<WebQuizListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late QuizController controller;

  @override
  void initState() {
    super.initState();
    try {
      controller = Get.find<QuizController>();
    } catch (e) {
      controller = Get.put(QuizController(), permanent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = WebResponsiveUtils.isDesktop(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: WebAppBar(
        title: 'Quizzes',
        onMenuPressed:
            isDesktop ? null : () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer:
          !isDesktop
              ? Drawer(child: WebSidebar(currentRoute: WebRoutes.quizzes))
              : null,
      body: Row(
        children: [
          if (isDesktop) const WebSidebar(currentRoute: WebRoutes.quizzes),
          Expanded(
            child: Container(
              color: WebTheme.backgroundLight,
              child: Obx(() {
                if (controller.isLoading.value && controller.quizzes.isEmpty) {
                  return _buildSkeletonLoading(context);
                }
                return _buildContent(context);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: RefreshIndicator(
          onRefresh: () => controller.refreshQuizzes(),
          child: SingleChildScrollView(
            padding: WebResponsiveUtils.getResponsivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                if (controller.quizzes.isEmpty)
                  _buildEmptyState()
                else
                  _buildQuizGrid(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Your Quizzes', style: WebTheme.headingLarge),
            IconButton(
              icon: const Icon(Icons.refresh, color: WebTheme.primaryGreen),
              onPressed: () => controller.refreshQuizzes(),
              tooltip: 'Refresh',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(
          () => Text(
            controller.currentInstructorUid.value.isNotEmpty
                ? 'Showing quizzes from ${controller.currentInstructorName.value}'
                : 'All quizzes across your courses',
            style: WebTheme.bodyMedium.copyWith(color: WebTheme.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizGrid(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    int crossAxisCount = 1;
    if (width > 1200) {
      crossAxisCount = 3;
    } else if (width > 800) {
      crossAxisCount = 2;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        mainAxisExtent: 180,
      ),
      itemCount: controller.quizzes.length,
      itemBuilder: (context, index) {
        final quiz = controller.quizzes[index];
        return _buildQuizCard(quiz);
      },
    );
  }

  Widget _buildQuizCard(Map<String, dynamic> quiz) {
    final quizId = quiz['id']?.toString() ?? '';
    final status = controller.submissionStatus[quizId] ?? 'not_submitted';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          controller.setSelectedQuiz(quiz);
          Get.to(() => WebQuizDetailScreen(quiz: quiz));
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: WebTheme.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.quiz,
                      color: Colors.purple,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  _buildStatusBadge(status, quiz['dueDate']),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                quiz['title'] ?? 'No Title',
                style: WebTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: WebTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Due: ${controller.getDueDateFormatted(quiz['dueDate'])}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: WebTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, dynamic dueDate) {
    Color badgeColor;
    String badgeText;

    // bool isPastDue = false;
    // Note: QuizController formats dates into strings in loadQuizzes()
    // So we might need to be careful here if we want real-time late status.
    // However, the controller already handles basic status.

    switch (status.toLowerCase()) {
      case 'submitted':
        badgeColor = Colors.blue;
        badgeText = 'Submitted';
        break;
      case 'graded':
        badgeColor = WebTheme.primaryGreen;
        badgeText = 'Graded';
        break;
      default:
        badgeColor = Colors.grey;
        badgeText = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          color: badgeColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            Icon(Icons.quiz_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 24),
            const Text('No quizzes found', style: WebTheme.headingMedium),
            const SizedBox(height: 8),
            Text(
              'Your quizzes will appear here once assigned by your instructor.',
              style: WebTheme.bodyMedium.copyWith(
                color: WebTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: SingleChildScrollView(
          padding: WebResponsiveUtils.getResponsivePadding(context),
          child: Column(
            children: List.generate(
              6,
              (index) => const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: SkeletonListItem(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension on QuizController {
  String getDueDateFormatted(dynamic dueDate) {
    if (dueDate == null) return 'No due date';

    try {
      DateTime date;

      if (dueDate is Timestamp) {
        date = dueDate.toDate();
      } else if (dueDate is DateTime) {
        date = dueDate;
      } else if (dueDate is String) {
        // The controller pre-formats the due date as a human-readable string
        // (e.g. "Feb 28, 2026 11:00 AM"). Return it directly.
        if (dueDate.isEmpty) return 'No due date';
        // Handle Firebase server-formatted strings: "February 11, 2026 at 11:00:00 AM UTC+8"
        if (dueDate.contains('at') &&
            (dueDate.contains('AM') || dueDate.contains('PM'))) {
          return dueDate.replaceAll(' UTC+8', '').replaceAll(' UTC', '');
        }
        // For already-formatted strings like "Feb 28, 2026 11:00 AM"
        return dueDate;
      } else if (dueDate is int) {
        date = DateTime.fromMillisecondsSinceEpoch(dueDate);
      } else {
        return 'No due date';
      }

      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final hour =
          date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';

      return '${months[date.month - 1]} ${date.day}, ${date.year} at $hour:$minute $period';
    } catch (e) {
      if (dueDate is String && (dueDate as String).isNotEmpty) return dueDate;
      return 'No due date';
    }
  }
}
