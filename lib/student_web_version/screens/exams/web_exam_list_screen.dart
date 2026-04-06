import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../user/submit/exam/exam_controller.dart';
import 'web_exam_detail_screen.dart';
import '../../config/web_theme.dart';
import '../../config/web_routes.dart';
import '../../utils/web_responsive_utils.dart';
import '../../widgets/layout/web_app_bar.dart';
import '../../widgets/layout/web_sidebar.dart';
import '../../../core/utils/date_utils.dart';
import '../../widgets/web_card_skeleton.dart';

class WebExamListScreen extends StatefulWidget {
  const WebExamListScreen({super.key});

  @override
  State<WebExamListScreen> createState() => _WebExamListScreenState();
}

class _WebExamListScreenState extends State<WebExamListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late ExamController controller;

  @override
  void initState() {
    super.initState();
    try {
      controller = Get.find<ExamController>();
    } catch (e) {
      controller = Get.put(ExamController(), permanent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = WebResponsiveUtils.isDesktop(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: WebAppBar(
        title: 'Exams',
        onMenuPressed:
            isDesktop ? null : () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer:
          !isDesktop
              ? Drawer(child: WebSidebar(currentRoute: WebRoutes.exams))
              : null,
      body: Row(
        children: [
          if (isDesktop) const WebSidebar(currentRoute: WebRoutes.exams),
          Expanded(
            child: Container(
              color: WebTheme.backgroundLight,
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const WebCardSkeletonGrid();
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
          onRefresh: () => controller.refreshExams(),
          child: SingleChildScrollView(
            padding: WebResponsiveUtils.getResponsivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                if (controller.exams.isEmpty)
                  _buildEmptyState()
                else
                  _buildExamGrid(context),
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
            const Text('Your Exams', style: WebTheme.headingLarge),
            IconButton(
              icon: const Icon(Icons.refresh, color: WebTheme.primaryGreen),
              onPressed: () => controller.refreshExams(),
              tooltip: 'Refresh',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(
          () => Text(
            controller.currentInstructorUid.value.isNotEmpty
                ? 'Showing exams from ${controller.currentInstructorName.value}'
                : 'All exams across your courses',
            style: WebTheme.bodyMedium.copyWith(color: WebTheme.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildExamGrid(BuildContext context) {
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
      itemCount: controller.exams.length,
      itemBuilder: (context, index) {
        final exam = controller.exams[index];
        return _buildExamCard(exam);
      },
    );
  }

  Widget _buildExamCard(Map<String, dynamic> exam) {
    final examId = exam['id']?.toString() ?? '';
    final status = controller.submissionStatus[examId] ?? 'not_submitted';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          controller.setSelectedExam(exam);
          Get.to(() => WebExamDetailScreen(exam: exam));
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
                      color: const Color(0xFFEF6C00).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.fact_check_outlined,
                      color: Color(0xFFEF6C00),
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  _buildStatusBadge(status, exam['dueDate']),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                exam['title'] ?? 'No Title',
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
                      'Due: ${controller.getDueDateFormatted(exam['dueDate'])}',
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

    final isPastDue =
        status.toLowerCase() == 'not_submitted' &&
        DueDateUtils.isPastDue(dueDate);

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
        badgeColor = isPastDue ? Colors.red : Colors.grey;
        badgeText = isPastDue ? 'Closed' : 'Pending';
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
            Icon(Icons.fact_check_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 24),
            const Text('No exams found', style: WebTheme.headingMedium),
            const SizedBox(height: 8),
            Text(
              'Your exams will appear here once assigned by your instructor.',
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
}

extension on ExamController {
  String getDueDateFormatted(dynamic dueDate) {
    if (dueDate == null) return 'No due date';

    try {
      DateTime date;

      if (dueDate is Timestamp) {
        date = dueDate.toDate();
      } else if (dueDate is DateTime) {
        date = dueDate;
      } else if (dueDate is String) {
        if (dueDate.isEmpty) return 'No due date';
        if (dueDate.contains('at') &&
            (dueDate.contains('AM') || dueDate.contains('PM'))) {
          return dueDate.replaceAll(' UTC+8', '').replaceAll(' UTC', '');
        }
        return dueDate;
      } else if (dueDate is int) {
        date = DateTime.fromMillisecondsSinceEpoch(dueDate);
      } else {
        return 'No due date';
      }

      const months = [
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
      if (dueDate is String && dueDate.isNotEmpty) return dueDate;
      return 'No due date';
    }
  }
}
