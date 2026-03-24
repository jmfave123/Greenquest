import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:greenquest/instructor/instructor_dashboard_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/widgets/skeleton_loading.dart';
import '../../../shared/utils/presence_utils.dart';
import '../class_screen_controller.dart';
import '../class_detail_constants.dart';

/// People (Students) Tab Widget - Shows student enrollment with approval/rejection
/// Extracted from ClassDetailScreen per agent.md Section 4.1 (Separation of Concerns)
class ClassPeopleTab extends StatefulWidget {
  final Map<String, dynamic> classData;
  final ClassController classController;
  final InstructorController instructorController;
  final VoidCallback onRefresh;

  const ClassPeopleTab({
    super.key,
    required this.classData,
    required this.classController,
    required this.instructorController,
    required this.onRefresh,
  });

  @override
  State<ClassPeopleTab> createState() => _ClassPeopleTabState();
}

class _ClassPeopleTabState extends State<ClassPeopleTab> {
  String _selectedStudentFilter = 'All';
  final List<String> _studentFilterOptions =
      ClassDetailConstants.studentFilterOptions;

  @override
  Widget build(BuildContext context) {
    String currentSectionCode = widget.classData['section'] ?? '';
    String currentCourseCode = widget.classData['course'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ClassDetailConstants.horizontalPagePadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Class Info Banner
          Container(
            padding: const EdgeInsets.all(ClassDetailConstants.defaultPadding),
            margin: const EdgeInsets.only(
              bottom: ClassDetailConstants.largePadding,
            ),
            decoration: BoxDecoration(
              color: ClassDetailConstants.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                ClassDetailConstants.cardBorderRadius,
              ),
              border: Border.all(
                color: ClassDetailConstants.primaryGreen.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ClassDetailConstants.primaryGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.class_,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: ClassDetailConstants.defaultPadding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Viewing students for:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$currentCourseCode $currentSectionCode',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ClassDetailConstants.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                // Enrollment Statistics
                Obx(() {
                  final stats = widget.classController.getEnrollmentStats(
                    currentSectionCode,
                  );
                  return Row(
                    children: [
                      _buildStatChip('Total', stats['total'] ?? 0, Colors.blue),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        'Pending',
                        stats['pending'] ?? 0,
                        Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        'Approved',
                        stats['approved'] ?? 0,
                        Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        'Rejected',
                        stats['rejected'] ?? 0,
                        Colors.red,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),

          // Teacher Section
          const Text(
            'Teacher',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 10),
          Divider(color: Colors.grey.withOpacity(0.4)),
          const SizedBox(height: 10),
          Row(
            children: [
              Obx(() => _buildInstructorProfileAvatar()),
              const SizedBox(width: ClassDetailConstants.defaultPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(
                      () => Text(
                        widget.instructorController.instructorName.value,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Instructor',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Students',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Row(
                children: [
                  // Enrollment Status Filter
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedStudentFilter,
                      underline: const SizedBox(),
                      isDense: true,
                      hint: const Text('Status'),
                      items:
                          _studentFilterOptions.map((String value) {
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
                          _selectedStudentFilter = newValue!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: widget.onRefresh,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh students and status',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.grey.withOpacity(0.4)),
          const SizedBox(height: 10),
          Expanded(
            child: Obx(() {
              // Get students only for the current section
              String currentSection = widget.classData['section'] ?? '';
              List<Map<String, dynamic>> sectionStudents = widget
                  .classController
                  .getStudentsForSection(currentSection);

              // Show skeleton loading if students are being loaded and list is empty
              if (widget.classController.isLoading.value &&
                  sectionStudents.isEmpty) {
                return _buildSkeletonLoading();
              }

              // Apply enrollment status filter
              List<Map<String, dynamic>> filteredStudents = sectionStudents;
              if (_selectedStudentFilter != 'All') {
                filteredStudents =
                    sectionStudents.where((student) {
                      final status = student['enrollmentStatus'] ?? 'pending';
                      switch (_selectedStudentFilter) {
                        case 'Pending':
                          return status == 'pending';
                        case 'Approved':
                          return status == 'approved';
                        case 'Rejected':
                          return status == 'rejected';
                        default:
                          return true;
                      }
                    }).toList();
              }

              if (filteredStudents.isEmpty) {
                return _buildEmptyState(currentSection);
              }

              return ListView.builder(
                itemCount: filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = filteredStudents[index];
                  return _buildStudentCard(student);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, i) {
        return Container(
          margin: const EdgeInsets.only(
            bottom: ClassDetailConstants.cardVerticalSpacing,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: ClassDetailConstants.defaultPadding,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              ClassDetailConstants.cardBorderRadius,
            ),
            border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              SkeletonAvatar(radius: 24),
              const SizedBox(width: ClassDetailConstants.defaultPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonText(width: 200, height: 16),
                    const SizedBox(height: 4),
                    SkeletonText(width: 150, height: 13),
                  ],
                ),
              ),
              SkeletonBox(
                width: 60,
                height: 24,
                borderRadius: ClassDetailConstants.cardBorderRadius,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String currentSection) {
    String message = 'No students found';
    String subtitle =
        'Students from section $currentSection will appear here when they complete their registration';

    if (_selectedStudentFilter != 'All') {
      message = 'No ${_selectedStudentFilter.toLowerCase()} students found';
      subtitle = 'Try changing the filter or refresh the list';
    }

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
              Icon(
                Icons.people_outline,
                size: 64,
                color: Colors.grey.withOpacity(0.5),
              ),
              const SizedBox(height: ClassDetailConstants.defaultPadding),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ClassDetailConstants.defaultPadding,
                ),
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ClassDetailConstants.defaultPadding,
                ),
                child: Text(
                  subtitle,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final enrollmentStatus = student['enrollmentStatus'] ?? 'pending';

    return Container(
      margin: const EdgeInsets.only(
        bottom: ClassDetailConstants.cardVerticalSpacing,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: ClassDetailConstants.defaultPadding,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          ClassDetailConstants.cardBorderRadius,
        ),
        border: Border.all(
          color: _getEnrollmentStatusColor(enrollmentStatus).withOpacity(0.3),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _getEnrollmentStatusColor(
              enrollmentStatus,
            ).withOpacity(0.1),
            child: Text(
              (student['studentName'] ?? 'U').isNotEmpty
                  ? (student['studentName'] ?? 'U')
                      .substring(0, 1)
                      .toUpperCase()
                  : 'U',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getEnrollmentStatusColor(enrollmentStatus),
              ),
            ),
          ),
          const SizedBox(width: ClassDetailConstants.defaultPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['studentName'] ??
                      ClassDetailConstants.defaultStudentName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enrolled: ${_formatEnrollmentDate(student['enrolledAt'])}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                if (enrollmentStatus == 'rejected' &&
                    student['rejectionReason'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Reason: ${student['rejectionReason']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Status and Action Buttons
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // First row: Status badges
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Enrollment Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getEnrollmentStatusColor(
                        enrollmentStatus,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getEnrollmentStatusLabel(enrollmentStatus),
                      style: TextStyle(
                        fontSize: 10,
                        color: _getEnrollmentStatusColor(enrollmentStatus),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Active Status for approved students (real-time updates)
                  if (enrollmentStatus == 'approved')
                    _buildOnlineStatusWidget(student),
                ],
              ),
              const SizedBox(height: 4),
              // Second row: Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // View COR button (always visible for all students)
                  IconButton(
                    onPressed: () => _viewStudentCOR(student),
                    icon: Icon(
                      Icons.description,
                      color:
                          (student['corUrl'] != null &&
                                  student['corUrl'].toString().isNotEmpty)
                              ? ClassDetailConstants.primaryGreen
                              : Colors.grey,
                      size: 18,
                    ),
                    tooltip:
                        (student['corUrl'] != null &&
                                student['corUrl'].toString().isNotEmpty)
                            ? 'View COR'
                            : 'COR not uploaded',
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: const EdgeInsets.all(4),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          (student['corUrl'] != null &&
                                  student['corUrl'].toString().isNotEmpty)
                              ? ClassDetailConstants.primaryGreen.withOpacity(
                                0.1,
                              )
                              : Colors.grey.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  if (enrollmentStatus == 'pending') const SizedBox(width: 4),
                  // Approval buttons for pending students
                  if (enrollmentStatus == 'pending') ...[
                    IconButton(
                      onPressed: () => _approveStudent(student),
                      icon: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 18,
                      ),
                      tooltip: 'Approve enrollment',
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: const EdgeInsets.all(4),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.green.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () => _rejectStudent(student),
                      icon: const Icon(
                        Icons.cancel,
                        color: Colors.red,
                        size: 18,
                      ),
                      tooltip: 'Reject enrollment',
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: const EdgeInsets.all(4),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build instructor profile avatar with image or initials
  Widget _buildInstructorProfileAvatar() {
    // Get initials from name
    String getInitials(String name) {
      if (name.isEmpty) return '';
      final parts = name.trim().split(' ');
      if (parts.length == 1) {
        return parts[0].substring(0, 1).toUpperCase();
      }
      return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
          .toUpperCase();
    }

    final instructorName = widget.instructorController.instructorName.value;
    final profileImageUrl = widget.instructorController.profileImageUrl.value;
    final initials = getInitials(instructorName);
    final hasImage = profileImageUrl.isNotEmpty;

    return CircleAvatar(
      radius: 30,
      backgroundColor:
          hasImage ? Colors.transparent : ClassDetailConstants.primaryGreen,
      backgroundImage: hasImage ? NetworkImage(profileImageUrl) : null,
      child:
          !hasImage
              ? Text(
                initials,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
              : null,
    );
  }

  /// Build online status widget with real-time updates
  Widget _buildOnlineStatusWidget(Map<String, dynamic> student) {
    final studentId = student['studentId'];

    // If no studentId, show offline
    if (studentId == null) {
      return const Text(
        'Offline',
        style: TextStyle(color: Colors.black54, fontSize: 11),
      );
    }

    // Use StreamBuilder for real-time updates
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(studentId)
              .snapshots(),
      builder: (context, snapshot) {
        final isOnline =
            snapshot.hasData &&
            snapshot.data!.exists &&
            (snapshot.data!.data() as Map<String, dynamic>?)?['isOnline'] ==
                true;

        dynamic lastSeen;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          lastSeen = data?['lastSeen'];
        } else {
          lastSeen = null;
        }

        final isActuallyOnline = PresenceUtils.isActuallyOnline(
          isOnline: isOnline,
          lastSeen: lastSeen,
        );

        // Display: "Online" with green dot or "Active X ago"
        if (isActuallyOnline) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: ClassDetailConstants.primaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Online',
                style: TextStyle(
                  color: ClassDetailConstants.primaryGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        } else if (lastSeen != null) {
          try {
            DateTime? lastSeenTime;
            if (lastSeen is Timestamp) {
              lastSeenTime = lastSeen.toDate();
            } else if (lastSeen is DateTime) {
              lastSeenTime = lastSeen;
            }

            if (lastSeenTime != null) {
              return Text(
                _formatLastSeen(lastSeenTime),
                style: const TextStyle(color: Colors.black54, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            }
          } catch (e) {
            // Fall through to offline
          }
        }

        // Default: Offline
        return const Text(
          'Offline',
          style: TextStyle(color: Colors.black54, fontSize: 11),
        );
      },
    );
  }

  /// Format last seen time
  String _formatLastSeen(DateTime lastSeenTime) {
    return PresenceUtils.formatLastSeen(lastSeenTime);
  }

  /// Format enrollment date — matches canonical format used across the instructor side
  /// Output: "Jan 15, 2024 10:30 AM"
  String _formatEnrollmentDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    try {
      DateTime? date;

      if (timestamp is DateTime) {
        date = timestamp;
      } else if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      }

      if (date == null) return 'Unknown';

      const months = [
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

      final month = months[date.month - 1];
      final day = date.day;
      final year = date.year;
      int hour = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final ampm = hour >= 12 ? 'PM' : 'AM';
      if (hour == 0) {
        hour = 12;
      } else if (hour > 12) {
        hour -= 12;
      }

      return '$month $day, $year $hour:$minute $ampm';
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Get enrollment status color
  Color _getEnrollmentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return ClassDetailConstants.approvedColor;
      case 'rejected':
        return ClassDetailConstants.rejectedColor;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Get enrollment status label
  String _getEnrollmentStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'pending':
        return 'Pending';
      default:
        return 'Unknown';
    }
  }

  /// Build stat chip for enrollment statistics
  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }

  /// Approve student enrollment
  void _approveStudent(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Approve Student Enrollment'),
            content: Text(
              'Are you sure you want to approve ${student['studentName']}\'s enrollment?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await widget.classController.approveStudentEnrollment(
                    studentId: student['studentId'],
                    sectionCode: widget.classData['section'] ?? '',
                  );
                  // Refresh the student list
                  widget.onRefresh();
                },
                child: const Text(
                  'Approve',
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ],
          ),
    );
  }

  /// Reject student enrollment
  void _rejectStudent(Map<String, dynamic> student) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reject Student Enrollment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to reject ${student['studentName']}\'s enrollment?',
                ),
                const SizedBox(height: ClassDetailConstants.defaultPadding),
                const Text(
                  'Reason for rejection (optional):',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    hintText: 'Enter reason for rejection...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await widget.classController.rejectStudentEnrollment(
                    studentId: student['studentId'],
                    sectionCode: widget.classData['section'] ?? '',
                    reason:
                        reasonController.text.trim().isNotEmpty
                            ? reasonController.text.trim()
                            : null,
                  );
                  // Refresh the student list
                  widget.onRefresh();
                },
                child: const Text(
                  'Reject',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  /// View student Certificate of Registration (COR)
  void _viewStudentCOR(Map<String, dynamic> student) {
    final corUrl = student['corUrl']?.toString() ?? '';

    if (corUrl.isEmpty) {
      Get.snackbar(
        'COR Not Available',
        'This student has not uploaded their Certificate of Registration.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                ClassDetailConstants.cardBorderRadius,
              ),
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              padding: const EdgeInsets.all(ClassDetailConstants.largePadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Certificate of Registration',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: ClassDetailConstants.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            student['studentName'] ??
                                ClassDetailConstants.defaultStudentName,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: ClassDetailConstants.largePadding),
                  Container(
                    padding: const EdgeInsets.all(
                      ClassDetailConstants.defaultPadding,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        ClassDetailConstants.cardBorderRadius,
                      ),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: ClassDetailConstants.primaryGreen
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.picture_as_pdf,
                            size: 40,
                            color: ClassDetailConstants.primaryGreen,
                          ),
                        ),
                        const SizedBox(
                          width: ClassDetailConstants.defaultPadding,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'COR Document',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'PDF Document',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse(corUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              Get.snackbar(
                                'Error',
                                'Could not open the COR document',
                                snackPosition: SnackPosition.TOP,
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ClassDetailConstants.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: const Text('Open PDF'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: ClassDetailConstants.defaultPadding),
                  Text(
                    'This document was uploaded during registration and is stored securely in the cloud.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
