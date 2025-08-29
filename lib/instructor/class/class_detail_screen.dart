// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../shared/instructor/instructor_appbar.dart';
import '../../shared/instructor/instructor_sidebar.dart';

class ClassDetailScreen extends StatefulWidget {
  final Map<String, dynamic> classData;
  
  const ClassDetailScreen({super.key, required this.classData});

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  int _selectedSidebarIndex = 2; // Class index
  int _selectedTabIndex = 0; // Stream tab by default
  
  // Checkbox states
  bool _selectAll = false;
  Map<String, bool> _studentSelections = {};
  
  // Sorting states
  String _sortBy = 'Sort by Last name';
  List<Map<String, dynamic>> _sortedGrades = [];

  // Sample data for the class
  final List<Map<String, dynamic>> _activities = [
    {
      'type': 'activity',
      'title': 'ACTIVITY 10',
      'date': 'July 28',
      'instructor': 'Mia Castro',
    },
    {
      'type': 'activity',
      'title': 'ACTIVITY 9',
      'date': 'July 21',
      'instructor': 'Mia Castro',
    },
    {
      'type': 'activity',
      'title': 'ACTIVITY 8',
      'date': 'July 20',
      'instructor': 'Mia Castro',
    },
    {
      'type': 'activity',
      'title': 'ACTIVITY 7',
      'date': 'July 10',
      'instructor': 'Mia Castro',
    },
    {
      'type': 'activity',
      'title': 'ACTIVITY 6',
      'date': 'July 16',
      'instructor': 'Mia Castro',
    },
    {
      'type': 'assignment',
      'title': 'Assignment 9',
      'date': 'July 16',
      'instructor': 'Mia Castro',
    },
    {
      'type': 'assignment',
      'title': 'Assignment 8',
      'date': 'July 15',
      'instructor': 'Mia Castro',
    },
    {
      'type': 'assignment',
      'title': 'Assignment 7',
      'date': 'July 12',
      'instructor': 'Mia Castro',
    },
    {
      'type': 'material',
      'title': 'Environmental Education',
      'date': 'July 12',
      'instructor': 'Mia Castro',
    },
  ];

  final List<Map<String, dynamic>> _students = [
    {'name': 'Andrei Vern', 'avatar': 'assets/images/Avatar.png'},
    {'name': 'Sofia Grey', 'avatar': 'assets/images/Avatar.png'},
    {'name': 'Princess', 'avatar': 'assets/images/Avatar.png'},
    {'name': 'Sophia', 'avatar': 'assets/images/Avatar.png'},
    {'name': 'Rose Ann', 'avatar': 'assets/images/Avatar.png'},
    {'name': 'Bryan David', 'avatar': 'assets/images/Avatar.png'},
    {'name': 'Janna Mae', 'avatar': 'assets/images/Avatar.png'},
    {'name': 'Martha Yu', 'avatar': 'assets/images/Avatar.png'},
  ];

  final List<Map<String, dynamic>> _grades = [
    {'name': 'Andrei Vern', 'activity10': 100, 'assignment9': null, 'avatar': 'assets/images/Avatar.png'},
    {'name': 'Sofia Grey', 'activity10': 75, 'assignment9': null, 'avatar': 'assets/images/Avatar.png'},
    {'name': 'Princess', 'activity10': 90, 'assignment9': null, 'avatar': 'assets/images/Avatar.png'},
    {'name': 'Sophia', 'activity10': 100, 'assignment9': null, 'avatar': 'assets/images/Avatar.png'},
    {'name': 'Rose Ann', 'activity10': 100, 'assignment9': null, 'avatar': 'assets/images/Avatar.png'},
    {'name': 'Marie Lyn', 'activity10': 100, 'assignment9': null, 'avatar': 'assets/images/Avatar.png'},
    {'name': 'Janna Mae', 'activity10': 70, 'assignment9': null, 'avatar': 'assets/images/Avatar.png'},
  ];

  @override
  void initState() {
    super.initState();
    _sortedGrades = List.from(_grades);
    _sortGrades('Sort by Last name (A-Z)'); // Initialize with default sort
  }

  void _handleSidebarSelection(int index) {
    setState(() {
      _selectedSidebarIndex = index;
    });
  }

