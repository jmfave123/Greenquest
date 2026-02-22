// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/instructor/instructor_appbar.dart';
import '../../shared/instructor/instructor_sidebar.dart';
import '../../shared/instructor/instructor_navigation_constants.dart';
import '../create/create_controller.dart';
import '../submissions/submissions_controller.dart';
import '../topics/topic_controller.dart';
import 'class_screen_controller.dart';
import '../instructor_dashboard_controller.dart';
import '../../core/utils/app_logger.dart';
import 'widgets/class_trees_tab.dart';
import 'widgets/class_classwork_tab.dart';
import 'widgets/class_people_tab.dart';
import 'widgets/class_stream_tab.dart';

class ClassDetailScreen extends StatefulWidget {
  final Map<String, dynamic> classData;

  const ClassDetailScreen({super.key, required this.classData});

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  final _logger = AppLogger('ClassDetailScreen');
  InstructorNavigationItem _selectedItem =
      InstructorNavigationItem.classManagement;
  int _selectedTabIndex = 0; // Class tab by default
  final CreateController _createController = Get.put(CreateController());
  final ClassController _classController = Get.find<ClassController>();
  final SubmissionsController _submissionsController = Get.put(
    SubmissionsController(),
  );
  final InstructorController _instructorController = Get.put(
    InstructorController(),
  );
  final TopicController _topicController = Get.put(TopicController());

  // Sorting states
  List<Map<String, dynamic>> _sortedGrades = [];

  // Tree submissions counter
  final RxInt _pendingTreeSubmissions = 0.obs;

