import 'package:flutter/material.dart';
import '../../shared/instructor/instructor_appbar.dart';
import '../../shared/instructor/instructor_sidebar.dart';

class AssignmentScreen extends StatefulWidget {
  const AssignmentScreen({super.key});

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  int _selectedSidebarIndex = 1; // Create index
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _instructionController = TextEditingController();
  String _selectedClass = 'BSIT-A';
  final TextEditingController _pointsController = TextEditingController(text: '100');
  DateTime? _selectedDueDate;
  String _selectedTopic = 'No Topic';
  bool _showForDropdown = false;
  bool _showTopicDropdown = false;
  bool _showTitleError = false;

  final List<String> _classes = ['BSIT-A', 'BSIT-B', 'BSIT-C'];
  final List<String> _topics = ['No Topic', 'Programming', 'Database', 'Web Development'];
  final Map<String, bool> _selectedClasses = {
    'BSIT-A': false,
    'BSIT-B': false,
    'BSIT-C': false,
  };

  void _handleSidebarSelection(int index) {
    setState(() {
      _selectedSidebarIndex = index;
    });
  }

  void _toggleClassSelection(String className) {
    setState(() {
      _selectedClasses[className] = !_selectedClasses[className]!;
    });
  }

  void _toggleForDropdown() {
    setState(() {
      _showForDropdown = !_showForDropdown;
      if (_showForDropdown) {
        _showTopicDropdown = false;
      }
    });
  }



  void _toggleTopicDropdown() {
    setState(() {
      _showTopicDropdown = !_showTopicDropdown;
      if (_showTopicDropdown) {
        _showForDropdown = false;
      }
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

  void _postAssignment() {
    // Here you would typically send the data to your backend
    // For now, we'll just show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Assignment posted successfully!'),
        backgroundColor: Color(0xFF34A853),
      ),
    );
    
    // Clear the form
    _titleController.clear();
    _instructionController.clear();
    setState(() {
      _showTitleError = false;
    });
  }

  void _applyFormatting(String format) {
    final TextEditingController controller = _instructionController;
    final TextSelection selection = controller.selection;
    
    if (selection.isCollapsed) {
      // No text selected, just apply to cursor position
      return;
    }

    final String selectedText = selection.textInside(controller.text);
    String formattedText = selectedText;
    
    switch (format) {
      case 'bold':
        formattedText = '**$selectedText**';
        break;
      case 'italic':
        formattedText = '*$selectedText*';
        break;
      case 'underline':
        formattedText = '__${selectedText}__';
        break;
      case 'bullet':
        formattedText = '• $selectedText';
        break;
      case 'number':
        formattedText = '1. $selectedText';
        break;
    }

    final String newText = controller.text.replaceRange(
      selection.start,
      selection.end,
      formattedText,
    );

    controller.text = newText;
    controller.selection = TextSelection.collapsed(
      offset: selection.start + formattedText.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
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
                const InstructorAppBar(instructorName: '',),
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => Navigator.of(context).pop(),
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
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Post',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
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
                                cursorColor: Colors.black54,
                                onChanged: (value) {
                                  if (_showTitleError && value.trim().isNotEmpty) {
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
                                      color: _showTitleError ? Colors.red : const Color(0xFF9E9E9E),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: _showTitleError ? Colors.red : const Color(0xFF9E9E9E),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFF34A853)),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                cursorColor: Colors.black54,
                                onChanged: (value) {
                                  // No validation needed for instruction
                                },
                                decoration: InputDecoration(
                                  hintText: 'Instruction (optional)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFF9E9E9E)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFF9E9E9E)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFF34A853)),
                                  ),
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                              ),

                              const SizedBox(height: 10),
                              // Formatting Toolbar
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      onPressed: () => _applyFormatting('bold'),
                                      icon: const Icon(
                                        Icons.format_bold,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _applyFormatting('italic'),
                                      icon: const Icon(
                                        Icons.format_italic,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _applyFormatting('underline'),
                                      icon: const Icon(
                                        Icons.format_underline,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    IconButton(
                                      onPressed: () => _applyFormatting('bullet'),
                                      icon: const Icon(Icons.format_list_bulleted, color: Colors.black54),
                                    ),
                                    IconButton(
                                      onPressed: () => _applyFormatting('number'),
                                      icon: const Icon(Icons.format_list_numbered, color: Colors.black54),
                                    ),
                                    const SizedBox(width: 16),
                                    IconButton(
                                      onPressed: () {
                                        _instructionController.clear();
                                      },
                                      icon: const Icon(Icons.clear, color: Colors.black54),
                                    ),
                                  ],
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
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildAttachOption('Drive', 'assets/instructor/images/image 362.png'),
                                  const SizedBox(width: 16),
                                  _buildAttachOption('YouTube', 'assets/instructor/images/image 363.png'),
                                  const SizedBox(width: 16),
                                  _buildAttachOption('Create', 'assets/instructor/images/image 364.png'),
                                  const SizedBox(width: 16),
                                  _buildAttachOption('Upload', 'assets/instructor/images/material-symbols-light_upload.png'),
                                  const SizedBox(width: 16),
                                  _buildAttachOption('Link', 'assets/instructor/images/iconamoon_link-light.png'),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: _showForDropdown 
                                            ? const Color(0xFF34A853)
                                            : const Color(0xFF9E9E9E),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                      border: Border.all(color: const Color(0xFF9E9E9E)),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: _classes.map((className) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: _selectedClasses[className],
                                              onChanged: (bool? value) {
                                                _toggleClassSelection(className);
                                              },
                                              activeColor: const Color(0xFF34A853),
                                            ),
                                            Text(
                                              className,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )).toList(),
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
                                      borderSide: const BorderSide(color: Color(0xFF9E9E9E)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFF9E9E9E)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFF34A853)),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFF9E9E9E)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _selectedDueDate != null
                                              ? '${_selectedDueDate!.month}/${_selectedDueDate!.day}/${_selectedDueDate!.year}'
                                              : 'MM/DD/YYYY',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: _selectedDueDate != null ? Colors.black : Colors.grey,
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
                                // Topic Dropdown
                                const Text(
                                  'Topic',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _toggleTopicDropdown,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: _showTopicDropdown 
                                            ? const Color(0xFF34A853)
                                            : const Color(0xFF9E9E9E),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _selectedTopic,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Icon(
                                          _showTopicDropdown 
                                              ? Icons.keyboard_arrow_up
                                              : Icons.keyboard_arrow_down,
                                          color: Colors.black54,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Topic dropdown options
                                if (_showTopicDropdown)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: const Color(0xFF9E9E9E)),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: _topics.map((topic) => GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedTopic = topic;
                                            _showTopicDropdown = false;
                                          });
                                        },
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          child: Text(
                                            topic,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      )).toList(),
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
          child: Center(
            child: Image.asset(
              iconPath,
              width: 24,
              height: 24,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
} 