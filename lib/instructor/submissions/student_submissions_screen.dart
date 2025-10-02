// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/instructor/instructor_appbar.dart';
import '../../shared/instructor/instructor_sidebar.dart';
import '../../shared/instructor/instructor_navigation_constants.dart';
import 'submission_detail_screen.dart';
import 'submissions_controller.dart';

class StudentSubmissionsScreen extends StatefulWidget {
  final Map<String, dynamic> activityData;

  const StudentSubmissionsScreen({super.key, required this.activityData});

  @override
  State<StudentSubmissionsScreen> createState() =>
      _StudentSubmissionsScreenState();
}

class _StudentSubmissionsScreenState extends State<StudentSubmissionsScreen> {
  InstructorNavigationItem _selectedItem =
      InstructorNavigationItem.classManagement;

  late SubmissionsController submissionsController;

  @override
  void initState() {
    super.initState();
    submissionsController = Get.put(SubmissionsController());
    _loadSubmissions();
  }

  void _loadSubmissions() {
    final activityData = widget.activityData;
    final itemType =
        activityData['type']?.toString().toLowerCase() ?? 'activity';

    if (itemType == 'assignment') {
      submissionsController.loadAssignmentSubmissions(activityData['id'] ?? '');
    } else {
      submissionsController.loadActivitySubmissions(activityData['id'] ?? '');
    }
  }

  // Sample student submissions data (keeping as fallback)
  final List<Map<String, dynamic>> _sampleSubmissions = [
    {
      'id': '1',
      'studentName': 'Andrei Vern',
      'studentId': '2023-001',
      'avatar': 'assets/images/Avatar.png',
      'submittedAt': '2024-01-15 10:30 AM',
      'status': 'submitted', // submitted, graded, late
      'score': null,
      'maxScore': 100,
      'files': [
        {'name': 'activity_10_solution.pdf', 'type': 'pdf', 'size': '2.3 MB'},
        {'name': 'activity_10_code.py', 'type': 'python', 'size': '1.2 KB'},
      ],
      'comments': '',
    },
    {
      'id': '2',
      'studentName': 'Sofia Grey',
      'studentId': '2023-002',
      'avatar': 'assets/images/Avatar.png',
      'submittedAt': '2024-01-15 11:45 AM',
      'status': 'graded',
      'score': 85,
      'maxScore': 100,
      'files': [
        {'name': 'assignment_solution.docx', 'type': 'docx', 'size': '1.8 MB'},
      ],
      'comments': 'Good work! Consider improving the conclusion.',
    },
    {
      'id': '3',
      'studentName': 'Princess',
      'studentId': '2023-003',
      'avatar': 'assets/images/Avatar.png',
      'submittedAt': '2024-01-16 09:15 AM',
      'status': 'late',
      'score': null,
      'maxScore': 100,
      'files': [
        {'name': 'activity_submission.pdf', 'type': 'pdf', 'size': '3.1 MB'},
      ],
      'comments': '',
    },
    {
      'id': '4',
      'studentName': 'Sophia',
      'studentId': '2023-004',
      'avatar': 'assets/images/Avatar.png',
      'submittedAt': '2024-01-14 08:20 PM',
      'status': 'graded',
      'score': 95,
      'maxScore': 100,
      'files': [
        {'name': 'solution_report.pdf', 'type': 'pdf', 'size': '2.7 MB'},
        {'name': 'data_analysis.xlsx', 'type': 'excel', 'size': '456 KB'},
      ],
      'comments': 'Excellent work! Very detailed analysis.',
    },
    {
      'id': '5',
      'studentName': 'Rose Ann',
      'studentId': '2023-005',
      'avatar': 'assets/images/Avatar.png',
      'submittedAt': '2024-01-15 02:30 PM',
      'status': 'submitted',
      'score': null,
      'maxScore': 100,
      'files': [
        {'name': 'activity_10_final.pdf', 'type': 'pdf', 'size': '1.9 MB'},
      ],
      'comments': '',
    },
    {
      'id': '6',
      'studentName': 'Bryan David',
      'studentId': '2023-006',
      'avatar': 'assets/images/Avatar.png',
      'submittedAt': '2024-01-15 12:00 PM',
      'status': 'graded',
      'score': 78,
      'maxScore': 100,
      'files': [
        {'name': 'submission.zip', 'type': 'zip', 'size': '4.2 MB'},
      ],
      'comments': 'Good effort. Please review the formatting guidelines.',
    },
  ];

  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Submitted', 'Graded', 'Late'];