  final List<Map<String, dynamic>> _grades = [
    {
      'name': 'Andrei Vern',
      'activity10': 100,
      'assignment9': null,
      'avatar': 'assets/images/Avatar.png',
    },
    {
      'name': 'Sofia Grey',
      'activity10': 75,
      'assignment9': null,
      'avatar': 'assets/images/Avatar.png',
    },
    {
      'name': 'Princess',
      'activity10': 90,
      'assignment9': null,
      'avatar': 'assets/images/Avatar.png',
    },
    {
      'name': 'Sophia',
      'activity10': 100,
      'assignment9': null,
      'avatar': 'assets/images/Avatar.png',
    },
    {
      'name': 'Rose Ann',
      'activity10': 100,
      'assignment9': null,
      'avatar': 'assets/images/Avatar.png',
    },
    {
      'name': 'Marie Lyn',
      'activity10': 100,
      'assignment9': null,
      'avatar': 'assets/images/Avatar.png',
    },
    {
      'name': 'Janna Mae',
      'activity10': 70,
      'assignment9': null,
      'avatar': 'assets/images/Avatar.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _sortedGrades = List.from(_grades);
    _sortGrades('Sort by Last name (A-Z)'); // Initialize with default sort

    // Use addPostFrameCallback to ensure operations run after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load instructor data
      _instructorController.loadInstructor();
      // Load created items when the screen initializes
      _createController.loadCreatedItems();
      // Load students for this specific class
      _loadStudentsForThisClass();
      // Load recent submissions for this class
      _loadRecentSubmissions();
      // Set up real-time status monitoring for students
      _setupStudentStatusMonitoring();
      // Set up real-time submission monitoring
      _setupSubmissionMonitoring();
      // Set up tree submissions monitoring
      _setupTreeSubmissionMonitoring();
    });
  }

  Future<void> _loadStudentsForThisClass() async {
    // Load students from users collection who selected this instructor
    // and are in this specific section
    String sectionCode = widget.classData['section'] ?? '';
    await _classController.loadStudentsFromUsersCollection(
      sectionCode: sectionCode,
    );

    // Refresh student online status
    await _classController.refreshStudentStatus(sectionCode);

    // Use addPostFrameCallback to prevent setState during build
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {}); // Refresh the UI to show updated student list
        }
      });
    }
  }

  /// Wrapper method for People tab refresh functionality
  Future<void> _loadStudentsAndRefreshStatus() async {
    await _loadStudentsForThisClass();
    String sectionCode = widget.classData['section'] ?? '';
    _classController.setupStudentStatusListener(sectionCode);
  }

  /// Refresh class data for Stream tab
  Future<void> _refreshClassData() async {
    await _createController.loadCreatedItems();
    await _topicController.loadTopics();
  }

  Future<void> _loadRecentSubmissions() async {
    // Load recent submissions for this specific class section
    String sectionCode = widget.classData['section'] ?? '';

    try {
      _logger.info(
        'Loading submissions for section',
        context: {'section': sectionCode},
      );
      _logger.debug('Class data', context: widget.classData);

      await _submissionsController.loadInstructorSubmissions(
        sectionId: sectionCode,
      );

      // Real-time listener removed - no more automatic updates

      _logger.success(
        'Submissions loaded successfully',
        context: {'count': _submissionsController.submissions.length},
      );

      // Use addPostFrameCallback to prevent setState during build
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {}); // Trigger UI rebuild
          }
        });
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Error loading submissions',
        error: e,
        stackTrace: stackTrace,
      );
      // Show error message to user
      Get.snackbar(
        'Error',
        'Failed to load submissions: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _setupStudentStatusMonitoring() {
    // Real-time student status monitoring removed - no more automatic updates
    // Users can manually refresh using the refresh button
  }

  void _setupSubmissionMonitoring() {
    // Real-time monitoring removed - no more automatic updates
    // Users can manually refresh using the refresh button
  }

  void _setupTreeSubmissionMonitoring() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final sectionName = widget.classData['section'] ?? '';

    // Listen to tree planting submissions for pending count
    FirebaseFirestore.instance
        .collection('submissions')
        .where('activityType', isEqualTo: 'tree_planting')
        .where('instructorId', isEqualTo: user.uid)
        .where('sectionName', isEqualTo: sectionName)
        .where('status', isEqualTo: 'submitted')
        .snapshots()
        .listen((snapshot) {
          _pendingTreeSubmissions.value = snapshot.docs.length;
        });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _handleNavigationSelect(InstructorNavigationItem item) {
    setState(() {
      _selectedItem = item;
    });
    String route = InstructorNavigationHelper.getRoute(item);
    Navigator.of(context).pushReplacementNamed(route);
  }

  void _selectTab(int index) {
    setState(() {
      _selectedTabIndex = index;
    });

    // Automatic refresh removed - users can manually refresh if needed
  }

  void _sortGrades(String sortType) {
    setState(() {
      _sortedGrades = List.from(_grades);

      switch (sortType) {
        case 'Sort by Last name (A-Z)':
          _sortedGrades.sort((a, b) => a['name'].compareTo(b['name']));
          break;
        case 'Sort by Last name (Z-A)':
          _sortedGrades.sort((a, b) => b['name'].compareTo(a['name']));
          break;
        case 'Sort by Average Score (High-Low)':
          _sortedGrades.sort((a, b) {
            double avgA = _calculateAverage(a);
            double avgB = _calculateAverage(b);
            return avgB.compareTo(avgA); // High to Low
          });
          break;
        case 'Sort by Average Score (Low-High)':
          _sortedGrades.sort((a, b) {
            double avgA = _calculateAverage(a);
            double avgB = _calculateAverage(b);
            return avgA.compareTo(avgB); // Low to High
          });
          break;
        default:
          // Default sort by last name A-Z
          _sortedGrades.sort((a, b) => a['name'].compareTo(b['name']));
      }
    });
  }

  double _calculateAverage(Map<String, dynamic> grade) {
    List<double> scores = [];

    if (grade['activity10'] != null) {
      scores.add(grade['activity10'].toDouble());
    }
    if (grade['assignment9'] != null) {
      scores.add(grade['assignment9'].toDouble());
    }

    if (scores.isEmpty) return 0.0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          InstructorSidebar(
            selectedItem: _selectedItem,
            onItemSelected: _handleNavigationSelect,
          ),
          // Main Content
          Expanded(
            child: Column(
              children: [
                // App Bar
                Obx(
                  () => InstructorAppBar(
                    instructorName: _instructorController.instructorName.value,
                    instructorRole: 'Instructor',
                    profileImageUrl:
                        _instructorController.profileImageUrl.value,
                  ),
                ),
                // Main Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Calculate available height for tab content
                        // Account for: tabs and spacing
                        const double tabsHeight = 50; // Approximate tabs height
                        final double availableHeight =
                            constraints.maxHeight -
                            tabsHeight -
                            20; // SizedBox height

                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tabs
                              Row(
                                children: [
                                  _buildTab('Class', 0),
                                  const SizedBox(width: 32),
                                  Obx(() {
                                    final sectionCode =
                                        widget.classData['section'] ?? '';
                                    // Access classStudents directly to ensure GetX tracks it
                                    final students =
                                        _classController
                                            .classStudents[sectionCode] ??
                                        [];
                                    final pendingCount =
                                        students
                                            .where(
                                              (s) =>
                                                  (s['enrollmentStatus'] ??
                                                      'pending') ==
                                                  'pending',
                                            )
                                            .length;
                                    return _buildTab(
                                      'Students',
                                      1,
                                      badgeCount: pendingCount,
                                    );
                                  }),
                                  const SizedBox(width: 32),
                                  Obx(
                                    () => _buildTab(
                                      'Classwork',
                                      2,
                                      badgeCount:
                                          _submissionsController
                                              .submissionStats['pending'] ??
                                          0,
                                    ),
                                  ),
                                  const SizedBox(width: 32),
                                  Obx(
                                    () => _buildTab(
                                      'Trees',
                                      3,
                                      badgeCount: _pendingTreeSubmissions.value,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Tab Content with fixed height for independent scrolling
                              SizedBox(
                                height:
                                    availableHeight > 400
                                        ? availableHeight
                                        : 400, // Minimum height of 400
                                child: _buildTabContent(),
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
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index, {int badgeCount = 0}) {
    return _ClassTab(
      title: title,
      isSelected: _selectedTabIndex == index,
      badgeCount: badgeCount,
      onTap: () => _selectTab(index),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return ClassStreamTab(
          classData: widget.classData,
          createController: _createController,
          topicController: _topicController,
          instructorController: _instructorController,
          classController: _classController,
          onRefresh: _refreshClassData,
        );
      case 1:
        return ClassPeopleTab(
          classData: widget.classData,
          classController: _classController,
          instructorController: _instructorController,
          onRefresh: _loadStudentsAndRefreshStatus,
        );
      case 2:
        return ClassClassworkTab(
          classData: widget.classData,
          submissionsController: _submissionsController,
          onRefresh: _loadRecentSubmissions,
        );
      case 3:
        return ClassTreesTab(
          classData: widget.classData,
          instructorController: _instructorController,
        );
      default:
        return ClassStreamTab(
          classData: widget.classData,
          createController: _createController,
          topicController: _topicController,
          instructorController: _instructorController,
          classController: _classController,
          onRefresh: _refreshClassData,
        );
    }
  }
}

/// Isolated tab button — hover state is self-contained so parent never rebuilds.
class _ClassTab extends StatefulWidget {
  final String title;
  final bool isSelected;
  final int badgeCount;
  final VoidCallback onTap;

  const _ClassTab({
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  State<_ClassTab> createState() => _ClassTabState();
}

class _ClassTabState extends State<_ClassTab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isSelected || _hovered;
    final showBadge = widget.badgeCount > 0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeInOut,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: active ? const Color(0xFF34A853) : Colors.black54,
                  ),
                  child: Text(widget.title),
                ),
                if (showBadge) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        widget.badgeCount >= 9
                            ? '9+'
                            : widget.badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeInOut,
              width: 40,
              height: active ? 4 : 3,
              decoration: BoxDecoration(
                color: active ? const Color(0xFF34A853) : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
