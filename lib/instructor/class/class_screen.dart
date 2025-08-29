// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../shared/instructor/instructor_appbar.dart';
import '../../shared/instructor/instructor_sidebar.dart';
import 'class_detail_screen.dart';

class ClassScreen extends StatefulWidget {
  const ClassScreen({super.key});

  @override
  State<ClassScreen> createState() => _ClassScreenState();
}

class _ClassScreenState extends State<ClassScreen> {
  int _selectedSidebarIndex = 2; // Class index
  bool _showCreateClassDialog = false;
  
  final TextEditingController _classNameController = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  
  // Day of week selection
  String? _selectedDay;
  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday', 
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  // Sample class data
  final List<Map<String, dynamic>> _classes = [
    {
      'name': 'BSIT 1A-NSTP',
      'time': 'Wed 1:00 PM - 2:30 PM',
      'students': 25,
      'subject': 'NSTP',
    },
    {
      'name': 'BFPT 1A-NSTP',
      'time': 'Thu 9:00 AM - 10:30 AM',
      'students': 30,
      'subject': 'NSTP',
    },
    {
      'name': 'ICT 1A-NSTP',
      'time': 'Fri 2:00 PM - 3:30 PM',
      'students': 28,
      'subject': 'NSTP',
    },
    {
      'name': 'IA 1A-NSTP',
      'time': 'Mon 10:00 AM - 11:30 AM',
      'students': 22,
      'subject': 'NSTP',
    },
  ];

  void _handleSidebarSelection(int index) {
    setState(() {
      _selectedSidebarIndex = index;
    });
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
      _sectionController.clear();
      _subjectController.clear();
      _roomController.clear();
    });
  }

  void _createClass() {
    // Validate form with specific error messages
    String errorMessage = '';
    
    if (_classNameController.text.trim().isEmpty) {
      errorMessage = 'Please enter section';
    } else if (_subjectController.text.trim().isEmpty) {
      errorMessage = 'Please enter subject';
    } else if (_roomController.text.trim().isEmpty) {
      errorMessage = 'Please enter room';
    }  else if (_startTimeController.text.trim().isEmpty) {
      errorMessage = 'Please select start time';
    } else if (_endTimeController.text.trim().isEmpty) {
      errorMessage = 'Please select end time';
    }
    
    if (errorMessage.isNotEmpty) {
      // Debug: Print all controller values
      print('Debug - Controller values:');
      print('Class Name: "${_classNameController.text}"');
      print('Section: "${_sectionController.text}"');
      print('Subject: "${_subjectController.text}"');
      print('Room: "${_roomController.text}"');
      print('Day: "$_selectedDay"');
      print('Start Time: "${_startTimeController.text}"');
      print('End Time: "${_endTimeController.text}"');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Add class to the list
    setState(() {
      _classes.add({
        'name': _classNameController.text,
        'section': _sectionController.text,
        'subject': _subjectController.text,
              'room': _roomController.text,
      'day': _selectedDay,
      'time': '${_startTimeController.text} - ${_endTimeController.text}',
      });
    });

    // Clear controllers
    _classNameController.clear();
    _sectionController.clear();
    _subjectController.clear();
    _roomController.clear();
    _startTimeController.clear();
    _endTimeController.clear();

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Class created successfully!'),
        backgroundColor: Color(0xFF34A853),
      ),
    );
    
    _hideCreateClassDialog();
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              // Sidebar
              InstructorSidebar(
                selectedIndex: _selectedSidebarIndex,
                onItemSelected: _handleSidebarSelection,
              ),
              // Main Content
              Expanded(
                child: Column(
                  children: [
                    // App Bar
                    const InstructorAppBar(
                      instructorName: 'Mia Castro',
                      instructorRole: 'Instructor',
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
                            // Create Class Button
                                                         ElevatedButton.icon(
                               onPressed: _openCreateClassDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF34A853),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
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
                            const SizedBox(height: 32),
                            // Class Cards Grid
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  // Determine grid layout based on screen width
                                  double screenWidth = MediaQuery.of(context).size.width;
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
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: screenWidth < 768 ? 16 : 20,
                                      mainAxisSpacing: screenWidth < 768 ? 16 : 20,
                                      childAspectRatio: childAspectRatio,
                                    ),
                                    itemCount: _classes.length,
                                    itemBuilder: (context, index) {
                                      final classData = _classes[index];
                                      return _buildClassCard(classData, screenWidth);
                                    },
                                  );
                                },
                              ),
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
                  width: MediaQuery.of(context).size.width < 768 ? MediaQuery.of(context).size.width * 0.9 : 500,
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width < 768 ? 20 : 30, 
                    vertical: MediaQuery.of(context).size.width < 768 ? 16 : 20
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
                      // Section
                      TextField(
                        controller: _sectionController,
                        cursorColor: Colors.black45,
                        decoration: InputDecoration(
                          hintText: 'Section',
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Course
                      TextField(
                        controller: _subjectController,
                        cursorColor: Colors.black45,
                        decoration: InputDecoration(
                          hintText: 'Course',
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Day of Week Dropdown
                      Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
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
                          items: _daysOfWeek.map((String day) {
                            return DropdownMenuItem<String>(
                              value: day,
                              child: Text(
                                day,
                                style: const TextStyle(color: Colors.black87),
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
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            onPressed: _createClass,
                            child: const Text(
                              'Create',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF34A853),
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
                          classData['name'],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth < 768 ? 14 : 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          classData['time'],
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
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                     Icon(Icons.meeting_room_outlined, color: Colors.black54, size: 24,),
                     SizedBox(width: 10,),
                     Text('MSC01', style: TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.bold),),
                    ],

                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),);
  }
} 