import 'package:flutter/material.dart';
import '../../shared/instructor/instructor_appbar.dart';
import '../../shared/instructor/instructor_sidebar.dart';

class ClassReportScreen extends StatefulWidget {
  const ClassReportScreen({Key? key}) : super(key: key);

  @override
  State<ClassReportScreen> createState() => _ClassReportScreenState();
}

class _ClassReportScreenState extends State<ClassReportScreen> {
  int _tabIndex = 0;
  int _selectedSidebarIndex = 5; // Reports index
  bool _showAddActivity = false;
  final TextEditingController _activityNameController = TextEditingController();
  final TextEditingController _maxScoreController = TextEditingController();
  final TextEditingController _activityTypeController = TextEditingController();

  // Dynamic activities for each period
  final List<Map<String, dynamic>> _prelimActivities = [];
  final List<Map<String, dynamic>> _midtermActivities = [];
  final List<Map<String, dynamic>> _prefinalActivities = [];
  final List<Map<String, dynamic>> _finalActivities = [];

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> tabs = ['Prelim', 'Midterm', 'Prefinal', 'Final'];

  final List<Map<String, dynamic>> prelimScores = [
    {
      'id': '2021-001',
      'name': 'John Doe',
      'quiz1': 28,
      'quiz2': 12,
      'quiz3': 10,
      'quiz4': 23,
      'assignment': 19,
      'exam': 49,
      'average': 83.5,
    },
    {
      'id': '2021-002',
      'name': 'May Ann',
      'quiz1': 29,
      'quiz2': 14,
      'quiz3': 8,
      'quiz4': 14,
      'assignment': 15,
      'exam': 35,
      'average': 70.8,
    },
    {
      'id': '2021-003',
      'name': 'Angel Mae',
      'quiz1': 26,
      'quiz2': 15,
      'quiz3': 9,
      'quiz4': 9,
      'assignment': 20,
      'exam': 38,
      'average': 91.7,
    },
    {
      'id': '2021-001',
      'name': 'John Doe',
      'quiz1': 28,
      'quiz2': 12,
      'quiz3': 10,
      'quiz4': 23,
      'assignment': 19,
      'exam': 49,
      'average': 83.5,
    },
    {
      'id': '2021-002',
      'name': 'May Ann',
      'quiz1': 29,
      'quiz2': 14,
      'quiz3': 8,
      'quiz4': 14,
      'assignment': 15,
      'exam': 35,
      'average': 70.8,
    },
    {
      'id': '2021-003',
      'name': 'Angel Mae',
      'quiz1': 26,
      'quiz2': 15,
      'quiz3': 9,
      'quiz4': 9,
      'assignment': 20,
      'exam': 38,
      'average': 91.7,
    },
  ];
  final List<Map<String, dynamic>> midtermScores = [
    {
      'id': '2021-001', 'name': 'John Doe', 'exam': 38, 'pit': 90, 'average': 83.5,
    },
    {
      'id': '2021-002', 'name': 'May Ann', 'exam': 41, 'pit': 85, 'average': 70.6,
    },
    {
      'id': '2021-003', 'name': 'Angel Mae', 'exam': 49, 'pit': 95, 'average': 97.0,
    },
  ];
  final List<Map<String, dynamic>> prefinalScores = [
    {
      'id': '2021-001', 'name': 'John Doe', 'quiz6': 7, 'quiz7': 30, 'quiz8': 20, 'quiz9': 15, 'quiz10': 8, 'exam': 50, 'average': 79.5,
    },
    {
      'id': '2021-002', 'name': 'May Ann', 'quiz6': 10, 'quiz7': 20, 'quiz8': 15, 'quiz9': 13, 'quiz10': 5, 'exam': 43, 'average': 85.0,
    },
    {'id': '2021-003', 'name': 'Angel Mae', 'quiz6': 9, 'quiz7': 10, 'quiz8': 12, 'quiz9': 12, 'quiz10': 6, 'exam': 41, 'average': 93.0},
  ];
  final List<Map<String, dynamic>> finalScores = [
    {'id': '2021-001', 'name': 'John Doe', 'exam': 50, 'pit': 98, 'average': 97.0},
    {'id': '2021-002', 'name': 'May Ann', 'exam': 34, 'pit': 90, 'average': 93.0},
    {'id': '2021-003', 'name': 'Angel Mae', 'exam': 47, 'pit': 88, 'average': 91.0},
  ];

