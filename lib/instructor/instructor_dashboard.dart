import 'package:flutter/material.dart';
import 'package:greenquest/instructor/instructor_dashboard_controller.dart';
import 'package:greenquest/instructor/create/create_controller.dart';
import 'package:greenquest/instructor/submissions/submissions_controller.dart';
import '../shared/instructor/instructor_appbar.dart';
import '../shared/instructor/instructor_sidebar.dart';
import '../shared/instructor/instructor_navigation_constants.dart';
import '../shared/widgets/safe_asset_image.dart';
import '../shared/widgets/skeleton_loading.dart';
import 'package:get/get.dart';

class InstructorDashboardScreen extends StatefulWidget {
  const InstructorDashboardScreen({super.key});

  @override
  State<InstructorDashboardScreen> createState() =>
      _InstructorDashboardScreenState();
}

class _InstructorDashboardScreenState extends State<InstructorDashboardScreen> {
  final InstructorController instructorController = Get.put(
    InstructorController(),
  );
  final CreateController createController = Get.put(CreateController());
  final SubmissionsController submissionsController = Get.put(
    SubmissionsController(),
  );
  InstructorNavigationItem _selectedItem = InstructorNavigationItem.dashboard;

  void _handleNavigationSelect(InstructorNavigationItem item) {
    setState(() {
      _selectedItem = item;
    });
    String route = InstructorNavigationHelper.getRoute(item);
    Navigator.of(context).pushNamed(route);
  }

