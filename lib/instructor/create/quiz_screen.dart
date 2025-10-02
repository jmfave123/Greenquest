import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'quiz_controller.dart';
import '../../../shared/instructor/instructor_appbar.dart';
import '../../../shared/instructor/instructor_sidebar.dart';
import '../../../shared/instructor/instructor_navigation_constants.dart';

class QuizScreen extends StatefulWidget {
  final String period;
  final bool isEdit;
  final String? itemId;
  final Map<String, dynamic>? initialData;

  const QuizScreen({
    super.key,
    required this.period,
    this.isEdit = false,
    this.itemId,
    this.initialData,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final QuizController _quizController = Get.put(QuizController());
  InstructorNavigationItem _selectedItem = InstructorNavigationItem.create;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _instructionController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController(
    text: '0',
  );
  final TextEditingController _dueDateController = TextEditingController();

  final TextEditingController _typeController = TextEditingController();

  List<Map<String, dynamic>> _questions = [];
  String? _currentInstructorId;

  void _handleNavigationSelect(InstructorNavigationItem item) {
    setState(() {
      _selectedItem = item;
    });
    String route = InstructorNavigationHelper.getRoute(item);
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentInstructor();
    if (widget.isEdit && widget.initialData != null) {
      _populateFields();
    }
  }

  Future<void> _loadCurrentInstructor() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentInstructorId = user.uid;
      });
    }
  }

  void _populateFields() {
    final data = widget.initialData!;
    _titleController.text = data['title'] ?? '';
    _instructionController.text = data['instruction'] ?? '';
    _dueDateController.text = data['dueDate'] ?? '';
    _typeController.text = data['topic'] ?? '';

    if (data['questions'] != null) {
      _questions = List<Map<String, dynamic>>.from(data['questions']);
      _updateOverallPoints();
    } else {
      _pointsController.text = '0';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _instructionController.dispose();
    _pointsController.dispose();
    _dueDateController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF34A853),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF34A853),
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        _dueDateController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year} ${time.format(context)}';
      }
    }
  }

  void _addQuestion() {
    setState(() {
      _questions.add({
        'question': '',
        'options': ['', '', '', ''],
        'correctAnswer': 0,
        'points': 10,
      });
      _updateOverallPoints();
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
      _updateOverallPoints();
    });
  }

  void _updateQuestion(int index, String field, dynamic value) {
    setState(() {
      _questions[index][field] = value;
      if (field == 'points') {
        _updateOverallPoints();
      }
    });
  }

  void _updateOverallPoints() {
    final totalPoints = _questions.fold<int>(
      0,
      (sum, question) => sum + (question['points'] as int? ?? 0),
    );
    _pointsController.text = totalPoints.toString();
  }

  void _createOrUpdateQuiz() {
    final title = _titleController.text.trim();
    final instruction = _instructionController.text.trim();
    final pointsText = _pointsController.text.trim();
    final dueDate = _dueDateController.text.trim();
    final topic = _typeController.text.trim();

    if (title.isEmpty ||
        pointsText.isEmpty ||
        dueDate.isEmpty ||
        _currentInstructorId == null) {
      Get.snackbar('Error', 'All fields are required!');
      return;
    }

    if (_questions.isEmpty) {
      Get.snackbar('Error', 'Please add at least one question!');
      return;
    }

    final points = int.tryParse(pointsText);
    if (points == null || points <= 0) {
      Get.snackbar('Error', 'Please enter a valid number of points!');
      return;
    }

    if (widget.isEdit && widget.itemId != null) {
      _quizController.updateQuiz(
        instructorId: _currentInstructorId!,
        quizId: widget.itemId!,
        title: title,
        instruction: instruction,
        points: points,
        dueDate: dueDate,
        topic: topic,
        period: widget.period,
        questions: _questions,
      );
    } else {
      _quizController.createQuiz(
        instructorId: _currentInstructorId!,
        title: title,
        instruction: instruction,
        points: points,
        dueDate: dueDate,
        topic: topic,
        period: widget.period,
        questions: _questions,
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                const InstructorAppBar(
                  instructorName: 'Instructor',
                  instructorRole: 'Instructor',
                ),
                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Quiz Management',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 32,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.isEdit
                                        ? 'Edit Quiz'
                                        : 'Create New Quiz',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              // Action Button
                              Obx(
                                () => ElevatedButton.icon(
                                  onPressed:
                                      _quizController.isLoading.value
                                          ? null
                                          : _createOrUpdateQuiz,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF34A853),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                  ),
                                  icon:
                                      _quizController.isLoading.value
                                          ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                          : const Icon(Icons.save),
                                  label: Text(
                                    widget.isEdit
                                        ? 'Update Quiz'
                                        : 'Create Quiz',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          // Quiz Details Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Quiz Details',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Form Fields in Grid Layout
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Left Column - Main Details
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Title
                                          const Text(
                                            'Quiz Title',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextField(
                                            controller: _titleController,
                                            cursorColor: const Color(
                                              0xFF34A853,
                                            ),
                                            decoration: _inputDecoration(
                                              'Enter quiz title',
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          // Instruction
                                          const Text(
                                            'Instructions',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextField(
                                            controller: _instructionController,
                                            cursorColor: const Color(
                                              0xFF34A853,
                                            ),
                                            maxLines: 4,
                                            decoration: _inputDecoration(
                                              'Enter quiz instructions (optional)',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    // Right Column - Settings
                                    Expanded(
                                      flex: 1,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Points
                                          const Text(
                                            'Total Points (Auto-calculated)',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextField(
                                            controller: _pointsController,
                                            cursorColor: const Color(
                                              0xFF34A853,
                                            ),
                                            keyboardType: TextInputType.number,
                                            readOnly: true,
                                            decoration: _inputDecoration(
                                              'Total points',
                                            ).copyWith(
                                              hintText: 'Auto-calculated',
                                              fillColor: const Color(
                                                0xFFF5F5F5,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          // Due Date
                                          const Text(
                                            'Due Date & Time',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          GestureDetector(
                                            onTap: _selectDueDate,
                                            child: AbsorbPointer(
                                              child: TextField(
                                                controller: _dueDateController,
                                                cursorColor: const Color(
                                                  0xFF34A853,
                                                ),
                                                decoration: _inputDecoration(
                                                  'Select Date & Time',
                                                ).copyWith(
                                                  suffixIcon: const Icon(
                                                    Icons.calendar_today,
                                                    color: Color(0xFF34A853),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          // Type
                                          const Text(
                                            'Type',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextField(
                                            controller: _typeController,
                                            cursorColor: const Color(
                                              0xFF34A853,
                                            ),
                                            decoration: _inputDecoration(
                                              'Enter type',
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          // Period (read-only)
                                          const Text(
                                            'Period',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF34A853,
                                              ).withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: const Color(
                                                  0xFF34A853,
                                                ).withValues(alpha: 0.3),
                                              ),
                                            ),
                                            child: Text(
                                              widget.period,
                                              style: const TextStyle(
                                                color: Color(0xFF34A853),
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Questions Section
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Quiz Questions',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: Colors.black,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: _addQuestion,
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text('Add Question'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF34A853,
                                        ),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // Questions List
                                if (_questions.isNotEmpty)
                                  ...List.generate(_questions.length, (index) {
                                    final question = _questions[index];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFB),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFE5E7EB),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Question ${index + 1}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              IconButton(
                                                onPressed:
                                                    () =>
                                                        _removeQuestion(index),
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                ),
                                                style: IconButton.styleFrom(
                                                  backgroundColor: Colors.red
                                                      .withValues(alpha: 0.1),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          TextField(
                                            onChanged:
                                                (value) => _updateQuestion(
                                                  index,
                                                  'question',
                                                  value,
                                                ),
                                            cursorColor: const Color(
                                              0xFF34A853,
                                            ),
                                            decoration: _inputDecoration(
                                              'Enter question text',
                                            ),
                                            maxLines: 2,
                                          ),
                                          const SizedBox(height: 16),
                                          const Text(
                                            'Answer Options:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          ...List.generate(4, (optionIndex) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 12,
                                              ),
                                              child: Row(
                                                children: [
                                                  Radio<int>(
                                                    value: optionIndex,
                                                    groupValue:
                                                        question['correctAnswer'],
                                                    onChanged:
                                                        (value) =>
                                                            _updateQuestion(
                                                              index,
                                                              'correctAnswer',
                                                              value,
                                                            ),
                                                    activeColor: const Color(
                                                      0xFF34A853,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: TextField(
                                                      onChanged: (value) {
                                                        final options = List<
                                                          String
                                                        >.from(
                                                          question['options'],
                                                        );
                                                        options[optionIndex] =
                                                            value;
                                                        _updateQuestion(
                                                          index,
                                                          'options',
                                                          options,
                                                        );
                                                      },
                                                      cursorColor: const Color(
                                                        0xFF34A853,
                                                      ),
                                                      decoration: _inputDecoration(
                                                        'Option ${optionIndex + 1}',
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              const Text(
                                                'Points: ',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 80,
                                                child: TextField(
                                                  onChanged:
                                                      (value) =>
                                                          _updateQuestion(
                                                            index,
                                                            'points',
                                                            int.tryParse(
                                                                  value,
                                                                ) ??
                                                                10,
                                                          ),
                                                  cursorColor: const Color(
                                                    0xFF34A853,
                                                  ),
                                                  keyboardType:
                                                      TextInputType.number,
                                                  decoration: _inputDecoration(
                                                    '10',
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                if (_questions.isEmpty)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(40),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFB),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFE5E7EB),
                                        style: BorderStyle.solid,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.quiz_outlined,
                                          size: 48,
                                          color: Colors.grey.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No questions added yet',
                                          style: TextStyle(
                                            color: Colors.grey.withValues(
                                              alpha: 0.7,
                                            ),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Click "Add Question" to start building your quiz',
                                          style: TextStyle(
                                            color: Colors.grey.withValues(
                                              alpha: 0.5,
                                            ),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
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
        ],
      ),
    );
  }

  // Helper method for input decoration
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black45),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF34A853), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