  void _selectTab(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      // Update all student selections
      for (var student in _students) {
        _studentSelections[student['name']] = _selectAll;
      }
    });
  }

  void _toggleStudentSelection(String studentName, bool? value) {
    setState(() {
      _studentSelections[studentName] = value ?? false;
      
      // Check if all students are selected
      bool allSelected = _students.every((student) => 
        _studentSelections[student['name']] == true);
      
      _selectAll = allSelected;
    });
  }

  void _sortGrades(String sortType) {
    setState(() {
      _sortBy = sortType;
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
            selectedIndex: _selectedSidebarIndex,
            onItemSelected: _handleSidebarSelection,
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
                            _buildTab('Stream', 0),
                            const SizedBox(width: 32),
                            _buildTab('People', 1),
                            const SizedBox(width: 32),
                            _buildTab('Grades', 2),
                          ],
                        ),
                        const SizedBox(height: 30),
                        
                        // Tab Content
                        Expanded(
                          child: _buildTabContent(),
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
        return _buildGradesTab();
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
                          widget.classData['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.classData['time'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
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
            child: ListView.builder(
              itemCount: _activities.length,
              itemBuilder: (context, index) {
                final activity = _activities[index];
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
                  child: Row(
                    children: [
                     Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF34A853),
                      shape: BoxShape.circle,
                    ),
                    
                    child:Image.asset('assets/icons/solar_document-outline.png', width: 24), 
                  ),
                  const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${activity['instructor']} posted new ${activity['type']}:',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                 const SizedBox(width: 5),
                            Text(
                              activity['title'],
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                              ],
                            ),
                           
                            const SizedBox(height: 4),
                            Text(
                              activity['date'],
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                     
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeopleTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              const Text(
                'Mia Castro',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
                const SizedBox(height: 10),
                      const Text(
          'Students',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
                      ),
          const SizedBox(height: 10),
           Divider(color: Colors.grey.withOpacity(0.4)),
          const SizedBox(height: 10),
          // Students Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                              Row(
                  children: [
                    Checkbox(
                      value: _selectAll,
                      onChanged: _toggleSelectAll,
                      activeColor: const Color(0xFF34A853),
                    ),
                    
                       const SizedBox(width: 10),
                   const Text('Select All', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 5),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _studentSelections[student['name']] ?? false,
                        onChanged: (value) => _toggleStudentSelection(student['name'], value),
                        activeColor: const Color(0xFF34A853),
                      ),
                      CircleAvatar(
                        radius: 25,
                        backgroundImage: AssetImage(student['avatar']),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        student['name'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradesTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        
          // Main Grades Container
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Student Column Header
                        Expanded(
                          flex: 1,
                          child:   // Sort Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
                           child: Center(
                             child: DropdownButton<String>(
                                            value: _sortBy,
                                            underline: Container(),
                                            items: const [
                                              DropdownMenuItem(value: 'Sort by Last name (A-Z)', child: Text('Sort by Last name (A-Z)')),
                                              DropdownMenuItem(value: 'Sort by Last name (Z-A)', child: Text('Sort by Last name (Z-A)')),
                                              DropdownMenuItem(value: 'Sort by Average Score (High-Low)', child: Text('Sort by Average Score (High-Low)')),
                                              DropdownMenuItem(value: 'Sort by Average Score (Low-High)', child: Text('Sort by Average Score (Low-High)')),
                                            ],
                                            onChanged: (value) {
                                              if (value != null) {
                                                _sortGrades(value);
                                              }
                                            },
                                          ),
                           ),
          ),
                        ),
                        // Activity 10 Column Header
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Jul 24',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const Text(
                                'ACTIVITY 10',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const Text(
                                'out of 100',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Assignment 9 Column Header
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'No due date',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const Text(
                                'ASSIGNMENT 9',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const Text(
                                'out of 100',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Class Average Row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Row(
                            children: [
                              Image.asset('assets/instructor/icons/mage_users.png', width: 20, height: 20),
                              const SizedBox(width: 12),
                              const Text(
                                'Class Average',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: Text(
                              '90.71',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF34A853),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: Text(
                              '-',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                                     // Student Rows
                   Expanded(
                     child: ListView.builder(
                       itemCount: _sortedGrades.length,
                       itemBuilder: (context, index) {
                         final grade = _sortedGrades[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Student Info
                              Expanded(
                                flex: 1,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage: AssetImage(grade['avatar']),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      grade['name'],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Activity 10 Score
                              Expanded(
                                flex: 1,
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        grade['activity10']?.toString() ?? '_',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: grade['activity10'] != null 
                                            ? const Color(0xFF34A853) 
                                            : Colors.grey,
                                        ),
                                      ),
                                      if (grade['activity10'] != null) ...[
                                        const Text(
                                          '/100',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF34A853),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert, size: 16, color: Colors.grey),
                                          itemBuilder: (context) => [
                                            const PopupMenuItem<String>(
                                              value: 'view',
                                              child: Text('View Submission'),
                                            ),
                                          ],
                                          onSelected: (value) {
                                            // Handle view submission
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              // Assignment 9 Score
                              Expanded(
                                flex: 1,
                                child: Center(
                                  child: Text(
                                    grade['assignment9']?.toString() ?? '_/100',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: grade['assignment9'] != null 
                                        ? const Color(0xFF34A853) 
                                        : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}