// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/instructor/instructor_appbar.dart';
import '../../shared/instructor/instructor_sidebar.dart';
import '../../shared/instructor/instructor_navigation_constants.dart';
import '../instructor_dashboard_controller.dart';
import 'submission_detail_screen.dart';
import 'submissions_controller.dart';

class StudentSubmissionsScreen extends StatefulWidget {
  final Map<String, dynamic> activityData;
  final String? sectionId; // Add section ID parameter

  const StudentSubmissionsScreen({
    super.key,
    required this.activityData,
    this.sectionId,
  });

  @override
  State<StudentSubmissionsScreen> createState() =>
      _StudentSubmissionsScreenState();
}

class _StudentSubmissionsScreenState extends State<StudentSubmissionsScreen> {
  InstructorNavigationItem _selectedItem =
      InstructorNavigationItem.classManagement;

  late SubmissionsController submissionsController;
  final InstructorController instructorController = Get.put(
    InstructorController(),
  );

  @override
  void initState() {
    super.initState();
    submissionsController = Get.put(SubmissionsController());

    // Defer loading to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSubmissions();

      // Set up a delayed fallback to try direct loading if no submissions found
      Future.delayed(const Duration(seconds: 2), () {
        if (submissionsController.submissions.isEmpty) {
          print(
            '🔄 No submissions found with standard method, trying direct loading...',
          );
          _loadSubmissionsDirectly();
        }
      });
    });
  }

  void _loadSubmissions() {
    final activityData = widget.activityData;
    final itemType =
        activityData['type']?.toString().toLowerCase() ?? 'activity';
    final sectionId = widget.sectionId;

    print('🔍 Loading submissions for:');
    print('  - Activity ID: ${activityData['id']}');
    print('  - Activity Type: $itemType');
    print('  - Section ID: $sectionId');

    // First try the standard loading method
    if (itemType == 'assignment') {
      submissionsController.loadAssignmentSubmissions(
        activityData['id'] ?? '',
        sectionId: sectionId,
      );
    } else if (itemType == 'quiz') {
      submissionsController.loadQuizSubmissions(
        activityData['id'] ?? '',
        sectionId: sectionId,
      );
    } else if (itemType == 'activity') {
      submissionsController.loadActivitySubmissions(
        activityData['id'] ?? '',
        sectionId: sectionId,
      );
    } else if (itemType == 'pit') {
      // For PITs, use direct loading since there's no specific PIT loading method
      _loadSubmissionsDirectly();
    } else {
      // Fallback to direct loading for any other types
      _loadSubmissionsDirectly();
    }
  }

  // Alternative method to load submissions directly from Firestore
  // Uses unified submissions collection (like the submissions controller)
  Future<void> _loadSubmissionsDirectly() async {
    try {
      final activityData = widget.activityData;
      final itemType =
          activityData['type']?.toString().toLowerCase() ?? 'activity';
      final activityId = activityData['id'] ?? '';
      final sectionId = widget.sectionId;
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        print('❌ No user authenticated for direct load');
        return;
      }

      print('🔧 Direct load: $itemType with ID: $activityId');
      print('🔧 Section: $sectionId');

      // Use unified submissions collection
      Query query = FirebaseFirestore.instance
          .collection('submissions')
          .where('activityType', isEqualTo: itemType)
          .where('activityId', isEqualTo: activityId)
          .where('instructorId', isEqualTo: user.uid);

      // If section is provided, query directly by sectionName
      if (sectionId != null && sectionId.isNotEmpty) {
        print('  - Querying directly by sectionName: $sectionId');
        query = query.where('sectionName', isEqualTo: sectionId);
      }

      QuerySnapshot querySnapshot;
      try {
        querySnapshot =
            await query.orderBy('submittedAt', descending: true).get();
      } catch (e) {
        print('  - OrderBy failed, trying without it: $e');
        querySnapshot = await query.get();
      }

      print('🔧 Direct query returned ${querySnapshot.docs.length} documents');

      List<Map<String, dynamic>> directSubmissions = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('🔧 Found direct submission: ${doc.id}');
        print('  - Student: ${data['studentName']}');
        print('  - Section: ${data['sectionName']}');
        directSubmissions.add({'id': doc.id, 'type': itemType, ...data});
      }

      // Load enrolled students if section is specified
      if (sectionId != null && sectionId.isNotEmpty) {
        await submissionsController.loadEnrolledStudents(sectionId);
      }

      // Update observables directly - async operations are done, build phase is complete
      submissionsController.submissions.assignAll(directSubmissions);
      submissionsController.updateStats();
    } catch (e) {
      print('❌ Error in direct load: $e');
    }
  }

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
    // If filter is "All", combine submissions and non-submitted students
    if (submissionsController.selectedFilter.value == 'All') {
      final allStudents = <Map<String, dynamic>>[];

      // Add all submissions first
      allStudents.addAll(submissionsController.submissions);

      // Add students who haven't submitted
      allStudents.addAll(submissionsController.getStudentsWithoutSubmission());

      return allStudents;
    }

    // If filter is "Not Yet Submitted", return students without submissions
    if (submissionsController.selectedFilter.value == 'Not Yet Submitted') {
      return submissionsController.getStudentsWithoutSubmission();
    }

    // Otherwise return filtered submissions from controller
    return submissionsController.filteredSubmissions;
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

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'activity':
        return Colors.blue;
      case 'assignment':
        return Colors.orange;
      case 'quiz':
        return Colors.purple;
      case 'pit':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'activity':
        return 'ACTIVITY';
      case 'assignment':
        return 'ASSIGNMENT';
      case 'quiz':
        return 'QUIZ';
      case 'pit':
        return 'PIT';
      default:
        return 'UNKNOWN';
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
                    instructorName: instructorController.instructorName.value,
                    instructorRole: 'Instructor',
                    profileImageUrl: instructorController.profileImageUrl.value,
                  ),
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
                                    '${widget.activityData['type'] ?? 'Activity'}: ${widget.activityData['title'] ?? 'Untitled'}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                ],
                              ),
                            ),
                            // Refresh button
                            IconButton(
                              onPressed: () {
                                _loadSubmissions();
                              },
                              icon: const Icon(Icons.refresh),
                              tooltip: 'Refresh submissions',
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFF34A853,
                                ).withOpacity(0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Statistics Cards
                        Obx(
                          () => Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                _buildStatCard(
                                  'Total Submissions',
                                  submissionsController.submissionStats['total']
                                      .toString(),
                                  Icons.people,
                                  Colors.blue,
                                ),
                                const SizedBox(width: 16),
                                _buildStatCard(
                                  'Graded',
                                  submissionsController
                                      .submissionStats['graded']
                                      .toString(),
                                  Icons.check_circle,
                                  Colors.green,
                                ),
                                const SizedBox(width: 16),
                                _buildStatCard(
                                  'Pending',
                                  submissionsController
                                      .submissionStats['pending']
                                      .toString(),
                                  Icons.pending,
                                  Colors.orange,
                                ),
                                const SizedBox(width: 16),
                                _buildStatCard(
                                  'Not Yet Submitted',
                                  submissionsController
                                      .submissionStats['notSubmitted']
                                      .toString(),
                                  Icons.cancel_outlined,
                                  Colors.red,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Filter Dropdown
                        Obx(
                          () => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE0E0E0),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.filter_list,
                                  color: Color(0xFF34A853),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Filter:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButton<String>(
                                    value:
                                        submissionsController
                                            .selectedFilter
                                            .value,
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    items:
                                        submissionsController.filterOptions.map(
                                          (String filter) {
                                            return DropdownMenuItem<String>(
                                              value: filter,
                                              child: Text(
                                                filter,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            );
                                          },
                                        ).toList(),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        submissionsController.setFilter(
                                          newValue,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Submissions List
                        Expanded(
                          child: Obx(() {
                            if (submissionsController.isLoading.value) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF34A853),
                                ),
                              );
                            }

                            if (submissionsController.submissions.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inbox,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No submissions yet',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Student submissions will appear here once they submit their work.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ListView.builder(
                              itemCount: _getFilteredSubmissions().length,
                              itemBuilder: (context, index) {
                                final submission =
                                    _getFilteredSubmissions()[index];
                                return _buildSubmissionCard(submission);
                              },
                            );
                          }),
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
    // Check if this is a student without submission
    final bool isNotSubmitted =
        submission['status'] == null &&
        submission['files'] == null &&
        submission['submittedAt'] == null;

    if (isNotSubmitted) {
      return _buildNotSubmittedCard(submission);
    }

    final files = submission['files'] as List<dynamic>? ?? [];
    final submittedAt = submission['submittedAt'];
    final studentName = submission['studentName'] ?? 'Unknown Student';
    final studentId =
        submission['idNumber'] ??
        submission['studentIdNumber'] ??
        submission['studentId'] ??
        'N/A';
    final status = submission['status'] ?? 'submitted';
    final grade = submission['grade'];
    final maxScore = widget.activityData['points'] ?? 100;

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
              backgroundColor: const Color(0xFF34A853).withOpacity(0.1),
              child: Text(
                studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF34A853),
                ),
              ),
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
                        studentName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '($studentId)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getTypeColor(
                            submission['type'] ?? 'activity',
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getTypeLabel(submission['type'] ?? 'activity'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getTypeColor(
                              submission['type'] ?? 'activity',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Submitted: ${submissionsController.formatSubmissionDate(submittedAt)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.attach_file,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${files.length} file(s)',
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
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(status),
                        size: 12,
                        color: _getStatusColor(status),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (grade != null)
                  Text(
                    '$grade/$maxScore',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  )
                else
                  const Text(
                    'Not graded',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),

            const SizedBox(width: 16),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildNotSubmittedCard(Map<String, dynamic> student) {
    final studentName = student['studentName'] ?? 'Unknown Student';
    // Try multiple possible ID field names
    final studentId =
        student['idNumber'] ??
        student['studentIdNumber'] ??
        student['studentId'] ??
        'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Student Avatar - Greyed out
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey.shade300,
            child: Text(
              studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
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
                      studentName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '($studentId)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'No submission yet',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          // Not Submitted Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cancel_outlined,
                  size: 16,
                  color: Colors.red.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  'Not Submitted',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