  @override
  void initState() {
    super.initState();
    // Removed auto-loading - data will load only when user explicitly requests it
    // Set up real-time listener for all submissions (this is lightweight)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      submissionsController.setupAllSubmissionsRealtimeListener();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          InstructorSidebar(
            selectedItem: _selectedItem,
            onItemSelected: _handleNavigationSelect,
          ),
          Expanded(
            child: Column(
              children: [
                Obx(
                  () => InstructorAppBar(
                    instructorName: instructorController.instructorName.value,
                    instructorRole: 'Instructor',
                    profileImageUrl: instructorController.profileImageUrl.value,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome, Instructor!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Manage your classes  and track environmental impact through education',
                          style: TextStyle(color: Colors.black38, fontSize: 15),
                        ),
                        const SizedBox(height: 28),
                        // Dynamic Statistics Cards
                        Obx(
                          () =>
                              instructorController.isLoadingStats.value
                                  ? const Row(
                                    children: [
                                      SkeletonInstructorStatCard(),
                                      SizedBox(width: 18),
                                      SkeletonInstructorStatCard(),
                                      SizedBox(width: 18),
                                      SkeletonInstructorStatCard(),
                                    ],
                                  )
                                  : Row(
                                    children: [
                                      _StatCard(
                                        image:
                                            'assets/instructor/images/image 377.png',
                                        label: 'Students',
                                        value:
                                            instructorController
                                                .studentCount
                                                .value
                                                .toString(),
                                        borderColor: const Color(0xFF2563EB),
                                        iconBg: const Color(0xFFE8F0FE),
                                      ),
                                      const SizedBox(width: 18),
                                      _StatCard(
                                        image:
                                            'assets/instructor/images/image 378.png',
                                        label: 'Planted Trees',
                                        value:
                                            instructorController
                                                .plantedTreesCount
                                                .value
                                                .toString(),
                                        borderColor: const Color(0xFF22C55E),
                                        iconBg: const Color(0xFFE6F7EC),
                                      ),
                                      const SizedBox(width: 18),
                                      _StatCard(
                                        image:
                                            'assets/instructor/images/image 379.png',
                                        label: 'Active Classes',
                                        value:
                                            instructorController
                                                .activeClassesCount
                                                .value
                                                .toString(),
                                        borderColor: const Color(0xFFF59E42),
                                        iconBg: const Color(0xFFFFF7E6),
                                      ),
                                    ],
                                  ),
                        ),
                        const SizedBox(height: 28),
                        // Dynamic Leaderboard - only show if instructor has classes
                        Obx(() {
                          // Don't show leaderboard if instructor has no classes
                          if (instructorController.activeClassesCount.value ==
                              0) {
                            return const SizedBox.shrink();
                          }
                          // Show loading skeleton or leaderboard card
                          return instructorController.isLoadingLeaderboard.value
                              ? const SkeletonInstructorLeaderboardCard()
                              : _LeaderboardCard();
                        }),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String image;
  final String label;
  final String value;
  final Color borderColor;
  final Color iconBg;
  const _StatCard({
    required this.image,
    required this.label,
    required this.value,
    required this.borderColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: borderColor, width: 5),
            top: BorderSide(color: borderColor),
            right: BorderSide(color: borderColor),
            bottom: BorderSide(color: borderColor),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SafeAssetImage(assetPath: image, height: 80),
            const SizedBox(width: 20),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black38,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// class _StudentProgressCard extends StatefulWidget {
//   @override
//   State<_StudentProgressCard> createState() => _StudentProgressCardState();
// }

// class _StudentProgressCardState extends State<_StudentProgressCard> {
//   final List<String> months = [
//     'January',
//     'February',
//     'March',
//     'April',
//     'May',
//     'June',
//     'July',
//     'August',
//     'September',
//     'October',
//     'November',
//     'December',
//   ];
//   int selectedMonth = 8; // September (0-based)
//   int selectedYear = 2025;

//   // Mock data for each month/year
//   Map<String, List<double>> barData = {
//     '2025-9': [0.33, 0.22, 0.17, 0.58],
//     '2025-8': [0.28, 0.19, 0.15, 0.45],
//     '2025-7': [0.25, 0.18, 0.13, 0.40],
//   };
//   Map<String, List<double>> lineData = {
//     '2025-9': [0.37, 0.25, 0.20, 0.58],
//     '2025-8': [0.32, 0.22, 0.18, 0.45],
//     '2025-7': [0.30, 0.20, 0.15, 0.40],
//   };

//   void _changeMonth(int delta) {
//     setState(() {
//       selectedMonth += delta;
//       if (selectedMonth < 0) {
//         selectedMonth = 11;
//         selectedYear--;
//       } else if (selectedMonth > 11) {
//         selectedMonth = 0;
//         selectedYear++;
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     String key = '${selectedYear}-${selectedMonth + 1}';
//     final bars = barData[key] ?? [0.33, 0.22, 0.17, 0.58];
//     final line = lineData[key] ?? [0.37, 0.25, 0.20, 0.58];
//     final labels = ['BSIT-1A', 'BFT-1B', 'IA-1C', 'ICT-1D'];
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: [
//           BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 'Student  Progress',
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//               ),
//               Row(
//                 children: [
//                   IconButton(
//                     icon: const Icon(
//                       Icons.chevron_left,
//                       size: 22,
//                       color: Colors.black38,
//                     ),
//                     onPressed: () => _changeMonth(-1),
//                   ),
//                   Text(
//                     months[selectedMonth],
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 15,
//                       color: Colors.black54,
//                     ),
//                   ),
//                   IconButton(
//                     icon: const Icon(
//                       Icons.chevron_right,
//                       size: 22,
//                       color: Colors.black38,
//                     ),
//                     onPressed: () => _changeMonth(1),
//                   ),
//                   const SizedBox(width: 10),
//                   Container(
//                     width: 10,
//                     height: 10,
//                     decoration: const BoxDecoration(
//                       color: Color(0xFF22C55E),
//                       shape: BoxShape.circle,
//                     ),
//                   ),
//                   const SizedBox(width: 6),
//                   Text(
//                     '$selectedYear',
//                     style: const TextStyle(
//                       color: Color(0xFF22C55E),
//                       fontWeight: FontWeight.bold,
//                       fontSize: 14,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           const SizedBox(height: 18),
//           SizedBox(
//             height: 300,
//             width: double.infinity,
//             child: CustomPaint(
//               painter: _BarLineChartPainter(
//                 bars: bars,
//                 line: line,
//                 labels: labels,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

class _LeaderboardCard extends StatefulWidget {
  @override
  State<_LeaderboardCard> createState() => _LeaderboardCardState();
}

class _LeaderboardCardState extends State<_LeaderboardCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Leaderboard\nTop 10',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 290,
            child: Scrollbar(
              thumbVisibility: true,
              radius: const Radius.circular(8),
              thickness: 6,
              child: Obx(() {
                final instructorController = Get.find<InstructorController>();
                final leaderboard =
                    instructorController.leaderboardData['Total'] ?? [];

                return ListView.builder(
                  itemCount: 10,
                  itemBuilder: (context, i) {
                    Widget? leading;
                    Color? bgColor;
                    Color? borderColor;
                    Color? nameColor = Colors.black;
                    String name = '';
                    String className = '';
                    int points = 0;
                    bool isPlaceholder = i >= leaderboard.length;

                    if (!isPlaceholder) {
                      final entry = leaderboard[i];
                      name = entry['name'] as String;
                      className = entry['class'] as String;
                      points = entry['points'] as int;
                    }

                    final bool isTop = i < 3 && !isPlaceholder;
                    if (isTop) {
                      bgColor = const Color(0xFFFFFDEB);
                      borderColor = Colors.transparent;
                      nameColor = Colors.black;
                      if (i == 0) {
                        leading = SafeAssetImage(
                          assetPath:
                              'assets/instructor/icons/stash_trophy-light.png',
                          width: 30,
                          height: 30,
                        );
                      } else if (i == 1) {
                        leading = SafeAssetImage(
                          assetPath:
                              'assets/instructor/icons/stash_trophy-light.png',
                          width: 30,
                          height: 30,
                          color: const Color(0xFFB6BBC4),
                        );
                      } else {
                        leading = SafeAssetImage(
                          assetPath:
                              'assets/instructor/icons/stash_trophy-light.png',
                          width: 30,
                          height: 30,
                          color: Color(0xFFCD7F32),
                        );
                      }
                    } else {
                      bgColor = const Color(0xFFF8FAFB);
                      borderColor = Colors.transparent;
                      nameColor = const Color(0xFFB6BBC4);
                      leading = Text(
                        '#${i + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB6BBC4),
                          fontSize: 18,
                        ),
                      );
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: Row(
                        children: [
                          leading,
                          const SizedBox(width: 14),
                          Expanded(
                            child:
                                isPlaceholder
                                    ? Container()
                                    : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: nameColor,
                                          ),
                                        ),
                                        Text(
                                          className,
                                          style: const TextStyle(
                                            color: Colors.black38,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                          ),
                          if (!isPlaceholder)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$points pts',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
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
}
