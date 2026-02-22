import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../../shared/widgets/skeleton_loading.dart';
import '../../../user/materials/materials_detail_screen.dart';
import '../../create/create_controller.dart';
import '../../topics/topic_controller.dart';
import '../../submissions/student_submissions_screen.dart';
import '../../../shared/widgets/class_banner_image_picker.dart';
import '../class_screen_controller.dart';
import '../class_detail_constants.dart';
import '../../instructor_dashboard_controller.dart';

/// Stream Tab Widget - Shows class banner and posted activities
/// Extracted from ClassDetailScreen per agent.md Section 4.1 (Separation of Concerns)
class ClassStreamTab extends StatefulWidget {
  final Map<String, dynamic> classData;
  final CreateController createController;
  final TopicController topicController;
  final InstructorController instructorController;
  final ClassController classController;
  final VoidCallback onRefresh;

  const ClassStreamTab({
    super.key,
    required this.classData,
    required this.createController,
    required this.topicController,
    required this.instructorController,
    required this.classController,
    required this.onRefresh,
  });

  @override
  State<ClassStreamTab> createState() => _ClassStreamTabState();
}

class _ClassStreamTabState extends State<ClassStreamTab> {
  // Filter for Posted Items
  String _selectedPostedItemTypeFilter = 'All Types';
  final List<String> _postedItemTypeFilterOptions =
      ClassDetailConstants.postedItemTypeFilterOptions;

  String _selectedPostedItemTopicFilter = 'All Topics';

