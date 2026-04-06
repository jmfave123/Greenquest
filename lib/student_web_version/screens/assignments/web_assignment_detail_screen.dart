import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../user/submit/assignment/assignment_controller.dart';
import '../../../user/submit/student_submission_controller.dart';
import '../../../shared/controllers/file_submission_controller.dart';
import '../../widgets/submissions/web_file_upload_widget.dart';
import '../../widgets/submissions/web_instructor_attachments_widget.dart';
import '../../widgets/submissions/web_submitted_files_widget.dart';
import '../../../core/utils/date_utils.dart';
import '../../config/web_theme.dart';
import '../../config/web_routes.dart';
import '../../utils/web_responsive_utils.dart';
import '../../widgets/layout/web_app_bar.dart';
import '../../widgets/layout/web_sidebar.dart';

class WebAssignmentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> assignment;

  const WebAssignmentDetailScreen({super.key, required this.assignment});

  @override
  State<WebAssignmentDetailScreen> createState() =>
      _WebAssignmentDetailScreenState();
}

class _WebAssignmentDetailScreenState extends State<WebAssignmentDetailScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AssignmentController assignmentController;
  late StudentSubmissionController submissionController;
  late FileSubmissionController fileController;

  @override
  void initState() {
    super.initState();
    try {
      assignmentController = Get.find<AssignmentController>();
    } catch (e) {
      assignmentController = Get.put(AssignmentController(), permanent: true);
    }

    submissionController = Get.put(StudentSubmissionController());
    fileController = Get.put(FileSubmissionController());
    _loadSubmissionData();
  }

  Future<void> _loadSubmissionData() async {
    await submissionController.loadSubmissionData(
      activityId: widget.assignment['id'],
      activityType: 'assignment',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = WebResponsiveUtils.isDesktop(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: WebAppBar(
        title: 'Assignment Details',
        onMenuPressed:
            isDesktop ? null : () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer:
          !isDesktop
              ? Drawer(child: WebSidebar(currentRoute: WebRoutes.assignments))
              : null,
      body: Row(
        children: [
          if (isDesktop) const WebSidebar(currentRoute: WebRoutes.assignments),
          Expanded(
            child: Container(
              color: WebTheme.backgroundLight,
              child: _buildContent(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final isDesktop = WebResponsiveUtils.isDesktop(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: SingleChildScrollView(
          padding: WebResponsiveUtils.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // Back button
              TextButton.icon(
                onPressed: () => Get.toNamed(WebRoutes.assignments),
                icon: const Icon(Icons.arrow_back, size: 20),
                label: const Text('Back to Assignments'),
                style: TextButton.styleFrom(
                  foregroundColor: WebTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildMainInfo()),
                    const SizedBox(width: 32),
                    Expanded(flex: 1, child: _buildSubmissionPanel()),
                  ],
                )
              else
                Column(
                  children: [
                    _buildMainInfo(),
                    const SizedBox(height: 24),
                    _buildSubmissionPanel(),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainInfo() {
    final List<dynamic> attachments = widget.assignment['attachments'] ?? [];

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WebTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTaskHeader(),
          const Divider(height: 48),
          const Text(
            'Instructions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: WebTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.assignment['instruction'] ?? 'No instructions provided.',
            style: WebTheme.bodyLarge.copyWith(height: 1.6),
          ),
          WebInstructorAttachmentsWidget(attachments: attachments),
        ],
      ),
    );
  }

  Widget _buildTaskHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'ASSIGNMENT',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            const Spacer(),
            _buildPointsBadge(),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          widget.assignment['title'] ?? 'Untitled Assignment',
          style: WebTheme.headingMedium.copyWith(fontSize: 28),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildInfoChip(
              Icons.person_outline,
              widget.assignment['instructorName'] ?? 'Instructor',
            ),
            const SizedBox(width: 24),
            _buildInfoChip(
              Icons.calendar_today_outlined,
              'Due: ${assignmentController.getDueDateFormatted(widget.assignment['dueDate'])}',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: WebTheme.textSecondary),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: WebTheme.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildPointsBadge() {
    return Row(
      children: [
        const Icon(Icons.stars, color: Colors.orange, size: 20),
        const SizedBox(width: 8),
        Text(
          '${widget.assignment['points'] ?? 0} Points',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: WebTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmissionPanel() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: WebTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Work',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildStatusDisplay(),
          const SizedBox(height: 24),
          _buildSubmissionAction(),
          const SizedBox(height: 16),
          WebSubmittedFilesWidget(
            submissionController: submissionController,
          ),
          const SizedBox(height: 24),
          _buildFeedbackSection(),
        ],
      ),
    );
  }

  Widget _buildStatusDisplay() {
    return Obx(() {
      final status = submissionController.submissionStatus.value;
      final isGraded = submissionController.isGraded.value;

      Color statusColor = Colors.grey;
      IconData statusIcon = Icons.info_outline;
      String statusText = status.isNotEmpty ? status : 'Pending';

      if (isGraded) {
        statusColor = WebTheme.primaryGreen;
        statusIcon = Icons.check_circle;
      } else if (status.toLowerCase().contains('submitted')) {
        statusColor = Colors.blue;
        statusIcon = Icons.cloud_done;
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status',
                    style: TextStyle(
                      color: statusColor.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            if (isGraded)
              Text(
                '${submissionController.submissionScore.value.toInt()}/${widget.assignment['points'] ?? 100}',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildSubmissionAction() {
    final isPastDue = DueDateUtils.isPastDue(widget.assignment['dueDate']);
    return Obx(() {
      final isSubmitted =
          submissionController.submissionStatus.value.toLowerCase().contains(
            'submitted',
          ) ||
          submissionController.isGraded.value;

      if (isSubmitted) {
        return Column(
          children: [
            const Icon(Icons.task_alt, color: WebTheme.primaryGreen, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Successfully Submitted',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: WebTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Submitted on ${submissionController.getSubmittedAtFormatted()}',
              style: const TextStyle(
                fontSize: 12,
                color: WebTheme.textSecondary,
              ),
            ),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload Files',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: WebTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          WebFileUploadWidget(
            controller: fileController,
            label: 'Submit Assignment',
            isDisabled: isPastDue,
            onUploadComplete: () async {
              // 1. Upload files to Cloudinary first
              final success = await fileController.uploadFiles(
                folder: 'submissions/assignments',
                tags: {
                  'type': 'assignment',
                  'activityId': widget.assignment['id'],
                },
              );

              if (success) {
                // 2. Submit assignment data to Firestore
                final submitted = await fileController.submitAssignment(
                  assignmentId: widget.assignment['id'],
                  instructorId: widget.assignment['instructorId'] ?? '',
                  instructorName: widget.assignment['instructorName'] ?? '',
                  sectionId:
                      '', // Controller will use student's enrolled section
                );

                if (submitted) {
                  // Reload submission data to show success state
                  _loadSubmissionData();
                }
              }
            },
          ),
        ],
      );
    });
  }

  Widget _buildFeedbackSection() {
    return Obx(() {
      if (!submissionController.isGraded.value ||
          submissionController.submissionFeedback.value.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.lock_outline,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 6),
              const Text(
                'Private Comment',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: WebTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Text(
              submissionController.submissionFeedback.value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.amber.shade900,
                height: 1.5,
              ),
            ),
          ),
        ],
      );
    });
  }
}

extension on AssignmentController {
  String getDueDateFormatted(dynamic dueDate) {
    if (dueDate == null) return 'No due date';
    try {
      DateTime date;
      if (dueDate is Timestamp) {
        date = dueDate.toDate();
      } else if (dueDate is String) {
        // If it's already a formatted string from Firebase, just return it
        if (dueDate.contains('at') &&
            (dueDate.contains('AM') || dueDate.contains('PM'))) {
          // Firebase format: "February 11, 2026 at 11:00:00 AM UTC+8"
          // Just clean it up a bit
          return dueDate.replaceAll(' UTC+8', '').replaceAll(' UTC', '');
        }
        // Try to parse ISO format
        date = DateTime.parse(dueDate);
      } else if (dueDate is DateTime) {
        date = dueDate;
      } else {
        return 'No due date';
      }

      final months = [
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
      final hour =
          date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final period = date.hour >= 12 ? 'PM' : 'AM';
      final minute = date.minute.toString().padLeft(2, '0');

      return '${months[date.month - 1]} ${date.day}, ${date.year} at $hour:$minute $period';
    } catch (e) {
      // If all parsing fails, return the original string if it's a string
      if (dueDate is String) return dueDate;
      return 'No due date';
    }
  }
}

extension on StudentSubmissionController {
  String getSubmittedAtFormatted() {
    return 'Recently';
  }
}
