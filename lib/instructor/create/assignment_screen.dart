import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/instructor/instructor_appbar.dart';
import '../../shared/instructor/instructor_sidebar.dart';
import '../../shared/instructor/instructor_navigation_constants.dart';
import 'create_controller.dart';

class AssignmentScreen extends StatefulWidget {
  final String? period;
  final bool isEdit;
  final String? itemId;
  final Map<String, dynamic>? initialData;

  const AssignmentScreen({
    super.key,
    this.period,
    this.isEdit = false,
    this.itemId,
    this.initialData,
  });

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  final CreateController _createController = Get.find<CreateController>();
  InstructorNavigationItem _selectedItem = InstructorNavigationItem.create;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _instructionController = TextEditingController();
  String _selectedClass = 'BSIT-A';
  final TextEditingController _pointsController = TextEditingController(
    text: '100',
  );
  DateTime? _selectedDueDate;
  String _selectedTopic = 'No Topic';
  bool _showForDropdown = false;
  bool _showTitleError = false;

  final List<String> _classes = ['BSIT-A', 'BSIT-B', 'BSIT-C'];
  final Map<String, bool> _selectedClasses = {
    'BSIT-A': false,
    'BSIT-B': false,
    'BSIT-C': false,
  };

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.initialData != null) {
      _loadInitialData();
    }
  }

  void _loadInitialData() {
    final data = widget.initialData!;
    _titleController.text = data['title'] ?? '';
    _instructionController.text = data['instruction'] ?? '';
    _pointsController.text = data['points'] ?? '100';
    _selectedTopic = data['topic'] ?? 'No Topic';

    // Set selected classes
    if (data['selectedClasses'] != null) {
      for (String className in data['selectedClasses']) {
        if (_selectedClasses.containsKey(className)) {
          _selectedClasses[className] = true;
        }
      }
    }

    // Set due date
    if (data['dueDate'] != null) {
      _selectedDueDate = DateTime.parse(data['dueDate']);
    }
  }

  void _handleNavigationSelect(InstructorNavigationItem item) {
    setState(() {
      _selectedItem = item;
    });
    String route = InstructorNavigationHelper.getRoute(item);
    Navigator.of(context).pushReplacementNamed(route);
  }

  void _toggleClassSelection(String className) {
    setState(() {
      _selectedClasses[className] = !_selectedClasses[className]!;
    });
  }

  void _toggleForDropdown() {
    setState(() {
      _showForDropdown = !_showForDropdown;
    });
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF34A853), // Green color for the calendar
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  void _validateAndPost() {
    setState(() {
      _showTitleError = _titleController.text.trim().isEmpty;
    });

    if (!_showTitleError) {
      // Proceed with posting
      _postAssignment();
    }
  }

  Future<void> _postAssignment() async {
    if (_selectedDueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a due date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get selected classes
    List<String> selectedClasses =
        _selectedClasses.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();

    if (selectedClasses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one class'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.isEdit && widget.itemId != null) {
      // Update existing assignment
      final success = await _createController.updateAssignment(
        assignmentId: widget.itemId!,
        title: _titleController.text.trim(),
        instruction: _instructionController.text.trim(),
        selectedClasses: selectedClasses,
        points: _pointsController.text.trim(),
        dueDate: _selectedDueDate!,
        topic: _selectedTopic,
        period: widget.period,
      );

      if (success) {
        Navigator.of(context).pop();
      }
    } else {
      // Create new assignment
      final success = await _createController.createAssignment(
        title: _titleController.text.trim(),
        instruction: _instructionController.text.trim(),
        selectedClasses: selectedClasses,
        points: _pointsController.text.trim(),
        dueDate: _selectedDueDate!,
        topic: _selectedTopic,
        period: widget.period,
      );

      if (success) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
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
                // App Bar
                const InstructorAppBar(instructorName: ''),
                // Main Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main Form Area
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap:
                                            () => Navigator.of(context).pop(),
                                        child: const Icon(
                                          Icons.arrow_back,
                                          size: 24,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Assignment',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton(
                                    onPressed: _validateAndPost,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF34A853),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 15,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Obx(
                                      () =>
                                          _createController.isLoading.value
                                              ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              )
                                              : Text(
                                                widget.isEdit
                                                    ? 'Update'
                                                    : 'Post',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              // Title Field
                              const Text(
                                'Title',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _titleController,
                                cursorColor: const Color(0xFF34A853),
                                onChanged: (value) {
                                  if (_showTitleError &&
                                      value.trim().isNotEmpty) {
                                    setState(() {
                                      _showTitleError = false;
                                    });
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: 'Title',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color:
                                          _showTitleError
                                              ? Colors.red
                                              : const Color(0xFF9E9E9E),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color:
                                          _showTitleError
                                              ? Colors.red
                                              : const Color(0xFF9E9E9E),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF34A853),
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (_showTitleError)
                                const Text(
                                  'Title is required',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                  ),
                                ),
                              const SizedBox(height: 24),
                              // Instruction Field
                              const Text(
                                'Instruction',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _instructionController,
                                maxLines: 6,
                                cursorColor: const Color(0xFF34A853),
                                onChanged: (value) {
                                  // No validation needed for instruction
                                },
                                decoration: InputDecoration(
                                  hintText: 'Instruction (optional)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF9E9E9E),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF9E9E9E),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF34A853),
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                              ),

                              const SizedBox(height: 32),
                              // Attach Section
                              const Text(
                                'Attach',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  _buildAttachOption(
                                    'Upload',
                                    'assets/instructor/images/material-symbols-light_upload.png',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        // Right Panel
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.15,
                          height: double.infinity,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: const BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: Colors.black12,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Assignment Details',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  // For Dropdown
                                  const Text(
                                    'For',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: _toggleForDropdown,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color:
                                              _showForDropdown
                                                  ? const Color(0xFF34A853)
                                                  : const Color(0xFF9E9E9E),
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _selectedClass,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black,
                                            ),
                                          ),
                                          Icon(
                                            _showForDropdown
                                                ? Icons.keyboard_arrow_up
                                                : Icons.keyboard_arrow_down,
                                            color: Colors.black54,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Dropdown options
                                  if (_showForDropdown)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                          color: const Color(0xFF9E9E9E),
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.1,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children:
                                            _classes
                                                .map(
                                                  (className) => Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                          vertical: 8,
                                                        ),
                                                    child: Row(
                                                      children: [
                                                        Checkbox(
                                                          value:
                                                              _selectedClasses[className],
                                                          onChanged: (
                                                            bool? value,
                                                          ) {
                                                            _toggleClassSelection(
                                                              className,
                                                            );
                                                          },
                                                          activeColor:
                                                              const Color(
                                                                0xFF34A853,
                                                              ),
                                                        ),
                                                        Text(
                                                          className,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 14,
                                                                color:
                                                                    Colors
                                                                        .black,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                      ),
                                    ),
                                  const SizedBox(height: 15),

                                  // Points Input
                                  const Text(
                                    'Points',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _pointsController,
                                    keyboardType: TextInputType.number,
                                    cursorColor: Colors.black54,
                                    decoration: InputDecoration(
                                      hintText: 'Enter points',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF9E9E9E),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF9E9E9E),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF34A853),
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  // Due Date & Time
                                  const Text(
                                    'Due date & time',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: _selectDueDate,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFF9E9E9E),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _selectedDueDate != null
                                                ? '${_selectedDueDate!.month}/${_selectedDueDate!.day}/${_selectedDueDate!.year}'
                                                : 'MM/DD/YYYY',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  _selectedDueDate != null
                                                      ? Colors.black
                                                      : Colors.grey,
                                            ),
                                          ),
                                          const Icon(
                                            Icons.calendar_today,
                                            color: Colors.black54,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  // Type Field
                                  const Text(
                                    'Type',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: TextEditingController(
                                      text: _selectedTopic,
                                    ),
                                    cursorColor: const Color(0xFF34A853),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedTopic = value;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Enter type',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF9E9E9E),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF9E9E9E),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF34A853),
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachOption(String label, String iconPath) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF9E9E9E)),
          ),
          child: Center(child: Image.asset(iconPath, width: 24, height: 24)),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }
}