  Widget _buildTabButton(String label, int idx) {
    final bool selected = _tabIndex == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = idx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.black : Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoresTable() {
    if (_tabIndex == 0) {
      return _PrelimTable(scores: _getFilteredScores(prelimScores), activities: _prelimActivities);
    } else if (_tabIndex == 1) {
      return _MidtermTable(scores: _getFilteredScores(midtermScores), activities: _midtermActivities);
    } else if (_tabIndex == 2) {
      return _PrefinalTable(scores: _getFilteredScores(prefinalScores), activities: _prefinalActivities);
    } else {
      return _FinalTable(scores: _getFilteredScores(finalScores), activities: _finalActivities);
    }
  }

  void _handleSidebarSelection(int index) {
    setState(() {
      _selectedSidebarIndex = index;
    });
  }

  void _addActivity() {
    final activityName = _activityNameController.text.trim();
    final maxScore = int.tryParse(_maxScoreController.text.trim()) ?? 0;
    final activityType = _activityTypeController.text.trim();

    if (activityName.isNotEmpty && maxScore > 0 && activityType.isNotEmpty) {
      final newActivity = {
        'name': activityName,
        'maxScore': maxScore,
        'type': activityType,
      };

      // Add to the appropriate period based on current tab
      switch (_tabIndex) {
        case 0: // Prelim
          _prelimActivities.add(newActivity);
          break;
        case 1: // Midterm
          _midtermActivities.add(newActivity);
          break;
        case 2: // Prefinal
          _prefinalActivities.add(newActivity);
          break;
        case 3: // Final
          _finalActivities.add(newActivity);
          break;
      }

      // Clear controllers
      _activityNameController.clear();
      _maxScoreController.clear();
      _activityTypeController.clear();

      setState(() {
        _showAddActivity = false;
      });
    }
  }

  List<Map<String, dynamic>> _getCurrentActivities() {
    switch (_tabIndex) {
      case 0:
        return _prelimActivities;
      case 1:
        return _midtermActivities;
      case 2:
        return _prefinalActivities;
      case 3:
        return _finalActivities;
      default:
        return [];
    }
  }

  List<Map<String, dynamic>> _getFilteredScores(List<Map<String, dynamic>> scores) {
    if (_searchQuery.isEmpty) {
      return scores;
    }
    
    return scores.where((student) {
      final name = student['name'].toString().toLowerCase();
      final id = student['id'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      
      return name.contains(query) || id.contains(query);
    }).toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Row(
            children: [
              // Sidebar
              InstructorSidebar(
                selectedIndex: _selectedSidebarIndex,
                onItemSelected: _handleSidebarSelection,
              ),
              // Main content
              Expanded(
                child: Column(
                  children: [
                    // AppBar
                    const InstructorAppBar(
                      instructorName: 'John Smith',
                      instructorRole: 'Instructor',
                    ),
                    // Main content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Text('BSIT -1A', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                                SizedBox(width: 12),
                                Text('Class Report', style: TextStyle(color: Colors.black54, fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text('Bachelor of Science in Information Technology', 
                                style: TextStyle(color: Colors.black54, fontSize: 14)),
                            const SizedBox(height: 24),
                            // Search bar and action buttons
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: _onSearchChanged,
                                    cursorColor: Colors.black54,
                                    decoration: InputDecoration(
                                      hintText: 'Search students by name or ID...',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Color(0xFF34A853), width: 2),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      prefixIcon: const Icon(Icons.search, color: Colors.black54),
                                      suffixIcon: _searchQuery.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear, color: Colors.black54),
                                              onPressed: () {
                                                _searchController.clear();
                                                _onSearchChanged('');
                                              },
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  height: 50, // Match TextField height
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      side: const BorderSide(color: Color(0xFF9E9E9E)), // black38 equivalent
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                    ),
                                    onPressed: () {},
                                    icon: const Icon(Icons.download, size: 18),
                                    label: const Text('Export Scores', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  height: 50, // Match TextField height
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      side: const BorderSide(color: Color(0xFF9E9E9E)), // black38 equivalent
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                    ),
                                    onPressed: () => setState(() => _showAddActivity = true),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Add Activity', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  height: 50, // Match TextField height
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      side: const BorderSide(color: Color(0xFF9E9E9E)), // black38 equivalent
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                    ),
                                    onPressed: () {},
                                    icon: const Icon(Icons.download, size: 18),
                                    label: const Text('Export Student List', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                                                        // Tab buttons
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFB),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final containerWidth = constraints.maxWidth;
                                  final tabWidth = containerWidth / tabs.length;
                                  final indicatorWidth = tabWidth - 0;
                                  final indicatorLeft = _tabIndex * (tabWidth - 3) + 4;
                                  
                                  return Stack(
                                    children: [
                                      // Sliding indicator
                                      AnimatedPositioned(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                        left: indicatorLeft,
                                        child: Container(
                                          width: indicatorWidth,
                                          height: 45,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.08),
                                            blurRadius: 2,
                                            offset: const Offset(0, 1),
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                      Row(
                                        children: List.generate(tabs.length, (i) => _buildTabButton(tabs[i], i)),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Scores table
                            Expanded(child: _buildScoresTable()),
                            const SizedBox(height: 24),
                            // Average cards
                            Row(
                              children: const [
                                Expanded(child: _AverageCard(label: 'Prelim Average', value: '85.3')),
                                SizedBox(width: 12),
                                Expanded(child: _AverageCard(label: 'Midterm Average', value: '85.3')),
                                SizedBox(width: 12),
                                Expanded(child: _AverageCard(label: 'Prefinal Average', value: '90.3')),
                                SizedBox(width: 12),
                                Expanded(child: _AverageCard(label: 'Final Average', value: '90.3')),
                              ],
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
          // Add Activity Dialog overlay
          if (_showAddActivity)
            _AddActivityDialog(
              activityNameController: _activityNameController,
              maxScoreController: _maxScoreController,
              activityTypeController: _activityTypeController,
              onCancel: () => setState(() => _showAddActivity = false),
              onAdd: _addActivity,
            ),
        ],
      ),
    );
  }
}

class _PrelimTable extends StatelessWidget {
  final List<Map<String, dynamic>> scores;
  final List<Map<String, dynamic>> activities;
  const _PrelimTable({required this.scores, required this.activities});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Prelim Scores', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const Text('Quizzes and Assignment scores', style: TextStyle(color: Colors.black38, fontSize: 14)),
          const SizedBox(height: 16),
          Expanded(
            child: scores.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No students found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try adjusting your search terms',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFB)),
                        columns: [
                          const DataColumn(label: Text('Student ID', style: TextStyle(fontWeight: FontWeight.bold))),
                          const DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                          const DataColumn(label: Text('Quiz 1 /30', style: TextStyle(fontWeight: FontWeight.bold))),
                          const DataColumn(label: Text('Quiz 2 /15', style: TextStyle(fontWeight: FontWeight.bold))),
                          const DataColumn(label: Text('Quiz 3 /10', style: TextStyle(fontWeight: FontWeight.bold))),
                          const DataColumn(label: Text('Quiz 4 /25', style: TextStyle(fontWeight: FontWeight.bold))),
                          const DataColumn(label: Text('Assignment /20', style: TextStyle(fontWeight: FontWeight.bold))),
                          const DataColumn(label: Text('Prelim Exam /50', style: TextStyle(fontWeight: FontWeight.bold))),
                          // Dynamic activity columns
                          ...activities.map((activity) => DataColumn(
                            label: Text('${activity['name']} /${activity['maxScore']}', 
                              style: const TextStyle(fontWeight: FontWeight.bold)
                            ),
                          )),
                          const DataColumn(label: Text('Average', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: scores.map((s) => DataRow(cells: [
                          DataCell(Text(s['id'])),
                          DataCell(Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text('${s['quiz1']}')),
                          DataCell(Text('${s['quiz2']}')),
                          DataCell(Text('${s['quiz3']}')),
                          DataCell(Text('${s['quiz4']}')),
                          DataCell(Text('${s['assignment']}')),
                          DataCell(Text('${s['exam']}')),
                          // Dynamic activity cells
                          ...activities.map((activity) => DataCell(
                            Text('0', style: const TextStyle(color: Colors.grey)),
                          )),
                          DataCell(Text('${s['average']}', style: TextStyle(
                            color: s['average'] >= 90 ? Colors.orange : (s['average'] >= 80 ? Color(0xFF34A853) : Colors.blue),
                            fontWeight: FontWeight.bold,
                          ))),
                        ])).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MidtermTable extends StatelessWidget {
  final List<Map<String, dynamic>> scores;
  final List<Map<String, dynamic>> activities;
  const _MidtermTable({required this.scores, required this.activities});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Midterm Scores', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const Text('Exam and PIT', style: TextStyle(color: Colors.black38, fontSize: 14)),
          const SizedBox(height: 16),
          Expanded(
            child: scores.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No students found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try adjusting your search terms',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFB)),
                  columns: [
                    const DataColumn(label: Text('Student ID', style: TextStyle(fontWeight: FontWeight.bold))),
                    const DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                    const DataColumn(label: Text('Midterm Exam', style: TextStyle(fontWeight: FontWeight.bold))),
                    const DataColumn(label: Text('PIT /NO', style: TextStyle(fontWeight: FontWeight.bold))),
                    // Dynamic activity columns
                    ...activities.map((activity) => DataColumn(
                      label: Text('${activity['name']} /${activity['maxScore']}', 
                        style: const TextStyle(fontWeight: FontWeight.bold)
                      ),
                    )),
                    const DataColumn(label: Text('Average', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: scores.map((s) => DataRow(cells: [
                    DataCell(Text(s['id'])),
                    DataCell(Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text('${s['exam']}')),
                    DataCell(Text('${s['pit']}')),
                    // Dynamic activity cells
                    ...activities.map((activity) => DataCell(
                      Text('0', style: const TextStyle(color: Colors.grey)),
                    )),
                    DataCell(Text('${s['average']}', style: TextStyle(
                      color: s['average'] >= 90 ? Colors.orange : (s['average'] >= 80 ? Color(0xFF34A853) : Colors.blue),
                      fontWeight: FontWeight.bold,
                    ))),
                  ])).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrefinalTable extends StatelessWidget {
  final List<Map<String, dynamic>> scores;
  final List<Map<String, dynamic>> activities;
  const _PrefinalTable({required this.scores, required this.activities});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Prefinal Scores', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const Text('Quizzes scores', style: TextStyle(color: Colors.black38, fontSize: 14)),
          const SizedBox(height: 16),
          Expanded(
            child: scores.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No students found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try adjusting your search terms',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFB)),
                  columns: [
                    const DataColumn(label: Text('Student ID', style: TextStyle(fontWeight: FontWeight.bold))),
                    const DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                    const DataColumn(label: Text('Quiz 6 /10', style: TextStyle(fontWeight: FontWeight.bold))),
                    const DataColumn(label: Text('Quiz 7 /50', style: TextStyle(fontWeight: FontWeight.bold))),
                    const DataColumn(label: Text('Quiz 8 /20', style: TextStyle(fontWeight: FontWeight.bold))),
                    const DataColumn(label: Text('Quiz 9 /15', style: TextStyle(fontWeight: FontWeight.bold))),
                    const DataColumn(label: Text('Quiz 10 /10', style: TextStyle(fontWeight: FontWeight.bold))),
                    const DataColumn(label: Text('Prefinal Exam /50', style: TextStyle(fontWeight: FontWeight.bold))),
                    // Dynamic activity columns
                    ...activities.map((activity) => DataColumn(
                      label: Text('${activity['name']} /${activity['maxScore']}', 
                        style: const TextStyle(fontWeight: FontWeight.bold)
                      ),
                    )),
                    const DataColumn(label: Text('Average', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: scores.map((s) => DataRow(cells: [
                    DataCell(Text(s['id'])),
                    DataCell(Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text('${s['quiz6']}')),
                    DataCell(Text('${s['quiz7']}')),
                    DataCell(Text('${s['quiz8']}')),
                    DataCell(Text('${s['quiz9']}')),
                    DataCell(Text('${s['quiz10']}')),
                    DataCell(Text('${s['exam']}')),
                    // Dynamic activity cells
                    ...activities.map((activity) => DataCell(
                      Text('0', style: const TextStyle(color: Colors.grey)),
                    )),
                    DataCell(Text('${s['average']}', style: TextStyle(
                      color: s['average'] >= 90 ? Colors.orange : (s['average'] >= 80 ? Color(0xFF34A853) : Colors.blue),
                      fontWeight: FontWeight.bold,
                    ))),
                  ])).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinalTable extends StatelessWidget {
  final List<Map<String, dynamic>> scores;
  final List<Map<String, dynamic>> activities;
  const _FinalTable({required this.scores, required this.activities});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Final Scores', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const Text('Exam and PIT', style: TextStyle(color: Colors.black38, fontSize: 14)),
          const SizedBox(height: 16),
          Expanded(
            child: scores.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No students found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try adjusting your search terms',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFB)),
                  columns: [
                    const DataColumn(label: Text('Student ID', style: TextStyle(fontWeight: FontWeight.bold))),
                    const DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                    const DataColumn(label: Text('Final Exam /90', style: TextStyle(fontWeight: FontWeight.bold))),
                    const DataColumn(label: Text('Final PIT /100', style: TextStyle(fontWeight: FontWeight.bold))),
                    // Dynamic activity columns
                    ...activities.map((activity) => DataColumn(
                      label: Text('${activity['name']} /${activity['maxScore']}', 
                        style: const TextStyle(fontWeight: FontWeight.bold)
                      ),
                    )),
                    const DataColumn(label: Text('Average', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: scores.map((s) => DataRow(cells: [
                    DataCell(Text(s['id'])),
                    DataCell(Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text('${s['exam']}')),
                    DataCell(Text('${s['pit']}')),
                    // Dynamic activity cells
                    ...activities.map((activity) => DataCell(
                      Text('0', style: const TextStyle(color: Colors.grey)),
                    )),
                    DataCell(Text('${s['average']}', style: TextStyle(
                      color: s['average'] >= 90 ? Colors.orange : (s['average'] >= 80 ? Color(0xFF34A853) : Colors.blue),
                      fontWeight: FontWeight.bold,
                    ))),
                  ])).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AverageCard extends StatelessWidget {
  final String label;
  final String value;
  const _AverageCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 15)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        ],
      ),
    );
  }
}

class _AddActivityDialog extends StatelessWidget {
  final TextEditingController activityNameController;
  final TextEditingController maxScoreController;
  final TextEditingController activityTypeController;
  final VoidCallback onCancel;
  final VoidCallback onAdd;
  const _AddActivityDialog({
    required this.activityNameController,
    required this.maxScoreController,
    required this.activityTypeController,
    required this.onCancel,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, 8))],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add New Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onCancel,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text('Activity Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              TextField(
                controller: activityNameController,
                cursorColor: Colors.black54,
                decoration: InputDecoration(
                  hintText: 'Enter activity name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF9E9E9E)), // black38 equivalent
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF34A853), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 18),
              const Text('Maximum Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              TextField(
                controller: maxScoreController,
                cursorColor: Colors.black54,
                decoration: InputDecoration(
                  hintText: 'Enter maximum score',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF9E9E9E)), // black38 equivalent
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF34A853), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 18),
              const Text('Activity Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              TextField(
                controller: activityTypeController,
                cursorColor: Colors.black54,
                decoration: InputDecoration(
                  hintText: 'Enter activity type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF9E9E9E)), // black38 equivalent
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF34A853), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 50, // Match TextField height
                    width: 160,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Color(0xFF9E9E9E)), // black38 equivalent
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                      ),
                      onPressed: onCancel,
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 50, // Match TextField height
                    width: 160,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF34A853),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                      ),
                      onPressed: onAdd,
                      child: const Text('Add Activity', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}