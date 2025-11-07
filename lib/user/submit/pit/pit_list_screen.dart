import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:greenquest/user/submit/pit/pit_detail_screen.dart';
import 'pit_controller.dart';
import 'package:greenquest/shared/widgets/skeleton_loading.dart';

class PitListScreen extends StatefulWidget {
  const PitListScreen({super.key});

  @override
  State<PitListScreen> createState() => _PitListScreenState();
}

class _PitListScreenState extends State<PitListScreen> {
  PitController? controller;

  @override
  void initState() {
    super.initState();
    try {
      // Try to find existing controller first, if not found create new one
      try {
        controller = Get.find<PitController>();
      } catch (e) {
        // Controller not found, create new one
        controller = Get.put(PitController(), permanent: true);
      }
    } catch (e) {
      print('Error initializing PitController: $e');
    }
  }

  @override
  void dispose() {
    // Don't delete the controller as it's permanent
    super.dispose();
  }

  /// Build real-time stream for PITs
  Stream<QuerySnapshot>? _buildPitsStream(String instructorId) {
    if (controller == null || instructorId.isEmpty) return null;

    final firestore = FirebaseFirestore.instance;

    // Use asyncExpand to first get section code, then build the stream
    return Stream.fromFuture(_getUserSectionCode()).asyncExpand((sectionCode) {
      Query query = firestore
          .collection('instructors')
          .doc(instructorId)
          .collection('pits')
          .orderBy('createdAt', descending: true);

      if (sectionCode != null && sectionCode.isNotEmpty) {
        query = query.where('selectedClasses', arrayContains: sectionCode);
      }

      return query.snapshots();
    });
  }

  /// Get user's section code
  Future<String?> _getUserSectionCode() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['selectedSectionCode']?.toString();
      }
      return null;
    } catch (e) {
      print('❌ Error getting user section code: $e');
      return null;
    }
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (status.toLowerCase()) {
      case 'submitted':
        badgeColor = const Color(0xFF2196F3); // Blue
        badgeText = 'Submitted';
        badgeIcon = Icons.check_circle;
        break;
      case 'draft':
        badgeColor = const Color(0xFFFF9800); // Orange
        badgeText = 'Draft';
        badgeIcon = Icons.edit;
        break;
      case 'graded':
        badgeColor = const Color(0xFF34A853); // Green
        badgeText = 'Graded';
        badgeIcon = Icons.star;
        break;
      case 'needs_revision':
        badgeColor = const Color(0xFFF44336); // Red
        badgeText = 'Revise';
        badgeIcon = Icons.refresh;
        break;
      default: // 'not_submitted'
        badgeColor = const Color(0xFF9E9E9E); // Gray
        badgeText = 'Not Started';
        badgeIcon = Icons.radio_button_unchecked;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDisplayDate(dynamic dateData) {
    if (dateData == null) return 'Unknown Date';

    if (dateData is String) {
      if (dateData.contains(' ') &&
          !dateData.contains('T') &&
          !dateData.contains('-')) {
        return dateData;
      }
    }

    try {
      DateTime date;
      if (dateData is DateTime) {
        date = dateData;
      } else if (dateData is String) {
        if (dateData.contains('T')) {
          date = DateTime.parse(dateData);
        } else if (dateData.contains('-')) {
          date = DateTime.parse(dateData);
        } else {
          date = DateTime.parse(dateData);
        }
      } else if (dateData is Timestamp) {
        date = dateData.toDate();
      } else {
        return 'Unknown Date';
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

      final month = months[date.month - 1];
      final day = date.day.toString().padLeft(2, '0');
      final year = date.year;

      int hour = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';

      if (hour == 0) {
        hour = 12;
      } else if (hour > 12) {
        hour -= 12;
      }

      return '$month $day, $year ${hour.toString().padLeft(2, '0')}:$minute $period';
    } catch (e) {
      print('Error formatting date: $e');
      return 'Unknown Date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title:
            controller == null
                ? const Text(
                  'Choose PIT',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                )
                : Obx(
                  () => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        controller!.currentInstructorUid.value.isNotEmpty
                            ? 'PITs'
                            : 'All PITs',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (controller!.currentInstructorUid.value.isNotEmpty &&
                          controller!.currentInstructorName.value.isNotEmpty)
                        Text(
                          'by ${controller!.currentInstructorName.value}',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              if (controller != null) {
                controller!.refreshPits();
              }
            },
            tooltip: 'Refresh PITs',
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body:
          controller == null
              ? ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                itemCount: 5,
                itemBuilder: (context, i) => const SkeletonListItem(),
              )
              : Obx(() {
                final instructorId = controller!.currentInstructorUid.value;

                if (instructorId.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.engineering_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Please select an instructor first',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Go to Course Selection to choose your instructor',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: _buildPitsStream(instructorId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        itemCount: 5,
                        itemBuilder: (context, i) => const SkeletonListItem(),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error: ${snapshot.error}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.engineering_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No PITs available',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'This instructor has not posted any PITs yet',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final pits =
                        snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final instructorName =
                              controller!.currentInstructorName.value.isNotEmpty
                                  ? controller!.currentInstructorName.value
                                  : data['instructorName']?.toString() ??
                                      'Unknown Instructor';
                          return {
                            'id': doc.id,
                            ...data,
                            'instructorName': instructorName,
                          };
                        }).toList();

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      itemCount: pits.length,
                      itemBuilder: (context, i) {
                        final pit = pits[i];

                        // Validate pit data before navigation
                        if (pit.isEmpty) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'Invalid PIT',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          );
                        }

                        return GestureDetector(
                          onTap: () {
                            if (pit.isNotEmpty && controller != null) {
                              controller!.setSelectedPit(pit);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PitDetailScreen(pit: pit),
                                ),
                              );
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE0E0E0),
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
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF34A853),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.engineering,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${pit['instructorName']} posted new PIT: ${pit['title']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 15,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatDisplayDate(pit['createdAt']),
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Status Badge
                                Obx(() {
                                  final pitId = pit['id']?.toString();
                                  final status =
                                      controller?.submissionStatus[pitId] ??
                                      'not_submitted';
                                  return _buildStatusBadge(status);
                                }),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              }),
    );
  }
}
