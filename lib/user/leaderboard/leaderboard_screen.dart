import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/login/custom_drawer.dart';
import 'leaderboard_controller.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  int selectedDrawerIndex = 3;
  late TabController _tabController;
  LeaderboardController? leaderboardController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    leaderboardController = Get.put(LeaderboardController());

    // Add listener to refresh data when tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {}); // Trigger rebuild to update the displayed data
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = ['All', 'Quizzes', 'Activities'];
    final selectedTab = tabs[_tabController.index];
    return Scaffold(
      drawer: CustomDrawer(
        selectedIndex: selectedDrawerIndex,
        onSelect: (i) {
          setState(() => selectedDrawerIndex = i);
          Navigator.pop(context);
        },
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.black),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        title: const Text(
          'Leaderboard',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body:
          leaderboardController == null
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF34A853)),
                ),
              )
              : Obx(() {
                if (leaderboardController!.isLoadingLeaderboard.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF34A853),
                      ),
                    ),
                  );
                }

                final topThree = leaderboardController!.getTopThree(
                  selectedTab,
                );
                final remainingStudents = leaderboardController!
                    .getRemainingStudents(selectedTab);

                return Column(
                  children: [
                    const SizedBox(height: 18),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: TabBar(
                          controller: _tabController,
                          indicator: const UnderlineTabIndicator(
                            borderSide: BorderSide(
                              color: Color(0xFF34A853),
                              width: 3,
                            ),
                          ),
                          labelColor: const Color(0xFF34A853),
                          unselectedLabelColor: Colors.black54,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                          tabs: const [
                            Tab(text: 'All'),
                            Tab(text: 'Quizzes'),
                            Tab(text: 'Activities'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Top 3 Podium
                    _buildPodium(topThree),
                    const SizedBox(height: 24),
                    // Remaining students list
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                          border: Border.fromBorderSide(
                            BorderSide(color: Colors.black12),
                          ),
                        ),
                        child:
                            remainingStudents.isEmpty
                                ? const Center(
                                  child: Text(
                                    'No students found',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                                : ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  itemCount: remainingStudents.length,
                                  itemBuilder: (context, i) {
                                    final student = remainingStudents[i];
                                    return _buildStudentItem(student, i + 4);
                                  },
                                ),
                      ),
                    ),
                  ],
                );
              }),
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> topThree) {
    // Ensure we have at least 3 students, pad with empty data if needed
    final paddedTopThree = List<Map<String, dynamic>>.from(topThree);
    while (paddedTopThree.length < 3) {
      paddedTopThree.add({
        'name': 'No Student',
        'points': 0,
        'profileImageUrl': 'assets/images/Avatar.png',
      });
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 2nd place
        _buildPodiumItem(paddedTopThree[1], 2, 130),
        const SizedBox(width: 18),
        // 1st place
        _buildPodiumItem(paddedTopThree[0], 1, 190),
        const SizedBox(width: 18),
        // 3rd place
        _buildPodiumItem(paddedTopThree[2], 3, 130),
      ],
    );
  }

  Widget _buildPodiumItem(
    Map<String, dynamic> student,
    int rank,
    double height,
  ) {
    final isPlaceholder = student['name'] == 'No Student';
    final name = student['name'] as String;
    final points = student['points'] as int;
    final profileImageUrl = student['profileImageUrl'] as String?;
    final initials = student['initials'] as String?;

    return Column(
      children: [
        SizedBox(
          height: height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              Image.asset(
                _getBackgroundImage(rank),
                width: rank == 1 ? 120 : 100,
              ),
              // Profile image
              CircleAvatar(
                radius: rank == 1 ? 54 : 45,
                backgroundColor:
                    isPlaceholder ||
                            profileImageUrl == null ||
                            profileImageUrl.isEmpty
                        ? const Color(0xFF34A853)
                        : null,
                backgroundImage:
                    isPlaceholder
                        ? null
                        : profileImageUrl != null && profileImageUrl.isNotEmpty
                        ? (profileImageUrl.startsWith('http')
                            ? NetworkImage(profileImageUrl) as ImageProvider
                            : AssetImage(profileImageUrl))
                        : null,
                child:
                    isPlaceholder ||
                            profileImageUrl == null ||
                            profileImageUrl.isEmpty
                        ? Text(
                          initials ?? 'U',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: rank == 1 ? 24 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                        : null,
              ),
              // Crown for 1st place
              if (rank == 1)
                Positioned(
                  top: -7,
                  child: Image.asset(
                    'assets/images/image 310 (1).png',
                    width: 60,
                  ),
                ),
              // Medal for other ranks
              if (rank != 1)
                Positioned(
                  bottom: -5,
                  child: Image.asset(_getMedalImage(rank), width: 45),
                ),
            ],
          ),
        ),
        SizedBox(height: rank == 1 ? 10 : 8),
        SizedBox(
          width: 90,
          child: Column(
            children: [
              Text(
                isPlaceholder ? 'No Student' : name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                softWrap: true,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '$points pts',
                style: const TextStyle(color: Colors.black54, fontSize: 13),
                softWrap: true,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentItem(Map<String, dynamic> student, int rank) {
    final name = student['name'] as String;
    final points = student['points'] as int;
    final profileImageUrl = student['profileImageUrl'] as String?;
    final initials = student['initials'] as String?;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '#$rank',
                style: const TextStyle(
                  color: Colors.black38,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            CircleAvatar(
              backgroundColor:
                  profileImageUrl == null || profileImageUrl.isEmpty
                      ? const Color(0xFF34A853)
                      : null,
              backgroundImage:
                  profileImageUrl != null && profileImageUrl.isNotEmpty
                      ? (profileImageUrl.startsWith('http')
                          ? NetworkImage(profileImageUrl) as ImageProvider
                          : AssetImage(profileImageUrl))
                      : null,
              radius: 30,
              child:
                  profileImageUrl == null || profileImageUrl.isEmpty
                      ? Text(
                        initials ?? 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                      : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$points pts',
              style: const TextStyle(
                color: Color(0xFF34A853),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getBackgroundImage(int rank) {
    switch (rank) {
      case 1:
        return 'assets/images/Ellipse 91.png';
      case 2:
        return 'assets/images/Ellipse 97.png';
      case 3:
        return 'assets/images/Ellipse 100.png';
      default:
        return 'assets/images/Ellipse 100.png';
    }
  }

  String _getMedalImage(int rank) {
    switch (rank) {
      case 2:
        return 'assets/images/Group 1171274949.png';
      case 3:
        return 'assets/images/Group 1171274949 (1).png';
      default:
        return 'assets/images/Group 1171274949.png';
    }
  }
}