  void _handleNavigationSelect(InstructorNavigationItem item) {
    setState(() {
      _selectedItem = item;
    });
    String route = InstructorNavigationHelper.getRoute(item);
    Navigator.of(context).pushReplacementNamed(route);
  }

  void _navigateToSubmissionDetail(Map<String, dynamic> submission) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => SubmissionDetailScreen(
              activityData: widget.activityData,
              submissionData: submission,
            ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredSubmissions() {
    if (_selectedFilter == 'All') {
      return submissionsController.submissions;
    }

    return submissionsController.submissions.where((submission) {
      switch (_selectedFilter) {
        case 'Submitted':
          return submission['status'] == 'submitted';
        case 'Graded':
          return submission['status'] == 'graded';
        case 'Late':
          return submission['status'] == 'late';
        default:
          return true;
      }
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'submitted':
        return Colors.blue;
      case 'graded':
        return Colors.green;
      case 'late':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'submitted':
        return Icons.upload_file;
      case 'graded':
        return Icons.check_circle;
      case 'late':
        return Icons.schedule;
      default:
        return Icons.help_outline;
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
                        // Header
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Color(0xFF34A853),
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFF34A853,
                                ).withOpacity(0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Student Submissions',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.activityData['title'] ?? 'Activity',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Filter dropdown
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFE0E0E0),
                                ),
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
                        const SizedBox(height: 24),

                        // Statistics Cards
                        Row(
                          children: [
                            _buildStatCard(
                              'Total Submissions',
                              submissionsController.submissions.length
                                  .toString(),
                              Icons.people,
                              Colors.blue,
                            ),
                            const SizedBox(width: 16),
                            _buildStatCard(
                              'Graded',
                              submissionsController.submissions
                                  .where((s) => s['status'] == 'graded')
                                  .length
                                  .toString(),
                              Icons.check_circle,
                              Colors.green,
                            ),
                            const SizedBox(width: 16),
                            _buildStatCard(
                              'Pending',
                              submissionsController.submissions
                                  .where((s) => s['status'] == 'submitted')
                                  .length
                                  .toString(),
                              Icons.pending,
                              Colors.orange,
                            ),
                            const SizedBox(width: 16),
                            _buildStatCard(
                              'Late',
                              submissionsController.submissions
                                  .where((s) => s['status'] == 'late')
                                  .length
                                  .toString(),
                              Icons.schedule,
                              Colors.red,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Submissions List
                        Expanded(
                          child: ListView.builder(
                            itemCount: _getFilteredSubmissions().length,
                            itemBuilder: (context, index) {
                              final submission =
                                  _getFilteredSubmissions()[index];
                              return _buildSubmissionCard(submission);
                            },
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
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionCard(Map<String, dynamic> submission) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToSubmissionDetail(submission),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Student Avatar
            CircleAvatar(
              radius: 25,
              backgroundImage: AssetImage(submission['avatar']),
            ),
            const SizedBox(width: 16),

            // Student Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        submission['studentName'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${submission['studentId']})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Submitted: ${submission['submittedAt']}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.attach_file, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${submission['files'].length} file(s)',
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

            // Status and Score
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      submission['status'],
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(submission['status']),
                        size: 12,
                        color: _getStatusColor(submission['status']),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        submission['status'].toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(submission['status']),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (submission['score'] != null)
                  Text(
                    '${submission['score']}/${submission['maxScore']}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  )
                else
                  Text(
                    'Not graded',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),

            const SizedBox(width: 16),
            Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
