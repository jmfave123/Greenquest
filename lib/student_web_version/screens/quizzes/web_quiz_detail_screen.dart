import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

class WebQuizDetailScreen extends StatefulWidget {
  final Map<String, dynamic> quiz;

  const WebQuizDetailScreen({super.key, required this.quiz});

  @override
  State<WebQuizDetailScreen> createState() => _WebQuizDetailScreenState();
}

class _WebQuizDetailScreenState extends State<WebQuizDetailScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late StudentSubmissionController submissionController;
  late FileSubmissionController fileController;

  @override
  void initState() {
    super.initState();
    submissionController = Get.put(StudentSubmissionController());
    fileController = Get.put(FileSubmissionController());
    _loadSubmissionData();
  }

  Future<void> _loadSubmissionData() async {
    await submissionController.loadSubmissionData(
      activityId: widget.quiz['id'],
      activityType: 'quiz',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = WebResponsiveUtils.isDesktop(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: WebAppBar(
        title: 'Quiz Details',
        onMenuPressed:
            isDesktop ? null : () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer:
          !isDesktop
              ? Drawer(child: WebSidebar(currentRoute: WebRoutes.quizzes))
              : null,
      body: Row(
        children: [
          if (isDesktop) const WebSidebar(currentRoute: WebRoutes.quizzes),
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: SingleChildScrollView(
          padding: WebResponsiveUtils.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // Back button
              TextButton.icon(
                onPressed: () => Get.toNamed(WebRoutes.quizzes),
                icon: const Icon(Icons.arrow_back, size: 20),
                label: const Text('Back to Quizzes'),
                style: TextButton.styleFrom(
                  foregroundColor: WebTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildMainInfo()),
                  const SizedBox(width: 32),
                  Expanded(flex: 1, child: _buildSubmissionPanel()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainInfo() {
    final List<dynamic> attachments = widget.quiz['attachments'] ?? [];

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
          _buildHeader(),
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
            widget.quiz['instruction'] ?? 'No instructions provided.',
            style: WebTheme.bodyLarge.copyWith(height: 1.6),
          ),
          WebInstructorAttachmentsWidget(attachments: attachments),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'QUIZ',
                style: TextStyle(
                  color: Colors.purple,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            const Spacer(),
            if (widget.quiz['period'] != null)
              _buildPeriodBadge(widget.quiz['period'].toString()),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          widget.quiz['title'] ?? 'Untitled Quiz',
          style: WebTheme.headingMedium.copyWith(fontSize: 26),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildInfoChip(
              Icons.person_outline,
              widget.quiz['instructorName'] ?? 'Instructor',
            ),
            const SizedBox(width: 20),
            _buildInfoChip(Icons.stars, '${widget.quiz['points'] ?? 0} Points'),
            const SizedBox(width: 20),
            _buildInfoChip(
              Icons.calendar_today_outlined,
              'Due: ${_getDueDateFormatted(widget.quiz['dueDate'])}',
            ),
          ],
        ),
      ],
    );
  }

  String _getDueDateFormatted(dynamic dueDate) {
    if (dueDate == null) return 'No due date';
    try {
      DateTime? date;
      if (dueDate is Timestamp) {
        date = dueDate.toDate();
      } else if (dueDate is DateTime) {
        date = dueDate;
      } else if (dueDate is String) {
        // Already formatted by controller — pass through
        if (dueDate.contains('AM') || dueDate.contains('PM')) return dueDate;
        date = DateTime.tryParse(dueDate);
      }
      if (date == null) return dueDate.toString();
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
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      final ampm = date.hour < 12 ? 'AM' : 'PM';
      return '${months[date.month - 1]} ${date.day}, ${date.year} $hour:$minute $ampm';
    } catch (_) {
      return dueDate.toString();
    }
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: WebTheme.textSecondary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: WebTheme.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildPeriodBadge(String period) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Text(
        period,
        style: const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSubmissionPanel() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WebTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Submission',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Obx(() {
            final isGraded = submissionController.isGraded.value;
            final status = submissionController.submissionStatus.value;

            if (isGraded) {
              return _buildGradedState();
            } else if (status.toLowerCase().contains('submit')) {
              return _buildSubmittedState();
            } else {
              return _buildPendingState();
            }
          }),
          const SizedBox(height: 16),
          WebSubmittedFilesWidget(
            submissionController: submissionController,
          ),
        ],
      ),
    );
  }

  Widget _buildGradedState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: WebTheme.hoverGreen,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.check_circle,
                color: WebTheme.primaryGreen,
                size: 40,
              ),
              const SizedBox(height: 12),
              const Text(
                'Successfully Graded',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${submissionController.submissionScore.value.toInt()} / ${widget.quiz['points'] ?? 100}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: WebTheme.primaryGreen,
                ),
              ),
            ],
          ),
        ),
        if (submissionController.submissionFeedback.value.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildFeedbackBox(),
        ],
      ],
    );
  }

  Widget _buildSubmittedState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            children: [
              Icon(Icons.cloud_done_outlined, color: Colors.blue, size: 40),
              SizedBox(height: 12),
              Text(
                'Handed In',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Awaiting instructor review',
                style: TextStyle(fontSize: 12, color: WebTheme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPendingState() {
    final isPastDue = DueDateUtils.isPastDue(widget.quiz['dueDate']);
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
          label: 'Submit Quiz',
          isDisabled: isPastDue,
          onUploadComplete: () async {
            // 1. Upload files to Cloudinary
            final success = await fileController.uploadFiles(
              folder: 'submissions/quizzes',
              tags: {'type': 'quiz', 'activityId': widget.quiz['id']},
            );

            if (success) {
              // 2. Submit quiz to Firestore
              final submitted = await fileController.submitQuiz(
                quizId: widget.quiz['id'],
                instructorId: widget.quiz['instructorId'] ?? '',
                instructorName: widget.quiz['instructorName'] ?? '',
                sectionId: '',
              );

              if (submitted) {
                _loadSubmissionData();
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildFeedbackBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lock_outline,
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 6),
              const Text(
                'Private Comment',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            submissionController.submissionFeedback.value,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.amber.shade900,
            ),
          ),
        ],
      ),
    );
  }
}
