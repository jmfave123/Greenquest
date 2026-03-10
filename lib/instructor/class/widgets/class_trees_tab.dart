import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/app_logger.dart';
import '../../../shared/widgets/custom_dialogs.dart';
import '../../../shared/services/notify_service.dart';
import '../../../shared/services/in_app_notification_service.dart';
import '../../instructor_dashboard_controller.dart';
import '../../planted_trees/nstp_form_widget.dart';
import '../../services/nstp_pdf_export_service.dart';
import '../class_detail_constants.dart';

/// Trees Tab Widget - Shows planted trees for the class
/// Extracted from ClassDetailScreen per agent.md Section 4.1 (Separation of Concerns)
class ClassTreesTab extends StatefulWidget {
  final Map<String, dynamic> classData;
  final InstructorController instructorController;

  const ClassTreesTab({
    super.key,
    required this.classData,
    required this.instructorController,
  });

  @override
  State<ClassTreesTab> createState() => _ClassTreesTabState();
}

class _ClassTreesTabState extends State<ClassTreesTab> {
  final _logger = AppLogger('ClassTreesTab');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ClassDetailConstants.horizontalPagePadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trees Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Planted Trees',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              IconButton(
                onPressed: () {
                  // Refresh trees data
                  setState(() {});
                },
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh trees',
              ),
            ],
          ),
          const SizedBox(height: ClassDetailConstants.defaultPadding),

          // Trees List
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadTreesForClass(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                final trees = snapshot.data ?? [];

                if (trees.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  itemCount: trees.length,
                  itemBuilder: (context, index) {
                    final tree = trees[index];
                    return _buildTreeCard(tree);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Load trees for this specific class
  Future<List<Map<String, dynamic>>> _loadTreesForClass() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _logger.warning('No user logged in');
        return [];
      }

      final sectionName = widget.classData['section'] ?? '';

      _logger.info(
        'Loading tree submissions',
        context: {'section': sectionName, 'userId': user.uid},
      );

      // Load from submissions collection with tree_planting type
      final snapshot =
          await FirebaseFirestore.instance
              .collection(ClassDetailConstants.submissionsCollection)
              .where(
                'activityType',
                isEqualTo: ClassDetailConstants.activityTypeTreePlanting,
              )
              .where('instructorId', isEqualTo: user.uid)
              .where('sectionName', isEqualTo: sectionName)
              .get();

      final trees =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'studentName':
                  data['studentName'] ??
                  ClassDetailConstants.defaultStudentName,
              'studentIdNumber': data['studentIdNumber'] ?? '',
              'studentId': data['studentId'] ?? '',
              'plantDate': data['plantDate'] ?? '',
              'quantity': data['quantity'] ?? 1,
              'location': data['location'] ?? '',
              'sectionName': data['sectionName'] ?? '',
              'nstpComponent': data['nstpComponent'] ?? '',
              'treeNames': data['treeNames'] ?? <String>[],
              'status': data['status'] ?? ClassDetailConstants.statusSubmitted,
              'feedback': data['feedback'],
              'files': data['files'] ?? [],
              'submittedAt': data['submittedAt'],
              'isStudentSubmission': true, // Mark as student submission
            };
          }).toList();

      // Sort by submittedAt descending (most recent first)
      trees.sort((a, b) {
        final aTime = a['submittedAt'] as Timestamp?;
        final bTime = b['submittedAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      return trees;
    } catch (e, stackTrace) {
      _logger.error(
        'Error loading tree submissions',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Build tree card widget
  Widget _buildTreeCard(Map<String, dynamic> tree) {
    final isStudentSubmission = tree['isStudentSubmission'] == true;
    final status = tree['status'] ?? ClassDetailConstants.statusSubmitted;
    final files = tree['files'] as List<dynamic>? ?? [];

    // Format the plant date
    String formattedDate = 'Unknown';
    final plantDate = tree['plant Date'];
    if (plantDate != null) {
      if (plantDate is Timestamp) {
        final dateTime = plantDate.toDate();
        formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime);
      } else if (plantDate is String) {
        // Handle old string format
        formattedDate = plantDate;
      }
    }

    Color statusColor;
    String statusText;
    switch (status) {
      case ClassDetailConstants.statusApproved:
        statusColor = ClassDetailConstants.approvedColor;
        statusText = 'APPROVED';
        break;
      case ClassDetailConstants.statusRejected:
        statusColor = ClassDetailConstants.rejectedColor;
        statusText = 'REJECTED';
        break;
      default:
        statusColor = ClassDetailConstants.pendingColor;
        statusText = 'PENDING';
    }

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
          color:
              isStudentSubmission
                  ? statusColor.withOpacity(0.3)
                  : ClassDetailConstants.primaryGreen.withOpacity(0.3),
        ),
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
          Row(
            children: [
              // User avatar or tree icon
              if (isStudentSubmission)
                _buildStudentAvatar(tree)
              else
                _buildTreeIcon(),
              const SizedBox(width: ClassDetailConstants.defaultPadding),
              // Tree details
              Expanded(
                child: _buildTreeDetails(
                  tree,
                  isStudentSubmission,
                  formattedDate,
                ),
              ),
              // Status badge and quantity
              if (isStudentSubmission)
                _buildStatusBadges(tree, statusColor, statusText)
              else
                _buildQuantityBadge(tree['quantity']),
            ],
          ),

          // Evidence photos for student submissions
          if (isStudentSubmission && files.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Evidence:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            _buildEvidencePhotos(files),
          ],

          // Feedback section
          if (isStudentSubmission && tree['feedback'] != null) ...[
            const SizedBox(height: 12),
            _buildFeedbackSection(tree['feedback']),
          ],

          // Action buttons for pending submissions
          if (isStudentSubmission &&
              status == ClassDetailConstants.statusSubmitted) ...[
            const SizedBox(height: 12),
            _buildActionButtons(tree),
          ],

          // NSTP Form button — always visible on student submissions
          if (isStudentSubmission) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () async => _showNstpFormDialog(tree),
                icon: const Icon(
                  Icons.description_outlined,
                  size: 16,
                  color: Color(0xFF1A237E),
                ),
                label: const Text(
                  'NSTP Form',
                  style: TextStyle(
                    color: Color(0xFF1A237E),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF1A237E)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStudentAvatar(Map<String, dynamic> tree) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance
              .collection(ClassDetailConstants.usersCollection)
              .doc(tree['studentId'])
              .get(),
      builder: (context, snapshot) {
        String? photoUrl;
        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          photoUrl = userData?['photoUrl'];
        }

        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color:
                photoUrl == null
                    ? ClassDetailConstants.primaryGreen.withOpacity(0.1)
                    : null,
            borderRadius: BorderRadius.circular(25),
          ),
          child:
              photoUrl != null
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            _getInitials(
                              tree['studentName'] ??
                                  ClassDetailConstants.defaultStudentName,
                            ),
                            style: TextStyle(
                              color: ClassDetailConstants.primaryGreen,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                  : Center(
                    child: Text(
                      _getInitials(
                        tree['studentName'] ??
                            ClassDetailConstants.defaultStudentName,
                      ),
                      style: TextStyle(
                        color: ClassDetailConstants.primaryGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
        );
      },
    );
  }

  Widget _buildTreeIcon() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: ClassDetailConstants.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Icon(
        Icons.eco,
        color: ClassDetailConstants.primaryGreen,
        size: 24,
      ),
    );
  }

  Widget _buildTreeDetails(
    Map<String, dynamic> tree,
    bool isStudentSubmission,
    String formattedDate,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${tree['quantity']} tree${tree['quantity'] > 1 ? 's' : ''} planted',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        if (isStudentSubmission) ...[
          Text(
            'By: ${tree['studentName']} (${tree['studentIdNumber']})',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          if (tree['location']?.isNotEmpty == true) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    tree['location'],
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          // Tree species names
          Builder(
            builder: (_) {
              final treeNames = tree['treeNames'];
              final names =
                  treeNames is List
                      ? treeNames
                          .map((e) => e.toString())
                          .where((s) => s.isNotEmpty)
                          .toList()
                      : <String>[];
              if (names.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Icon(Icons.park, size: 13, color: Color(0xFF388E3C)),
                    ...names.asMap().entries.map(
                      (e) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF388E3C).withOpacity(0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF388E3C).withOpacity(0.35),
                          ),
                        ),
                        child: Text(
                          '${e.key + 1}. ${e.value}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ] else
          Text(
            'Planted by: ${tree['plantedBy']}',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        const SizedBox(height: 2),
        Text(
          'Date: $formattedDate',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildStatusBadges(
    Map<String, dynamic> tree,
    Color statusColor,
    String statusText,
  ) {
    return Row(
      children: [
        // Quantity badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: ClassDetailConstants.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.eco,
                size: 14,
                color: ClassDetailConstants.primaryGreen,
              ),
              const SizedBox(width: 4),
              Text(
                '${tree['quantity']}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ClassDetailConstants.primaryGreen,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityBadge(int quantity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ClassDetailConstants.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$quantity',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: ClassDetailConstants.primaryGreen,
        ),
      ),
    );
  }

  Widget _buildEvidencePhotos(List<dynamic> files) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: files.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final file = files[index];
          final fileUrl = file['url'] ?? '';
          return GestureDetector(
            onTap: () async {
              if (fileUrl.isNotEmpty) {
                final uri = Uri.parse(fileUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            },
            child: Container(
              width: 80,
              height: 80,
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
        },
      ),
    );
  }

  Widget _buildFeedbackSection(String feedback) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.feedback, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(feedback, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  /// Opens the NSTP monitoring form dialog.
  /// If [tree] is missing nstpComponent or treeNames (old submissions),
  /// falls back to fetching them live from the users collection.
  Future<void> _showNstpFormDialog(Map<String, dynamic> tree) async {
    final studentId = tree['studentId'] as String? ?? '';

    // Show a brief loading indicator while resolving missing fields.
    String nstpComponent = (tree['nstpComponent'] as String? ?? '').trim();
    List<String> treeNames =
        (tree['treeNames'] is List)
            ? List<String>.from(tree['treeNames'] as List)
            : <String>[];

    // Fallback: fetch from users collection if fields are missing.
    if ((nstpComponent.isEmpty || treeNames.isEmpty) && studentId.isNotEmpty) {
      try {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(studentId)
                .get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          if (nstpComponent.isEmpty) {
            nstpComponent = (userData['nstpComponent'] as String? ?? '').trim();
          }
          if (treeNames.isEmpty && userData['treeNames'] is List) {
            treeNames = List<String>.from(userData['treeNames'] as List);
          }
        }
      } catch (e) {
        _logger.warning('Could not fetch user fallback data: $e');
      }
    }

    final formData = <String, dynamic>{
      'studentName': tree['studentName'] ?? '',
      'sectionName': tree['sectionName'] ?? '',
      'nstpComponent': nstpComponent,
      'quantity': tree['quantity'] ?? 0,
      'treeNames': treeNames,
      'location': tree['location'] ?? '',
      'submittedAt': tree['submittedAt'],
      'files': tree['files'] ?? <dynamic>[],
    };

    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (dialogContext) => Dialog(
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title bar
                  Container(
                    color: const Color(0xFF1A237E),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'NSTP Monitoring Form',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        // Export PDF button
                        TextButton.icon(
                          onPressed: () async {
                            try {
                              await NstpPdfExportService.exportToPdf(formData);
                            } catch (e) {
                              if (dialogContext.mounted) {
                                ScaffoldMessenger.of(
                                  dialogContext,
                                ).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to export PDF.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: const Text(
                            'Export PDF',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.15),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                        ),
                      ],
                    ),
                  ),
                  // Scrollable form
                  Flexible(
                    child: SingleChildScrollView(
                      child: NstpFormWidget(data: formData),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> tree) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _rejectTreeSubmission(tree),
            icon: const Icon(Icons.cancel, size: 16),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ClassDetailConstants.rejectedColor,
              side: BorderSide(color: ClassDetailConstants.rejectedColor),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _approveTreeSubmission(tree),
            icon: const Icon(Icons.check_circle, size: 16),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ClassDetailConstants.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      itemCount: 4,
      itemBuilder: (context, i) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
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
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading trees: $error',
            style: const TextStyle(fontSize: 16, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.eco_outlined,
                size: 64,
                color: Colors.grey.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'No trees planted yet',
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
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Click the "Plant Tree" button to add trees for this class.',
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

  /// Approve tree submission
  Future<void> _approveTreeSubmission(Map<String, dynamic> submission) async {
    final result = await CustomDialogs.showApprovalDialog(
      context: context,
      title: 'Approve Tree Planting',
      message:
          'Are you sure you want to approve ${submission['quantity']} tree(s) planted by ${submission['studentName']}?',
      feedbackLabel: 'Feedback (optional)',
      feedbackHint: 'Add your feedback here...',
      confirmText: 'Approve',
      iconColor: ClassDetailConstants.primaryGreen,
      confirmButtonColor: ClassDetailConstants.primaryGreen,
      icon: Icons.check_circle,
    );

    if (result['confirmed'] == true) {
      try {
        await FirebaseFirestore.instance
            .collection(ClassDetailConstants.submissionsCollection)
            .doc(submission['id'])
            .update({
              'status': ClassDetailConstants.statusApproved,
              'feedback':
                  result['feedback'].isEmpty ? null : result['feedback'],
              'gradedAt': FieldValue.serverTimestamp(),
              'gradedBy': FirebaseAuth.instance.currentUser?.uid,
            });

        // Send push notification to student
        final studentId = submission['studentId'];
        if (studentId != null) {
          try {
            final playerId = await OneSignalHelper.getPlayerIdForUser(
              studentId,
            );
            if (playerId != null) {
              await NotifServices.sendIndividualNotification(
                playerId: playerId,
                heading: '🌳 Tree Planting Approved!',
                content:
                    result['feedback'].isEmpty
                        ? 'Your tree planting submission has been approved. Great work!'
                        : 'Your tree planting has been approved! Feedback: ${result['feedback']}',
              );
            }

            // Create in-app notification
            final instructorName =
                widget.instructorController.instructorName.value;
            await InAppNotificationService.createIndividualNotification(
              type: ClassDetailConstants.notificationTypeTreeApproved,
              instructorId: FirebaseAuth.instance.currentUser?.uid ?? '',
              instructorName: instructorName,
              itemId: submission['id'],
              title: ClassDetailConstants.successTreeApproved,
              targetUserIds: [studentId],
              description:
                  result['feedback'].isEmpty
                      ? 'Your tree planting submission (${submission['quantity']} trees) has been approved. Great work!'
                      : 'Your tree planting (${submission['quantity']} trees) has been approved! Feedback: ${result['feedback']}',
              metadata: {
                'quantity': submission['quantity'],
                'location': submission['location'],
                'plantDate': submission['plantDate'],
                'status': ClassDetailConstants.statusApproved,
              },
            );
          } catch (e) {
            _logger.error('Error sending tree approval notification', error: e);
          }
        }

        Get.snackbar(
          'Success',
          ClassDetailConstants.successTreeApproved,
          backgroundColor: ClassDetailConstants.primaryGreen,
          colorText: Colors.white,
        );

        setState(() {}); // Refresh the list
      } catch (e) {
        _logger.error('Error approving tree submission', error: e);
        Get.snackbar(
          'Error',
          '${ClassDetailConstants.errorGradingSubmission}: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  /// Reject tree submission
  Future<void> _rejectTreeSubmission(Map<String, dynamic> submission) async {
    final result = await CustomDialogs.showRejectionDialog(
      context: context,
      title: 'Reject Tree Planting',
      message:
          'Are you sure you want to reject the tree planting submission from ${submission['studentName']}?',
      reasonLabel: 'Reason for rejection (required)',
      reasonHint: 'Explain why this submission is being rejected...',
      confirmText: 'Reject',
      iconColor: ClassDetailConstants.rejectedColor,
      confirmButtonColor: ClassDetailConstants.rejectedColor,
      icon: Icons.cancel,
      errorMessage: 'Please provide a reason for rejection',
    );

    if (result['confirmed'] == true && result['feedback'].isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection(ClassDetailConstants.submissionsCollection)
            .doc(submission['id'])
            .update({
              'status': ClassDetailConstants.statusRejected,
              'feedback': result['feedback'],
              'gradedAt': FieldValue.serverTimestamp(),
              'gradedBy': FirebaseAuth.instance.currentUser?.uid,
            });

        // Send push notification to student
        final studentId = submission['studentId'];
        if (studentId != null) {
          try {
            final playerId = await OneSignalHelper.getPlayerIdForUser(
              studentId,
            );
            if (playerId != null) {
              await NotifServices.sendIndividualNotification(
                playerId: playerId,
                heading: '🌳 Tree Planting Needs Revision',
                content:
                    'Your tree planting submission was not accepted. Reason: ${result['feedback']}',
              );
            }

            // Create in-app notification
            final instructorName =
                widget.instructorController.instructorName.value;
            await InAppNotificationService.createIndividualNotification(
              type: ClassDetailConstants.notificationTypeTreeRejected,
              instructorId: FirebaseAuth.instance.currentUser?.uid ?? '',
              instructorName: instructorName,
              itemId: submission['id'],
              title: 'Tree Planting Needs Revision',
              targetUserIds: [studentId],
              description:
                  'Your tree planting submission (${submission['quantity']} trees) needs revision. Reason: ${result['feedback']}',
              metadata: {
                'quantity': submission['quantity'],
                'location': submission['location'],
                'plantDate': submission['plantDate'],
                'status': ClassDetailConstants.statusRejected,
                'feedback': result['feedback'],
              },
            );
          } catch (e) {
            _logger.error(
              'Error sending tree rejection notification',
              error: e,
            );
          }
        }

        Get.snackbar(
          'Success',
          ClassDetailConstants.successTreeRejected,
          backgroundColor: ClassDetailConstants.rejectedColor,
          colorText: Colors.white,
        );

        setState(() {}); // Refresh the list
      } catch (e) {
        _logger.error('Error rejecting tree submission', error: e);
        Get.snackbar(
          'Error',
          '${ClassDetailConstants.errorGradingSubmission}: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  /// Get initials from name
  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
