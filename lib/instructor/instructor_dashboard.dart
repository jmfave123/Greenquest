import 'package:flutter/material.dart';
import 'package:greenquest/instructor/instructor_dashboard_controller.dart';
import 'package:greenquest/instructor/create/create_controller.dart';
import '../shared/instructor/instructor_appbar.dart';
import '../shared/instructor/instructor_sidebar.dart';
import '../shared/instructor/instructor_navigation_constants.dart';
import '../shared/widgets/safe_asset_image.dart';
import 'package:get/get.dart';

class InstructorDashboardScreen extends StatefulWidget {
  const InstructorDashboardScreen({Key? key}) : super(key: key);

  @override
  State<InstructorDashboardScreen> createState() =>
      _InstructorDashboardScreenState();
}

class _InstructorDashboardScreenState extends State<InstructorDashboardScreen> {
  final InstructorController instructorController = Get.put(
    InstructorController(),
  );
  final CreateController createController = Get.put(CreateController());
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
    // Refresh created items when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      createController.loadCreatedItems();
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
                        Row(
                          children: [
                            _StatCard(
                              image: 'assets/instructor/images/image 377.png',
                              label: 'Students',
                              value: '153',
                              borderColor: const Color(0xFF2563EB),
                              iconBg: const Color(0xFFE8F0FE),
                            ),
                            const SizedBox(width: 18),
                            _StatCard(
                              image: 'assets/instructor/images/image 378.png',
                              label: 'Planted Tress',
                              value: '200',
                              borderColor: const Color(0xFF22C55E),
                              iconBg: const Color(0xFFE6F7EC),
                            ),
                            const SizedBox(width: 18),
                            _StatCard(
                              image: 'assets/instructor/images/image 379.png',
                              label: 'Active Class',
                              value: '4',
                              borderColor: const Color(0xFFF59E42),
                              iconBg: const Color(0xFFFFF7E6),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Expanded(child: _StudentProgressCard()),
                            // const SizedBox(width: 24),
                            Expanded(child: _LeaderboardCard()),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Created Items Section
                        _buildCreatedItemsSection(),
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

  Widget _buildCreatedItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Created Items',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.black,
              ),
            ),
            IconButton(
              onPressed: () {
                createController.loadCreatedItems();
              },
              icon: const Icon(Icons.refresh, color: Colors.black54),
              tooltip: 'Refresh created items',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Obx(
          () =>
              createController.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : createController.createdItems.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: createController.createdItems.length,
                    itemBuilder: (context, index) {
                      final item = createController.createdItems[index];
                      return _buildCreatedItemCard(item);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.description_outlined,
              size: 40,
              color: Colors.grey.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'This is where you\'ll sign work',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You can add assignments and other activities for the class.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCreatedItemCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Type Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF34A853).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                _getTypeIcon(item['type']),
                color: const Color(0xFF34A853),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item['type'],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    if (item['period'] != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item['period'],
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (item['topic'] != null &&
                        item['topic'].toString().isNotEmpty) ...[
                      Text(
                        'Topic: ',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        item['topic'].toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (item['points'] != null &&
                        item['points'].toString().isNotEmpty) ...[
                      Text(
                        'Points: ',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        item['points'].toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (item['dueDate'] != null &&
                        item['dueDate'].toString().isNotEmpty) ...[
                      Text(
                        'Due: ',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        item['dueDate'].toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Created: ',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black38,
                      ),
                    ),
                    Text(
                      item['createdAt']?.toString() ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black54, size: 20),
            onSelected: (value) {
              if (value == 'edit') {
                // Edit functionality - navigate to edit screen
                _navigateToEditScreen(item);
              } else if (value == 'delete') {
                // Show confirmation dialog
                _showDeleteDialog(item);
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18, color: Colors.black54),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Assignment':
        return Icons.assignment;
      case 'Activity':
        return Icons.assignment_turned_in;
      case 'Material':
        return Icons.description;
      case 'Quiz':
        return Icons.quiz_outlined;
      default:
        return Icons.description;
    }
  }

  void _navigateToEditScreen(Map<String, dynamic> item) {
    // This would navigate to the appropriate edit screen
    // For now, just show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${item['type']} functionality coming soon')),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text(
            'Are you sure you want to delete this ${item['type']}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                createController.deleteItem(item['id'], item['type']);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
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

class _BarLineChartPainter extends CustomPainter {
  final List<double> bars;
  final List<double> line; // will be ignored
  final List<String> labels;
  _BarLineChartPainter({
    required this.bars,
    required this.line,
    required this.labels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double leftPad = 36;
    final double bottomPad = 36;
    final double topPad = 24;
    final double rightPad = 16;
    final double chartHeight = size.height - bottomPad - topPad;
    final double chartWidth = size.width - leftPad - rightPad;
    final barWidth = 40.0;
    final barSpace = (chartWidth - barWidth * bars.length) / (bars.length + 1);

    // Draw grid lines and y-labels
    final gridPaint =
        Paint()
          ..color = const Color(0xFFE5E7EB)
          ..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i <= 6; i++) {
      double y = topPad + chartHeight * (1 - i / 6);
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(size.width - rightPad, y),
        gridPaint,
      );
      // Draw y-label
      final percent = (i * 10);
      textPainter.text = TextSpan(
        text: '$percent%',
        style: const TextStyle(
          color: Colors.black38,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(leftPad - textPainter.width - 6, y - textPainter.height / 2),
      );
    }

    // Draw bars (no border radius, closer together)
    for (int i = 0; i < bars.length; i++) {
      final x = leftPad + barSpace + i * (barWidth + barSpace);
      final barTop = topPad + chartHeight * (1 - bars[i]);
      final barRect = Rect.fromLTWH(x, barTop, barWidth, chartHeight * bars[i]);
      final barPaint = Paint()..color = const Color(0xFF22C55E);
      canvas.drawRect(barRect, barPaint);
    }

    // Draw x-labels
    for (int i = 0; i < labels.length; i++) {
      final x = leftPad + barSpace + i * (barWidth + barSpace) + barWidth / 2;
      textPainter.text = TextSpan(
        text: labels[i],
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: Colors.black38,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - bottomPad + 8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _LeaderboardCard extends StatefulWidget {
  @override
  State<_LeaderboardCard> createState() => _LeaderboardCardState();
}

class _LeaderboardCardState extends State<_LeaderboardCard> {
  int selectedTab = 0;
  final List<String> tabs = ['Total', 'Assignments', 'Activities'];

  final Map<String, List<Map<String, dynamic>>> leaderboardData = {
    'Total': [
      {'name': 'John Mark', 'class': 'BSIT-1A', 'points': 112},
      {'name': 'Andrei Vern', 'class': 'BSIT-1A', 'points': 110},
      {'name': 'Sofia Grey', 'class': 'BSIT-1A', 'points': 99},
      {'name': 'Pricess', 'class': 'BSIT-1A', 'points': 97},
      {'name': 'Sophia', 'class': 'BSIT-1A', 'points': 95},
    ],
    'Assignments': [
      {'name': 'Andrei Vern', 'class': 'BSIT-1A', 'points': 80},
      {'name': 'John Mark', 'class': 'BSIT-1A', 'points': 78},
      {'name': 'Sofia Grey', 'class': 'BSIT-1A', 'points': 75},
      {'name': 'Pricess', 'class': 'BSIT-1A', 'points': 70},
      {'name': 'Sophia', 'class': 'BSIT-1A', 'points': 68},
    ],
    'Activities': [
      {'name': 'Sofia Grey', 'class': 'BSIT-1A', 'points': 60},
      {'name': 'John Mark', 'class': 'BSIT-1A', 'points': 59},
      {'name': 'Andrei Vern', 'class': 'BSIT-1A', 'points': 58},
      {'name': 'Pricess', 'class': 'BSIT-1A', 'points': 55},
      {'name': 'Sophia', 'class': 'BSIT-1A', 'points': 53},
    ],
  };

  @override
  Widget build(BuildContext context) {
    final leaderboard = leaderboardData[tabs[selectedTab]]!;
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Leaderboard\nTop 10',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Row(
                children: [
                  ...List.generate(
                    tabs.length,
                    (i) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _LeaderboardTab(
                        label: tabs[i],
                        selected: selectedTab == i,
                        onTap: () => setState(() => selectedTab = i),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 290,
            child: Scrollbar(
              thumbVisibility: true,
              radius: const Radius.circular(8),
              thickness: 6,
              child: ListView.builder(
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LeaderboardTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF22C55E) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
