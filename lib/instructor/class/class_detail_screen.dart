// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/instructor/instructor_appbar.dart';
import '../../shared/instructor/instructor_sidebar.dart';
import '../../shared/instructor/instructor_navigation_constants.dart';
import '../create/create_controller.dart';
import '../submissions/student_submissions_screen.dart';
import 'class_screen_controller.dart';

class ClassDetailScreen extends StatefulWidget {
  final Map<String, dynamic> classData;

  const ClassDetailScreen({super.key, required this.classData});

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  InstructorNavigationItem _selectedItem =
      InstructorNavigationItem.classManagement;
  int _selectedTabIndex = 0; // Stream tab by default
  final CreateController _createController = Get.put(CreateController());
  final ClassController _classController = Get.find<ClassController>();

  // Sorting states
  List<Map<String, dynamic>> _sortedGrades = [];

  // Filter states for Created Items
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Assignment', 'Activity', 'Quiz'];

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
    // Load created items when the screen initializes
    _createController.loadCreatedItems();
    // Load students for this specific class
    _loadStudentsForThisClass();
  }

  Future<void> _loadStudentsForThisClass() async {
    // Load students from users collection who selected this instructor
    // and are in this specific section
    String sectionCode = widget.classData['section'] ?? '';
    await _classController.loadStudentsFromUsersCollection(
      sectionCode: sectionCode,
    );
    // Refresh the UI to show updated student list
    setState(() {});
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
                const InstructorAppBar(
                  instructorName: 'Mia Castro',
                  instructorRole: 'Instructor',
                ),
                // Main Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tabs
                        Row(
                          children: [
                            _buildTab('Class', 0),
                            const SizedBox(width: 32),
                            _buildTab('Students', 1),
                            const SizedBox(width: 32),
                            _buildTab('Created Items', 2),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // Tab Content
                        Expanded(child: _buildTabContent()),
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

  Widget _buildTab(String title, int index) {
    bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => _selectTab(index),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? const Color(0xFF34A853) : Colors.black54,
            ),
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
        return _buildCreatedItemsTab();
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
                      Text(
                        '${_getDayAbbreviation(widget.classData['day'])} ${widget.classData['startTime']} - ${widget.classData['endTime']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
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
          // Activities List
          Expanded(
            child: Obx(() {
              if (_createController.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF34A853)),
                );
              }

              if (_createController.createdItems.isEmpty) {
                return Center(
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
                      const Text(
                        'No activities posted yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create assignments, activities, and quizzes for your class.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: _createController.createdItems.length,
                itemBuilder: (context, index) {
                  final item = _createController.createdItems[index];
                  return _buildActivityCard(item);
                },
              );
            }),
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
              CircleAvatar(
                radius: 30,
                backgroundImage: AssetImage('assets/images/Avatar.png'),
              ),
              const SizedBox(width: 16),
              Obx(
                () => Text(
                  _classController.instructorName.value,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              IconButton(
                onPressed: _loadStudentsForThisClass,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh students',
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

              if (sectionStudents.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No students enrolled in $currentSection yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Students from section $currentSection will appear here when they complete their registration',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: sectionStudents.length,
                itemBuilder: (context, index) {
                  final student = sectionStudents[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
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
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(
                            0xFF34A853,
                          ).withOpacity(0.1),
                          child: Text(
                            (student['studentName'] ?? 'U')
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF34A853),
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
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF34A853).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF34A853),
                              fontWeight: FontWeight.bold,
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
        ],
      ),
    );
  }

  String _formatEnrollmentDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    try {
      if (timestamp is DateTime) {
        return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
      }
      // Handle Firestore Timestamp
      return 'Recently enrolled';
    } catch (e) {
      return 'Unknown';
    }
  }

  Widget _buildCreatedItemsTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Created Items',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              // Filter dropdown
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedFilter,
                  underline: const SizedBox(),
                  isDense: true,
                  items:
                      _filterOptions.map((String value) {
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
                      _selectedFilter = newValue!;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Items List
          Expanded(
            child: Obx(() {
              if (_createController.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF34A853)),
                );
              }

              if (_createController.createdItems.isEmpty) {
                return Center(
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
                      const Text(
                        'No created items yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create assignments, activities, and quizzes for your class.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              // Filter items based on selected filter
              final filteredItems =
                  _selectedFilter == 'All'
                      ? _createController.createdItems
                      : _createController.createdItems
                          .where((item) => item['type'] == _selectedFilter)
                          .toList();

              return ListView.builder(
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  return _buildCreatedItemCard(item);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatedItemCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF34A853),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getItemIcon(item['type']),
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type badges
                Row(
                  children: [
                    _buildTypeBadge(item['type']),
                    if (item['period'] != null) ...[
                      const SizedBox(width: 8),
                      _buildTypeBadge(item['period']),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                // Title
                Text(
                  item['title'] ?? 'No Title',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),

                // Details
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Topic: ${item['topic'] ?? 'No Topic'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    if (item['points'] != null) ...[
                      const SizedBox(width: 16),
                      Text(
                        'Points: ${item['points']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),

                // Dates
                Row(
                  children: [
                    if (item['dueDate'] != null) ...[
                      Expanded(
                        child: Text(
                          'Due: ${item['dueDate']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Created: ${item['createdAt']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Options menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'edit') {
                _editItem(item);
              } else if (value == 'delete') {
                _deleteItem(item);
              } else if (value == 'submissions') {
                _navigateToSubmissions(item);
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'submissions',
                    child: Row(
                      children: [
                        Icon(Icons.people, size: 16),
                        SizedBox(width: 8),
                        Text('View Submissions'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
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

  Widget _buildTypeBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Colors.grey,
        ),
      ),
    );
  }

  IconData _getItemIcon(String type) {
    switch (type.toLowerCase()) {
      case 'assignment':
        return Icons.assignment;
      case 'activity':
        return Icons.quiz;
      case 'quiz':
        return Icons.quiz_outlined;
      default:
        return Icons.description;
    }
  }

  void _editItem(Map<String, dynamic> item) {
    // Navigate to edit screen based on item type
    String route = '';
    switch (item['type']) {
      case 'Assignment':
        route = '/assignment';
        break;
      case 'Activity':
        route = '/activity';
        break;
      case 'Quiz':
        route = '/quiz';
        break;
    }

    if (route.isNotEmpty) {
      Navigator.of(context).pushNamed(
        route,
        arguments: {'isEdit': true, 'itemId': item['id'], 'initialData': item},
      );
    }
  }

  void _deleteItem(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Item'),
            content: Text(
              'Are you sure you want to delete "${item['title']}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _createController.deleteItem(item['id'], item['type']);
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
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
              child: Icon(
                _getItemIcon(item['type']),
                color: Colors.white,
                size: 24,
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
                        '${_classController.instructorName.value} posted new ${item['type'].toLowerCase()}:',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        item['title'] ?? 'No Title',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (item['dueDate'] != null) ...[
                        Text(
                          'Due: ${item['dueDate']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      Text(
                        'Created: ${item['createdAt'] ?? 'Unknown'}',
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

  void _navigateToItem(Map<String, dynamic> item) {
    // Navigate to appropriate screen based on item type
    String itemType = item['type'] ?? '';

    switch (itemType.toLowerCase()) {
      case 'assignment':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StudentSubmissionsScreen(activityData: item),
          ),
        );
        break;
      case 'activity':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StudentSubmissionsScreen(activityData: item),
          ),
        );
        break;
      case 'quiz':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StudentSubmissionsScreen(activityData: item),
          ),
        );
        break;
      default:
        // Default navigation to submissions screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StudentSubmissionsScreen(activityData: item),
          ),
        );
    }
  }

  void _navigateToSubmissions(Map<String, dynamic> activity) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StudentSubmissionsScreen(activityData: activity),
      ),
    );
  }
}
