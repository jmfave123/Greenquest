import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/instructor/instructor_sidebar.dart';
import '../../shared/instructor/instructor_navigation_constants.dart';
import '../../shared/responsive/responsive_layout.dart';
import '../../shared/controllers/file_submission_controller.dart';
import '../../shared/services/instructor_class_service.dart';
import '../../shared/widgets/skeleton_loading.dart';
import '../topics/topic_controller.dart';
import 'create_controller.dart';

class PITScreen extends StatefulWidget {
  final String? period;
  final bool isEdit;
  final String? itemId;
  final Map<String, dynamic>? initialData;

  const PITScreen({
    super.key,
    this.period,
    this.isEdit = false,
    this.itemId,
    this.initialData,
  });

  @override
  State<PITScreen> createState() => _PITScreenState();
}

class _PITScreenState extends State<PITScreen> {
  final CreateController _createController = Get.find<CreateController>();
  final FileSubmissionController _fileController = Get.put(
    FileSubmissionController(),
  );
  final TopicController _topicController = Get.put(TopicController());
  InstructorNavigationItem _selectedItem = InstructorNavigationItem.create;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _instructionController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController(
    text: '100',
  );
  DateTime? _selectedDueDate;
  String _selectedCategory = 'pit';
  bool _showForDropdown = false;
  bool _showCategoryDropdown = false;
  bool _showTitleError = false;

  // Topic selection
  String? _selectedTopicId;
  String? _selectedTopicName;

  List<String> _classes = [];
  Map<String, bool> _selectedClasses = {};
  bool _isLoadingClasses = true;

  // Excel category options
  final Map<String, String> _categories = {
    'class_standing': 'Class Standing Performance Items (10%)',
    'quiz_prelim': 'Quiz/Prelim Performance Item (40%)',
    'midterm_exam': 'Midterm Exam (10%)',
    'final_exam': 'Final Exam (10%)',
    'pit': 'Per Inno Task (20%)',
  };

