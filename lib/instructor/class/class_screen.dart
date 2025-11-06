// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:greenquest/instructor/class/class_screen_controller.dart';
import '../../shared/instructor/instructor_appbar.dart';
import '../../shared/instructor/instructor_sidebar.dart';
import '../../shared/instructor/instructor_navigation_constants.dart';
import 'class_detail_screen.dart';
import 'package:get/get.dart';
import '../instructor_dashboard_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/class_schedule.dart';
import '../../shared/widgets/skeleton_loading.dart';

class ClassScreen extends StatefulWidget {
  const ClassScreen({super.key});

  @override
  State<ClassScreen> createState() => _ClassScreenState();
}

class _ClassScreenState extends State<ClassScreen> with WidgetsBindingObserver {
  final ClassController _classController = Get.put(ClassController());
  final InstructorController instructorController = Get.put(
    InstructorController(),
  );
  InstructorNavigationItem _selectedItem =
      InstructorNavigationItem.classManagement;
  bool _showCreateClassDialog = false;
  bool _showEditClassDialog = false;
  Map<String, dynamic>? _editingClassData;
  bool _showArchivedClasses = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final TextEditingController _classNameController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();

  // Multiple schedules support
  List<Map<String, dynamic>> _schedules = [];
  final TextEditingController _tempStartTimeController =
      TextEditingController();
  final TextEditingController _tempEndTimeController = TextEditingController();
  final TextEditingController _tempRoomController = TextEditingController();
  String? _tempSelectedDay;

  // Section and Day selection
  String? _selectedSectionId;
  List<Map<String, dynamic>> _availableSections = [];
  bool _isLoadingSections = false;

  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  void _handleNavigationSelect(InstructorNavigationItem item) {
    setState(() {
      _selectedItem = item;
    });
    String route = InstructorNavigationHelper.getRoute(item);
    Navigator.of(context).pushReplacementNamed(route);
  }

  void _openCreateClassDialog() {
    setState(() {
      _showCreateClassDialog = true;
    });
  }

  void _hideCreateClassDialog() {
    setState(() {
      _showCreateClassDialog = false;
      // Clear form fields
      _classNameController.clear();
      _roomController.clear();
      _selectedSectionId = null;
      _schedules.clear();
      _tempSelectedDay = null;
      _tempStartTimeController.clear();
      _tempEndTimeController.clear();
      _tempRoomController.clear();
    });
  }

  void _openEditClassDialog(Map<String, dynamic> classData) {
    setState(() {
      _editingClassData = classData;
      _showEditClassDialog = true;

      // Populate form fields with existing class data
      _selectedSectionId = classData['sectionId'];

      // Load schedules
      if (classData.containsKey('schedules') &&
          classData['schedules'] is List) {
        _schedules = List<Map<String, dynamic>>.from(classData['schedules']);
      } else {
        // Fallback to old format
        _schedules = [
          {
            'day': classData['day'] ?? '',
            'startTime': classData['startTime'] ?? '',
            'endTime': classData['endTime'] ?? '',
            'room': classData['room'] ?? '',
          },
        ];
      }

      // Set room controller (use first schedule's room)
      if (_schedules.isNotEmpty) {
        _roomController.text = _schedules[0]['room'] ?? '';
      }
    });
  }

  void _hideEditClassDialog() {
    setState(() {
      _showEditClassDialog = false;
      _editingClassData = null;
      // Clear form fields
      _classNameController.clear();
      _roomController.clear();
      _selectedSectionId = null;
      _schedules.clear();
      _tempSelectedDay = null;
      _tempStartTimeController.clear();
      _tempEndTimeController.clear();
      _tempRoomController.clear();
    });
  }

  void _addSchedule() {
    // Limit to 2 schedules maximum
    if (_schedules.length >= 2) {
      Get.snackbar("Limit Reached", "You can only add up to 2 schedules!");
      return;
    }

    if (_tempSelectedDay == null ||
        _tempStartTimeController.text.isEmpty ||
        _tempEndTimeController.text.isEmpty ||
        _tempRoomController.text.trim().isEmpty) {
      Get.snackbar(
        "Error",
        "Please fill in all schedule fields including room!",
      );
      return;
    }

    setState(() {
      _schedules.add({
        'day': _tempSelectedDay!,
        'startTime': _tempStartTimeController.text,
        'endTime': _tempEndTimeController.text,
        'room': _tempRoomController.text.trim(),
      });
      // Clear temporary fields
      _tempSelectedDay = null;
      _tempStartTimeController.clear();
      _tempEndTimeController.clear();
      _tempRoomController.clear();
    });
  }

