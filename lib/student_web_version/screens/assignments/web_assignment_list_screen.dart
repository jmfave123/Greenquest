import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../user/submit/assignment/assignment_controller.dart';
import 'web_assignment_detail_screen.dart';
import '../../config/web_theme.dart';
import '../../config/web_routes.dart';
import '../../utils/web_responsive_utils.dart';
import '../../widgets/layout/web_app_bar.dart';
import '../../widgets/layout/web_sidebar.dart';
import '../../../shared/widgets/skeleton_loading.dart';

class WebAssignmentListScreen extends StatefulWidget {
  const WebAssignmentListScreen({super.key});

  @override
  State<WebAssignmentListScreen> createState() =>
      _WebAssignmentListScreenState();
}

class _WebAssignmentListScreenState extends State<WebAssignmentListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AssignmentController controller;

  @override
  void initState() {
    super.initState();
    try {
      controller = Get.find<AssignmentController>();
    } catch (e) {
      controller = Get.put(AssignmentController(), permanent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = WebResponsiveUtils.isDesktop(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: WebAppBar(
        title: 'Assignments',
        onMenuPressed:
            isDesktop ? null : () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer:
          !isDesktop
              ? Drawer(child: WebSidebar(currentRoute: WebRoutes.assignments))
              : null,
      body: Row(
        children: [
          if (isDesktop) const WebSidebar(currentRoute: WebRoutes.assignments),
          Expanded(
            child: Container(
              color: WebTheme.backgroundLight,
              child: Obx(() {
                if (controller.isLoading.value &&
                    controller.assignments.isEmpty) {
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
          onRefresh: () => controller.refreshAssignments(),
          child: SingleChildScrollView(
            padding: WebResponsiveUtils.getResponsivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                if (controller.assignments.isEmpty)
                  _buildEmptyState()
                else
                  _buildAssignmentGrid(context),
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
            const Text('Your Assignments', style: WebTheme.headingLarge),
            IconButton(
              icon: const Icon(Icons.refresh, color: WebTheme.primaryGreen),
              onPressed: () => controller.refreshAssignments(),
              tooltip: 'Refresh',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(
          () => Text(
            controller.currentInstructorUid.value.isNotEmpty
                ? 'Showing assignments from ${controller.currentInstructorName.value}'
                : 'All assignments across your courses',
            style: WebTheme.bodyMedium.copyWith(color: WebTheme.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildAssignmentGrid(BuildContext context) {
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
      itemCount: controller.assignments.length,
      itemBuilder: (context, index) {
        final assignment = controller.assignments[index];
        return _buildAssignmentCard(assignment);
      },
    );
  }

  Widget _buildAssignmentCard(Map<String, dynamic> assignment) {
    final assignmentId = assignment['id']?.toString() ?? '';
    final status = controller.submissionStatus[assignmentId] ?? 'not_submitted';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          controller.setSelectedAssignment(assignment);
          Get.to(() => WebAssignmentDetailScreen(assignment: assignment));
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
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.task,
                      color: Colors.orange,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  _buildStatusBadge(status, assignment['dueDate']),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                assignment['title'] ?? 'No Title',
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
                      'Due: ${controller.getDueDateFormatted(assignment['dueDate'])}',
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

    bool isPastDue = false;
    if (status.toLowerCase() == 'not_submitted' && dueDate != null) {
      try {
        DateTime? dueDatetime;
        if (dueDate is Timestamp) {
          dueDatetime = dueDate.toDate();
        } else if (dueDate is DateTime) {
          dueDatetime = dueDate;
        }

        if (dueDatetime != null) {
          isPastDue = DateTime.now().isAfter(dueDatetime);
        }
      } catch (e) {}
    }

    switch (status.toLowerCase()) {
      case 'submitted':
        badgeColor = Colors.blue;
        badgeText = 'Submitted';
        break;
      case 'graded':
        badgeColor = WebTheme.primaryGreen;
        badgeText = 'Graded';
        break;
      case 'needs_revision':
        badgeColor = Colors.orange;
        badgeText = 'Revise';
        break;
      default:
        badgeColor = isPastDue ? Colors.red : Colors.grey;
        badgeText = isPastDue ? 'Late' : 'Pending';
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
            Icon(Icons.task_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 24),
            const Text('No assignments found', style: WebTheme.headingMedium),
            const SizedBox(height: 8),
            Text(
              'Your assignments will appear here once assigned by your instructor.',
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

extension on AssignmentController {
  String getDueDateFormatted(dynamic dueDate) {
    if (dueDate == null) return 'No due date';

    try {
      DateTime date;

      if (dueDate is Timestamp) {
        date = dueDate.toDate();
      } else if (dueDate is DateTime) {
        date = dueDate;
      } else if (dueDate is String) {
        // Parse custom format: "Feb 11, 2026 11:00 AM"
        date = _parseCustomDateString(dueDate);
      } else if (dueDate is int) {
        date = DateTime.fromMillisecondsSinceEpoch(dueDate);
      } else {
        return 'No due date';
      }

      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];

      // Format time
      final hour =
          date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final minute = date.minute.toString().padLeft(2, '0');
      final second = date.second.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';

      // Get timezone offset
      final offset = date.timeZoneOffset;
      final offsetHours = offset.inHours;
      final timezone = 'UTC${offsetHours >= 0 ? '+' : ''}$offsetHours';

      return '${months[date.month - 1]} ${date.day}, ${date.year} at $hour:$minute:$second $period $timezone';
    } catch (e) {
      return 'No due date';
    }
  }

  DateTime _parseCustomDateString(String dateStr) {
    // Parse format: "Feb 11, 2026 11:00 AM"
    final monthMap = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };

    final parts = dateStr.split(' ');
    if (parts.length < 4) throw FormatException('Invalid date format');

    final month = monthMap[parts[0]] ?? 1;
    final day = int.parse(parts[1].replaceAll(',', ''));
    final year = int.parse(parts[2]);
    final timeParts = parts[3].split(':');
    var hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final period = parts.length > 4 ? parts[4] : 'AM';

    // Convert to 24-hour format
    if (period == 'PM' && hour != 12) {
      hour += 12;
    } else if (period == 'AM' && hour == 12) {
      hour = 0;
    }

    return DateTime(year, month, day, hour, minute);
  }
}
