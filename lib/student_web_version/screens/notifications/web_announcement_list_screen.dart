import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/web_theme.dart';
import '../../config/web_routes.dart';
import '../../utils/web_responsive_utils.dart';
import '../../widgets/layout/web_app_bar.dart';
import '../../widgets/layout/web_sidebar.dart';
import '../../../user/notification/announcement_controller.dart';
import '../../widgets/web_card_skeleton.dart';

class WebAnnouncementListScreen extends StatelessWidget {
  const WebAnnouncementListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserAnnouncementController>();
    final isDesktop = WebResponsiveUtils.isDesktop(context);
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      appBar: WebAppBar(
        title: 'Announcements',
        onMenuPressed:
            isDesktop ? null : () => scaffoldKey.currentState?.openDrawer(),
      ),
      drawer:
          !isDesktop
              ? Drawer(child: WebSidebar(currentRoute: WebRoutes.announcements))
              : null,
      body: Row(
        children: [
          if (isDesktop)
            const WebSidebar(currentRoute: WebRoutes.announcements),
          Expanded(
            child: Container(
              color: WebTheme.backgroundLight,
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const WebAnnouncementSkeletonView();
                }

                if (controller.selectedInstructorId.value.isEmpty) {
                  return _buildNoInstructorState();
                }

                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: controller.getAnnouncementsStream(
                    controller.selectedInstructorId.value,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.data == null) {
                      return const WebAnnouncementSkeletonView();
                    }

                    final announcements = snapshot.data ?? [];

                    if (announcements.isEmpty) {
                      return _buildEmptyState();
                    }

                    return _buildAnnouncementList(
                      context,
                      announcements,
                      controller,
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementList(
    BuildContext context,
    List<Map<String, dynamic>> announcements,
    UserAnnouncementController controller,
  ) {
    return SingleChildScrollView(
      padding: WebResponsiveUtils.getResponsivePadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(controller),
              const SizedBox(height: 24),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: announcements.length,
                separatorBuilder:
                    (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final announcement = announcements[index];
                  return _buildAnnouncementCard(
                    context,
                    announcement,
                    controller,
                  );
                },
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(UserAnnouncementController controller) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Latest Updates',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: WebTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Stay informed about your classes and school broadcasts.',
                style: TextStyle(
                  fontSize: 16,
                  color: WebTheme.textSecondary.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => controller.forceReload(),
          icon: const Icon(Icons.refresh, color: WebTheme.primaryGreen),
          tooltip: 'Refresh Announcements',
        ),
      ],
    );
  }

  Widget _buildAnnouncementCard(
    BuildContext context,
    Map<String, dynamic> announcement,
    UserAnnouncementController controller,
  ) {
    final bool isUrgent = announcement['urgent'] ?? false;
    final bool isPinned = announcement['pinned'] ?? false;
    final String imageUrl = announcement['imageUrl'] ?? '';

    return InkWell(
      onTap: () {
        controller.updateViews(announcement['id']);
        _showDetailDialog(context, announcement);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isUrgent ? Colors.red.withOpacity(0.3) : WebTheme.borderLight,
            width: isUrgent ? 1.5 : 1,
          ),
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
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isPinned)
                        _buildBadge(Icons.push_pin, 'Pinned', Colors.orange),
                      if (isUrgent)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _buildBadge(
                            Icons.warning_amber,
                            'Urgent',
                            Colors.red,
                          ),
                        ),
                      const Spacer(),
                      Text(
                        announcement['date'] ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          color: WebTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    announcement['title'] ?? 'Untitled Announcement',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: WebTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    announcement['content'] ?? '',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      color: WebTheme.textPrimary.withOpacity(0.8),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: WebTheme.primaryGreen.withOpacity(0.1),
                        backgroundImage:
                            announcement['instructorProfileUrl']?.isNotEmpty ==
                                    true
                                ? NetworkImage(
                                  announcement['instructorProfileUrl'],
                                )
                                : null,
                        child:
                            announcement['instructorProfileUrl']?.isEmpty ==
                                    true
                                ? const Icon(
                                  Icons.person,
                                  size: 16,
                                  color: WebTheme.primaryGreen,
                                )
                                : null,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        announcement['instructorName'] ?? 'Instructor',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: WebTheme.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.visibility_outlined,
                        size: 16,
                        color: WebTheme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${announcement['views'] ?? 0}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: WebTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Read More',
                        style: TextStyle(
                          color: WebTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: WebTheme.primaryGreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoInstructorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search_outlined,
            size: 80,
            color: WebTheme.textSecondary.withOpacity(0.2),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Instructor Selected',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: WebTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Please select an instructor from your home dashboard to see announcements.',
            style: TextStyle(fontSize: 16, color: WebTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 80,
            color: WebTheme.textSecondary.withOpacity(0.2),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Announcements Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: WebTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Check back later for updates from your instructor.',
            style: TextStyle(fontSize: 16, color: WebTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(
    BuildContext context,
    Map<String, dynamic> announcement,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (announcement['imageUrl']?.isNotEmpty == true)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child: Image.network(
                          announcement['imageUrl'],
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                announcement['date'] ?? '',
                                style: const TextStyle(
                                  color: WebTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close),
                                color: WebTheme.textSecondary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            announcement['title'] ?? '',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: WebTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            announcement['content'] ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              color: WebTheme.textPrimary,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Divider(),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage:
                                    announcement['instructorProfileUrl']
                                                ?.isNotEmpty ==
                                            true
                                        ? NetworkImage(
                                          announcement['instructorProfileUrl'],
                                        )
                                        : null,
                                child:
                                    announcement['instructorProfileUrl']
                                                ?.isEmpty ==
                                            true
                                        ? const Icon(Icons.person)
                                        : null,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    announcement['instructorName'] ??
                                        'Instructor',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const Text(
                                    'Class Instructor',
                                    style: TextStyle(
                                      color: WebTheme.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
