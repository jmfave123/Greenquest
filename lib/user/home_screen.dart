import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/services/tree_progress_service.dart';
import 'package:greenquest/shared/login/custom_drawer.dart';
import 'package:greenquest/shared/login/custom_appbar.dart';
import 'package:greenquest/user/submit/activity/activity_list_screen.dart';
import 'package:greenquest/user/submit/assignment/assignment_list_screen.dart';
import 'package:greenquest/user/submit/quiz_new/quiz_list_screen.dart';
import 'package:greenquest/user/submit/pit/pit_list_screen.dart';
import 'package:greenquest/user/home_screen_controller.dart';
import 'package:greenquest/shared/widgets/skeleton_loading.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeScreenController controller = Get.put(HomeScreenController());
  int selectedDrawerIndex = 0;

  // Plant image based on calculated progress
  String plantImage(double progress) {
    if (progress < 0.25) return 'assets/images/image_304-removebg-preview.png';
    if (progress < 0.5) return 'assets/images/image_307-removebg-preview.png';
    if (progress < 0.75) return 'assets/images/image_309-removebg-preview.png';
    if (progress < 1.0) return 'assets/images/image_310-removebg-preview.png';
    if (progress >= 1.0) return 'assets/images/image_311-removebg-preview.png';
    return 'assets/images/image_311-removebg-preview.png';
  }

  final drawerItems = [
    {
      'label': 'Home',
      'icon': 'assets/icons/material-symbols-light_home-rounded.png',
      'iconSelected':
          'assets/icons/material-symbols-light_home-rounded (1).png',
    },
    {
      'label': 'Message',
      'icon': 'assets/icons/mage_message-fill.png',
      'iconSelected': 'assets/icons/mage_message-fill (1).png',
    },
    {
      'label': 'Leaderboard',
      'icon': 'assets/icons/material-symbols-light_leaderboard-rounded.png',
      'iconSelected':
          'assets/icons/material-symbols-light_leaderboard-rounded (1).png',
    },
    {
      'label': 'Materials',
      'icon': 'assets/icons/mage_book-fill.png',
      'iconSelected': 'assets/icons/mage_book-fill (1).png',
    },
    {
      'label': 'Profile',
      'icon': 'assets/icons/mingcute_user-3-fill.png',
      'iconSelected': 'assets/icons/mingcute_user-3-fill (1).png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomDrawer(
        selectedIndex: selectedDrawerIndex,
        onSelect: (i) {
          setState(() => selectedDrawerIndex = i);
          Navigator.pop(context);
        },
      ),
      appBar: CustomAppBar(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  const SkeletonHomeProgressCard(),
                  const SkeletonCategoryCompletionCard(),
                  const SkeletonSubmitWorkCard(),
                ],
              ),
            ),
          );
        }

        // Check if user is approved
        if (!controller.isApproved.value) {
          return _buildPendingApprovalContent();
        }

        // User is approved, show normal home content
        // Real-time progress stream - wraps both seedling and category completion
        return StreamBuilder<ProgressResult>(
          stream: controller.progressStream,
          builder: (context, snapshot) {
            final progress = snapshot.hasData ? snapshot.data!.progress : 0.0;
            final isLoadingProgress =
                snapshot.connectionState == ConnectionState.waiting;
            final computedGrade =
                snapshot.hasData ? snapshot.data!.computedFinalGrade : 5.00;
            final midtermCompletions =
                snapshot.hasData
                    ? snapshot.data!.midtermCompletions
                        .map(
                          (c) => {
                            'category': c.category,
                            'displayName': c.displayName,
                            'completed': c.completed,
                            'total': c.total,
                            'percentage': c.percentage,
                            'period': c.period,
                          },
                        )
                        .toList()
                    : <Map<String, dynamic>>[];
            final finalCompletions =
                snapshot.hasData
                    ? snapshot.data!.finalCompletions
                        .map(
                          (c) => {
                            'category': c.category,
                            'displayName': c.displayName,
                            'completed': c.completed,
                            'total': c.total,
                            'percentage': c.percentage,
                            'period': c.period,
                          },
                        )
                        .toList()
                    : <Map<String, dynamic>>[];

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    // Seedling Progress Card - Real-time updates via StreamBuilder
                    Container(
                      width: double.infinity,
                      height: 320,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            right: 0,
                            top: 0,
                            child:
                                isLoadingProgress
                                    ? const SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFF34A853),
                                            ),
                                      ),
                                    )
                                    : Text(
                                      // Real-time progress percentage from StreamBuilder
                                      '${(progress * 100).round()}%\nComplete',
                                      textAlign: TextAlign.left,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                          ),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 250,
                                height: 250,
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: CircularProgressIndicator(
                                    // Real-time progress value from StreamBuilder
                                    value: progress,
                                    strokeWidth: 25,
                                    color: Colors.white,
                                    backgroundColor: const Color(0xFFE0E0E0),
                                    valueColor: const AlwaysStoppedAnimation(
                                      Color(0xFF34A853),
                                    ),
                                  ),
                                ),
                              ),
                              // Real-time plant image based on progress from StreamBuilder
                              Image.asset(plantImage(progress), height: 150),
                            ],
                          ),
                          // Current Grade at bottom of seedling
                          Positioned(
                            bottom: 60,
                            child: Column(
                              children: [
                                Text(
                                  'Current Grade:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 2),
                                // Real-time grade value from StreamBuilder
                                Builder(
                                  builder: (context) {
                                    final grade =
                                        isLoadingProgress
                                            ? 5.00
                                            : computedGrade;

                                    // Color: Green for 1.00-3.00 (passing), Red for 3.01-5.00 (failing)
                                    final gradeColor =
                                        grade <= 3.00
                                            ? const Color(
                                              0xFF34A853,
                                            ) // Green for passing
                                            : const Color(
                                              0xFFE53935,
                                            ); // Red for failing

                                    return Text(
                                      grade.toStringAsFixed(2),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: gradeColor,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            child: Text(
                              // Real-time progress message from StreamBuilder
                              isLoadingProgress
                                  ? 'Loading progress...'
                                  : _getProgressMessage(progress),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Category Completion Cards - Real-time updates via StreamBuilder
                    Builder(
                      builder: (context) {
                        // Combine midterm and final completions from stream data
                        final allCompletions = [
                          ...midtermCompletions,
                          ...finalCompletions,
                        ];

                        if (allCompletions.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.checklist_rounded,
                                    color: Color(0xFF34A853),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Category Completion',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Display real-time category completion data from StreamBuilder
                              ...allCompletions.map((completion) {
                                // Real-time values from stream
                                final completed =
                                    (completion['completed'] ?? 0) as int;
                                final total = (completion['total'] ?? 0) as int;
                                final displayName =
                                    (completion['displayName'] ?? '') as String;
                                final percentage =
                                    (completion['percentage'] ?? 0.0) as double;
                                final period =
                                    (completion['period'] ?? 'midterm')
                                        as String;
                                final isComplete =
                                    completed == total && total > 0;
                                final hasItems = total > 0;

                                // Add period label to display name
                                final periodLabel =
                                    period == 'midterm'
                                        ? 'Prelim/Midterm'
                                        : 'Final';
                                final fullDisplayName =
                                    '$periodLabel - $displayName';

                                // Always show category, even if 0/0 (no items created yet)
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color:
                                        hasItems
                                            ? (isComplete
                                                ? Color(0xFFE8F5E9)
                                                : Color(0xFFFFF3E0))
                                            : Color(
                                              0xFFF5F5F5,
                                            ), // Gray for no items
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          hasItems
                                              ? (isComplete
                                                  ? Color(0xFF81C784)
                                                  : Color(0xFFFFB74D))
                                              : Color(
                                                0xFFE0E0E0,
                                              ), // Light gray border
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        hasItems
                                            ? (isComplete
                                                ? Icons.check_circle
                                                : Icons.pending_outlined)
                                            : Icons.radio_button_unchecked,
                                        color:
                                            hasItems
                                                ? (isComplete
                                                    ? Color(0xFF4CAF50)
                                                    : Color(0xFFFF9800))
                                                : Colors.grey[400],
                                        size: 28,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              fullDisplayName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color:
                                                    hasItems
                                                        ? (isComplete
                                                            ? Color(0xFF2E7D32)
                                                            : Color(0xFFE65100))
                                                        : Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                // Real-time completion count from StreamBuilder
                                                Text(
                                                  '$completed/$total completed',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[700],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                if (hasItems)
                                                  Expanded(
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                      child: LinearProgressIndicator(
                                                        // Real-time percentage from StreamBuilder
                                                        value: percentage,
                                                        minHeight: 6,
                                                        backgroundColor:
                                                            Colors.grey[300],
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                              Color
                                                            >(
                                                              isComplete
                                                                  ? Color(
                                                                    0xFF4CAF50,
                                                                  )
                                                                  : Color(
                                                                    0xFFFF9800,
                                                                  ),
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                if (!hasItems)
                                                  Expanded(
                                                    child: Container(
                                                      height: 6,
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey[200],
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          'No items yet',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color:
                                                                Colors
                                                                    .grey[500],
                                                            fontStyle:
                                                                FontStyle
                                                                    .italic,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                const SizedBox(width: 8),
                                                if (hasItems)
                                                  // Real-time percentage display from StreamBuilder
                                                  Text(
                                                    '${(percentage * 100).round()}%',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          isComplete
                                                              ? Color(
                                                                0xFF2E7D32,
                                                              )
                                                              : Color(
                                                                0xFFE65100,
                                                              ),
                                                    ),
                                                  ),
                                                if (!hasItems)
                                                  Text(
                                                    '-',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.grey[400],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      },
                    ),
                    // Submit Your Work
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF70E774),
                                      Color(0xFF28863D),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.asset(
                                    'assets/icons/fluent_task-list-20-filled.png',
                                    width: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Submit Your Work',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Complete tasks to grow your\nlearning tree',
                                    style: TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Submit Activity
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ActivityListScreen(),
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFB6F5C3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFC6F6D5),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Image.asset(
                                        'assets/icons/Vector (4).png',
                                        width: 28,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Submit Activity',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFF43A047),
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Image.asset(
                                              'assets/icons/Vector (5).png',
                                              width: 24,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              'Complete your daily learning\ntask',
                                              style: TextStyle(
                                                color: Color(0xFF6B7280),
                                                fontSize: 13,
                                              ),
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
                          // Submit Assignment
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AssignmentListScreen(),
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F0FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Color(0xFFB6D5F5)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD6E4FF),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Image.asset(
                                        'assets/icons/Vector (0).png',
                                        width: 28,
                                        color: Color(0xFF2886D7),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Submit Assignment',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFF2886D7),
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Image.asset(
                                              'assets/icons/Vector (6).png',
                                              width: 24,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              'Turn in your major project',
                                              style: TextStyle(
                                                color: Color(0xFF6B7280),
                                                fontSize: 13,
                                              ),
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

                          // Submit Quizzes
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const QuizListScreen(),
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F1FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Color.fromARGB(255, 215, 199, 245),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE9D8FD),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Image.asset(
                                        'assets/icons/Vector (0).png',
                                        width: 28,
                                        color: Color(0xFF8B5CF6),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Submit Quizzes',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFF8B5CF6),
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Image.asset(
                                              'assets/icons/Vector (6).png',
                                              width: 24,

                                              color: Color(0xFF8B5CF6),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              'Turn in your quizzes',
                                              style: TextStyle(
                                                color: Color(0xFF6B7280),
                                                fontSize: 13,
                                              ),
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

                          // Submit PIT
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PitListScreen(),
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Color(0xFFFFB74D)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFE0B2),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.engineering,
                                        size: 28,
                                        color: Color(0xFFFF9800),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Submit PIT',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFFFF9800),
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.upload_file,
                                              size: 24,
                                              color: Color(0xFFFF9800),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              'Turn in your PIT project',
                                              style: TextStyle(
                                                color: Color(0xFF6B7280),
                                                fontSize: 13,
                                              ),
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildPendingApprovalContent() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Status Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color:
                  controller.enrollmentStatus.value == 'rejected'
                      ? Colors.red.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              controller.enrollmentStatus.value == 'rejected'
                  ? Icons.cancel_outlined
                  : Icons.hourglass_empty,
              size: 60,
              color:
                  controller.enrollmentStatus.value == 'rejected'
                      ? Colors.red
                      : Colors.orange,
            ),
          ),

          const SizedBox(height: 32),

          // Status Title
          Text(
            controller.enrollmentStatus.value == 'rejected'
                ? 'Enrollment Rejected'
                : 'Pending Instructor Approval',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Status Description
          Text(
            controller.enrollmentStatus.value == 'rejected'
                ? 'Your enrollment request has been rejected. Please select a different instructor.'
                : 'Your enrollment request is pending approval from your selected instructor.',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          if (controller.instructorName.value.isNotEmpty) ...[
            const SizedBox(height: 24),

            // Instructor Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.person, color: Color(0xFF34A853), size: 32),
                  const SizedBox(height: 12),
                  Text(
                    'Selected Instructor',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.instructorName.value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Section Info Card
          if (controller.selectedSectionCode.value.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F8FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFB3D9FF)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.school, color: Color(0xFF2196F3), size: 32),
                  const SizedBox(height: 12),
                  Text(
                    'Section',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.selectedSectionCode.value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Action Buttons
          if (controller.enrollmentStatus.value == 'rejected') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.navigateToInstructorSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF34A853),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Select Different Instructor',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ] else ...[
            // Cancel request button for pending status
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    controller.isLoading.value ? null : _showCancelConfirmation,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel Request'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Refresh button for pending status
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed:
                    controller.isLoading.value
                        ? null
                        : controller.refreshStatus,
                icon:
                    controller.isLoading.value
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.refresh),
                label: Text(
                  controller.isLoading.value ? 'Checking...' : 'Refresh Status',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF34A853),
                  side: const BorderSide(color: Color(0xFF34A853)),
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Help text
          Text(
            controller.enrollmentStatus.value == 'rejected'
                ? 'You can select a different instructor and try again.'
                : 'You will be automatically redirected once your instructor approves your enrollment.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getProgressMessage(double progress) {
    if (progress < 0.25) {
      return 'Just starting to grow!';
    } else if (progress < 0.5) {
      return 'Growing steadily!';
    } else if (progress < 0.75) {
      return 'Growing strong and healthy!';
    } else if (progress < 1.0) {
      return 'Almost fully grown!';
    } else {
      return 'Fully grown and thriving!';
    }
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Request'),
          content: const Text(
            'Are you sure you want to cancel your enrollment request? You will be able to select a different instructor.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Keep Request'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                controller.cancelRequest();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel Request'),
            ),
          ],
        );
      },
    );
  }
}
