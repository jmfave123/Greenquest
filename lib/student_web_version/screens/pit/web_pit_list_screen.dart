import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../user/submit/pit/pit_controller.dart';
import 'web_pit_detail_screen.dart';
import '../../config/web_theme.dart';
import '../../config/web_routes.dart';
import '../../utils/web_responsive_utils.dart';
import '../../widgets/layout/web_app_bar.dart';
import '../../widgets/layout/web_sidebar.dart';
import '../../../core/utils/date_utils.dart';
import '../../widgets/web_card_skeleton.dart';

class WebPitListScreen extends StatefulWidget {
  const WebPitListScreen({super.key});

  @override
  State<WebPitListScreen> createState() => _WebPitListScreenState();
}

class _WebPitListScreenState extends State<WebPitListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late PitController controller;

  @override
  void initState() {
    super.initState();
    try {
      controller = Get.find<PitController>();
    } catch (e) {
      controller = Get.put(PitController());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = WebResponsiveUtils.isDesktop(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: WebAppBar(
        title: 'Performance Institutional Tasks',
        onMenuPressed:
            isDesktop ? null : () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer:
          !isDesktop
              ? Drawer(child: WebSidebar(currentRoute: WebRoutes.pits))
              : null,
      body: Row(
        children: [
          if (isDesktop) const WebSidebar(currentRoute: WebRoutes.pits),
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
          onRefresh: () => controller.refreshPits(),
          child: SingleChildScrollView(
            padding: WebResponsiveUtils.getResponsivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                if (controller.pits.isEmpty)
                  _buildEmptyState()
                else
                  _buildPitGrid(context),
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
            const Text('Your PITs', style: WebTheme.headingLarge),
            IconButton(
              icon: const Icon(Icons.refresh, color: WebTheme.primaryGreen),
              onPressed: () => controller.refreshPits(),
              tooltip: 'Refresh',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(
          () => Text(
            controller.currentInstructorUid.value.isNotEmpty
                ? 'Showing Performance Institutional Tasks from ${controller.currentInstructorName.value}'
                : 'All Performance Institutional Tasks across your courses',
            style: WebTheme.bodyMedium.copyWith(color: WebTheme.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildPitGrid(BuildContext context) {
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
      itemCount: controller.pits.length,
      itemBuilder: (context, index) {
        final pit = controller.pits[index];
        return _buildPitCard(pit);
      },
    );
  }

  Widget _buildPitCard(Map<String, dynamic> pit) {
    final pitId = pit['id']?.toString() ?? '';
    final status = controller.submissionStatus[pitId] ?? 'not_submitted';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          controller.setSelectedPit(pit);
          Get.to(() => WebPitDetailScreen(pit: pit));
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
                      color: const Color(0xFF34A853).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.engineering,
                      color: Color(0xFF34A853),
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  _buildStatusBadge(status, pit['dueDate']),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                pit['title'] ?? 'No Title',
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
                      'Due: ${_formatDisplayDate(pit['dueDate'])}',
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
      case 'needs_revision':
        badgeColor = Colors.orange;
        badgeText = 'Revise';
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

  String _formatDisplayDate(dynamic dateData) {
    if (dateData == null) return 'No due date';

    try {
      DateTime date;

      if (dateData is Timestamp) {
        date = dateData.toDate();
      } else if (dateData is DateTime) {
        date = dateData;
      } else if (dateData is String) {
        // Return pre-formatted strings directly.
        if (dateData.isEmpty) return 'No due date';
        // Handle Firebase server-formatted strings: "February 11, 2026 at 11:00:00 AM UTC+8"
        if (dateData.contains('at') &&
            (dateData.contains('AM') || dateData.contains('PM'))) {
          return dateData.replaceAll(' UTC+8', '').replaceAll(' UTC', '');
        }
        // For already-formatted strings like "Feb 28, 2026 11:00 AM"
        return dateData;
      } else if (dateData is int) {
        date = DateTime.fromMillisecondsSinceEpoch(dateData);
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
      if (dateData is String && (dateData as String).isNotEmpty)
        return dateData;
      return 'No due date';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            Icon(Icons.engineering_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 24),
            const Text('No PITs found', style: WebTheme.headingMedium),
            const SizedBox(height: 8),
            Text(
              'Your PITs will appear here once assigned by your instructor.',
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
