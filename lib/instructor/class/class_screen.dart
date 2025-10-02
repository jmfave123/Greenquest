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

  final TextEditingController _classNameController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  // Section and Day selection
  String? _selectedSectionId;
  String? _selectedDay;
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
      _selectedDay = null;
      _startTimeController.clear();
      _endTimeController.clear();
    });
  }

  void _createClass() {
    final room = _roomController.text.trim();
    final day = _selectedDay ?? "";
    final startTime = _startTimeController.text.trim();
    final endTime = _endTimeController.text.trim();

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

    // Get course information from selected section
    final selectedSection = _availableSections.firstWhere(
      (section) => section['id'] == _selectedSectionId,
      orElse: () => {},
    );

    final sectionCode = selectedSection['sectionCode'] ?? "";
    final courseCode = selectedSection['courseCode'] ?? "";

    if (room.isEmpty || day.isEmpty || startTime.isEmpty || endTime.isEmpty) {
      Get.snackbar("Error", "All fields are required!");
      return;
    }

    _classController.addClass(
      section: sectionCode,
      course: courseCode,
      room: room,
      day: day,
      startTime: startTime,
      endTime: endTime,
      sectionId: _selectedSectionId,
    );

    _hideCreateClassDialog();
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

  void _deleteClass(Map<String, dynamic> classData) {
    final classId = classData['id'];
    if (classId != null) {
      _classController.deleteClass(classId);
    }
    Navigator.of(context).pop(); // Close dialog
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
        _startTimeController.text = picked.format(context);
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
        _endTimeController.text = picked.format(context);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSections();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    await _classController.loadStudentsFromUsersCollection();
  }

  Future<void> _loadSections() async {
    setState(() {
      _isLoadingSections = true;
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
      setState(() {
        _isLoadingSections = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh classes when app comes back to foreground
      _classController.loadClasses();
    }
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
                            // Action Buttons Row
                            Row(
                              children: [
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
                                // ElevatedButton.icon(
                                //   onPressed: _loadStudents,
                                //   style: ElevatedButton.styleFrom(
                                //     backgroundColor: Colors.blue,
                                //     foregroundColor: Colors.white,
                                //     padding: const EdgeInsets.symmetric(
                                //       horizontal: 30,
                                //       vertical: 20,
                                //     ),
                                //     shape: RoundedRectangleBorder(
                                //       borderRadius: BorderRadius.circular(8),
                                //     ),
                                //   ),
                                //   icon: const Icon(Icons.refresh),
                                //   label: const Text(
                                //     'Refresh Students',
                                //     style: TextStyle(
                                //       fontSize: 16,
                                //       fontWeight: FontWeight.w600,
                                //     ),
                                //   ),
                                // ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            // Class Cards Grid
                            Expanded(
                              child: Obx(() {
                                if (_classController.isLoading.value) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF34A853),
                                      ),
                                    ),
                                  );
                                }

                                if (_classController.classes.isEmpty) {
                                  return const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.school_outlined,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'No classes found',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Create your first class to get started',
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
                                      itemCount:
                                          _classController.classes.length,
                                      itemBuilder: (context, index) {
                                        final classData =
                                            _classController.classes[index];
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
                      // Section Dropdown
                      Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34A853).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButton<String>(
                          borderRadius: BorderRadius.circular(15),
                          value: _selectedSectionId,
                          hint:
                              _isLoadingSections
                                  ? const Text(
                                    'Loading sections...',
                                    style: TextStyle(color: Colors.black45),
                                  )
                                  : _availableSections.isEmpty
                                  ? const Text(
                                    'No sections assigned',
                                    style: TextStyle(color: Colors.black45),
                                  )
                                  : const Text(
                                    'Select Section',
                                    style: TextStyle(color: Colors.black45),
                                  ),
                          isExpanded: true,
                          underline: Container(),
                          items:
                              _availableSections.map<DropdownMenuItem<String>>((
                                section,
                              ) {
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
                      // Room
                      TextField(
                        controller: _roomController,
                        cursorColor: Colors.black45,
                        decoration: InputDecoration(
                          hintText: 'Room',
                          hintStyle: const TextStyle(color: Colors.black45),
                          filled: true,
                          fillColor: const Color(0xFF34A853).withOpacity(0.15),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Day of Week Dropdown
                      Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34A853).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButton<String>(
                          borderRadius: BorderRadius.circular(15),
                          value: _selectedDay,
                          hint: const Text(
                            'Select Day',
                            style: TextStyle(color: Colors.black45),
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
                              _selectedDay = newValue;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Time Range Row
                      Row(
                        children: [
                          // Start Time
                          Expanded(
                            child: GestureDetector(
                              onTap: _selectStartTime,
                              child: AbsorbPointer(
                                child: TextField(
                                  controller: _startTimeController,
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
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // End Time
                          Expanded(
                            child: GestureDetector(
                              onTap: _selectEndTime,
                              child: AbsorbPointer(
                                child: TextField(
                                  controller: _endTimeController,
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
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
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
                      const SizedBox(height: 24),
                      // Action Buttons
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
                                        _selectedSectionId == null
                                    ? null
                                    : _createClass,
                            child: Text(
                              'Create',
                              style: TextStyle(
                                fontSize: 16,
                                color:
                                    _availableSections.isEmpty ||
                                            _selectedSectionId == null
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

    // Format the time as "DAY START_TIME - END_TIME" (e.g., "Wed 1:00 PM - 2:30 PM")
    final dayAbbr = _getDayAbbreviation(classData['day']);
    final timeString =
        '$dayAbbr ${classData['startTime']} - ${classData['endTime']}';

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
                        // Room info
                        Row(
                          children: [
                            Icon(
                              Icons.meeting_room_outlined,
                              color: Colors.black54,
                              size: 24,
                            ),
                            SizedBox(width: 10),
                            Text(
                              classData['room'] ?? 'N/A',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
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
