import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../user/leaderboard/leaderboard_controller.dart';
import '../../config/web_theme.dart';
import '../../config/web_routes.dart';
import '../../utils/web_responsive_utils.dart';
import '../../widgets/layout/web_app_bar.dart';
import '../../widgets/layout/web_sidebar.dart';

class WebLeaderboardScreen extends StatefulWidget {
  const WebLeaderboardScreen({super.key});

  @override
  State<WebLeaderboardScreen> createState() => _WebLeaderboardScreenState();
}

class _WebLeaderboardScreenState extends State<WebLeaderboardScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late LeaderboardController controller;
  late TabController _tabController;
  final List<String> _categories = [
    'All',
    'Quizzes',
    'Activities',
    'PIT',
    'Assignments',
  ];

  @override
  void initState() {
    super.initState();
    controller = Get.put(LeaderboardController());
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = WebResponsiveUtils.isDesktop(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: WebAppBar(
        title: 'Leaderboard',
        onMenuPressed:
            isDesktop ? null : () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer:
          !isDesktop
              ? Drawer(child: WebSidebar(currentRoute: WebRoutes.leaderboard))
              : null,
      body: Row(
        children: [
          if (isDesktop) const WebSidebar(currentRoute: WebRoutes.leaderboard),
          Expanded(
            child: Container(
              color: WebTheme.backgroundLight,
              child: _buildContent(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Column(
          children: [_buildHeader(), Expanded(child: _buildLeaderboardBody())],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        children: [
          const Text(
            'Quest Champions',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: WebTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'See who is leading the green journey!',
            style: TextStyle(color: WebTheme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 32),
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: WebTheme.borderLight),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: WebTheme.primaryGreen.withOpacity(0.1),
              ),
              labelColor: WebTheme.primaryGreen,
              unselectedLabelColor: WebTheme.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: _categories.map((cat) => Tab(text: cat)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardBody() {
    return Obx(() {
      if (controller.isLoadingLeaderboard.value) {
        return const Center(
          child: CircularProgressIndicator(color: WebTheme.primaryGreen),
        );
      }

      return TabBarView(
        controller: _tabController,
        children:
            _categories
                .map((category) => _buildCategoryList(category))
                .toList(),
      );
    });
  }

  Widget _buildCategoryList(String category) {
    final topThree = controller.getTopThree(category);
    final remaining = controller.getRemainingStudents(category);

    if (topThree.isEmpty && remaining.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => controller.refreshLeaderboard(),
      color: WebTheme.primaryGreen,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildPodium(topThree),
          const SizedBox(height: 32),
          ...remaining.asMap().entries.map(
            (entry) => _buildRankItem(entry.value, entry.key + 4),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> topThree) {
    if (topThree.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (topThree.length >= 2) _buildPodiumSpot(topThree[1], 2, 160),
          const SizedBox(width: 16),
          _buildPodiumSpot(topThree[0], 1, 200),
          const SizedBox(width: 16),
          if (topThree.length >= 3) _buildPodiumSpot(topThree[2], 3, 140),
        ],
      ),
    );
  }

  Widget _buildPodiumSpot(
    Map<String, dynamic> student,
    int rank,
    double height,
  ) {
    Color rankColor =
        rank == 1
            ? Colors.amber
            : (rank == 2 ? Colors.blueGrey.shade300 : Colors.brown.shade300);

    return Column(
      children: [
        _buildAvatar(student, 80, rankColor, showBadge: true, rank: rank),
        const SizedBox(height: 12),
        Text(
          student['name'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${student['points']} pts',
          style: TextStyle(
            color: WebTheme.primaryGreen,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 80,
          height: height - 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [rankColor.withOpacity(0.8), rankColor.withOpacity(0.4)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Center(
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(
    Map<String, dynamic> student,
    double size,
    Color borderColor, {
    bool showBadge = false,
    int rank = 0,
  }) {
    String? imageUrl = student['profileImageUrl'];
    String initials = student['initials'] ?? 'U';

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 3),
          ),
          child: CircleAvatar(
            radius: size / 2,
            backgroundColor: WebTheme.primaryGreen.withOpacity(0.1),
            backgroundImage:
                imageUrl != null && imageUrl.isNotEmpty
                    ? NetworkImage(imageUrl)
                    : null,
            child:
                imageUrl == null || imageUrl.isEmpty
                    ? Text(
                      initials,
                      style: TextStyle(
                        fontSize: size * 0.4,
                        fontWeight: FontWeight.bold,
                        color: WebTheme.primaryGreen,
                      ),
                    )
                    : null,
          ),
        ),
        if (showBadge)
          Positioned(
            bottom: -10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                Icons.workspace_premium,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRankItem(Map<String, dynamic> student, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WebTheme.borderLight),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '$rank',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: WebTheme.textSecondary,
                fontSize: 16,
              ),
            ),
          ),
          _buildAvatar(student, 40, Colors.transparent),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  student['class'] ?? 'General',
                  style: TextStyle(color: WebTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            '${student['points']} pts',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: WebTheme.primaryGreen,
            ),
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
            Icons.emoji_events_outlined,
            size: 80,
            color: WebTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No champions yet!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: WebTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Be the first one to climb the leaderboard!'),
        ],
      ),
    );
  }
}