  @override
  void initState() {
    super.initState();

    // Load topics from Firestore
    _topicController.loadTopics();

    // Clear files when creating a new item (not editing)
    if (!widget.isEdit) {
      _fileController.clearFiles();
    }

    _loadInstructorClasses().then((_) {
      if (widget.isEdit && widget.initialData != null) {
        _loadInitialData();
      } else {
        // Auto-update category based on period for new items
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateCategoryBasedOnPeriod();
        });
      }
    });
  }

  Future<void> _loadInstructorClasses() async {
    setState(() {
      _isLoadingClasses = true;
    });

    try {
      // Load section codes from instructor's assignments
      final sectionCodes =
          await InstructorClassService.getInstructorSectionCodes();

      if (sectionCodes.isNotEmpty) {
        _classes = sectionCodes;
        _selectedClasses = Map.fromEntries(
          _classes.map((e) => MapEntry(e, false)),
        );
        print('✅ Loaded ${_classes.length} instructor classes: $_classes');
      } else {
        // Fallback to static classes if no assignments found
        _classes = InstructorClassService.getFallbackClasses();
        _selectedClasses = Map.fromEntries(
          _classes.map((e) => MapEntry(e, false)),
        );
        print('⚠️ No assignments found, using fallback classes: $_classes');
      }
    } catch (e) {
      // Fallback to static classes on error
      _classes = InstructorClassService.getFallbackClasses();
      _selectedClasses = Map.fromEntries(
        _classes.map((e) => MapEntry(e, false)),
      );
      print('❌ Error loading classes, using fallback: $e');
    } finally {
      setState(() {
        _isLoadingClasses = false;
      });
    }
  }

  void _loadInitialData() {
    final data = widget.initialData!;
    setState(() {
      _titleController.text = data['title'] ?? '';
      _instructionController.text = data['instruction'] ?? '';
      _pointsController.text = data['points'] ?? '100';

      // Set selected classes
      if (data['selectedClasses'] != null) {
        for (String className in data['selectedClasses']) {
          if (_selectedClasses.containsKey(className)) {
            _selectedClasses[className] = true;
          }
        }
      }

      // Set due date - prefer raw date, fallback to formatted string
      final dueDateValue = data['dueDateRaw'] ?? data['dueDate'];
      if (dueDateValue != null) {
        try {
          // Handle both DateTime objects and ISO string formats
          if (dueDateValue is DateTime) {
            _selectedDueDate = dueDateValue;
          } else if (dueDateValue is Timestamp) {
            _selectedDueDate = dueDateValue.toDate();
          } else if (dueDateValue is String) {
            // Try parsing ISO string format
            _selectedDueDate = DateTime.parse(dueDateValue);
          }
        } catch (e) {
          print('Error parsing due date: $e');
          _selectedDueDate = null;
        }
      }

      // Set category if available
      if (data['category'] != null) {
        String category = data['category'] as String;
        // Auto-update category based on period
        if (widget.period == 'Final' && category == 'midterm_exam') {
          category = 'final_exam';
        } else if (widget.period != 'Final' && category == 'final_exam') {
          category = 'midterm_exam';
        }
        _selectedCategory = category;
      }

      // Auto-update category if period is Final and category is midterm_exam
      if (widget.period == 'Final' && _selectedCategory == 'midterm_exam') {
        _selectedCategory = 'final_exam';
      }

      // Load topic data - handle null, empty, and "null" string
      final topicId = data['topicId'];
      final topicName = data['topicName'];

      // Only set topic if it has a valid value (not null, not empty, not string "null")
      if (topicId != null && topicId != '' && topicId != 'null') {
        _selectedTopicId = topicId;
      } else {
        _selectedTopicId = null;
      }

      if (topicName != null && topicName != '' && topicName != 'null') {
        _selectedTopicName = topicName;
      } else {
        _selectedTopicName = null;
      }
    });
  }

  // Method to update category based on period
  void _updateCategoryBasedOnPeriod() {
    if (widget.period == 'Final') {
      // If period is Final and category is midterm_exam, change to final_exam
      if (_selectedCategory == 'midterm_exam') {
        setState(() {
          _selectedCategory = 'final_exam';
        });
      }
    } else if (widget.period == 'Prelim' || widget.period == 'Midterm') {
      // If period is Prelim or Midterm and category is final_exam, change to midterm_exam
      if (_selectedCategory == 'final_exam') {
        setState(() {
          _selectedCategory = 'midterm_exam';
        });
      }
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

  String _getSelectedClassesText() {
    if (_classes.isEmpty) {
      return 'No classes available';
    }

    final selectedClasses =
        _selectedClasses.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();

    if (selectedClasses.isEmpty) {
      return 'Select classes';
    } else if (selectedClasses.length == 1) {
      return selectedClasses.first;
    } else {
      return '${selectedClasses.length} classes selected';
    }
  }

  void _toggleForDropdown() {
    setState(() {
      _showForDropdown = !_showForDropdown;
    });
  }

  void _toggleCategoryDropdown() {
    setState(() {
      _showCategoryDropdown = !_showCategoryDropdown;
    });
  }

  Future<void> _showCreateTopicDialog() async {
    final TextEditingController topicController = TextEditingController();

    await showDialog<bool>(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create topic',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: topicController,
                    decoration: InputDecoration(
                      labelText: 'Topic name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF34A853)),
                      ),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          final topicName = topicController.text.trim();
                          if (topicName.isEmpty) {
                            Get.snackbar(
                              'Error',
                              'Please enter a topic name',
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                            return;
                          }

                          if (_topicController.topicExists(topicName)) {
                            Get.snackbar(
                              'Error',
                              'A topic with this name already exists',
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                            return;
                          }

                          final newTopic = await _topicController.createTopic(
                            topicName: topicName,
                          );

                          if (newTopic != null) {
                            Navigator.of(context).pop(true);
                            Get.snackbar(
                              'Success',
                              'Topic created',
                              backgroundColor: const Color(0xFF34A853),
                              colorText: Colors.white,
                            );

                            setState(() {
                              _selectedTopicId = newTopic.id;
                              _selectedTopicName = newTopic.topic;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF34A853),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Create'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _selectDueDate() async {
    // First, select the date
    // Allow past dates when editing (in case existing due date is in the past)
    final now = DateTime.now();
    final minDate =
        widget.isEdit &&
                _selectedDueDate != null &&
                _selectedDueDate!.isBefore(now)
            ? _selectedDueDate!.subtract(const Duration(days: 365))
            : now;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: minDate,
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

    if (pickedDate != null) {
      // Then, select the time
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime:
            _selectedDueDate != null
                ? TimeOfDay.fromDateTime(_selectedDueDate!)
                : TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF34A853), // Green color for the time picker
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        // Combine date and time
        final DateTime combinedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          _selectedDueDate = combinedDateTime;
        });
      }
    }
  }

  Future<void> _validateAndSubmit() async {
    setState(() {
      _showTitleError = _titleController.text.trim().isEmpty;
    });

    if (_showTitleError) {
      Get.snackbar(
        'Error',
        'Please enter a title for the PIT',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final selectedClassesList =
        _selectedClasses.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();

    if (selectedClassesList.isEmpty) {
      Get.snackbar(
        'Error',
        'Please select at least one class',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (_selectedDueDate == null) {
      Get.snackbar(
        'Error',
        'Please select a due date',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Upload files if any are selected
    List<String> attachmentUrls = [];
    if (_fileController.selectedFiles.isNotEmpty) {
      try {
        // Show loading indicator
        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );

        // Upload files
        final uploadSuccess = await _fileController.uploadFiles(
          folder: 'greenquest/pits',
          tags: {'type': 'pit', 'period': widget.period ?? 'current'},
        );

        // Close loading dialog
        Get.back();

        if (uploadSuccess) {
          // Get uploaded file URLs
          attachmentUrls =
              _fileController.uploadedFiles
                  .map((file) => file['url'] as String)
                  .toList();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload files. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      } catch (e) {
        // Close loading dialog
        Get.back();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading files: $e'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Auto-update category based on period before saving
    String categoryToSave = _selectedCategory;
    if (widget.period == 'Final' && categoryToSave == 'midterm_exam') {
      categoryToSave = 'final_exam';
    } else if (widget.period != 'Final' && categoryToSave == 'final_exam') {
      categoryToSave = 'midterm_exam';
    }

    if (widget.isEdit && widget.itemId != null) {
      // Update existing PIT
      final success = await _createController.updatePIT(
        pitId: widget.itemId!,
        title: _titleController.text.trim(),
        instruction: _instructionController.text.trim(),
        selectedClasses: selectedClassesList,
        points: _pointsController.text.trim(),
        dueDate: _selectedDueDate!,
        period: widget.period,
        category: categoryToSave,
        attachments: attachmentUrls,
        topicId: _selectedTopicId,
        topicName: _selectedTopicName,
      );

      if (success) {
        // Clear files and reset form after successful update
        _fileController.clearFiles();
        Navigator.of(context).pop();
      }
    } else {
      final success = await _createController.createPIT(
        title: _titleController.text.trim(),
        instruction: _instructionController.text.trim(),
        selectedClasses: selectedClassesList,
        points: _pointsController.text.trim(),
        dueDate: _selectedDueDate!,
        period: widget.period,
        category: categoryToSave,
        attachments: attachmentUrls,
        topicId: _selectedTopicId,
        topicName: _selectedTopicName,
      );

      if (success) {
        // Clear files and reset form after successful creation
        _fileController.clearFiles();
        _resetForm();
        Navigator.of(context).pop();
      }
    }
  }

  void _resetForm() {
    setState(() {
      _titleController.clear();
      _instructionController.clear();
      _pointsController.text = '100';
      _selectedDueDate = null;
      _selectedCategory = 'pit';
      _selectedClasses = Map.fromEntries(
        _classes.map((e) => MapEntry(e, false)),
      );
      _showTitleError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      sidebar: InstructorSidebar(
        selectedItem: _selectedItem,
        onItemSelected: _handleNavigationSelect,
      ),
      mainContent: _buildMainContent(),
      rightPanel: _buildRightPanel(),
      screenTitle: 'PIT',
      onBackPressed: () => Navigator.of(context).pop(),
      actionButton: _buildActionButton(),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Field
          ResponsiveFormField(
            label: 'Title',
            controller: _titleController,
            hintText: 'Title',
            isRequired: true,
            showError: _showTitleError,
            errorText: _showTitleError ? 'Title is required' : null,
            onChanged: (value) {
              if (_showTitleError && value.trim().isNotEmpty) {
                setState(() {
                  _showTitleError = false;
                });
              }
            },
          ),
          const SizedBox(height: 24),
          // Topic Selector
          const Text(
            'Topic',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Obx(() {
            final topics = _topicController.topics;
            return DropdownButtonFormField<String>(
              value: _selectedTopicName,
              isExpanded: true,
              decoration: InputDecoration(
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              hint: const Text('No topic'),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('No topic'),
                ),
                ...topics.map((topic) {
                  return DropdownMenuItem<String>(
                    value: topic.topic,
                    child: Text(
                      topic.topic,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
                const DropdownMenuItem<String>(
                  value: '__create_new__',
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 18, color: Color(0xFF34A853)),
                      SizedBox(width: 8),
                      Text(
                        'Create topic',
                        style: TextStyle(color: Color(0xFF34A853)),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (value) async {
                if (value == '__create_new__') {
                  await _showCreateTopicDialog();
                } else {
                  setState(() {
                    _selectedTopicName = value;
                    if (value == null) {
                      _selectedTopicId = null;
                    } else {
                      final topic = topics.firstWhere((t) => t.topic == value);
                      _selectedTopicId = topic.id;
                    }
                  });
                }
              },
            );
          }),
          const SizedBox(height: 24),
          // Instruction Field
          ResponsiveFormField(
            label: 'Instruction',
            controller: _instructionController,
            hintText: 'Instruction (optional)',
            maxLines: 6,
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
          _buildAttachmentSection(),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, minWidth: 250),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PIT Details',
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child:
                            _isLoadingClasses
                                ? const Text(
                                  'Loading classes...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                )
                                : Text(
                                  _getSelectedClassesText(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                      ),
                      const SizedBox(width: 8),
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
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child:
                      _isLoadingClasses
                          ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SkeletonListItem(),
                                SizedBox(height: 8),
                                SkeletonListItem(),
                                SizedBox(height: 8),
                                SkeletonListItem(),
                              ],
                            ),
                          )
                          : _classes.isEmpty
                          ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No classes available',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          )
                          : Column(
                            children:
                                _classes
                                    .map(
                                      (className) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value:
                                                  _selectedClasses[className] ??
                                                  false,
                                              onChanged: (bool? value) {
                                                _toggleClassSelection(
                                                  className,
                                                );
                                              },
                                              activeColor: const Color(
                                                0xFF34A853,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                className,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 2,
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
              Obx(() {
                final topics = _topicController.topics;
                return DropdownButtonFormField<String>(
                  value: _selectedTopicName,
                  isExpanded: true,
                  decoration: InputDecoration(
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  hint: const Text('No topic'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('No topic'),
                    ),
                    ...topics.map((topic) {
                      return DropdownMenuItem<String>(
                        value: topic.topic,
                        child: Text(
                          topic.topic,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    }).toList(),
                    const DropdownMenuItem<String>(
                      value: '__create_new__',
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 18, color: Color(0xFF34A853)),
                          SizedBox(width: 8),
                          Text(
                            'Create topic',
                            style: TextStyle(color: Color(0xFF34A853)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) async {
                    if (value == '__create_new__') {
                      await _showCreateTopicDialog();
                    } else {
                      setState(() {
                        _selectedTopicName = value;
                        if (value == null) {
                          _selectedTopicId = null;
                        } else {
                          final topic = topics.firstWhere(
                            (t) => t.topic == value,
                          );
                          _selectedTopicId = topic.id;
                        }
                      });
                    }
                  },
                );
              }),
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              // Excel Category Selection
              const Text(
                'Excel Category',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _toggleCategoryDropdown,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          _showCategoryDropdown
                              ? const Color(0xFF34A853)
                              : const Color(0xFF9E9E9E),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _categories[_selectedCategory]!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _showCategoryDropdown
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.black54,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              // Category dropdown options
              if (_showCategoryDropdown)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF9E9E9E)),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Column(
                    children:
                        _categories.entries
                            .where((entry) {
                              // Filter categories based on period
                              if (widget.period == 'Final') {
                                // For Final period, only show final_exam (hide midterm_exam)
                                return entry.key != 'midterm_exam';
                              } else {
                                // For Prelim/Midterm periods, only show midterm_exam (hide final_exam)
                                return entry.key != 'final_exam';
                              }
                            })
                            .map((entry) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = entry.key;
                                    _showCategoryDropdown = false;
                                  });
                                  // Auto-update category if period is Final
                                  _updateCategoryBasedOnPeriod();
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        _selectedCategory == entry.key
                                            ? const Color(
                                              0xFF34A853,
                                            ).withOpacity(0.1)
                                            : Colors.transparent,
                                  ),
                                  child: Text(
                                    entry.value,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          _selectedCategory == entry.key
                                              ? const Color(0xFF34A853)
                                              : Colors.black,
                                      fontWeight:
                                          _selectedCategory == entry.key
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                              );
                            })
                            .toList(),
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
                    border: Border.all(color: const Color(0xFF9E9E9E)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _selectedDueDate != null
                              ? '${_selectedDueDate!.month}/${_selectedDueDate!.day}/${_selectedDueDate!.year} ${_selectedDueDate!.hour.toString().padLeft(2, '0')}:${_selectedDueDate!.minute.toString().padLeft(2, '0')}'
                              : 'MM/DD/YYYY HH:MM',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                _selectedDueDate != null
                                    ? Colors.black
                                    : Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.black54,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return Obx(
      () => ResponsiveButton(
        text: widget.isEdit ? 'Update' : 'Post',
        onPressed: _validateAndSubmit,
        isLoading: _createController.isLoading.value,
      ),
    );
  }

  Widget _buildAttachmentSection() {
    return Obx(
      () => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File picker button
            GestureDetector(
              onTap: _pickFiles,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_upward, color: Colors.grey, size: 20),
                    SizedBox(height: 4),
                    Text(
                      'Upload',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            // Selected files display - now fully scrollable
            if (_fileController.selectedFiles.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Selected Files:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              // No height constraints - let it scroll naturally
              Column(
                children:
                    _fileController.selectedFiles.asMap().entries.map((entry) {
                      final index = entry.key;
                      final file = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getFileIcon(file.extension),
                              color: Colors.grey[600],
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    file.name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${(file.size / 1024).toStringAsFixed(1)} KB',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _fileController.removeFile(index),
                              child: const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ],

            // Upload status
            if (_fileController.uploadStatus.value.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _fileController.uploadStatus.value,
                style: TextStyle(
                  fontSize: 12,
                  color:
                      _fileController.uploadStatus.value.contains('Error')
                          ? Colors.red
                          : Colors.green,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickFiles() async {
    try {
      await _fileController.pickFiles();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick files: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  IconData _getFileIcon(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.attach_file;
    }
  }
}