  @override
  Widget build(BuildContext context) {
    final customImageUrl = widget.classData['classImageUrl'] as String?;
    final classId = widget.classData['id'] as String?;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ClassDetailConstants.horizontalPagePadding,
      ),
      child: Column(
        children: [
          // Class Banner with Edit Button
          _buildClassBanner(customImageUrl, classId),
          const SizedBox(height: 30),
          // Posted Assignments and Activities
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Header with Filter
                _buildSectionHeader(),
                const SizedBox(height: ClassDetailConstants.defaultPadding),

                // Posted Items List
                Expanded(child: _buildPostedItemsList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassBanner(String? customImageUrl, String? classId) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: ClassDetailConstants.primaryGreen,
              borderRadius: BorderRadius.circular(
                ClassDetailConstants.cardBorderRadius,
              ),
            ),
            child: Stack(
              children: [
                // Custom Image or Default Banner Background
                if (customImageUrl != null && customImageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      ClassDetailConstants.cardBorderRadius,
                    ),
                    child: Image.network(
                      customImageUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(
                            ClassDetailConstants.cardBorderRadius,
                          ),
                          child: Image.asset(
                            'assets/instructor/images/Group 1171274926.png',
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      ClassDetailConstants.cardBorderRadius,
                    ),
                    child: Image.asset(
                      'assets/instructor/images/Group 1171274926.png',
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                // Dark overlay for better text visibility
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      ClassDetailConstants.cardBorderRadius,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
                // Class Details Overlay
                Positioned(
                  bottom: 20,
                  left: 24,
                  right: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.classData['course']} ${widget.classData['section']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          // Display schedules - handle both single and multiple
                          Builder(
                            builder: (context) {
                              if (widget.classData.containsKey('schedules') &&
                                  widget.classData['schedules'] is List) {
                                final schedules =
                                    List<Map<String, dynamic>>.from(
                                      widget.classData['schedules'],
                                    );
                                if (schedules.isEmpty) {
                                  return const Text(
                                    'No schedule',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  );
                                }

                                // Check if all schedules have same time
                                final allSameTime = schedules.every(
                                  (s) =>
                                      s['startTime'] ==
                                          schedules[0]['startTime'] &&
                                      s['endTime'] == schedules[0]['endTime'],
                                );

                                if (allSameTime && schedules.length > 1) {
                                  // Show as "Mon/Wed 9:00 AM - 10:30 AM" with rooms
                                  final days = schedules
                                      .map((s) => _getDayAbbreviation(s['day']))
                                      .join('/');

                                  // Check if all rooms are the same
                                  final allSameRoom = schedules.every(
                                    (s) => s['room'] == schedules[0]['room'],
                                  );
                                  final roomText =
                                      allSameRoom
                                          ? ' • ${schedules[0]['room'] ?? 'No room'}'
                                          : ' • Multiple rooms';

                                  return Text(
                                    '$days ${schedules[0]['startTime']} - ${schedules[0]['endTime']}$roomText',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  );
                                } else {
                                  // Show all schedules separately with rooms
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children:
                                        schedules.map((schedule) {
                                          final dayAbbr = _getDayAbbreviation(
                                            schedule['day'],
                                          );
                                          final room =
                                              schedule['room'] ?? 'No room';
                                          return Text(
                                            '$dayAbbr ${schedule['startTime']} - ${schedule['endTime']} • $room',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                          );
                                        }).toList(),
                                  );
                                }
                              } else {
                                // Fallback to old format
                                return Text(
                                  '${_getDayAbbreviation(widget.classData['day'])} ${widget.classData['startTime']} - ${widget.classData['endTime']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.meeting_room_outlined,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.classData['room'] ?? 'N/A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Edit Button Overlay
          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showBannerImageDialog(classId),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Change Banner',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Posted Assignments & Activities',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Row(
          children: [
            // Type Filter Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ClassDetailConstants.primaryGreen.withOpacity(0.3),
                ),
              ),
              child: DropdownButton<String>(
                value: _selectedPostedItemTypeFilter,
                underline: const SizedBox(),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: ClassDetailConstants.primaryGreen,
                ),
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                items:
                    _postedItemTypeFilterOptions.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedPostedItemTypeFilter = newValue;
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            // Topic Filter Dropdown
            Obx(() {
              final topicOptions = [
                'All Topics',
                'No Topic',
                ...widget.topicController.topics.map((topic) => topic.topic),
              ];

              // Reset filter if selected topic no longer exists
              if (!topicOptions.contains(_selectedPostedItemTopicFilter)) {
                _selectedPostedItemTopicFilter = 'All Topics';
              }

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ClassDetailConstants.primaryGreen.withOpacity(0.3),
                  ),
                ),
                child: DropdownButton<String>(
                  value: _selectedPostedItemTopicFilter,
                  underline: const SizedBox(),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: ClassDetailConstants.primaryGreen,
                  ),
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  items:
                      topicOptions.map((String topic) {
                        return DropdownMenuItem<String>(
                          value: topic,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                topic == 'All Topics'
                                    ? Icons.topic
                                    : topic == 'No Topic'
                                    ? Icons.not_interested
                                    : Icons.bookmark,
                                size: 16,
                                color: ClassDetailConstants.primaryGreen,
                              ),
                              const SizedBox(width: 8),
                              Text(topic),
                            ],
                          ),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedPostedItemTopicFilter = newValue;
                      });
                    }
                  },
                ),
              );
            }),
            const SizedBox(width: 8),
            IconButton(
              onPressed: widget.onRefresh,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPostedItemsList() {
    return Obx(() {
      if (widget.createController.isLoading.value) {
        return ListView.builder(
          itemCount: 5,
          itemBuilder: (context, i) {
            return const Padding(
              padding: EdgeInsets.only(
                bottom: ClassDetailConstants.defaultPadding,
              ),
              child: SkeletonInstructorCreateItemCard(),
            );
          },
        );
      }

      // Get only posted items (assignments, activities, quizzes) for this specific class
      List<Map<String, dynamic>> postedItems = [];
      String currentClassSection = widget.classData['section'] ?? '';
      String currentClassCourse = widget.classData['course'] ?? '';
      String currentClassFullName = '$currentClassCourse $currentClassSection';

      for (var item in widget.createController.createdItems) {
        // Check if this item is assigned to the current class
        List<dynamic> selectedClasses = item['selectedClasses'] ?? [];
        bool isAssignedToCurrentClass = false;

        // Check if the current class is in the selectedClasses list
        for (var selectedClass in selectedClasses) {
          String selectedClassStr = selectedClass.toString().toLowerCase();
          String currentClassStr = currentClassFullName.toLowerCase();

          // Direct match
          if (selectedClassStr == currentClassStr) {
            isAssignedToCurrentClass = true;
            break;
          }

          // Check for partial matches (e.g., "BSIT-1A" matches "BSIT 1A")
          String normalizedSelected = selectedClassStr
              .replaceAll('-', ' ')
              .replaceAll('_', ' ');
          String normalizedCurrent = currentClassStr
              .replaceAll('-', ' ')
              .replaceAll('_', ' ');

          if (normalizedSelected == normalizedCurrent) {
            isAssignedToCurrentClass = true;
            break;
          }

          // Check if current class section matches (e.g., "1A" matches "BSIT-1A")
          if (selectedClassStr.contains(currentClassSection.toLowerCase()) ||
              currentClassStr.contains(selectedClassStr)) {
            isAssignedToCurrentClass = true;
            break;
          }
        }

        // Only add items that are assigned to the current class
        if (isAssignedToCurrentClass) {
          postedItems.add({
            ...item,
            'itemType': 'posted',
            'timestamp': item['createdAt'],
          });
        }
      }

      // Apply type filter
      if (_selectedPostedItemTypeFilter != 'All Types') {
        postedItems =
            postedItems.where((item) {
              final itemType = (item['type'] as String?)?.toLowerCase() ?? '';
              final filterType = _selectedPostedItemTypeFilter.toLowerCase();
              return itemType == filterType;
            }).toList();
      }

      // Apply topic filter
      if (_selectedPostedItemTopicFilter != 'All Topics') {
        postedItems =
            postedItems.where((item) {
              final itemTopicName = item['topicName'];
              final itemTopicId = item['topicId'];

              if (_selectedPostedItemTopicFilter == 'No Topic') {
                // Show items with no topic assigned (null, empty, or string "null")
                final hasNoTopic =
                    itemTopicName == null ||
                    itemTopicName == '' ||
                    itemTopicName == 'null' ||
                    itemTopicId == null ||
                    itemTopicId == '' ||
                    itemTopicId == 'null';
                return hasNoTopic;
              } else {
                // Show items with matching topic name
                final matches = itemTopicName == _selectedPostedItemTopicFilter;
                return matches;
              }
            }).toList();
      }

      // Sort by timestamp (most recent first)
      postedItems.sort((a, b) {
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

      if (postedItems.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.builder(
        itemCount: postedItems.length,
        itemBuilder: (context, index) {
          final item = postedItems[index];
          return _buildActivityCard(item);
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
                  'No assignments or activities posted yet',
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
                  'Create assignments, activities, and quizzes for your class.',
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

  Widget _buildActivityCard(Map<String, dynamic> item) {
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
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToItem(item),
        borderRadius: BorderRadius.circular(
          ClassDetailConstants.cardBorderRadius,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ClassDetailConstants.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.description,
                color: Colors.white,
                size: 24,
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
                        '${widget.instructorController.instructorName.value} posted new ${item['type'].toLowerCase()}:',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          item['title'] ?? 'No Title',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Topic badge
                  if (item['topicName'] != null && item['topicName'] != '') ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ClassDetailConstants.primaryGreen.withOpacity(
                          0.1,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: ClassDetailConstants.primaryGreen.withOpacity(
                            0.3,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bookmark,
                            size: 14,
                            color: ClassDetailConstants.primaryGreen,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item['topicName'],
                            style: TextStyle(
                              fontSize: 12,
                              color: ClassDetailConstants.primaryGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    children: [
                      if (item['dueDate'] != null) ...[
                        Text(
                          'Due: ${_formatTimestamp(item['dueDate'])}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      Text(
                        'Created: ${_formatTimestamp(item['createdAt'])}',
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
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  /// Show dialog to change class banner image
  void _showBannerImageDialog(String? classId) {
    if (classId == null) {
      Get.snackbar(
        'Error',
        'Class ID not found',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final currentImageUrl = widget.classData['classImageUrl'] as String?;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ClassDetailConstants.cardBorderRadius,
          ),
        ),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(ClassDetailConstants.largePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Change Class Banner',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ClassDetailConstants.primaryGreen,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: ClassDetailConstants.largePadding),
              ClassBannerImagePicker(
                currentImageUrl: currentImageUrl,
                onImageUploaded: (imageUrl) {
                  // Update banner image in Firestore
                  widget.classController.updateClassBannerImage(
                    classId: classId,
                    imageUrl: imageUrl,
                  );

                  // Update local state immediately for instant UI update
                  setState(() {
                    widget.classData['classImageUrl'] = imageUrl;
                  });

                  Get.back(); // Close dialog
                },
                onImageRemoved: () {
                  // Reset to default image in Firestore
                  widget.classController.updateClassBannerImage(
                    classId: classId,
                    imageUrl: null,
                  );

                  // Update local state immediately for instant UI update
                  setState(() {
                    widget.classData.remove('classImageUrl');
                  });

                  Get.back(); // Close dialog
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Navigate to appropriate screen based on item type
  void _navigateToItem(Map<String, dynamic> item) {
    String itemType = item['type'] ?? '';
    // Use section name (like "BSIT-1A") instead of sectionId
    final sectionCode = widget.classData['section'] ?? '';

    switch (itemType.toLowerCase()) {
      case 'material':
        // Navigate to material detail screen for materials
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MaterialsDetailScreen(material: item),
          ),
        );
        break;
      case 'assignment':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => StudentSubmissionsScreen(
                  activityData: item,
                  sectionId: sectionCode,
                ),
          ),
        );
        break;
      case 'activity':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => StudentSubmissionsScreen(
                  activityData: item,
                  sectionId: sectionCode,
                ),
          ),
        );
        break;
      case 'quiz':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => StudentSubmissionsScreen(
                  activityData: item,
                  sectionId: sectionCode,
                ),
          ),
        );
        break;
      default:
        // Default navigation to submissions screen for other types
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => StudentSubmissionsScreen(
                  activityData: item,
                  sectionId: sectionCode,
                ),
          ),
        );
    }
  }

  /// Get day abbreviation
  String _getDayAbbreviation(String? day) {
    if (day == null) return '';

    switch (day.toLowerCase()) {
      case 'monday':
        return 'Mon';
      case 'tuesday':
        return 'Tue';
      case 'wednesday':
        return 'Wed';
      case 'thursday':
        return 'Thu';
      case 'friday':
        return 'Fri';
      case 'saturday':
        return 'Sat';
      case 'sunday':
        return 'Sun';
      default:
        return day;
    }
  }

  /// Format timestamp to readable date
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    try {
      if (timestamp is Timestamp) {
        final dateTime = timestamp.toDate();
        return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
      } else if (timestamp is DateTime) {
        return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
      } else if (timestamp is String) {
        // Try to parse as ISO format or standard date format
        try {
          final dateTime = DateTime.parse(timestamp);
          return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
        } catch (e) {
          // If parsing fails, return as-is
          return timestamp;
        }
      }
      return 'Unknown';
    } catch (e) {
      // If it's a string that failed, return it as-is
      if (timestamp is String) {
        return timestamp;
      }
      return 'Unknown';
    }
  }
}