  void _removeSchedule(int index) {
    setState(() {
      _schedules.removeAt(index);
    });
  }

  void _createClass() {
    if (_availableSections.isEmpty) {
      Get.snackbar(
        "Error",
        "No sections are assigned to you. Please contact admin.",
      );
      return;
    }

    // Check if section is selected
    if (_selectedSectionId == null) {
      Get.snackbar("Error", "Please select a section!");
      return;
    }

    // Check if at least one schedule is added
    if (_schedules.isEmpty) {
      Get.snackbar("Error", "Please add at least one schedule!");
      return;
    }

    // Get course information from selected section
    final selectedSection = _availableSections.firstWhere(
      (section) => section['id'] == _selectedSectionId,
      orElse: () => {},
    );

    final sectionCode = selectedSection['sectionCode'] ?? "";
    final courseCode = selectedSection['courseCode'] ?? "";

    // Convert schedules to ClassSchedule objects (each with their own room)
    final classSchedules =
        _schedules
            .map(
              (schedule) => ClassSchedule(
                day: schedule['day'],
                startTime: schedule['startTime'],
                endTime: schedule['endTime'],
                room: schedule['room'],
              ),
            )
            .toList();

    _classController.addClass(
      section: sectionCode,
      course: courseCode,
      room:
          _schedules.isNotEmpty
              ? _schedules[0]['room']
              : '', // Use first schedule's room for backward compatibility
      schedules: classSchedules,
      sectionId: _selectedSectionId,
    );

    _hideCreateClassDialog();
  }

  void _updateClass() {
    if (_editingClassData == null) return;

    if (_availableSections.isEmpty) {
      Get.snackbar(
        "Error",
        "No sections are assigned to you. Please contact admin.",
      );
      return;
    }

    // Check if section is selected
    if (_selectedSectionId == null) {
      Get.snackbar("Error", "Please select a section!");
      return;
    }

    // Check if at least one schedule is added
    if (_schedules.isEmpty) {
      Get.snackbar("Error", "Please add at least one schedule!");
      return;
    }

    // Get course information from selected section
    final selectedSection = _availableSections.firstWhere(
      (section) => section['id'] == _selectedSectionId,
      orElse: () => {},
    );

    final sectionCode = selectedSection['sectionCode'] ?? "";
    final courseCode = selectedSection['courseCode'] ?? "";

    // Convert schedules to ClassSchedule objects
    final classSchedules =
        _schedules
            .map(
              (schedule) => ClassSchedule(
                day: schedule['day'],
                startTime: schedule['startTime'],
                endTime: schedule['endTime'],
                room: schedule['room'],
              ),
            )
            .toList();

    _classController.updateClass(
      classId: _editingClassData!['id'],
      section: sectionCode,
      course: courseCode,
      room:
          _schedules.isNotEmpty
              ? _schedules[0]['room']
              : '', // Use first schedule's room for backward compatibility
      schedules: classSchedules,
      sectionId: _selectedSectionId,
    );

    _hideEditClassDialog();
  }

  void _showDeleteConfirmation(Map<String, dynamic> classData) {
    final className = '${classData['course']} ${classData['section']}';
    showDialog(
      context: context,
      builder:
          (context) => _DeleteConfirmationDialog(
            className: className,
            onConfirm: () => _deleteClass(classData),
            onCancel: () => Navigator.of(context).pop(),
          ),
    );
  }

  void _showArchiveConfirmation(Map<String, dynamic> classData) {
    final className = '${classData['course']} ${classData['section']}';
    showDialog(
      context: context,
      builder:
          (context) => _ArchiveConfirmationDialog(
            className: className,
            onConfirm: () => _archiveClass(classData),
            onCancel: () => Navigator.of(context).pop(),
          ),
    );
  }

  void _deleteClass(Map<String, dynamic> classData) {
    final classId = classData['id'];
    if (classId != null) {
      _classController.deleteClass(classId);
    }
    Navigator.of(context).pop(); // Close dialog
  }

  void _archiveClass(Map<String, dynamic> classData) {
    final classId = classData['id'];
    if (classId != null) {
      _classController.archiveClass(classId);
    }
    Navigator.of(context).pop(); // Close dialog
  }

  void _unarchiveClass(Map<String, dynamic> classData) {
    final classId = classData['id'];
    if (classId != null) {
      _classController.unarchiveClass(classId);
    }
  }

