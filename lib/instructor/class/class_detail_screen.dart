// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../shared/instructor/instructor_appbar.dart';
import '../../shared/instructor/instructor_sidebar.dart';
import '../../shared/instructor/instructor_navigation_constants.dart';
import '../../shared/widgets/skeleton_loading.dart';
import '../../shared/widgets/custom_dialogs.dart';
import '../create/create_controller.dart';
import '../submissions/student_submissions_screen.dart';
import '../submissions/submission_detail_screen.dart';
import '../submissions/submissions_controller.dart';
import '../topics/topic_controller.dart';
import 'class_screen_controller.dart';
import '../instructor_dashboard_controller.dart';
import '../../user/materials/materials_detail_screen.dart';
import '../../shared/services/notify_service.dart';
import '../../shared/services/in_app_notification_service.dart';

class ClassDetailScreen extends StatefulWidget {
  final Map<String, dynamic> classData;

  const ClassDetailScreen({super.key, required this.classData});

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
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

  // Filter states for Students
  String _selectedStudentFilter = 'All';
  final List<String> _studentFilterOptions = [
    'All',
    'Pending',
    'Approved',
    'Rejected',
  ];

  // Tree submissions counter
  final RxInt _pendingTreeSubmissions = 0.obs;

  // Filter for Posted Items (Class Tab)
  String _selectedPostedItemTypeFilter = 'All Types';
  final List<String> _postedItemTypeFilterOptions = [
    'All Types',
    'Assignment',
    'Activity',
    'Quiz',
    'PIT',
    'Material',
  ];

  String _selectedPostedItemTopicFilter = 'All Topics';
  List<String> _postedItemTopicFilterOptions = ['All Topics', 'No Topic'];

