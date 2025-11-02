// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  Future<void> _loadSubmissionsDirectly() async {
    try {
      final activityData = widget.activityData;
      final itemType =
          activityData['type']?.toString().toLowerCase() ?? 'activity';
      final activityId = activityData['id'] ?? '';

      print('🔧 Direct load: $itemType with ID: $activityId');

      String collectionName;
      String idFieldName;

      switch (itemType) {
        case 'assignment':
          collectionName = 'assignment_submissions';
          idFieldName = 'assignmentId';
          break;
        case 'activity':
          collectionName = 'activity_submissions';
          idFieldName = 'activityId';
          break;
        case 'quiz':
          collectionName = 'quiz_submissions';
          idFieldName = 'quizId';
          break;
        case 'pit':
          collectionName = 'submissions';
          idFieldName = 'pitId';
          break;
        default:
          collectionName = 'activity_submissions';
          idFieldName = 'activityId';
      }

      final querySnapshot =
          await FirebaseFirestore.instance
              .collection(collectionName)
              .where(idFieldName, isEqualTo: activityId)
              .get();

      print('🔧 Direct query returned ${querySnapshot.docs.length} documents');

      List<Map<String, dynamic>> directSubmissions = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        print('🔧 Found direct submission: ${doc.id}');
        print('  - Student: ${data['studentName']}');
        print('  - Section: ${data['sectionId']}');
        directSubmissions.add({'id': doc.id, 'type': itemType, ...data});
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
    // Return all submissions from controller
    return submissionsController.submissions;
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
                                  Text(
                                    'Topic: ${widget.activityData['topic'] ?? 'No topic'}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
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
                                  'Late',
                                  submissionsController.submissionStats['late']
                                      .toString(),
                                  Icons.schedule,
                                  Colors.red,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

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
    final files = submission['files'] as List<dynamic>? ?? [];
    final submittedAt = submission['submittedAt'];
    final studentName = submission['studentName'] ?? 'Unknown Student';
    final studentId =
        submission['studentIdNumber'] ?? submission['studentId'] ?? 'N/A';
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
}
