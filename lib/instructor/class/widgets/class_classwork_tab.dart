import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../../core/utils/app_logger.dart';
import '../../../shared/widgets/skeleton_loading.dart';
import '../../submissions/submission_detail_screen.dart';
import '../../submissions/submissions_controller.dart';
import '../class_detail_constants.dart';

/// Classwork Tab Widget - Shows student submissions with filtering
/// Extracted from ClassDetailScreen per agent.md Section 4.1 (Separation of Concerns)
class ClassClassworkTab extends StatefulWidget {
  final Map<String, dynamic> classData;
  final SubmissionsController submissionsController;
  final VoidCallback onRefresh;

  const ClassClassworkTab({
    super.key,
    required this.classData,
    required this.submissionsController,
    required this.onRefresh,
  });

  @override
  State<ClassClassworkTab> createState() => _ClassClassworkTabState();
}

class _ClassClassworkTabState extends State<ClassClassworkTab> {
  final _logger = AppLogger('ClassClassworkTab');

  // Search and filter states
  final TextEditingController _submissionSearchController =
      TextEditingController();
  String _submissionSearchQuery = '';
  String _selectedSubmissionTypeFilter = 'All Types';
  String _selectedSubmissionStatusFilter = 'All Status';

  @override
  void dispose() {
    _submissionSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ClassDetailConstants.horizontalPagePadding,
      ),
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
                      onPressed: widget.onRefresh,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh submissions',
                    ),
                  ],
                ),
                const SizedBox(height: ClassDetailConstants.defaultPadding),

                // Search and Filter Controls
                _buildSearchAndFilterControls(),
                const SizedBox(height: ClassDetailConstants.defaultPadding),

                // Results Counter
                if (_submissionSearchQuery.isNotEmpty ||
                    _selectedSubmissionTypeFilter != 'All Types' ||
                    _selectedSubmissionStatusFilter != 'All Status')
                  _buildResultsCounter(),
                if (_submissionSearchQuery.isNotEmpty ||
                    _selectedSubmissionTypeFilter != 'All Types' ||
                    _selectedSubmissionStatusFilter != 'All Status')
                  const SizedBox(height: 12),

                // Student Submissions List
                Expanded(child: _buildSubmissionsList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterControls() {
    return Container(
      padding: const EdgeInsets.all(ClassDetailConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(
          ClassDetailConstants.cardBorderRadius,
        ),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _submissionSearchController,
            decoration: InputDecoration(
              hintText: 'Search by student name or activity name...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon:
                  _submissionSearchQuery.isNotEmpty
                      ? IconButton(
                        onPressed: () {
                          _submissionSearchController.clear();
                          setState(() {
                            _submissionSearchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.clear, color: Colors.grey),
                      )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: ClassDetailConstants.primaryGreen,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: ClassDetailConstants.defaultPadding,
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
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: DropdownButton<String>(
                    value: _selectedSubmissionTypeFilter,
                    underline: const SizedBox(),
                    isDense: true,
                    hint: const Text('Filter by type'),
                    items:
                        ClassDetailConstants.submissionTypeFilterOptions.map((
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
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: DropdownButton<String>(
                    value: _selectedSubmissionStatusFilter,
                    underline: const SizedBox(),
                    isDense: true,
                    hint: const Text('Filter by status'),
                    items:
                        ClassDetailConstants.submissionStatusFilterOptions.map((
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
    );
  }

  Widget _buildResultsCounter() {
    final filteredCount = _getFilteredSubmissionsCount();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ClassDetailConstants.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ClassDetailConstants.primaryGreen.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.filter_list,
            size: 16,
            color: ClassDetailConstants.primaryGreen,
          ),
          const SizedBox(width: 8),
          Text(
            'Showing $filteredCount submission${filteredCount != 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: ClassDetailConstants.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionsList() {
    return Obx(() {
      if (widget.submissionsController.isLoading.value) {
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
      for (var submission in widget.submissionsController.submissions) {
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
        return _buildEmptyState();
      }

      return ListView.builder(
        itemCount: submissions.length,
        itemBuilder: (context, index) {
          final submission = submissions[index];
          return _buildSubmissionCard(submission);
        },
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ClassDetailConstants.defaultPadding,
            vertical: ClassDetailConstants.largePadding,
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
              const SizedBox(height: ClassDetailConstants.defaultPadding),
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ClassDetailConstants.defaultPadding,
                ),
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
                padding: EdgeInsets.symmetric(
                  horizontal: ClassDetailConstants.defaultPadding,
                ),
                child: Text(
                  'Student submissions will appear here when they submit their work.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmissionCard(Map<String, dynamic> submission) {
    final status = submission['status'] ?? ClassDetailConstants.statusSubmitted;
    final studentName =
        submission['studentName'] ?? ClassDetailConstants.defaultStudentName;
    final submissionType = submission['type'] ?? 'assignment';
    final submittedAt = submission['submittedAt'];
    final grade = submission['grade'];

    return Container(
      margin: const EdgeInsets.only(
        bottom: ClassDetailConstants.cardVerticalSpacing,
      ),
      padding: const EdgeInsets.all(ClassDetailConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          ClassDetailConstants.cardBorderRadius,
        ),
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
        borderRadius: BorderRadius.circular(
          ClassDetailConstants.cardBorderRadius,
        ),
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

  /// Navigate to submission detail screen
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
      // Unified submissions use 'activityId' for all types
      final assignmentId =
          submission['activityId'] ?? // Unified field (preferred)
          submission['assignmentId'] ??
          submission['quizId'] ??
          submission['pitId'];

      if (assignmentId != null) {
        final submissionType =
            submission['type'] ?? submission['activityType'] ?? 'activity';
        String collection;

        switch (submissionType.toLowerCase()) {
          case ClassDetailConstants.activityTypeAssignment:
            collection = 'assignments';
            break;
          case ClassDetailConstants.activityTypeActivity:
            collection = 'activities';
            break;
          case ClassDetailConstants.activityTypeQuiz:
            collection = 'quizzes';
            break;
          case ClassDetailConstants.activityTypePIT:
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
            _logger.debug(
              'Fetched actual points',
              context: {
                'points': actualPoints,
                'type': submissionType,
                'id': assignmentId,
              },
            );
          }
        }
      }
    } catch (e) {
      _logger.warning(
        'Error fetching actual points',
        context: {'error': e.toString()},
      );
      // Keep default value of 100
    }

    // Hide loading indicator
    if (mounted) {
      Navigator.of(context).pop();
    }

    // Create activity data for the submission detail screen
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
    if (mounted) {
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
  }

  /// Show confirmation dialog for removing submission
  void _showRemoveSubmissionDialog(Map<String, dynamic> submission) {
    final studentName =
        submission['studentName'] ?? ClassDetailConstants.defaultStudentName;
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
                  backgroundColor: ClassDetailConstants.rejectedColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Remove'),
              ),
            ],
          ),
    );
  }

  /// Remove submission from Firestore and local list
  Future<void> _removeSubmission(Map<String, dynamic> submission) async {
    try {
      final submissionId = submission['id'];
      final submissionType = submission['type'] ?? 'assignment';

      if (submissionId == null) {
        Get.snackbar(
          'Error',
          'Submission ID not found',
          backgroundColor: ClassDetailConstants.rejectedColor,
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
      final success = await widget.submissionsController.removeSubmission(
        submissionId,
        submissionType,
      );

      if (success) {
        Get.snackbar(
          'Success',
          ClassDetailConstants.successSubmissionGraded,
          backgroundColor: ClassDetailConstants.approvedColor,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          ClassDetailConstants.errorGradingSubmission,
          backgroundColor: ClassDetailConstants.rejectedColor,
          colorText: Colors.white,
        );
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Error removing submission',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar(
        'Error',
        '${ClassDetailConstants.errorGradingSubmission}: $e',
        backgroundColor: ClassDetailConstants.rejectedColor,
        colorText: Colors.white,
      );
    }
  }

  /// Filter submissions based on search query and filters
  List<Map<String, dynamic>> _filterSubmissions(
    List<Map<String, dynamic>> submissions,
  ) {
    List<Map<String, dynamic>> filtered = submissions;

    // EXCLUDE tree planting submissions - they should only appear in Trees tab
    filtered =
        filtered.where((submission) {
          final activityType =
              submission['activityType']?.toString().toLowerCase() ?? '';
          return activityType != ClassDetailConstants.activityTypeTreePlanting;
        }).toList();

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
                return type == ClassDetailConstants.activityTypeAssignment;
              case 'Activity':
                return type == ClassDetailConstants.activityTypeActivity;
              case 'Quiz':
                return type == ClassDetailConstants.activityTypeQuiz;
              case 'PIT':
                return type ==
                    ClassDetailConstants.activityTypePIT.toLowerCase();
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
              case 'Submitted (Not Yet Graded)':
                return status == ClassDetailConstants.statusSubmitted;
              case 'Graded':
                return status == ClassDetailConstants.statusGraded;
              case 'Late':
                return status == ClassDetailConstants.statusLate;
              default:
                return true;
            }
          }).toList();
    }

    return filtered;
  }

  /// Get filtered submissions count
  int _getFilteredSubmissionsCount() {
    List<Map<String, dynamic>> submissions = [];
    for (var submission in widget.submissionsController.submissions) {
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

  /// Get status color
  Color _getSubmissionStatusColor(String status) {
    switch (status.toLowerCase()) {
      case ClassDetailConstants.statusSubmitted:
        return ClassDetailConstants.submittedColor;
      case ClassDetailConstants.statusGraded:
        return ClassDetailConstants.gradedColor;
      case ClassDetailConstants.statusLate:
        return ClassDetailConstants.lateSubmissionColor;
      case 'missing':
        return ClassDetailConstants.rejectedColor;
      default:
        return Colors.grey;
    }
  }

  /// Get status icon
  IconData _getSubmissionStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case ClassDetailConstants.statusSubmitted:
        return Icons.upload_file;
      case ClassDetailConstants.statusGraded:
        return Icons.check_circle;
      case ClassDetailConstants.statusLate:
        return Icons.schedule;
      case 'missing':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  /// Get type color
  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case ClassDetailConstants.activityTypeAssignment:
        return Colors.purple;
      case ClassDetailConstants.activityTypeActivity:
        return ClassDetailConstants.submittedColor;
      case ClassDetailConstants.activityTypeQuiz:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Format submission date
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
      _logger.warning(
        'Error formatting submission date',
        context: {'error': e.toString()},
      );
      return 'Recently submitted';
    }
  }
}