  // Search and filter states for Student Submissions
  final TextEditingController _submissionSearchController =
      TextEditingController();
  String _submissionSearchQuery = '';
  String _selectedSubmissionTypeFilter = 'All Types';
  String _selectedSubmissionStatusFilter = 'All Status';
  final List<String> _submissionTypeFilterOptions = [
    'All Types',
    'Assignment',
    'Activity',
    'Quiz',
    'PIT',
  ];
  final List<String> _submissionStatusFilterOptions = [
    'All Status',
    'Submitted',
    'Graded',
    'Late',
  ];

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
      // Load topics and update filter options
      _loadTopicsAndUpdateFilter();
      // Set up tree submissions monitoring
      _setupTreeSubmissionMonitoring();
    });
  }

  Future<void> _loadTopicsAndUpdateFilter() async {
    await _topicController.loadTopics();
    if (mounted) {
      setState(() {
        _postedItemTopicFilterOptions = [
          'All Topics',
          'No Topic',
          ..._topicController.topics.map((topic) => topic.topic),
        ];
      });
    }
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

  Future<void> _loadRecentSubmissions() async {
    // Load recent submissions for this specific class section
    String sectionCode = widget.classData['section'] ?? '';

    try {
      print('🔄 Loading submissions for section: $sectionCode');
      print('📋 Class data: ${widget.classData}');

      await _submissionsController.loadInstructorSubmissions(
        sectionId: sectionCode,
      );

      // Real-time listener removed - no more automatic updates

      print(
        '✅ Submissions loaded successfully: ${_submissionsController.submissions.length}',
      );

      // Use addPostFrameCallback to prevent setState during build
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {}); // Trigger UI rebuild
          }
        });
      }
    } catch (e) {
      print('❌ Error loading submissions: $e');
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

  // void _showNewSubmissionNotification(int submissionCount) {
  //   if (submissionCount > 0) {
  //     Get.snackbar(
  //       'New Submissions',
  //       'You have $submissionCount submission${submissionCount > 1 ? 's' : ''} to review',
  //       snackPosition: SnackPosition.TOP,
  //       backgroundColor: const Color(0xFF34A853),
  //       colorText: Colors.white,
  //       duration: const Duration(seconds: 3),
  //       icon: const Icon(Icons.assignment_turned_in, color: Colors.white),
  //     );
  //   }
  // }

  @override
  void dispose() {
    _submissionSearchController.dispose();
    super.dispose();
  }

  /// Format last seen time (same as message screen)
  String _formatLastSeen(DateTime lastSeenTime) {
    final now = DateTime.now();
    final difference = now.difference(lastSeenTime);

    if (difference.inMinutes < 1) {
      return 'Active just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return 'Active $minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'Active $hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return 'Active $days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Active $weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Active $months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      return 'Active a long time ago';
    }
  }

  /// Get initials from full name (e.g., "JM Ruiz" -> "JR", "JV P. Tenefrancia" -> "JT")
  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';

    // Get first character of first part
    String initials = parts[0][0].toUpperCase();

    // Get first character of last part (skip middle initials with periods)
    if (parts.length > 1) {
      // Find the last part that's not just an initial (has more than 2 chars or no period)
      for (int i = parts.length - 1; i > 0; i--) {
        final part = parts[i];
        if (part.length > 2 || !part.contains('.')) {
          initials += part[0].toUpperCase();
          break;
        }
      }
    }

    return initials;
  }

  /// Build online status widget with real-time updates (matching message screen logic)
  Widget _buildOnlineStatusWidget(Map<String, dynamic> student) {
    final studentId = student['studentId'];

    // If no studentId, show offline
    if (studentId == null) {
      return Text(
        'Offline',
        style: const TextStyle(color: Colors.black54, fontSize: 11),
      );
    }

    // Use StreamBuilder for real-time updates (same as message screen)
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(studentId)
              .snapshots(),
      builder: (context, snapshot) {
        final isOnline =
            snapshot.hasData &&
            snapshot.data!.exists &&
            (snapshot.data!.data() as Map<String, dynamic>?)?['isOnline'] ==
                true;

        dynamic lastSeen;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          lastSeen = data?['lastSeen'];
        } else {
          lastSeen = null;
        }

        // Check if online based on lastSeen (within 1 minute)
        bool isActuallyOnline = isOnline;
        if (!isOnline && lastSeen != null) {
          try {
            DateTime? lastSeenTime;
            if (lastSeen is Timestamp) {
              lastSeenTime = lastSeen.toDate();
            } else if (lastSeen is DateTime) {
              lastSeenTime = lastSeen;
            }

            if (lastSeenTime != null) {
              final now = DateTime.now();
              final difference = now.difference(lastSeenTime).inMinutes;
              isActuallyOnline =
                  difference <= 1; // Online if last seen within 1 minute
            }
          } catch (e) {
            isActuallyOnline = false;
          }
        }

        // Display: "Online" with green dot or "Active X ago"
        if (isActuallyOnline) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF34A853),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Online',
                style: TextStyle(
                  color: Color(0xFF34A853),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        } else if (lastSeen != null) {
          try {
            DateTime? lastSeenTime;
            if (lastSeen is Timestamp) {
              lastSeenTime = lastSeen.toDate();
            } else if (lastSeen is DateTime) {
              lastSeenTime = lastSeen;
            }

            if (lastSeenTime != null) {
              return Text(
                _formatLastSeen(lastSeenTime),
                style: const TextStyle(color: Colors.black54, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            }
          } catch (e) {
            // Fall through to offline
          }
        }

        // Default: Offline
        return Text(
          'Offline',
          style: const TextStyle(color: Colors.black54, fontSize: 11),
        );
      },
    );
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

  String _getDayAbbreviation(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
        return 'Mon';
      case 'tuesday':
        return 'Tue';
      case 'wednesday':
        return 'Wed';
      case 'thursday':
        return 'Thu';
      case 'friday':
        return 'Fri';
      case 'saturday':
        return 'Sat';
      case 'sunday':
        return 'Sun';
      default:
        return day;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    try {
      if (timestamp is Timestamp) {
        final dateTime = timestamp.toDate();
        return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
      } else if (timestamp is DateTime) {
        return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
      } else if (timestamp is String) {
        // Check if it's already a formatted date string
        // Handle formats like:
        // - "November 8, 2025 at 8:26:40 PM UTC+8" (full month name)
        // - "Nov 08, 2025 08:21 PM" (abbreviated month)
        final monthAbbrevs = [
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
        final monthNames = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ];

        final hasMonthAbbrev = monthAbbrevs.any(
          (month) => timestamp.contains(month),
        );
        final hasMonthName = monthNames.any(
          (month) => timestamp.contains(month),
        );

        // If it's already formatted with month name or abbreviation, extract date parts
        if (hasMonthName || hasMonthAbbrev) {
          // Try to extract date using regex for full month names: "November 8, 2025"
          final fullMonthMatch = RegExp(
            r'(January|February|March|April|May|June|July|August|September|October|November|December)\s+(\d{1,2}),\s+(\d{4})',
          ).firstMatch(timestamp);

          if (fullMonthMatch != null) {
            final monthStr = fullMonthMatch.group(1)!;
            final dayStr = fullMonthMatch.group(2)!;
            final yearStr = fullMonthMatch.group(3)!;

            final monthIndex = monthNames.indexOf(monthStr);
            if (monthIndex != -1) {
              final month = monthIndex + 1;
              final day = int.tryParse(dayStr);
              final year = int.tryParse(yearStr);

              if (day != null && year != null) {
                return '$month/$day/$year';
              }
            }
          }

          // Try to extract date using regex for abbreviated months: "Nov 08, 2025" or "Nov 8, 2025"
          final abbrevMonthMatch = RegExp(
            r'(\w{3})\s+(\d{1,2}),\s+(\d{4})',
          ).firstMatch(timestamp);

          if (abbrevMonthMatch != null) {
            final monthStr = abbrevMonthMatch.group(1)!;
            final dayStr = abbrevMonthMatch.group(2)!;
            final yearStr = abbrevMonthMatch.group(3)!;

            final monthIndex = monthAbbrevs.indexOf(monthStr);
            if (monthIndex != -1) {
              final month = monthIndex + 1;
              final day = int.tryParse(dayStr);
              final year = int.tryParse(yearStr);

              if (day != null && year != null) {
                return '$month/$day/$year';
              }
            }
          }

          // If regex doesn't match, try simple split
          final parts = timestamp.split(' ');
          if (parts.length >= 3) {
            final monthStr = parts[0];
            final dayStr = parts[1].replaceAll(',', '');
            final yearStr = parts[2];

            // Try full month name first
            var monthIndex = monthNames.indexOf(monthStr);
            if (monthIndex == -1) {
              // Try abbreviated month
              monthIndex = monthAbbrevs.indexOf(monthStr);
            }

            if (monthIndex != -1) {
              final month = monthIndex + 1;
              final day = int.tryParse(dayStr);
              final year = int.tryParse(yearStr);

              if (day != null && year != null) {
                return '$month/$day/$year';
              }
            }
          }
        }

        // Try to parse as ISO format or standard date format
        try {
          final dateTime = DateTime.parse(timestamp);
          return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
        } catch (e) {
          // If parsing fails and it's not a formatted string, return as-is
          return timestamp;
        }
      }
      return 'Unknown';
    } catch (e) {
      print(
        'Error formatting timestamp: $e, type: ${timestamp.runtimeType}, value: $timestamp',
      );
      // If it's a string that failed, return it as-is instead of "Unknown"
      if (timestamp is String) {
        return timestamp;
      }
      return 'Unknown';
    }
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
    bool isSelected = _selectedTabIndex == index;
    bool showBadge = badgeCount > 0;

    return GestureDetector(
      onTap: () => _selectTab(index),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? const Color(0xFF34A853) : Colors.black54,
                ),
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
                      badgeCount >= 9 ? '9+' : badgeCount.toString(),
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
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF34A853) : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildStreamTab();
      case 1:
        return _buildPeopleTab();
      case 2:
        return _buildClassworkTab();
      case 3:
        return _buildTreesTab();
      default:
        return _buildStreamTab();
    }
  }

  Widget _buildStreamTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF34A853),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                // Background Image
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/instructor/images/Group 1171274927.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Text Overlay
                Positioned(
                  left: 80,
                  bottom: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.classData['course']} ${widget.classData['section']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Display schedules - handle both single and multiple
                      Builder(
                        builder: (context) {
                          if (widget.classData.containsKey('schedules') &&
                              widget.classData['schedules'] is List) {
                            final schedules = List<Map<String, dynamic>>.from(
                              widget.classData['schedules'],
                            );
                            if (schedules.isEmpty) {
                              return const Text(
                                'No schedule',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              );
                            }

                            // Check if all schedules have same time
                            final allSameTime = schedules.every(
                              (s) =>
                                  s['startTime'] == schedules[0]['startTime'] &&
                                  s['endTime'] == schedules[0]['endTime'],
                            );

                            if (allSameTime && schedules.length > 1) {
                              // Show as "Mon/Wed 9:00 AM - 10:30 AM" with rooms
                              final days = schedules
                                  .map((s) => _getDayAbbreviation(s['day']))
                                  .join('/');

                              // Check if all rooms are the same
                              final allSameRoom = schedules.every(
                                (s) => s['room'] == schedules[0]['room'],
                              );
                              final roomText =
                                  allSameRoom
                                      ? ' • ${schedules[0]['room'] ?? 'No room'}'
                                      : ' • Multiple rooms';

                              return Text(
                                '$days ${schedules[0]['startTime']} - ${schedules[0]['endTime']}$roomText',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              );
                            } else {
                              // Show all schedules separately with rooms
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children:
                                    schedules.map((schedule) {
                                      final dayAbbr = _getDayAbbreviation(
                                        schedule['day'],
                                      );
                                      final room =
                                          schedule['room'] ?? 'No room';
                                      return Text(
                                        '$dayAbbr ${schedule['startTime']} - ${schedule['endTime']} • $room',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      );
                                    }).toList(),
                              );
                            }
                          } else {
                            // Fallback to old format
                            return Text(
                              '${_getDayAbbreviation(widget.classData['day'])} ${widget.classData['startTime']} - ${widget.classData['endTime']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.meeting_room_outlined,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.classData['room'] ?? 'N/A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
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
          const SizedBox(height: 30),
          // Posted Assignments and Activities
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Header with Filter
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Posted Assignments & Activities',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Row(
                      children: [
                        // Type Filter Dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF34A853).withOpacity(0.3),
                            ),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedPostedItemTypeFilter,
                            underline: const SizedBox(),
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Color(0xFF34A853),
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            items:
                                _postedItemTypeFilterOptions.map((String type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(type),
                                  );
                                }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedPostedItemTypeFilter = newValue;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Topic Filter Dropdown
                        Obx(() {
                          final topicOptions = [
                            'All Topics',
                            'No Topic',
                            ..._topicController.topics.map(
                              (topic) => topic.topic,
                            ),
                          ];

                          // Reset filter if selected topic no longer exists
                          if (!topicOptions.contains(
                            _selectedPostedItemTopicFilter,
                          )) {
                            _selectedPostedItemTopicFilter = 'All Topics';
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF34A853).withOpacity(0.3),
                              ),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedPostedItemTopicFilter,
                              underline: const SizedBox(),
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Color(0xFF34A853),
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              items:
                                  topicOptions.map((String topic) {
                                    return DropdownMenuItem<String>(
                                      value: topic,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            topic == 'All Topics'
                                                ? Icons.topic
                                                : topic == 'No Topic'
                                                ? Icons.not_interested
                                                : Icons.bookmark,
                                            size: 16,
                                            color: const Color(0xFF34A853),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(topic),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedPostedItemTopicFilter = newValue;
                                  });
                                }
                              },
                            ),
                          );
                        }),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () async {
                            await _topicController.loadTopics();
                            await _createController.loadCreatedItems();
                          },
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Refresh',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Posted Items List
                Expanded(
                  child: Obx(() {
                    if (_createController.isLoading.value) {
                      return ListView.builder(
                        itemCount: 5,
                        itemBuilder: (context, i) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: SkeletonInstructorCreateItemCard(),
                          );
                        },
                      );
                    }

                    // Get only posted items (assignments, activities, quizzes) for this specific class
                    List<Map<String, dynamic>> postedItems = [];
                    String currentClassSection =
                        widget.classData['section'] ?? '';
                    String currentClassCourse =
                        widget.classData['course'] ?? '';
                    String currentClassFullName =
                        '$currentClassCourse $currentClassSection';

                    for (var item in _createController.createdItems) {
                      // Check if this item is assigned to the current class
                      List<dynamic> selectedClasses =
                          item['selectedClasses'] ?? [];
                      bool isAssignedToCurrentClass = false;

                      // Check if the current class is in the selectedClasses list
                      for (var selectedClass in selectedClasses) {
                        String selectedClassStr =
                            selectedClass.toString().toLowerCase();
                        String currentClassStr =
                            currentClassFullName.toLowerCase();

                        // Direct match
                        if (selectedClassStr == currentClassStr) {
                          isAssignedToCurrentClass = true;
                          break;
                        }

                        // Check for partial matches (e.g., "BSIT-1A" matches "BSIT 1A")
                        String normalizedSelected = selectedClassStr
                            .replaceAll('-', ' ')
                            .replaceAll('_', ' ');
                        String normalizedCurrent = currentClassStr
                            .replaceAll('-', ' ')
                            .replaceAll('_', ' ');

                        if (normalizedSelected == normalizedCurrent) {
                          isAssignedToCurrentClass = true;
                          break;
                        }

                        // Check if current class section matches (e.g., "1A" matches "BSIT-1A")
                        if (selectedClassStr.contains(
                              currentClassSection.toLowerCase(),
                            ) ||
                            currentClassStr.contains(selectedClassStr)) {
                          isAssignedToCurrentClass = true;
                          break;
                        }
                      }

                      // Only add items that are assigned to the current class
                      if (isAssignedToCurrentClass) {
                        postedItems.add({
                          ...item,
                          'itemType': 'posted',
                          'timestamp': item['createdAt'],
                        });
                      }
                    }

                    // Apply type filter
                    if (_selectedPostedItemTypeFilter != 'All Types') {
                      postedItems =
                          postedItems.where((item) {
                            final itemType =
                                (item['type'] as String?)?.toLowerCase() ?? '';
                            final filterType =
                                _selectedPostedItemTypeFilter.toLowerCase();
                            return itemType == filterType;
                          }).toList();
                    }

                    // Apply topic filter
                    if (_selectedPostedItemTopicFilter != 'All Topics') {
                      postedItems =
                          postedItems.where((item) {
                            final itemTopicName = item['topicName'];
                            final itemTopicId = item['topicId'];

                            if (_selectedPostedItemTopicFilter == 'No Topic') {
                              // Show items with no topic assigned (null, empty, or string "null")
                              final hasNoTopic =
                                  itemTopicName == null ||
                                  itemTopicName == '' ||
                                  itemTopicName == 'null' ||
                                  itemTopicId == null ||
                                  itemTopicId == '' ||
                                  itemTopicId == 'null';
                              return hasNoTopic;
                            } else {
                              // Show items with matching topic name
                              final matches =
                                  itemTopicName ==
                                  _selectedPostedItemTopicFilter;
                              return matches;
                            }
                          }).toList();
                    }

                    // Sort by timestamp (most recent first)
                    postedItems.sort((a, b) {
                      dynamic timestampA = a['timestamp'];
                      dynamic timestampB = b['timestamp'];

                      // Handle different timestamp types
                      DateTime? dateTimeA;
                      DateTime? dateTimeB;

                      if (timestampA is Timestamp) {
                        dateTimeA = timestampA.toDate();
                      } else if (timestampA is DateTime) {
                        dateTimeA = timestampA;
                      } else if (timestampA is String) {
                        try {
                          dateTimeA = DateTime.parse(timestampA);
                        } catch (e) {
                          dateTimeA = null;
                        }
                      }

                      if (timestampB is Timestamp) {
                        dateTimeB = timestampB.toDate();
                      } else if (timestampB is DateTime) {
                        dateTimeB = timestampB;
                      } else if (timestampB is String) {
                        try {
                          dateTimeB = DateTime.parse(timestampB);
                        } catch (e) {
                          dateTimeB = null;
                        }
                      }

                      // Compare timestamps
                      if (dateTimeA == null && dateTimeB == null) return 0;
                      if (dateTimeA == null) return 1;
                      if (dateTimeB == null) return -1;

                      return dateTimeB.compareTo(dateTimeA);
                    });

                    if (postedItems.isEmpty) {
                      return Center(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 24,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/icons/solar_document-outline.png',
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'No assignments or activities posted yet',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'Create assignments, activities, and quizzes for your class.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: postedItems.length,
                      itemBuilder: (context, index) {
                        final item = postedItems[index];
                        return _buildActivityCard(item);
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeopleTab() {
    String currentSectionCode = widget.classData['section'] ?? '';
    String currentCourseCode = widget.classData['course'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Class Info Banner
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF34A853).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF34A853).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34A853),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.class_,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Viewing students for:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$currentCourseCode $currentSectionCode',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF34A853),
                        ),
                      ),
                    ],
                  ),
                ),
                // Enrollment Statistics
                Obx(() {
                  final stats = _classController.getEnrollmentStats(
                    currentSectionCode,
                  );
                  return Row(
                    children: [
                      _buildStatChip('Total', stats['total'] ?? 0, Colors.blue),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        'Pending',
                        stats['pending'] ?? 0,
                        Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        'Approved',
                        stats['approved'] ?? 0,
                        Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        'Rejected',
                        stats['rejected'] ?? 0,
                        Colors.red,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),

          // Teacher Section
          const Text(
            'Teacher',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 10),
          Divider(color: Colors.grey.withOpacity(0.4)),
          const SizedBox(height: 10),
          Row(
            children: [
              Obx(() => _buildInstructorProfileAvatar()),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(
                      () => Text(
                        _instructorController.instructorName.value,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Instructor',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Students',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Row(
                children: [
                  // Enrollment Status Filter
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedStudentFilter,
                      underline: const SizedBox(),
                      isDense: true,
                      hint: const Text('Status'),
                      items:
                          _studentFilterOptions.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedStudentFilter = newValue!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () async {
                      await _loadStudentsForThisClass();
                      // Also refresh status specifically
                      String sectionCode = widget.classData['section'] ?? '';
                      await _classController.refreshStudentStatus(sectionCode);

                      // Use addPostFrameCallback to prevent setState during build
                      if (mounted) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {}); // Trigger UI rebuild
                          }
                        });
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh students and status',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.grey.withOpacity(0.4)),
          const SizedBox(height: 10),
          Expanded(
            child: Obx(() {
              // Get students only for the current section
              String currentSection = widget.classData['section'] ?? '';
              List<Map<String, dynamic>> sectionStudents = _classController
                  .getStudentsForSection(currentSection);

              // Show skeleton loading if students are being loaded and list is empty
              if (_classController.isLoading.value && sectionStudents.isEmpty) {
                return ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, i) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          SkeletonAvatar(radius: 24),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SkeletonText(width: 200, height: 16),
                                const SizedBox(height: 4),
                                SkeletonText(width: 150, height: 13),
                              ],
                            ),
                          ),
                          SkeletonBox(width: 60, height: 24, borderRadius: 12),
                        ],
                      ),
                    );
                  },
                );
              }

              // Apply enrollment status filter
              List<Map<String, dynamic>> filteredStudents = sectionStudents;
              if (_selectedStudentFilter != 'All') {
                filteredStudents =
                    sectionStudents.where((student) {
                      final status = student['enrollmentStatus'] ?? 'pending';
                      switch (_selectedStudentFilter) {
                        case 'Pending':
                          return status == 'pending';
                        case 'Approved':
                          return status == 'approved';
                        case 'Rejected':
                          return status == 'rejected';
                        default:
                          return true;
                      }
                    }).toList();
              }

              if (filteredStudents.isEmpty) {
                String message = 'No students found';
                String subtitle =
                    'Students from section $currentSection will appear here when they complete their registration';

                if (_selectedStudentFilter != 'All') {
                  message =
                      'No ${_selectedStudentFilter.toLowerCase()} students found';
                  subtitle = 'Try changing the filter or refresh the list';
                }

                return Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 24,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              message,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = filteredStudents[index];
                  final enrollmentStatus =
                      student['enrollmentStatus'] ?? 'pending';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getEnrollmentStatusColor(
                          enrollmentStatus,
                        ).withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: _getEnrollmentStatusColor(
                            enrollmentStatus,
                          ).withOpacity(0.1),
                          child: Text(
                            (student['studentName'] ?? 'U').isNotEmpty
                                ? (student['studentName'] ?? 'U')
                                    .substring(0, 1)
                                    .toUpperCase()
                                : 'U',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _getEnrollmentStatusColor(
                                enrollmentStatus,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student['studentName'] ?? 'Unknown Student',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Enrolled: ${_formatEnrollmentDate(student['enrolledAt'])}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                              if (enrollmentStatus == 'rejected' &&
                                  student['rejectionReason'] != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Reason: ${student['rejectionReason']}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Status and Action Buttons - Use Column for better layout
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // First row: Status badges
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Enrollment Status Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getEnrollmentStatusColor(
                                      enrollmentStatus,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getEnrollmentStatusLabel(enrollmentStatus),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: _getEnrollmentStatusColor(
                                        enrollmentStatus,
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Active Status for approved students (real-time updates)
                                if (enrollmentStatus == 'approved')
                                  _buildOnlineStatusWidget(student),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Second row: Action buttons for pending enrollments and View COR button
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // View COR button (always visible for all students)
                                IconButton(
                                  onPressed: () => _viewStudentCOR(student),
                                  icon: Icon(
                                    Icons.description,
                                    color:
                                        (student['corUrl'] != null &&
                                                student['corUrl']
                                                    .toString()
                                                    .isNotEmpty)
                                            ? const Color(0xFF34A853)
                                            : Colors.grey,
                                    size: 18,
                                  ),
                                  tooltip:
                                      (student['corUrl'] != null &&
                                              student['corUrl']
                                                  .toString()
                                                  .isNotEmpty)
                                          ? 'View COR'
                                          : 'COR not uploaded',
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  style: IconButton.styleFrom(
                                    backgroundColor:
                                        (student['corUrl'] != null &&
                                                student['corUrl']
                                                    .toString()
                                                    .isNotEmpty)
                                            ? const Color(
                                              0xFF34A853,
                                            ).withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                                if (enrollmentStatus == 'pending')
                                  const SizedBox(width: 4),
                                // Approval buttons for pending students
                                if (enrollmentStatus == 'pending') ...[
                                  IconButton(
                                    onPressed: () => _approveStudent(student),
                                    icon: const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 18,
                                    ),
                                    tooltip: 'Approve enrollment',
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.green.withOpacity(
                                        0.1,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    onPressed: () => _rejectStudent(student),
                                    icon: const Icon(
                                      Icons.cancel,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    tooltip: 'Reject enrollment',
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.red.withOpacity(
                                        0.1,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  String _formatEnrollmentDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    try {
      if (timestamp is DateTime) {
        return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
      } else if (timestamp is Timestamp) {
        final dateTime = timestamp.toDate();
        return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
      }
      // Handle Firestore Timestamp
      return 'Recently enrolled';
    } catch (e) {
      return 'Unknown';
    }
  }

  // Helper method for filtering submissions
  List<Map<String, dynamic>> _filterSubmissions(
    List<Map<String, dynamic>> submissions,
  ) {
    List<Map<String, dynamic>> filtered = submissions;

    // Apply search filter
    if (_submissionSearchQuery.isNotEmpty) {
      filtered =
          filtered.where((submission) {
            final studentName =
                submission['studentName']?.toString().toLowerCase() ?? '';
            final activityTitle =
                submission['activityTitle']?.toString().toLowerCase() ?? '';
            final title = submission['title']?.toString().toLowerCase() ?? '';
            final type = submission['type']?.toString().toLowerCase() ?? '';

            return studentName.contains(_submissionSearchQuery) ||
                activityTitle.contains(_submissionSearchQuery) ||
                title.contains(_submissionSearchQuery) ||
                type.contains(_submissionSearchQuery);
          }).toList();
    }

    // Apply type filter
    if (_selectedSubmissionTypeFilter != 'All Types') {
      filtered =
          filtered.where((submission) {
            final type = submission['type']?.toString().toLowerCase() ?? '';
            switch (_selectedSubmissionTypeFilter) {
              case 'Assignment':
                return type == 'assignment';
              case 'Activity':
                return type == 'activity';
              case 'Quiz':
                return type == 'quiz';
              case 'PIT':
                return type == 'pit';
              default:
                return true;
            }
          }).toList();
    }

    // Apply status filter
    if (_selectedSubmissionStatusFilter != 'All Status') {
      filtered =
          filtered.where((submission) {
            final status = submission['status']?.toString().toLowerCase() ?? '';
            switch (_selectedSubmissionStatusFilter) {
              case 'Submitted':
                return status == 'submitted';
              case 'Graded':
                return status == 'graded';
              case 'Late':
                return status == 'late';
              default:
                return true;
            }
          }).toList();
    }

    return filtered;
  }

  // Helper method to get filtered submissions count
  int _getFilteredSubmissionsCount() {
    List<Map<String, dynamic>> submissions = [];
    for (var submission in _submissionsController.submissions) {
      submissions.add({
        ...submission,
        'itemType': 'submission',
        'timestamp': submission['submittedAt'],
        'title': '${submission['studentName']} submitted ${submission['type']}',
        'description': 'Submitted work for review',
      });
    }
    return _filterSubmissions(submissions).length;
  }

  // Helper methods for enrollment status
  Color _getEnrollmentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getEnrollmentStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'pending':
        return 'Pending';
      default:
        return 'Unknown';
    }
  }

  // Helper method for building stat chips
  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }

  // Action handlers for student enrollment
  void _approveStudent(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Approve Student Enrollment'),
            content: Text(
              'Are you sure you want to approve ${student['studentName']}\'s enrollment?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _classController.approveStudentEnrollment(
                    studentId: student['studentId'],
                    sectionCode: widget.classData['section'] ?? '',
                  );
                  // Refresh the student list and status
                  await _loadStudentsForThisClass();
                  // Set up status monitoring for the newly approved student
                  String sectionCode = widget.classData['section'] ?? '';
                  _classController.setupStudentStatusListener(sectionCode);

                  // Use addPostFrameCallback to prevent setState during build
                  if (mounted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {}); // Trigger UI rebuild
                      }
                    });
                  }
                },
                child: const Text(
                  'Approve',
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ],
          ),
    );
  }

  void _rejectStudent(Map<String, dynamic> student) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reject Student Enrollment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to reject ${student['studentName']}\'s enrollment?',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Reason for rejection (optional):',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    hintText: 'Enter reason for rejection...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _classController.rejectStudentEnrollment(
                    studentId: student['studentId'],
                    sectionCode: widget.classData['section'] ?? '',
                    reason:
                        reasonController.text.trim().isNotEmpty
                            ? reasonController.text.trim()
                            : null,
                  );
                  // Refresh the student list and status
                  await _loadStudentsForThisClass();

                  // Use addPostFrameCallback to prevent setState during build
                  if (mounted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {}); // Trigger UI rebuild
                      }
                    });
                  }
                },
                child: const Text(
                  'Reject',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _viewStudentCOR(Map<String, dynamic> student) {
    final corUrl = student['corUrl']?.toString() ?? '';

    if (corUrl.isEmpty) {
      Get.snackbar(
        'COR Not Available',
        'This student has not uploaded their Certificate of Registration.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Certificate of Registration',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF34A853),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            student['studentName'] ?? 'Unknown Student',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF34A853).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf,
                            size: 40,
                            color: Color(0xFF34A853),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'COR Document',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'PDF Document',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse(corUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              Get.snackbar(
                                'Error',
                                'Could not open the COR document',
                                snackPosition: SnackPosition.TOP,
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF34A853),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: const Text('Open PDF'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'This document was uploaded during registration and is stored securely in the cloud.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildClassworkTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Activity and Submissions
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Student Submissions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await _loadRecentSubmissions();
                      },
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh submissions',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search and Filter Controls
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      // Search Bar
                      TextField(
                        controller: _submissionSearchController,
                        decoration: InputDecoration(
                          hintText:
                              'Search by student name or activity name...',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                          suffixIcon:
                              _submissionSearchQuery.isNotEmpty
                                  ? IconButton(
                                    onPressed: () {
                                      _submissionSearchController.clear();
                                      setState(() {
                                        _submissionSearchQuery = '';
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Colors.grey,
                                    ),
                                  )
                                  : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF34A853),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _submissionSearchQuery = value.toLowerCase();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      // Filter Controls
                      Row(
                        children: [
                          // Type Filter
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: DropdownButton<String>(
                                value: _selectedSubmissionTypeFilter,
                                underline: const SizedBox(),
                                isDense: true,
                                hint: const Text('Filter by type'),
                                items:
                                    _submissionTypeFilterOptions.map((
                                      String value,
                                    ) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(
                                          value,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedSubmissionTypeFilter = newValue!;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Status Filter
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: DropdownButton<String>(
                                value: _selectedSubmissionStatusFilter,
                                underline: const SizedBox(),
                                isDense: true,
                                hint: const Text('Filter by status'),
                                items:
                                    _submissionStatusFilterOptions.map((
                                      String value,
                                    ) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(
                                          value,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedSubmissionStatusFilter = newValue!;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Clear Filters Button
                          IconButton(
                            onPressed: () {
                              _submissionSearchController.clear();
                              setState(() {
                                _submissionSearchQuery = '';
                                _selectedSubmissionTypeFilter = 'All Types';
                                _selectedSubmissionStatusFilter = 'All Status';
                              });
                            },
                            icon: const Icon(Icons.clear_all),
                            tooltip: 'Clear all filters',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey.withOpacity(0.1),
                              foregroundColor: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Results Counter
                if (_submissionSearchQuery.isNotEmpty ||
                    _selectedSubmissionTypeFilter != 'All Types' ||
                    _selectedSubmissionStatusFilter != 'All Status')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34A853).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF34A853).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.filter_list,
                          size: 16,
                          color: const Color(0xFF34A853),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Showing ${_getFilteredSubmissionsCount()} submission${_getFilteredSubmissionsCount() != 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF34A853),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_submissionSearchQuery.isNotEmpty ||
                    _selectedSubmissionTypeFilter != 'All Types' ||
                    _selectedSubmissionStatusFilter != 'All Status')
                  const SizedBox(height: 12),

                // Student Submissions List
                Expanded(
                  child: Obx(() {
                    if (_submissionsController.isLoading.value) {
                      return ListView.builder(
                        itemCount: 5,
                        itemBuilder: (context, i) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: SkeletonInstructorCreateItemCard(),
                          );
                        },
                      );
                    }

                    // Get only student submissions
                    List<Map<String, dynamic>> submissions = [];
                    for (var submission in _submissionsController.submissions) {
                      submissions.add({
                        ...submission,
                        'itemType': 'submission',
                        'timestamp': submission['submittedAt'],
                        'title':
                            '${submission['studentName']} submitted ${submission['type']}',
                        'description': 'Submitted work for review',
                      });
                    }

                    // Apply search and filters
                    submissions = _filterSubmissions(submissions);

                    // Sort by timestamp (most recent first)
                    submissions.sort((a, b) {
                      dynamic timestampA = a['timestamp'];
                      dynamic timestampB = b['timestamp'];

                      // Handle different timestamp types
                      DateTime? dateTimeA;
                      DateTime? dateTimeB;

                      if (timestampA is Timestamp) {
                        dateTimeA = timestampA.toDate();
                      } else if (timestampA is DateTime) {
                        dateTimeA = timestampA;
                      } else if (timestampA is String) {
                        try {
                          dateTimeA = DateTime.parse(timestampA);
                        } catch (e) {
                          dateTimeA = null;
                        }
                      }

                      if (timestampB is Timestamp) {
                        dateTimeB = timestampB.toDate();
                      } else if (timestampB is DateTime) {
                        dateTimeB = timestampB;
                      } else if (timestampB is String) {
                        try {
                          dateTimeB = DateTime.parse(timestampB);
                        } catch (e) {
                          dateTimeB = null;
                        }
                      }

                      // Compare timestamps
                      if (dateTimeA == null && dateTimeB == null) return 0;
                      if (dateTimeA == null) return 1;
                      if (dateTimeB == null) return -1;

                      return dateTimeB.compareTo(dateTimeA);
                    });

                    if (submissions.isEmpty) {
                      return Center(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 24,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/icons/solar_document-outline.png',
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'No student submissions yet',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'Student submissions will appear here when they submit their work.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: submissions.length,
                      itemBuilder: (context, index) {
                        final submission = submissions[index];
                        return _buildSubmissionCard(submission);
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToItem(item),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF34A853),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.description, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${_instructorController.instructorName.value} posted new ${item['type'].toLowerCase()}:',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          item['title'] ?? 'No Title',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Topic badge
                  if (item['topicName'] != null && item['topicName'] != '') ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34A853).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF34A853).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bookmark,
                            size: 14,
                            color: Color(0xFF34A853),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item['topicName'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF34A853),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    children: [
                      if (item['dueDate'] != null) ...[
                        Text(
                          'Due: ${_formatTimestamp(item['dueDate'])}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      Text(
                        'Created: ${_formatTimestamp(item['createdAt'])}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionCard(Map<String, dynamic> submission) {
    final status = submission['status'] ?? 'submitted';
    final studentName = submission['studentName'] ?? 'Unknown Student';
    final submissionType = submission['type'] ?? 'assignment';
    final submittedAt = submission['submittedAt'];
    final grade = submission['grade'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getSubmissionStatusColor(status).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToSubmissionDetail(submission),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getSubmissionStatusColor(status).withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getSubmissionStatusColor(status),
                  width: 2,
                ),
              ),
              child: Icon(
                _getSubmissionStatusIcon(status),
                color: _getSubmissionStatusColor(status),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$studentName submitted ',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        submissionType,
                        style: TextStyle(
                          fontSize: 14,
                          color: _getTypeColor(submissionType),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Submitted: ${_formatSubmissionDate(submittedAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getSubmissionStatusColor(
                            status,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: _getSubmissionStatusColor(status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Delete button
                      GestureDetector(
                        onTap: () => _showRemoveSubmissionDialog(submission),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 16,
                          ),
                        ),
                      ),
                      if (grade != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Grade: $grade',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _navigateToItem(Map<String, dynamic> item) {
    // Navigate to appropriate screen based on item type
    String itemType = item['type'] ?? '';
    // Use section name (like "BSIT-1A") instead of sectionId, matching how we load submissions
    final sectionCode = widget.classData['section'] ?? '';

    switch (itemType.toLowerCase()) {
      case 'material':
        // Navigate to material detail screen for materials
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MaterialsDetailScreen(material: item),
          ),
        );
        break;
      case 'assignment':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => StudentSubmissionsScreen(
                  activityData: item,
                  sectionId: sectionCode,
                ),
          ),
        );
        break;
      case 'activity':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => StudentSubmissionsScreen(
                  activityData: item,
                  sectionId: sectionCode,
                ),
          ),
        );
        break;
      case 'quiz':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => StudentSubmissionsScreen(
                  activityData: item,
                  sectionId: sectionCode,
                ),
          ),
        );
        break;
      default:
        // Default navigation to submissions screen for other types
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => StudentSubmissionsScreen(
                  activityData: item,
                  sectionId: sectionCode,
                ),
          ),
        );
    }
  }

  void _navigateToSubmissionDetail(Map<String, dynamic> submission) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Get the actual points from the assignment/quiz/activity document
    int actualPoints = 100; // Default fallback

    try {
      // Unified submissions use 'activityId' for all types (assignment, activity, quiz, pit)
      final assignmentId =
          submission['activityId'] ?? // Unified field (preferred)
          submission['assignmentId'] ??
          submission['quizId'] ??
          submission['pitId'];

      if (assignmentId != null) {
        // Check both 'type' and 'activityType' fields (unified submissions use 'activityType')
        final submissionType =
            submission['type'] ?? submission['activityType'] ?? 'activity';
        String collection;

        switch (submissionType.toLowerCase()) {
          case 'assignment':
            collection = 'assignments';
            break;
          case 'activity':
            collection = 'activities';
            break;
          case 'quiz':
            collection = 'quizzes';
            break;
          case 'pit':
            collection = 'pits';
            break;
          default:
            collection = 'activities';
        }

        // Get the instructor ID from the current user
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final doc =
              await FirebaseFirestore.instance
                  .collection('instructors')
                  .doc(user.uid)
                  .collection(collection)
                  .doc(assignmentId)
                  .get();

          if (doc.exists) {
            final data = doc.data()!;
            actualPoints = data['points'] ?? data['maxPoints'] ?? 100;
            print(
              '✅ Fetched actual points: $actualPoints for $submissionType $assignmentId',
            );
          }
        }
      }
    } catch (e) {
      print('Error fetching actual points: $e');
      // Keep default value of 100
    }

    // Hide loading indicator
    Navigator.of(context).pop();

    // Create activity data for the submission detail screen
    // Check both 'type' and 'activityType' fields (unified submissions use 'activityType')
    final submissionType =
        submission['type'] ?? submission['activityType'] ?? 'activity';

    final activityData = {
      'id':
          submission['activityId'] ?? // Unified field (preferred)
          submission['assignmentId'] ??
          submission['quizId'] ??
          submission['pitId'] ??
          submission['id'],
      'type': submissionType,
      'title':
          submission['activityTitle'] ??
          submission['title'] ??
          'Untitled $submissionType',
      'points': actualPoints, // Use actual points instead of fallback
      'description': submission['description'] ?? '',
    };

    // Navigate to submission detail screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => SubmissionDetailScreen(
              activityData: activityData,
              submissionData: submission,
            ),
      ),
    );
  }

  Color _getSubmissionStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Colors.blue;
      case 'graded':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'missing':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getSubmissionStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Icons.upload_file;
      case 'graded':
        return Icons.check_circle;
      case 'late':
        return Icons.schedule;
      case 'missing':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'assignment':
        return Colors.purple;
      case 'activity':
        return Colors.blue;
      case 'quiz':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatSubmissionDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    try {
      DateTime? dateTime;

      if (timestamp is String) {
        // Try to parse the string timestamp
        dateTime = DateTime.parse(timestamp);
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else {
        return 'Recently submitted';
      }

      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    } catch (e) {
      print('❌ Error formatting submission date: $e');
      return 'Recently submitted';
    }
  }

  // Show confirmation dialog for removing submission
  void _showRemoveSubmissionDialog(Map<String, dynamic> submission) {
    final studentName = submission['studentName'] ?? 'Unknown Student';
    final submissionType = submission['type'] ?? 'assignment';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove Submission'),
            content: Text(
              'Are you sure you want to remove the $submissionType submission from $studentName? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _removeSubmission(submission);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Remove'),
              ),
            ],
          ),
    );
  }

  // Remove submission from Firestore and local list
  Future<void> _removeSubmission(Map<String, dynamic> submission) async {
    try {
      final submissionId = submission['id'];
      final submissionType = submission['type'] ?? 'assignment';

      if (submissionId == null) {
        Get.snackbar(
          'Error',
          'Submission ID not found',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Show loading
      Get.snackbar(
        'Removing',
        'Removing submission...',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );

      // Remove from submissions controller
      final success = await _submissionsController.removeSubmission(
        submissionId,
        submissionType,
      );

      if (success) {
        Get.snackbar(
          'Success',
          'Submission removed successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to remove submission',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error removing submission: $e');
      Get.snackbar(
        'Error',
        'Failed to remove submission: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Show plant tree dialog
  void _showPlantTreeDialog() {
    final TextEditingController quantityController = TextEditingController(
      text: '1',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.eco, color: Color(0xFF34A853)),
                SizedBox(width: 8),
                Text('Add a Tree'),
              ],
            ),
            content: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quantity field
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      hintText: 'Enter number of trees',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final quantityText = quantityController.text.trim();

                  if (quantityText.isEmpty) {
                    Get.snackbar(
                      'Error',
                      'Please enter a quantity',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                    return;
                  }

                  final quantity = int.tryParse(quantityText);
                  if (quantity == null || quantity <= 0) {
                    Get.snackbar(
                      'Error',
                      'Please enter a valid quantity (number greater than 0)',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                    return;
                  }

                  Navigator.of(context).pop();

                  // Show loading
                  Get.snackbar(
                    'Adding Tree',
                    'Please wait...',
                    backgroundColor: const Color(0xFF34A853),
                    colorText: Colors.white,
                    duration: const Duration(seconds: 1),
                  );

                  // Add tree to Firestore
                  await _addTreeToClass(quantity);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF34A853),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add Tree'),
              ),
            ],
          ),
    );
  }

  // Add tree to the class
  Future<void> _addTreeToClass(int quantity) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Get.snackbar(
          'Error',
          'No user logged in',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Get class information
      final classData = widget.classData;
      final className = '${classData['course']} ${classData['section']}';
      final sectionName = classData['section'] ?? '';

      // Tree data for this class
      final treeData = {
        "plantedBy": sectionName, // Use section name as plantedBy
        "plantDate": DateTime.now().toString().split(' ')[0], // Today's date
        "quantity": quantity,
        "instructorId": user.uid, // Use instructorId instead of ownerId
        "classId": classData['id'],
        "className": className,
        "createdAt": FieldValue.serverTimestamp(),
      };

      // Save to instructors/{userId}/trees collection
      await FirebaseFirestore.instance
          .collection('instructors')
          .doc(user.uid)
          .collection('trees')
          .add(treeData);

      Get.snackbar(
        'Success',
        'Tree added successfully to $className!',
        backgroundColor: const Color(0xFF34A853),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      print('Error adding tree: $e');
      Get.snackbar(
        'Error',
        'Failed to add tree: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Widget _buildTreesTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trees Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Planted Trees',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              IconButton(
                onPressed: () {
                  // Refresh trees data
                  setState(() {});
                },
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh trees',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Trees List
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadTreesForClass(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    itemCount: 4,
                    itemBuilder: (context, i) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                          ),
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
                            SkeletonBox(width: 60, height: 60, borderRadius: 8),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SkeletonText(width: 200, height: 18),
                                  const SizedBox(height: 8),
                                  SkeletonText(width: 150, height: 14),
                                  const SizedBox(height: 4),
                                  SkeletonText(width: 100, height: 12),
                                ],
                              ),
                            ),
                            SkeletonBox(width: 24, height: 24, borderRadius: 4),
                          ],
                        ),
                      );
                    },
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading trees: ${snapshot.error}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final trees = snapshot.data ?? [];

                if (trees.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 24,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.eco_outlined,
                              size: 64,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'No trees planted yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Click the "Plant Tree" button to add trees for this class.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: trees.length,
                  itemBuilder: (context, index) {
                    final tree = trees[index];
                    return _buildTreeCard(tree);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Load trees for this specific class
  Future<List<Map<String, dynamic>>> _loadTreesForClass() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return [];
      }

      final classData = widget.classData;
      final sectionName = classData['section'] ?? '';

      print('🌳 Loading tree submissions for section: $sectionName');
      print('🌳 User ID: ${user.uid}');

      // Load from submissions collection with tree_planting type
      final snapshot =
          await FirebaseFirestore.instance
              .collection('submissions')
              .where('activityType', isEqualTo: 'tree_planting')
              .where('instructorId', isEqualTo: user.uid)
              .where('sectionName', isEqualTo: sectionName)
              .get();

      print('🌳 Found ${snapshot.docs.length} tree planting submissions');

      final trees =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'studentName': data['studentName'] ?? 'Unknown',
              'studentIdNumber': data['studentIdNumber'] ?? '',
              'studentId': data['studentId'] ?? '',
              'plantDate': data['plantDate'] ?? '',
              'quantity': data['quantity'] ?? 1,
              'location': data['location'] ?? '',
              'status': data['status'] ?? 'submitted',
              'feedback': data['feedback'],
              'files': data['files'] ?? [],
              'submittedAt': data['submittedAt'],
              'isStudentSubmission': true, // Mark as student submission
            };
          }).toList();

      // Sort by submittedAt descending (most recent first)
      trees.sort((a, b) {
        final aTime = a['submittedAt'] as Timestamp?;
        final bTime = b['submittedAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      return trees;
    } catch (e) {
      print('Error loading tree submissions for class: $e');
      return [];
    }
  }

  // Build tree card widget
  Widget _buildTreeCard(Map<String, dynamic> tree) {
    final isStudentSubmission = tree['isStudentSubmission'] == true;
    final status = tree['status'] ?? 'submitted';
    final files = tree['files'] as List<dynamic>? ?? [];

    // Format the plant date
    String formattedDate = 'Unknown';
    final plantDate = tree['plantDate'];
    if (plantDate != null) {
      if (plantDate is Timestamp) {
        final dateTime = plantDate.toDate();
        formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime);
      } else if (plantDate is String) {
        // Handle old string format
        formattedDate = plantDate;
      }
    }

    Color statusColor;
    String statusText;
    switch (status) {
      case 'approved':
        statusColor = const Color(0xFF34A853);
        statusText = 'APPROVED';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'REJECTED';
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'PENDING';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isStudentSubmission
                  ? statusColor.withOpacity(0.3)
                  : const Color(0xFF34A853).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // User avatar or tree icon
              if (isStudentSubmission)
                FutureBuilder<DocumentSnapshot>(
                  future:
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(tree['studentId'])
                          .get(),
                  builder: (context, snapshot) {
                    String? photoUrl;
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final userData =
                          snapshot.data!.data() as Map<String, dynamic>?;
                      photoUrl = userData?['photoUrl'];
                    }

                    return Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color:
                            photoUrl == null
                                ? const Color(0xFF34A853).withOpacity(0.1)
                                : null,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child:
                          photoUrl != null
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(25),
                                child: Image.network(
                                  photoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Text(
                                        _getInitials(
                                          tree['studentName'] ?? 'Unknown',
                                        ),
                                        style: const TextStyle(
                                          color: Color(0xFF34A853),
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                              : Center(
                                child: Text(
                                  _getInitials(
                                    tree['studentName'] ?? 'Unknown',
                                  ),
                                  style: const TextStyle(
                                    color: Color(0xFF34A853),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                    );
                  },
                )
              else
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF34A853).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(
                    Icons.eco,
                    color: Color(0xFF34A853),
                    size: 24,
                  ),
                ),
              const SizedBox(width: 16),
              // Tree details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${tree['quantity']} tree${tree['quantity'] > 1 ? 's' : ''} planted',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (isStudentSubmission) ...[
                      Text(
                        'By: ${tree['studentName']} (${tree['studentIdNumber']})',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      if (tree['location']?.isNotEmpty == true) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              tree['location'],
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ] else
                      Text(
                        'Planted by: ${tree['plantedBy']}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      'Date: $formattedDate',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // Status badge and quantity for student submissions
              if (isStudentSubmission)
                Row(
                  children: [
                    // Quantity badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34A853).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.eco,
                            size: 14,
                            color: Color(0xFF34A853),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${tree['quantity']}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF34A853),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34A853).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${tree['quantity']}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF34A853),
                    ),
                  ),
                ),
            ],
          ),

          // Evidence photos for student submissions
          if (isStudentSubmission && files.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Evidence:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: files.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final file = files[index];
                  final fileUrl = file['url'] ?? '';
                  return GestureDetector(
                    onTap: () async {
                      if (fileUrl.isNotEmpty) {
                        final uri = Uri.parse(fileUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      }
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          fileUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.image, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // Feedback section
          if (isStudentSubmission && tree['feedback'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.feedback, size: 14, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tree['feedback'],
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action buttons for pending submissions
          if (isStudentSubmission && status == 'submitted') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectTreeSubmission(tree),
                    icon: const Icon(Icons.cancel, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveTreeSubmission(tree),
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF34A853),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Approve tree submission
  Future<void> _approveTreeSubmission(Map<String, dynamic> submission) async {
    final result = await CustomDialogs.showApprovalDialog(
      context: context,
      title: 'Approve Tree Planting',
      message:
          'Are you sure you want to approve ${submission['quantity']} tree(s) planted by ${submission['studentName']}?',
      feedbackLabel: 'Feedback (optional)',
      feedbackHint: 'Add your feedback here...',
      confirmText: 'Approve',
      iconColor: const Color(0xFF34A853),
      confirmButtonColor: const Color(0xFF34A853),
      icon: Icons.check_circle,
    );

    if (result['confirmed'] == true) {
      try {
        await FirebaseFirestore.instance
            .collection('submissions')
            .doc(submission['id'])
            .update({
              'status': 'approved',
              'feedback':
                  result['feedback'].isEmpty ? null : result['feedback'],
              'gradedAt': FieldValue.serverTimestamp(),
              'gradedBy': FirebaseAuth.instance.currentUser?.uid,
            });

        // Send push notification to student
        final studentId = submission['studentId'];
        if (studentId != null) {
          try {
            final playerId = await OneSignalHelper.getPlayerIdForUser(
              studentId,
            );
            if (playerId != null) {
              await NotifServices.sendIndividualNotification(
                playerId: playerId,
                heading: '🌳 Tree Planting Approved!',
                content:
                    result['feedback'].isEmpty
                        ? 'Your tree planting submission has been approved. Great work!'
                        : 'Your tree planting has been approved! Feedback: ${result['feedback']}',
              );
            }

            // Create in-app notification
            final instructorName = _instructorController.instructorName.value;
            await InAppNotificationService.createIndividualNotification(
              type: 'tree_approved',
              instructorId: FirebaseAuth.instance.currentUser?.uid ?? '',
              instructorName: instructorName,
              itemId: submission['id'],
              title: 'Tree Planting Approved',
              targetUserIds: [studentId],
              description:
                  result['feedback'].isEmpty
                      ? 'Your tree planting submission (${submission['quantity']} trees) has been approved. Great work!'
                      : 'Your tree planting (${submission['quantity']} trees) has been approved! Feedback: ${result['feedback']}',
              metadata: {
                'quantity': submission['quantity'],
                'location': submission['location'],
                'plantDate': submission['plantDate'],
                'status': 'approved',
              },
            );
          } catch (e) {
            print('Error sending notification: $e');
          }
        }

        Get.snackbar(
          'Success',
          'Tree planting approved',
          backgroundColor: const Color(0xFF34A853),
          colorText: Colors.white,
        );

        setState(() {}); // Refresh the list
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to approve: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  // Reject tree submission
  Future<void> _rejectTreeSubmission(Map<String, dynamic> submission) async {
    final result = await CustomDialogs.showRejectionDialog(
      context: context,
      title: 'Reject Tree Planting',
      message:
          'Are you sure you want to reject the tree planting submission from ${submission['studentName']}?',
      reasonLabel: 'Reason for rejection (required)',
      reasonHint: 'Explain why this submission is being rejected...',
      confirmText: 'Reject',
      iconColor: Colors.red,
      confirmButtonColor: Colors.red,
      icon: Icons.cancel,
      errorMessage: 'Please provide a reason for rejection',
    );

    if (result['confirmed'] == true && result['feedback'].isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('submissions')
            .doc(submission['id'])
            .update({
              'status': 'rejected',
              'feedback': result['feedback'],
              'gradedAt': FieldValue.serverTimestamp(),
              'gradedBy': FirebaseAuth.instance.currentUser?.uid,
            });

        // Send push notification to student
        final studentId = submission['studentId'];
        if (studentId != null) {
          try {
            final playerId = await OneSignalHelper.getPlayerIdForUser(
              studentId,
            );
            if (playerId != null) {
              await NotifServices.sendIndividualNotification(
                playerId: playerId,
                heading: '🌳 Tree Planting Needs Revision',
                content:
                    'Your tree planting submission was not accepted. Reason: ${result['feedback']}',
              );
            }

            // Create in-app notification
            final instructorName = _instructorController.instructorName.value;
            await InAppNotificationService.createIndividualNotification(
              type: 'tree_rejected',
              instructorId: FirebaseAuth.instance.currentUser?.uid ?? '',
              instructorName: instructorName,
              itemId: submission['id'],
              title: 'Tree Planting Needs Revision',
              targetUserIds: [studentId],
              description:
                  'Your tree planting submission (${submission['quantity']} trees) needs revision. Reason: ${result['feedback']}',
              metadata: {
                'quantity': submission['quantity'],
                'location': submission['location'],
                'plantDate': submission['plantDate'],
                'status': 'rejected',
                'feedback': result['feedback'],
              },
            );
          } catch (e) {
            print('Error sending notification: $e');
          }
        }

        Get.snackbar(
          'Success',
          'Tree planting rejected',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );

        setState(() {}); // Refresh the list
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to reject: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  /// Build instructor profile avatar with image or initials
  Widget _buildInstructorProfileAvatar() {
    // Get initials from name
    String getInitials(String name) {
      if (name.isEmpty) return '';
      final parts = name.trim().split(' ');
      if (parts.length == 1) {
        return parts[0].substring(0, 1).toUpperCase();
      }
      return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
          .toUpperCase();
    }

    final instructorName = _instructorController.instructorName.value;
    final profileImageUrl = _instructorController.profileImageUrl.value;
    final initials = getInitials(instructorName);
    final hasImage = profileImageUrl.isNotEmpty;

    return CircleAvatar(
      radius: 30,
      backgroundColor: hasImage ? Colors.transparent : const Color(0xFF34A853),
      backgroundImage: hasImage ? NetworkImage(profileImageUrl) : null,
      child:
          !hasImage
              ? Text(
                initials,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
              : null,
    );
  }
}
