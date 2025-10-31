import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenquest/shared/login/custom_drawer.dart';
import 'package:greenquest/shared/login/custom_appbar.dart';
import 'package:greenquest/user/submit/activity/activity_list_screen.dart';
import 'package:greenquest/user/submit/assignment/assignment_list_screen.dart';
import 'package:greenquest/user/submit/quiz_new/quiz_list_screen.dart';
import 'package:greenquest/user/submit/pit/pit_list_screen.dart';
import 'package:greenquest/user/home_screen_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeScreenController controller = Get.put(HomeScreenController());
  int selectedDrawerIndex = 0;
  double progress = 0.5; // Example progress (18%)

  // Plant image based on progress
  String get plantImage {
    if (progress < 0.25) return 'assets/images/image_304-removebg-preview.png';
    if (progress < 0.5) return 'assets/images/image_307-removebg-preview.png';
    if (progress < 0.75) return 'assets/images/image_309-removebg-preview.png';
    if (progress < 1.0) return 'assets/images/image_310-removebg-preview.png';
    if (progress == 1.0) return 'assets/images/image_311-removebg-preview.png';
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
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF34A853)),
            ),
          );
        }

        // Check if user is approved
        if (!controller.isApproved.value) {
          return _buildPendingApprovalContent();
        }

        // User is approved, show normal home content
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // Plant Progress
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
                        child: Text(
                          '${(progress * 100).round()}%\nComplete',
                          textAlign: TextAlign.left,
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
                          Image.asset(plantImage, height: 150),
                        ],
                      ),
                      Positioned(
                        bottom: 0,
                        child: const Text(
                          'Growing strong and healthy!',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                // Slider to change progress interactively
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      Slider(
                        value: progress,
                        min: 0.0,
                        max: 1.0,
                        divisions: 100,
                        label: '${(progress * 100).round()}%',
                        onChanged: (value) {
                          setState(() {
                            progress = value;
                          });
                        },
                        activeColor: const Color(0xFF43A047),
                        inactiveColor: const Color(0xFFE0E0E0),
                      ),
                      const Text(
                        'Adjust progress to see plant evolve',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ),
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
                                colors: [Color(0xFF70E774), Color(0xFF28863D)],
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
                            border: Border.all(color: const Color(0xFFB6F5C3)),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
