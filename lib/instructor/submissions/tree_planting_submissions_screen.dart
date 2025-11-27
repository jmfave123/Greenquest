import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../shared/instructor/instructor_appbar.dart';
import '../../shared/instructor/instructor_sidebar.dart';
import '../../shared/instructor/instructor_navigation_constants.dart';
import 'submissions_controller.dart';

class TreePlantingSubmissionsScreen extends StatefulWidget {
  final String? sectionId;

  const TreePlantingSubmissionsScreen({super.key, this.sectionId});

  @override
  State<TreePlantingSubmissionsScreen> createState() =>
      _TreePlantingSubmissionsScreenState();
}

class _TreePlantingSubmissionsScreenState
    extends State<TreePlantingSubmissionsScreen> {
  InstructorNavigationItem _selectedItem =
      InstructorNavigationItem.classManagement;
  final SubmissionsController _controller = Get.find<SubmissionsController>();

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    await _controller.loadTreePlantingSubmissions(sectionId: widget.sectionId);
  }

  void _handleNavigationSelect(InstructorNavigationItem item) {
    setState(() {
      _selectedItem = item;
    });
    String route = InstructorNavigationHelper.getRoute(item);
    Navigator.of(context).pushReplacementNamed(route);
  }

  Future<void> _approveSubmission(Map<String, dynamic> submission) async {
    final feedback = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF34A853)),
                SizedBox(width: 8),
                Text('Approve Tree Planting'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Approve ${submission['quantity']} tree(s) planted by ${submission['studentName']}?',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: feedback,
                  decoration: const InputDecoration(
                    labelText: 'Feedback (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF34A853),
                ),
                child: const Text('Approve'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _controller.updateSubmissionStatus(
        submission['id'],
        'approved',
        feedback: feedback.text.trim().isEmpty ? null : feedback.text.trim(),
      );
      _loadSubmissions();
      Get.snackbar(
        'Success',
        'Tree planting approved',
        backgroundColor: const Color(0xFF34A853),
        colorText: Colors.white,
      );
    }
  }

  Future<void> _rejectSubmission(Map<String, dynamic> submission) async {
    final feedback = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.cancel, color: Colors.red),
                SizedBox(width: 8),
                Text('Reject Tree Planting'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Reject tree planting submission from ${submission['studentName']}?',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: feedback,
                  decoration: const InputDecoration(
                    labelText: 'Reason (required)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (feedback.text.trim().isEmpty) {
                    Get.snackbar(
                      'Error',
                      'Please provide a reason for rejection',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                    return;
                  }
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Reject'),
              ),
            ],
          ),
    );

    if (confirmed == true && feedback.text.trim().isNotEmpty) {
      await _controller.updateSubmissionStatus(
        submission['id'],
        'rejected',
        feedback: feedback.text.trim(),
      );
      _loadSubmissions();
      Get.snackbar(
        'Success',
        'Tree planting rejected',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          InstructorSidebar(
            selectedItem: _selectedItem,
            onItemSelected: _handleNavigationSelect,
          ),
          Expanded(
            child: Column(
              children: [
                Obx(
                  () => InstructorAppBar(
                    instructorName: _controller.instructorName.value,
                    instructorRole: 'Instructor',
                    profileImageUrl: _controller.profileImageUrl.value,
                  ),
                ),
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
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.eco,
                              color: Color(0xFF34A853),
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Tree Planting Submissions',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: _loadSubmissions,
                              tooltip: 'Refresh',
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Stats
                        Obx(() {
                          final total = _controller.submissions.length;
                          final pending =
                              _controller.submissions
                                  .where((s) => s['status'] == 'submitted')
                                  .length;
                          final approved =
                              _controller.submissions
                                  .where((s) => s['status'] == 'approved')
                                  .length;

                          return Row(
                            children: [
                              _buildStatCard(
                                'Total',
                                total.toString(),
                                Colors.blue,
                              ),
                              const SizedBox(width: 16),
                              _buildStatCard(
                                'Pending',
                                pending.toString(),
                                Colors.orange,
                              ),
                              const SizedBox(width: 16),
                              _buildStatCard(
                                'Approved',
                                approved.toString(),
                                const Color(0xFF34A853),
                              ),
                            ],
                          );
                        }),
                        const SizedBox(height: 24),

                        // Submissions List
                        Expanded(
                          child: Obx(() {
                            if (_controller.isLoading.value) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF34A853),
                                ),
                              );
                            }

                            if (_controller.submissions.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.eco_outlined,
                                      size: 64,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No tree planting submissions yet',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ListView.builder(
                              itemCount: _controller.submissions.length,
                              itemBuilder: (context, index) {
                                final submission =
                                    _controller.submissions[index];
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

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionCard(Map<String, dynamic> submission) {
    final status = submission['status'] ?? 'submitted';
    final studentName = submission['studentName'] ?? 'Unknown';
    final quantity = submission['quantity'] ?? 0;
    final location = submission['location'] ?? 'Unknown';
    final plantDate = submission['plantDate'] ?? 'Unknown';
    final files = submission['files'] as List<dynamic>? ?? [];

    Color statusColor;
    switch (status) {
      case 'approved':
        statusColor = const Color(0xFF34A853);
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF34A853).withOpacity(0.1),
                child: const Icon(Icons.eco, color: Color(0xFF34A853)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      submission['studentIdNumber'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
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
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Details
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  Icons.format_list_numbered,
                  '$quantity tree${quantity > 1 ? 's' : ''}',
                ),
              ),
              Expanded(
                child: _buildDetailItem(Icons.calendar_today, plantDate),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDetailItem(Icons.location_on, location),

          // Photos
          if (files.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Evidence Photos:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  files.map((file) {
                    final fileUrl = file['url'] ?? '';
                    return GestureDetector(
                      onTap: () async {
                        if (fileUrl.isNotEmpty) {
                          final uri = Uri.parse(fileUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        }
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            fileUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.image, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ],

          // Feedback
          if (submission['feedback'] != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.feedback, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      submission['feedback'],
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action Buttons
          if (status == 'submitted') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectSubmission(submission),
                    icon: const Icon(Icons.cancel, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveSubmission(submission),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF34A853),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }
}
