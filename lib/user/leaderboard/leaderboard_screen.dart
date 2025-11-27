import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/login/custom_drawer.dart';
import 'leaderboard_controller.dart';
import 'package:greenquest/shared/widgets/skeleton_loading.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  int selectedDrawerIndex = 3;
  LeaderboardController? leaderboardController;

  @override
  void initState() {
    super.initState();
    leaderboardController = Get.put(LeaderboardController());
  }

  @override
  Widget build(BuildContext context) {
    final selectedTab = 'All';
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
              ? _buildSkeletonLoading()
              : Obx(() {
                if (leaderboardController!.isLoadingLeaderboard.value) {
                  return _buildSkeletonLoading();
                }

                final topThree = leaderboardController!.getTopThree(
                  selectedTab,
                );
                final remainingStudents = leaderboardController!
                    .getRemainingStudents(selectedTab);

                return RefreshIndicator(
                  onRefresh: () async {
                    await leaderboardController!.refreshLeaderboard();
                  },
                  color: const Color(0xFF34A853),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            _buildPodium(topThree),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                      SliverFillRemaining(
                        hasScrollBody: true,
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
                  ),
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

  Widget _buildSkeletonLoading() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const SkeletonLeaderboardPodium(),
        const SizedBox(height: 24),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              border: Border.fromBorderSide(BorderSide(color: Colors.black12)),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: 5,
              itemBuilder: (context, i) => const SkeletonLeaderboardItem(),
            ),
          ),
        ),
      ],
    );
  }
}
