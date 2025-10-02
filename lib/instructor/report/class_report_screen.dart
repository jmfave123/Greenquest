import 'package:flutter/material.dart';
import '../../shared/instructor/instructor_appbar.dart';
import '../../shared/instructor/instructor_sidebar.dart';
import '../../shared/instructor/instructor_navigation_constants.dart';

class ClassReportScreen extends StatefulWidget {
  const ClassReportScreen({super.key});

  @override
  State<ClassReportScreen> createState() => _ClassReportScreenState();
}

class _ClassReportScreenState extends State<ClassReportScreen> {
  int _tabIndex = 0;
  InstructorNavigationItem _selectedItem = InstructorNavigationItem.reports;
  bool _showAddActivity = false;
  final TextEditingController _activityNameController = TextEditingController();
  final TextEditingController _maxScoreController = TextEditingController();
  final TextEditingController _activityTypeController = TextEditingController();

  // Dynamic activities for each period
  final List<Map<String, dynamic>> _prelimActivities = [];
  final List<Map<String, dynamic>> _midtermActivities = [];
  final List<Map<String, dynamic>> _finalActivities = [];

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> tabs = ['Prelim', 'Midterm', 'Final'];

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
      'id': '2021-001',
      'name': 'John Doe',
      'exam': 38,
      'pit': 90,
      'average': 83.5,
    },
    {
      'id': '2021-002',
      'name': 'May Ann',
      'exam': 41,
      'pit': 85,
      'average': 70.6,
    },
    {
      'id': '2021-003',
      'name': 'Angel Mae',
      'exam': 49,
      'pit': 95,
      'average': 97.0,
    },
  ];
  final List<Map<String, dynamic>> finalScores = [
    {
      'id': '2021-001',
      'name': 'John Doe',
      'exam': 50,
      'pit': 98,
      'average': 97.0,
    },
    {
      'id': '2021-002',
      'name': 'May Ann',
      'exam': 34,
      'pit': 90,
      'average': 93.0,
    },
    {
      'id': '2021-003',
      'name': 'Angel Mae',
      'exam': 47,
      'pit': 88,
      'average': 91.0,
    },
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
      return _PrelimTable(
        scores: _getFilteredScores(prelimScores),
        activities: _prelimActivities,
      );
    } else if (_tabIndex == 1) {
      return _MidtermTable(
        scores: _getFilteredScores(midtermScores),
        activities: _midtermActivities,
      );
    } else {
      return _FinalTable(
        scores: _getFilteredScores(finalScores),
        activities: _finalActivities,
      );
    }
  }

  void _handleNavigationSelect(InstructorNavigationItem item) {
    setState(() {
      _selectedItem = item;
    });
    String route = InstructorNavigationHelper.getRoute(item);
    Navigator.of(context).pushReplacementNamed(route);
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
        case 2: // Final
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

  List<Map<String, dynamic>> _getFilteredScores(
    List<Map<String, dynamic>> scores,
  ) {
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
                selectedItem: _selectedItem,
                onItemSelected: _handleNavigationSelect,
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
                                Text(
                                  'BSIT -1A',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Class Report',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Bachelor of Science in Information Technology',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                              ),
                            ),
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
                                      hintText:
                                          'Search students by name or ID...',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF34A853),
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        color: Colors.black54,
                                      ),
                                      suffixIcon:
                                          _searchQuery.isNotEmpty
                                              ? IconButton(
                                                icon: const Icon(
                                                  Icons.clear,
                                                  color: Colors.black54,
                                                ),
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
                                      side: const BorderSide(
                                        color: Color(0xFF9E9E9E),
                                      ), // black38 equivalent
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 0,
                                      ),
                                    ),
                                    onPressed: () {},
                                    icon: const Icon(Icons.download, size: 18),
                                    label: const Text(
                                      'Export Scores',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  height: 50, // Match TextField height
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      side: const BorderSide(
                                        color: Color(0xFF9E9E9E),
                                      ), // black38 equivalent
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 0,
                                      ),
                                    ),
                                    onPressed:
                                        () => setState(
                                          () => _showAddActivity = true,
                                        ),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text(
                                      'Add Quizzes',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  height: 50, // Match TextField height
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      side: const BorderSide(
                                        color: Color(0xFF9E9E9E),
                                      ), // black38 equivalent
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 0,
                                      ),
                                    ),
                                    onPressed: () {},
                                    icon: const Icon(Icons.download, size: 18),
                                    label: const Text(
                                      'Export Student List',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const SizedBox(height: 16),
                            // Combined class record table (Prelim + Midterm + Final)
                            Expanded(
                              child: _CombinedRecordTable(
                                prelimScores: _getFilteredScores(prelimScores),
                                midtermScores: _getFilteredScores(
                                  midtermScores,
                                ),
                                finalScores: _getFilteredScores(finalScores),
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
    Widget headerCell(
      String text, {
      Color? color,
      FontWeight? fontWeight,
      TextAlign align = TextAlign.center,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        alignment: Alignment.center,
        color: color ?? const Color(0xFFF8FAFB),
        child: Text(
          text,
          textAlign: align,
          style: TextStyle(
            fontWeight: fontWeight ?? FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }

    Widget dataCell(String text, {TextAlign align = TextAlign.center}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: align,
          style: const TextStyle(fontSize: 12),
        ),
      );
    }

    Widget headerCellV(String text, {Color? color}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 40),
        alignment: Alignment.center,
        color: color ?? const Color(0xFFF8FAFB),
        child: RotatedBox(
          quarterTurns: 3,
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    String v(Map<String, dynamic> s, String key) => (s[key] ?? '—').toString();

    final List<String> standingCols = [
      'assign',
      'recitation',
      'src',
      'cpa',
      'quiz1',
      'quiz2',
      'quiz3',
      'quiz4',
      'quiz5',
    ];

    final List<String> lectureCols = [
      'prelimExam',
      'srq',
      'qa',
      'midWrittenExam',
      'm',
      'pit',
      'pitTotal',
      'pitPercent',
      'mga',
    ];

    final List<String> gradeCols = [
      'midLecGradePoint',
      'midGGradePoint',
      'midtermGrade',
    ];

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
          const Text(
            'Prelim Scores',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const Text(
            'Arranged like the official class record (grouped headers)',
            style: TextStyle(color: Colors.black38, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Expanded(
            child:
                scores.isEmpty
                    ? const Center(child: Text('No students found'))
                    : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: Table(
                          defaultVerticalAlignment:
                              TableCellVerticalAlignment.middle,
                          columnWidths: const <int, TableColumnWidth>{
                            0: FixedColumnWidth(90), // No.
                            1: FixedColumnWidth(120), // ID Number
                            2: FixedColumnWidth(180), // Names
                          },
                          border: TableBorder.symmetric(
                            inside: BorderSide(color: const Color(0xFFE5E7EB)),
                            outside: BorderSide(color: const Color(0xFFE5E7EB)),
                          ),
                          children: [
                            // Header Group Row
                            TableRow(
                              children: [
                                headerCell('No.'),
                                headerCell('ID Number'),
                                headerCell('Names'),
                                headerCell(
                                  'Class Standing Performance',
                                  color: const Color(0xFFEFF6FF),
                                ),
                                ...List.generate(
                                  standingCols.length - 1,
                                  (_) => headerCell(''),
                                ),
                                headerCell(
                                  'Lecture 100%',
                                  color: const Color(0xFFFFF7ED),
                                ),
                                ...List.generate(
                                  lectureCols.length - 1,
                                  (_) => headerCell(''),
                                ),
                                headerCell(
                                  'Midterm Grade',
                                  color: const Color(0xFFFEF2F2),
                                ),
                                ...List.generate(
                                  gradeCols.length - 1,
                                  (_) => headerCell(''),
                                ),
                              ],
                            ),
                            // Header Detail Row
                            TableRow(
                              children: [
                                headerCell(''),
                                headerCell(''),
                                headerCell(''),
                                ...[
                                  headerCell('Assign'),
                                  headerCell('Recitation'),
                                  headerCell('Total Score (SRC)'),
                                  headerCell('CPA'),
                                  headerCell('Quiz 1'),
                                  headerCell('Quiz 2'),
                                  headerCell('Quiz 3'),
                                  headerCell('Quiz 4'),
                                  headerCell('Quiz 5'),
                                ],
                                ...[
                                  headerCell('Prelim Exam'),
                                  headerCell('Total Score (SRQ)'),
                                  headerCell('QA'),
                                  headerCell('Mid Written Exam'),
                                  headerCell('M'),
                                  headerCell('PIT'),
                                  headerCell('Total Score (PIT)'),
                                  headerCell('PIT %'),
                                  headerCell('MGA'),
                                ],
                                ...[
                                  headerCell('Mid Lec Grade Point'),
                                  headerCell('Mid G Grade Point'),
                                  headerCell('Midterm Grade'),
                                ],
                              ],
                            ),
                            // Data rows
                            ...scores.asMap().entries.map((entry) {
                              final int idx = entry.key;
                              final Map<String, dynamic> s = entry.value;
                              return TableRow(
                                children: [
                                  dataCell('${idx + 1}'),
                                  dataCell(v(s, 'id')),
                                  dataCell(v(s, 'name'), align: TextAlign.left),
                                  ...standingCols
                                      .map((c) => dataCell(v(s, c)))
                                      .toList(),
                                  ...lectureCols
                                      .map((c) => dataCell(v(s, c)))
                                      .toList(),
                                  ...gradeCols
                                      .map((c) => dataCell(v(s, c)))
                                      .toList(),
                                ],
                              );
                            }).toList(),
                          ],
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
          const Text(
            'Midterm Scores',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const Text(
            'Exam and PIT',
            style: TextStyle(color: Colors.black38, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Expanded(
            child:
                scores.isEmpty
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
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                    : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(
                            const Color(0xFFF8FAFB),
                          ),
                          columns: [
                            const DataColumn(
                              label: Text(
                                'Student ID',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Name',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Midterm Exam',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'PIT /NO',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            // Dynamic activity columns
                            ...activities.map(
                              (activity) => DataColumn(
                                label: Text(
                                  '${activity['name']} /${activity['maxScore']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Average',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          rows:
                              scores
                                  .map(
                                    (s) => DataRow(
                                      cells: [
                                        DataCell(Text(s['id'])),
                                        DataCell(
                                          Text(
                                            s['name'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        DataCell(Text('${s['exam']}')),
                                        DataCell(Text('${s['pit']}')),
                                        // Dynamic activity cells
                                        ...activities.map(
                                          (activity) => DataCell(
                                            Text(
                                              '0',
                                              style: const TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            '${s['average']}',
                                            style: TextStyle(
                                              color:
                                                  s['average'] >= 90
                                                      ? Colors.orange
                                                      : (s['average'] >= 80
                                                          ? Color(0xFF34A853)
                                                          : Colors.blue),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList(),
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
          const Text(
            'Final Scores',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const Text(
            'Exam and PIT',
            style: TextStyle(color: Colors.black38, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Expanded(
            child:
                scores.isEmpty
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
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                    : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(
                            const Color(0xFFF8FAFB),
                          ),
                          columns: [
                            const DataColumn(
                              label: Text(
                                'Student ID',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Name',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Final Exam /90',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Final PIT /100',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            // Dynamic activity columns
                            ...activities.map(
                              (activity) => DataColumn(
                                label: Text(
                                  '${activity['name']} /${activity['maxScore']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Average',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          rows:
                              scores
                                  .map(
                                    (s) => DataRow(
                                      cells: [
                                        DataCell(Text(s['id'])),
                                        DataCell(
                                          Text(
                                            s['name'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        DataCell(Text('${s['exam']}')),
                                        DataCell(Text('${s['pit']}')),
                                        // Dynamic activity cells
                                        ...activities.map(
                                          (activity) => DataCell(
                                            Text(
                                              '0',
                                              style: const TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            '${s['average']}',
                                            style: TextStyle(
                                              color:
                                                  s['average'] >= 90
                                                      ? Colors.orange
                                                      : (s['average'] >= 80
                                                          ? Color(0xFF34A853)
                                                          : Colors.blue),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

class _CombinedRecordTable extends StatelessWidget {
  final List<Map<String, dynamic>> prelimScores;
  final List<Map<String, dynamic>> midtermScores;
  final List<Map<String, dynamic>> finalScores;
  const _CombinedRecordTable({
    required this.prelimScores,
    required this.midtermScores,
    required this.finalScores,
  });

  @override
  Widget build(BuildContext context) {
    Widget headerCell(
      String text, {
      Color? color,
      FontWeight? fontWeight,
      TextAlign align = TextAlign.center,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        alignment: Alignment.center,
        color: color ?? const Color(0xFFF8FAFB),
        child: Text(
          text,
          textAlign: align,
          style: TextStyle(
            fontWeight: fontWeight ?? FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }

    Widget headerCellV(String text, {Color? color}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 40),
        alignment: Alignment.center,
        color: color ?? const Color(0xFFF8FAFB),
        child: RotatedBox(
          quarterTurns: 3,
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    Widget dataCell(String text, {TextAlign align = TextAlign.center}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: align,
          style: const TextStyle(fontSize: 12),
        ),
      );
    }

    String v(Map<String, dynamic> s, String key) => (s[key] ?? '—').toString();

    final List<String> prelimStandingCols = [
      'assign',
      'recitation',
      'src',
      'cpa',
      'quiz1',
      'quiz2',
      'quiz3',
      'quiz4',
      'quiz5',
    ];
    final List<String> prelimLectureCols = [
      'prelimExam',
      'srq',
      'qa',
      'midWrittenExam',
      'm',
      'pit',
      'pitTotal',
      'pitPercent',
      'mga',
      'midLecGradePoint',
      'midGGradePoint',
      'midtermGrade',
    ];

    final List<String> finalCols = [
      'recitation_f',
      'src_f',
      'cpa_f',
      'quizzes_f',
      'sFinalExam',
      'srq_f',
      'qa_f',
      'finWrittenExam',
      'f',
      'pit_f',
      'pitTotal_f',
      'pitPercent_f',
      'fga',
      'finLecGradePoint',
      'finalGGradePoint',
      'finalPeriodGrade',
    ];

    // Merge students by id across periods (simple demo merge)
    final Map<String, Map<String, dynamic>> byId = {};
    for (final s in prelimScores) {
      byId[s['id']] = {...s};
    }
    for (final s in midtermScores) {
      byId.update(s['id'], (old) => {...old, ...s}, ifAbsent: () => {...s});
    }
    for (final s in finalScores) {
      byId.update(s['id'], (old) => {...old, ...s}, ifAbsent: () => {...s});
    }

    final List<Map<String, dynamic>> students = byId.values.toList();

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
          const Text(
            'Class Record',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: Table(
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  defaultColumnWidth: const FixedColumnWidth(72),
                  columnWidths: <int, TableColumnWidth>{
                    0: const FixedColumnWidth(50),
                    1: const FixedColumnWidth(120),
                    2: const FixedColumnWidth(220),
                  },
                  border: TableBorder.symmetric(
                    inside: BorderSide(color: const Color(0xFFE5E7EB)),
                    outside: BorderSide(color: const Color(0xFFE5E7EB)),
                  ),
                  children: [
                    // Top bands: Midterm Grade | Final Period Grade
                    TableRow(
                      children: [
                        headerCell('No.'),
                        headerCell('ID Number'),
                        headerCell('Names'),
                        headerCell(
                          'Midterm Grade',
                          color: const Color(0xFFFFF7ED),
                        ),
                        ...List.generate(
                          prelimStandingCols.length +
                              prelimLectureCols.length -
                              1,
                          (_) => headerCell(''),
                        ),
                        headerCell(
                          'Final Period Grade',
                          color: const Color(0xFFFEF2F2),
                        ),
                        ...List.generate(
                          finalCols.length - 1,
                          (_) => headerCell(''),
                        ),
                      ],
                    ),
                    // Second bands: subgroups for midterm + final
                    TableRow(
                      children: [
                        headerCell(''),
                        headerCell(''),
                        headerCell(''),
                        headerCell('Class Standing Performance / Lecture 100%'),
                        ...List.generate(
                          prelimStandingCols.length - 1,
                          (_) => headerCell(''),
                        ),
                        ...List.generate(
                          prelimLectureCols.length,
                          (_) => headerCell(''),
                        ),
                        headerCell(
                          'Quiz/Pre-final • Final Exam • PerInno Task • Lecture',
                        ),
                        ...List.generate(
                          finalCols.length - 1,
                          (_) => headerCell(''),
                        ),
                      ],
                    ),
                    // Column labels for midterm standing + lecture + final
                    TableRow(
                      children: [
                        headerCell(''),
                        headerCell(''),
                        headerCell(''),
                        ...[
                          headerCellV('Assign'),
                          headerCellV('Recitation'),
                          headerCellV('SRC'),
                          headerCellV('CPA'),
                          headerCellV('Q1'),
                          headerCellV('Q2'),
                          headerCellV('Q3'),
                          headerCellV('Q4'),
                          headerCellV('Q5'),
                        ],
                        ...[
                          headerCellV('Prelim Exam'),
                          headerCellV('SRQ'),
                          headerCellV('QA'),
                          headerCellV('Mid Written Exam'),
                          headerCellV('M'),
                          headerCellV('PIT'),
                          headerCellV('PIT Total'),
                          headerCellV('PIT %'),
                          headerCellV('MGA'),
                          headerCellV('Mid Lec GP'),
                          headerCellV('Mid G GP'),
                          headerCellV('Midterm Grade'),
                        ],
                        ...[
                          headerCellV('Recitation'),
                          headerCellV('SRC'),
                          headerCellV('CPA'),
                          headerCellV('Quizzes'),
                          headerCellV('S/Final Exam'),
                          headerCellV('SRQ'),
                          headerCellV('QA'),
                          headerCellV('Fin Written Exam'),
                          headerCellV('F'),
                          headerCellV('PIT'),
                          headerCellV('PIT Total'),
                          headerCellV('PIT %'),
                          headerCellV('FGA'),
                          headerCellV('Fin Lec GP'),
                          headerCellV('Final G GP'),
                          headerCellV('Final Period Grade'),
                        ],
                      ],
                    ),
                    // Scale row (sample denominators)
                    TableRow(
                      children: [
                        headerCell(''),
                        headerCell(''),
                        headerCell(''),
                        headerCell('10'),
                        headerCell('5'),
                        headerCell('15'),
                        headerCell('100%'),
                        headerCell('30'),
                        headerCell('15'),
                        headerCell('10'),
                        headerCell('25'),
                        headerCell('20'),
                        // Midterm lecture denominators (12 items)
                        headerCell('50'), // Prelim Exam
                        headerCell('—'), // SRQ
                        headerCell('—'), // QA
                        headerCell('—'), // Mid Written
                        headerCell('—'), // M
                        headerCell('50'), // PIT
                        headerCell('50'), // PIT Total
                        headerCell('100%'), // PIT %
                        headerCell('1.000'), // MGA
                        headerCell('1.000'), // Mid Lec GP
                        headerCell('1.000'), // Mid G GP
                        headerCell('1.00'), // Midterm Grade
                        // final
                        headerCell('10'),
                        headerCell('10'),
                        headerCell('100%'),
                        headerCell('30'),
                        headerCell('60'),
                        headerCell('100%'),
                        headerCell('40'),
                        headerCell('100%'),
                        headerCell('100%'),
                        headerCell('100'),
                        headerCell('100'),
                        headerCell('100%'),
                        headerCell('100%'),
                        headerCell('1.000'),
                        headerCell('1.000'),
                        headerCell('1.00'),
                      ],
                    ),
                    // Data rows
                    ...students.asMap().entries.map((e) {
                      final i = e.key;
                      final s = e.value;
                      return TableRow(
                        children: [
                          dataCell('${i + 1}'),
                          dataCell(v(s, 'id')),
                          dataCell(v(s, 'name'), align: TextAlign.left),
                          // midterm standing
                          ...prelimStandingCols
                              .map((c) => dataCell(v(s, c)))
                              .toList(),
                          ...prelimLectureCols
                              .map((c) => dataCell(v(s, c)))
                              .toList(),
                          // final group
                          ...finalCols.map((c) => dataCell(v(s, c))).toList(),
                        ],
                      );
                    }).toList(),
                  ],
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
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
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
                  const Text(
                    'Add New Quiz',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onCancel,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Quiz Name',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: activityNameController,
                cursorColor: Colors.black54,
                decoration: InputDecoration(
                  hintText: 'Enter Quiz name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF9E9E9E),
                    ), // black38 equivalent
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF34A853),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Maximum Score',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: maxScoreController,
                cursorColor: Colors.black54,
                decoration: InputDecoration(
                  hintText: 'Enter maximum score',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF9E9E9E),
                    ), // black38 equivalent
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF34A853),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Quiz Type',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: activityTypeController,
                cursorColor: Colors.black54,
                decoration: InputDecoration(
                  hintText: 'Enter Quiz type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF9E9E9E),
                    ), // black38 equivalent
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF34A853),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
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
                        side: const BorderSide(
                          color: Color(0xFF9E9E9E),
                        ), // black38 equivalent
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 0,
                        ),
                      ),
                      onPressed: onCancel,
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 50, // Match TextField height
                    width: 160,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF34A853),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 0,
                        ),
                      ),
                      onPressed: onAdd,
                      child: const Text(
                        'Add Quiz',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