  List<Map<String, dynamic>> _getFilteredClasses() {
    final classesToShow =
        _showArchivedClasses
            ? _classController.archivedClasses
            : _classController.classes;

    if (_searchQuery.isEmpty) {
      return classesToShow;
    }

    return classesToShow.where((classData) {
      final section = (classData['section'] ?? '').toString().toLowerCase();
      final course = (classData['course'] ?? '').toString().toLowerCase();
      final room = (classData['room'] ?? '').toString().toLowerCase();

      // Search in schedules as well
      String scheduleText = '';
      if (classData.containsKey('schedules') &&
          classData['schedules'] is List) {
        final schedules = List<Map<String, dynamic>>.from(
          classData['schedules'],
        );
        scheduleText =
            schedules.map((s) => s['day'] ?? '').join(' ').toLowerCase();
      }

      final searchLower = _searchQuery.toLowerCase();
      return section.contains(searchLower) ||
          course.contains(searchLower) ||
          room.contains(searchLower) ||
          scheduleText.contains(searchLower);
    }).toList();
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF34A853), // Green header
              onPrimary: Colors.white, // White text on header
              onSurface: Colors.black, // Black text on surface
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _tempStartTimeController.text = picked.format(context);
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF34A853), // Green header
              onPrimary: Colors.white, // White text on header
              onSurface: Colors.black, // Black text on surface
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _tempEndTimeController.text = picked.format(context);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Use addPostFrameCallback to ensure operations run after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSections();
      _loadStudents();
    });
  }

  Future<void> _loadStudents() async {
    await _classController.loadStudentsFromUsersCollection();
  }

  Future<void> _loadSections() async {
    // Use addPostFrameCallback to prevent setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isLoadingSections = true;
        });
      }
    });

    try {
      // Get current instructor
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user logged in');
        return;
      }

      // Get instructor's assignments
      final instructorDoc =
          await FirebaseFirestore.instance
              .collection('instructors')
              .doc(user.uid)
              .get();

      if (!instructorDoc.exists) {
        print('Instructor document not found');
        return;
      }

      final instructorData = instructorDoc.data()!;
      final assignments = List<Map<String, dynamic>>.from(
        instructorData['assignments'] ?? [],
      );

      // Get all department IDs from instructor's assignments
      final departmentIds =
          assignments
              .map((assignment) => assignment['departmentId'])
              .where((id) => id != null && id.toString().isNotEmpty)
              .toSet();

      if (departmentIds.isEmpty) {
        print('No department assignments found for instructor');
        _availableSections = [];
        return;
      }

      // Load sections for assigned departments only
      final List<Map<String, dynamic>> allSections = [];

      for (String departmentId in departmentIds) {
        final sectionsSnapshot =
            await FirebaseFirestore.instance
                .collection('sections')
                .where('departmentId', isEqualTo: departmentId)
                .get();

        final sections =
            sectionsSnapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'sectionCode': data['sectionCode'] ?? '',
                'departmentId': data['departmentId'] ?? '',
                'departmentName': data['departmentName'] ?? '',
                'courseName': data['courseName'] ?? '',
                'courseCode': data['courseCode'] ?? '',
              };
            }).toList();

        allSections.addAll(sections);
      }

      _availableSections = allSections;
      print('Loaded ${_availableSections.length} sections for instructor');
    } catch (e) {
      print('Error loading sections: $e');
      _availableSections = [];
    } finally {
      // Use addPostFrameCallback to prevent setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isLoadingSections = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Removed auto-loading on app resume - data will load only when user explicitly requests it
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Row(
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
                    Obx(
                      () => InstructorAppBar(
                        instructorName:
                            instructorController.instructorName.value,
                        instructorRole: 'Instructor',
                        profileImageUrl:
                            instructorController.profileImageUrl.value,
                      ),
                    ),
                    // Main Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome, Instructor!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 32,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Manage your classes and track environmental impact through education',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 48),
                            // Search Bar (medium width)
                            Container(
                              width: 400,
                              height: 44,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search,
                                    color: Color(0xFFBDBDBD),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      decoration: InputDecoration(
                                        hintText:
                                            'Search by section, course, room, or day...',
                                        border: InputBorder.none,
                                        hintStyle: TextStyle(
                                          color: Color(0xFFBDBDBD),
                                        ),
                                      ),
                                      style: TextStyle(fontSize: 15),
                                      cursorColor: Colors.black54,
                                      onChanged: (value) {
                                        setState(() {
                                          _searchQuery = value.toLowerCase();
                                        });
                                      },
                                    ),
                                  ),
                                  if (_searchQuery.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.clear,
                                        size: 20,
                                        color: Color(0xFFBDBDBD),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _searchQuery = '';
                                          _searchController.clear();
                                        });
                                      },
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Action Buttons below search bar
                            Row(
                              children: [
                                // Create Class Button
                                ElevatedButton.icon(
                                  onPressed: _openCreateClassDialog,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF34A853),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 30,
                                      vertical: 20,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(Icons.add),
                                  label: const Text(
                                    'Create Class',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Toggle Archived Classes Button
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _showArchivedClasses =
                                          !_showArchivedClasses;
                                      // Clear search when switching views
                                      _searchQuery = '';
                                      _searchController.clear();
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        _showArchivedClasses
                                            ? Colors.orange
                                            : Colors.grey[600],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 30,
                                      vertical: 20,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: Icon(
                                    _showArchivedClasses
                                        ? Icons.unarchive
                                        : Icons.archive,
                                  ),
                                  label: Text(
                                    _showArchivedClasses
                                        ? 'Show Active'
                                        : 'Show Archived',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            // Class Cards Grid
                            Expanded(
                              child: Obx(() {
                                if (_classController.isLoading.value) {
                                  return LayoutBuilder(
                                    builder: (context, constraints) {
                                      // Determine grid layout based on screen width
                                      double screenWidth =
                                          MediaQuery.of(context).size.width;
                                      int crossAxisCount;
                                      double childAspectRatio;

                                      if (screenWidth < 768) {
                                        crossAxisCount = 1;
                                        childAspectRatio = 1.4;
                                      } else if (screenWidth < 1024) {
                                        crossAxisCount = 2;
                                        childAspectRatio = 1.6;
                                      } else if (screenWidth < 1440) {
                                        crossAxisCount = 3;
                                        childAspectRatio = 1.5;
                                      } else {
                                        crossAxisCount = 4;
                                        childAspectRatio = 1.4;
                                      }

                                      return GridView.builder(
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: crossAxisCount,
                                              crossAxisSpacing:
                                                  screenWidth < 768 ? 16 : 20,
                                              mainAxisSpacing:
                                                  screenWidth < 768 ? 16 : 20,
                                              childAspectRatio:
                                                  childAspectRatio,
                                            ),
                                        itemCount: 6,
                                        itemBuilder: (context, index) {
                                          return const SkeletonInstructorClassCard();
                                        },
                                      );
                                    },
                                  );
                                }

                                final classesToShow = _getFilteredClasses();

                                if (classesToShow.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _showArchivedClasses
                                              ? Icons.archive_outlined
                                              : Icons.school_outlined,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          _searchQuery.isNotEmpty
                                              ? 'No classes found'
                                              : _showArchivedClasses
                                              ? 'No archived classes found'
                                              : 'No classes found',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          _searchQuery.isNotEmpty
                                              ? 'Try adjusting your search query to find what you\'re looking for.'
                                              : _showArchivedClasses
                                              ? 'Archived classes will appear here'
                                              : 'Create your first class to get started',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return LayoutBuilder(
                                  builder: (context, constraints) {
                                    // Determine grid layout based on screen width
                                    double screenWidth =
                                        MediaQuery.of(context).size.width;
                                    int crossAxisCount;
                                    double childAspectRatio;

                                    if (screenWidth < 768) {
                                      // Mobile: 1 column
                                      crossAxisCount = 1;
                                      childAspectRatio = 1.4;
                                    } else if (screenWidth < 1024) {
                                      // Tablet: 2 columns
                                      crossAxisCount = 2;
                                      childAspectRatio = 1.6;
                                    } else if (screenWidth < 1440) {
                                      // Small desktop: 3 columns
                                      crossAxisCount = 3;
                                      childAspectRatio = 1.5;
                                    } else {
                                      // Large desktop: 4 columns
                                      crossAxisCount = 4;
                                      childAspectRatio = 1.4;
                                    }

                                    return GridView.builder(
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: crossAxisCount,
                                            crossAxisSpacing:
                                                screenWidth < 768 ? 16 : 20,
                                            mainAxisSpacing:
                                                screenWidth < 768 ? 16 : 20,
                                            childAspectRatio: childAspectRatio,
                                          ),
                                      itemCount: classesToShow.length,
                                      itemBuilder: (context, index) {
                                        final classData = classesToShow[index];
                                        return _buildClassCard(
                                          classData,
                                          screenWidth,
                                        );
                                      },
                                    );
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
          // Create Class Dialog
          if (_showCreateClassDialog)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  width:
                      MediaQuery.of(context).size.width < 768
                          ? MediaQuery.of(context).size.width * 0.9
                          : 500,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        MediaQuery.of(context).size.width < 768 ? 20 : 30,
                    vertical: MediaQuery.of(context).size.width < 768 ? 16 : 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create Class',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Scrollable content
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Section Dropdown
                              Container(
                                height: 50,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF34A853,
                                  ).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButton<String>(
                                  borderRadius: BorderRadius.circular(15),
                                  value: _selectedSectionId,
                                  hint:
                                      _isLoadingSections
                                          ? const Text(
                                            'Loading sections...',
                                            style: TextStyle(
                                              color: Colors.black45,
                                            ),
                                          )
                                          : _availableSections.isEmpty
                                          ? const Text(
                                            'No sections assigned',
                                            style: TextStyle(
                                              color: Colors.black45,
                                            ),
                                          )
                                          : const Text(
                                            'Select Section',
                                            style: TextStyle(
                                              color: Colors.black45,
                                            ),
                                          ),
                                  isExpanded: true,
                                  underline: Container(),
                                  items:
                                      _availableSections.map<
                                        DropdownMenuItem<String>
                                      >((section) {
                                        return DropdownMenuItem<String>(
                                          value: section['id'],
                                          child: Text(
                                            '${section['courseCode']} ${section['sectionCode']} - ${section['courseName']}',
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedSectionId = newValue;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Schedules Section Header
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Schedules',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    '${_schedules.length}/2 added',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          _schedules.length >= 2
                                              ? const Color(0xFF34A853)
                                              : Colors.black54,
                                      fontWeight:
                                          _schedules.length >= 2
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Display added schedules
                              if (_schedules.isNotEmpty)
                                Container(
                                  constraints: const BoxConstraints(
                                    maxHeight: 150,
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _schedules.length,
                                    itemBuilder: (context, index) {
                                      final schedule = _schedules[index];
                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF34A853,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: const Color(
                                              0xFF34A853,
                                            ).withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${schedule['day']} • ${schedule['startTime']} - ${schedule['endTime']}',
                                                    style: const TextStyle(
                                                      color: Colors.black87,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.meeting_room,
                                                        size: 14,
                                                        color: Colors.black54,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        schedule['room'] ??
                                                            'No room',
                                                        style: const TextStyle(
                                                          color: Colors.black54,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                                size: 20,
                                              ),
                                              onPressed:
                                                  () => _removeSchedule(index),
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),

                              if (_schedules.isNotEmpty)
                                const SizedBox(height: 12),

                              // Add Schedule Form (hidden when 2 schedules added)
                              if (_schedules.length < 2)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.grey.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Add Schedule',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Day Dropdown
                                      Container(
                                        height: 50,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF34A853,
                                          ).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: DropdownButton<String>(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          value: _tempSelectedDay,
                                          hint: const Text(
                                            'Select Day',
                                            style: TextStyle(
                                              color: Colors.black45,
                                            ),
                                          ),
                                          isExpanded: true,
                                          underline: Container(),
                                          items:
                                              _daysOfWeek.map((String day) {
                                                return DropdownMenuItem<String>(
                                                  value: day,
                                                  child: Text(
                                                    day,
                                                    style: const TextStyle(
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                          onChanged: (String? newValue) {
                                            setState(() {
                                              _tempSelectedDay = newValue;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Room field
                                      TextField(
                                        controller: _tempRoomController,
                                        cursorColor: Colors.black45,
                                        decoration: InputDecoration(
                                          hintText: 'Room',
                                          hintStyle: const TextStyle(
                                            color: Colors.black45,
                                          ),
                                          filled: true,
                                          fillColor: const Color(
                                            0xFF34A853,
                                          ).withOpacity(0.15),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Time Range Row
                                      Row(
                                        children: [
                                          // Start Time
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: _selectStartTime,
                                              child: AbsorbPointer(
                                                child: TextField(
                                                  controller:
                                                      _tempStartTimeController,
                                                  cursorColor: Colors.black45,
                                                  decoration: InputDecoration(
                                                    hintText: 'Start Time',
                                                    hintStyle: const TextStyle(
                                                      color: Colors.black45,
                                                    ),
                                                    filled: true,
                                                    fillColor: const Color(
                                                      0xFF34A853,
                                                    ).withOpacity(0.15),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      borderSide:
                                                          BorderSide.none,
                                                    ),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
                                                              ),
                                                          borderSide:
                                                              BorderSide.none,
                                                        ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
                                                              ),
                                                          borderSide:
                                                              BorderSide.none,
                                                        ),
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                          vertical: 12,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // End Time
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: _selectEndTime,
                                              child: AbsorbPointer(
                                                child: TextField(
                                                  controller:
                                                      _tempEndTimeController,
                                                  cursorColor: Colors.black45,
                                                  decoration: InputDecoration(
                                                    hintText: 'End Time',
                                                    hintStyle: const TextStyle(
                                                      color: Colors.black45,
                                                    ),
                                                    filled: true,
                                                    fillColor: const Color(
                                                      0xFF34A853,
                                                    ).withOpacity(0.15),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      borderSide:
                                                          BorderSide.none,
                                                    ),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
                                                              ),
                                                          borderSide:
                                                              BorderSide.none,
                                                        ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
                                                              ),
                                                          borderSide:
                                                              BorderSide.none,
                                                        ),
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                          vertical: 12,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // Add Schedule Button
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: _addSchedule,
                                          icon: const Icon(Icons.add, size: 18),
                                          label: const Text('Add Schedule'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF34A853,
                                            ),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Schedule requirement message
                      if (_schedules.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.orange[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Please add at least one schedule to create the class.',
                                  style: TextStyle(
                                    color: Colors.orange[700],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_schedules.isEmpty) const SizedBox(height: 16),
                      // Action Buttons (Fixed at bottom)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _hideCreateClassDialog,
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          TextButton(
                            onPressed:
                                _availableSections.isEmpty ||
                                        _selectedSectionId == null ||
                                        _schedules.isEmpty
                                    ? null
                                    : _createClass,
                            child: Text(
                              'Create',
                              style: TextStyle(
                                fontSize: 16,
                                color:
                                    _availableSections.isEmpty ||
                                            _selectedSectionId == null ||
                                            _schedules.isEmpty
                                        ? Colors.grey
                                        : const Color(0xFF34A853),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Edit Class Dialog
          if (_showEditClassDialog)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  width:
                      MediaQuery.of(context).size.width < 768
                          ? MediaQuery.of(context).size.width * 0.9
                          : 500,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        MediaQuery.of(context).size.width < 768 ? 20 : 30,
                    vertical: MediaQuery.of(context).size.width < 768 ? 16 : 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Edit Class',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Scrollable content
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Section Dropdown
                              Container(
                                height: 50,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF34A853,
                                  ).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButton<String>(
                                  borderRadius: BorderRadius.circular(15),
                                  value: _selectedSectionId,
                                  hint:
                                      _isLoadingSections
                                          ? const Text(
                                            'Loading sections...',
                                            style: TextStyle(
                                              color: Colors.black45,
                                            ),
                                          )
                                          : _availableSections.isEmpty
                                          ? const Text(
                                            'No sections assigned',
                                            style: TextStyle(
                                              color: Colors.black45,
                                            ),
                                          )
                                          : const Text(
                                            'Select Section',
                                            style: TextStyle(
                                              color: Colors.black45,
                                            ),
                                          ),
                                  isExpanded: true,
                                  underline: Container(),
                                  items:
                                      _availableSections.map<
                                        DropdownMenuItem<String>
                                      >((section) {
                                        return DropdownMenuItem<String>(
                                          value: section['id'],
                                          child: Text(
                                            '${section['courseCode']} ${section['sectionCode']} - ${section['courseName']}',
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedSectionId = newValue;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Schedules Section Header
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Schedules',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    '${_schedules.length}/2 added',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          _schedules.length >= 2
                                              ? const Color(0xFF34A853)
                                              : Colors.black54,
                                      fontWeight:
                                          _schedules.length >= 2
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Display added schedules
                              if (_schedules.isNotEmpty)
                                Container(
                                  constraints: const BoxConstraints(
                                    maxHeight: 150,
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _schedules.length,
                                    itemBuilder: (context, index) {
                                      final schedule = _schedules[index];
                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF34A853,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: const Color(
                                              0xFF34A853,
                                            ).withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${schedule['day']} • ${schedule['startTime']} - ${schedule['endTime']}',
                                                    style: const TextStyle(
                                                      color: Colors.black87,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.meeting_room,
                                                        size: 14,
                                                        color: Colors.black54,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        schedule['room'] ??
                                                            'No room',
                                                        style: const TextStyle(
                                                          color: Colors.black54,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                                size: 20,
                                              ),
                                              onPressed:
                                                  () => _removeSchedule(index),
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),

                              if (_schedules.isNotEmpty)
                                const SizedBox(height: 12),

                              // Add Schedule Form (hidden when 2 schedules added)
                              if (_schedules.length < 2)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.grey.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Add Schedule',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Day Dropdown
                                      Container(
                                        height: 50,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF34A853,
                                          ).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: DropdownButton<String>(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          value: _tempSelectedDay,
                                          hint: const Text(
                                            'Select Day',
                                            style: TextStyle(
                                              color: Colors.black45,
                                            ),
                                          ),
                                          isExpanded: true,
                                          underline: Container(),
                                          items:
                                              _daysOfWeek.map<
                                                DropdownMenuItem<String>
                                              >((String day) {
                                                return DropdownMenuItem<String>(
                                                  value: day,
                                                  child: Text(
                                                    day,
                                                    style: const TextStyle(
                                                      color: Colors.black87,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                          onChanged: (String? newValue) {
                                            setState(() {
                                              _tempSelectedDay = newValue;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Time and Room Row
                                      Row(
                                        children: [
                                          // Start Time
                                          Expanded(
                                            child: InkWell(
                                              onTap: _selectStartTime,
                                              child: Container(
                                                height: 50,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 12,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF34A853,
                                                  ).withOpacity(0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.access_time,
                                                      size: 18,
                                                      color: Colors.black54,
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: TextField(
                                                        controller:
                                                            _tempStartTimeController,
                                                        enabled: false,
                                                        decoration:
                                                            const InputDecoration(
                                                              hintText:
                                                                  'Start Time',
                                                              border:
                                                                  InputBorder
                                                                      .none,
                                                              hintStyle: TextStyle(
                                                                color:
                                                                    Colors
                                                                        .black45,
                                                              ),
                                                            ),
                                                        style: const TextStyle(
                                                          color: Colors.black87,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // End Time
                                          Expanded(
                                            child: InkWell(
                                              onTap: _selectEndTime,
                                              child: Container(
                                                height: 50,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 12,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF34A853,
                                                  ).withOpacity(0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.access_time,
                                                      size: 18,
                                                      color: Colors.black54,
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: TextField(
                                                        controller:
                                                            _tempEndTimeController,
                                                        enabled: false,
                                                        decoration:
                                                            const InputDecoration(
                                                              hintText:
                                                                  'End Time',
                                                              border:
                                                                  InputBorder
                                                                      .none,
                                                              hintStyle: TextStyle(
                                                                color:
                                                                    Colors
                                                                        .black45,
                                                              ),
                                                            ),
                                                        style: const TextStyle(
                                                          color: Colors.black87,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // Room Field
                                      Container(
                                        height: 50,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF34A853,
                                          ).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: TextField(
                                          controller: _tempRoomController,
                                          decoration: InputDecoration(
                                            hintText: 'Room',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide.none,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 12,
                                                ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Add Schedule Button
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: _addSchedule,
                                          icon: const Icon(Icons.add, size: 18),
                                          label: const Text('Add Schedule'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF34A853,
                                            ),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Schedule requirement message
                      if (_schedules.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.orange[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Please add at least one schedule to update the class.',
                                  style: TextStyle(
                                    color: Colors.orange[700],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_schedules.isEmpty) const SizedBox(height: 16),
                      // Action Buttons (Fixed at bottom)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _hideEditClassDialog,
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          TextButton(
                            onPressed:
                                _availableSections.isEmpty ||
                                        _selectedSectionId == null ||
                                        _schedules.isEmpty
                                    ? null
                                    : _updateClass,
                            child: Text(
                              'Update',
                              style: TextStyle(
                                fontSize: 16,
                                color:
                                    _availableSections.isEmpty ||
                                            _selectedSectionId == null ||
                                            _schedules.isEmpty
                                        ? Colors.grey
                                        : const Color(0xFF34A853),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClassCard(Map<String, dynamic> classData, double screenWidth) {
    // Format the class name as "COURSE SECTION" (e.g., "BSIT 1A")
    final className = '${classData['course']} ${classData['section']}';

    // Format schedules - handle both single and multiple schedules
    String timeString = '';
    if (classData.containsKey('schedules') && classData['schedules'] is List) {
      final schedules = List<Map<String, dynamic>>.from(classData['schedules']);
      if (schedules.isNotEmpty) {
        // Check if all schedules have the same time
        final allSameTime = schedules.every(
          (s) =>
              s['startTime'] == schedules[0]['startTime'] &&
              s['endTime'] == schedules[0]['endTime'],
        );

        if (allSameTime && schedules.length > 1) {
          // Show as "Mon/Wed 9:00 AM - 10:30 AM"
          final days = schedules
              .map((s) => _getDayAbbreviation(s['day']))
              .join('/');
          timeString =
              '$days ${schedules[0]['startTime']} - ${schedules[0]['endTime']}';
        } else {
          // Show first schedule with indicator of more
          final firstSchedule = schedules[0];
          final dayAbbr = _getDayAbbreviation(firstSchedule['day']);
          timeString =
              '$dayAbbr ${firstSchedule['startTime']} - ${firstSchedule['endTime']}';
          if (schedules.length > 1) {
            timeString += ' (+${schedules.length - 1} more)';
          }
        }
      }
    } else {
      // Fallback to old format for backward compatibility
      final dayAbbr = _getDayAbbreviation(classData['day']);
      timeString =
          '$dayAbbr ${classData['startTime']} - ${classData['endTime']}';
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ClassDetailScreen(classData: classData),
          ),
        );
      },
      child: Container(
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
        child: Column(
          children: [
            // Header Section (Green) - Full Width Image
            Container(
              decoration: const BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Stack(
                children: [
                  Image.asset(
                    'assets/instructor/images/Group 1171274926.png',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    left: screenWidth < 768 ? 20 : 40,
                    bottom: screenWidth < 768 ? 10 : 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          className,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth < 768 ? 14 : 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          timeString,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth < 768 ? 10 : 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Content Section (White)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    // Divider - Full Width
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: Colors.grey.withOpacity(0.4),
                    ),
                    const SizedBox(height: 8),
                    // Action Icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Room info - show from schedules if available
                        Row(
                          children: [
                            Icon(
                              Icons.meeting_room_outlined,
                              color: Colors.black54,
                              size: 24,
                            ),
                            SizedBox(width: 10),
                            Text(
                              () {
                                if (classData.containsKey('schedules') &&
                                    classData['schedules'] is List) {
                                  final schedules =
                                      List<Map<String, dynamic>>.from(
                                        classData['schedules'],
                                      );
                                  if (schedules.isNotEmpty) {
                                    // Check if all rooms are the same
                                    final allSameRoom = schedules.every(
                                      (s) => s['room'] == schedules[0]['room'],
                                    );
                                    if (allSameRoom) {
                                      return schedules[0]['room'] ?? 'N/A';
                                    } else {
                                      // Different rooms - show first with indicator
                                      return '${schedules[0]['room'] ?? 'N/A'} (+more)';
                                    }
                                  }
                                }
                                return classData['room'] ?? 'N/A';
                              }(),
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        // Action buttons
                        Row(
                          children: [
                            // Edit button
                            if (!_showArchivedClasses)
                              GestureDetector(
                                onTap: () => _openEditClassDialog(classData),
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                ),
                              ),
                            if (!_showArchivedClasses) SizedBox(width: 8),
                            // Archive/Unarchive button
                            GestureDetector(
                              onTap:
                                  () =>
                                      _showArchivedClasses
                                          ? _unarchiveClass(classData)
                                          : _showArchiveConfirmation(classData),
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      _showArchivedClasses
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : Colors.orange.withValues(
                                            alpha: 0.1,
                                          ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _showArchivedClasses
                                      ? Icons.unarchive_outlined
                                      : Icons.archive_outlined,
                                  color:
                                      _showArchivedClasses
                                          ? Colors.green
                                          : Colors.orange,
                                  size: 20,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            // Delete button
                            GestureDetector(
                              onTap: () => _showDeleteConfirmation(classData),
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayAbbreviation(String day) {
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
}

class _DeleteConfirmationDialog extends StatelessWidget {
  final String className;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _DeleteConfirmationDialog({
    required this.className,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Delete Class',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onCancel,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- MESSAGE ---
              const Text(
                'Are you sure you want to delete this class?',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF34A853).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF34A853).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFF34A853),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        className,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF34A853),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'This action cannot be undone. All class data, including student records and assignments, will be permanently removed.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),

              const SizedBox(height: 32),

              // --- ACTION BUTTONS ---
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Delete Class',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArchiveConfirmationDialog extends StatelessWidget {
  final String className;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _ArchiveConfirmationDialog({
    required this.className,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.archive_outlined,
                          color: Colors.orange,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Archive Class',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onCancel,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- MESSAGE ---
              const Text(
                'Are you sure you want to archive this class?',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF34A853).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF34A853).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFF34A853),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        className,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF34A853),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'This class will be moved to the archive. You can restore it later if needed. The class will no longer appear in your active classes list.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),

              const SizedBox(height: 32),

              // --- ACTION BUTTONS ---
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Archive Class',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
