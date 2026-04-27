import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenquest/instructor/helpers/extract_attachment_url.dart';
import 'package:greenquest/instructor/helpers/get_file_icon.dart';
import '../../shared/controllers/file_submission_controller.dart';
import '../../shared/instructor/instructor_navigation_constants.dart';
import '../../shared/instructor/instructor_sidebar.dart';
import '../../shared/responsive/responsive_layout.dart';
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

  String? _selectedTopicId;
  String? _selectedTopicName;

  List<String> _classes = [];
  Map<String, bool> _selectedClasses = {};
  bool _isLoadingClasses = true;
  List<dynamic> _existingAttachments = [];

  final Map<String, String> _categories = {
    'class_standing': 'Class Standing Performance Items (10%)',
    'quiz_prelim': 'Quiz/Prelim Performance Item (40%)',
    'midterm_exam': 'Midterm Exam (30%)',
    'final_exam': 'Final Exam (30%)',
    'pit': 'Per Inno Task (20%)',
  };

  @override
  void initState() {
    super.initState();

    _topicController.loadTopics();

    if (!widget.isEdit) {
      _fileController.clearFiles();
    }

    _loadInstructorClasses().then((_) {
      if (widget.isEdit && widget.initialData != null) {
        _loadInitialData();
      } else {
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
      final sectionCodes =
          await InstructorClassService.getInstructorSectionCodes();

      if (sectionCodes.isNotEmpty) {
        _classes = sectionCodes;
      } else {
        _classes = InstructorClassService.getFallbackClasses();
      }

      _selectedClasses = Map.fromEntries(
        _classes.map((e) => MapEntry(e, false)),
      );
    } catch (_) {
      _classes = InstructorClassService.getFallbackClasses();
      _selectedClasses = Map.fromEntries(
        _classes.map((e) => MapEntry(e, false)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingClasses = false;
        });
      }
    }
  }

  void _loadInitialData() {
    final data = widget.initialData!;

    setState(() {
      _titleController.text = data['title'] ?? '';
      _instructionController.text = data['instruction'] ?? '';
      _pointsController.text = data['points']?.toString() ?? '100';

      final dueDateValue = data['dueDateRaw'] ?? data['dueDate'];
      if (dueDateValue != null) {
        try {
          if (dueDateValue is DateTime) {
            _selectedDueDate = dueDateValue;
          } else if (dueDateValue is Timestamp) {
            _selectedDueDate = dueDateValue.toDate();
          } else if (dueDateValue is String) {
            _selectedDueDate = DateTime.parse(dueDateValue);
          }
        } catch (_) {
          _selectedDueDate = null;
        }
      }

      if (data['selectedClasses'] is List) {
        for (final dynamic className in data['selectedClasses']) {
          final key = className.toString();
          if (_selectedClasses.containsKey(key)) {
            _selectedClasses[key] = true;
          }
        }
      }

      if (data['category'] != null) {
        _selectedCategory = data['category'].toString();
      }

      final topicId = data['topicId'];
      final topicName = data['topicName'];

      if (topicId != null && topicId != '' && topicId != 'null') {
        _selectedTopicId = topicId.toString();
      }
      if (topicName != null && topicName != '' && topicName != 'null') {
        _selectedTopicName = topicName.toString();
      }

      _existingAttachments = List<dynamic>.from(data['attachments'] ?? []);

      _updateCategoryBasedOnPeriod();
    });
  }

  void _updateCategoryBasedOnPeriod() {
    if (widget.period == 'Final' && _selectedCategory == 'midterm_exam') {
      _selectedCategory = 'final_exam';
      return;
    }

    if ((widget.period == 'Prelim' || widget.period == 'Midterm') &&
        _selectedCategory == 'final_exam') {
      _selectedCategory = 'midterm_exam';
    }
  }

  void _handleNavigationSelect(InstructorNavigationItem item) {
    setState(() {
      _selectedItem = item;
    });
    final route = InstructorNavigationHelper.getRoute(item);
    Navigator.of(context).pushReplacementNamed(route);
  }

  void _toggleClassSelection(String className) {
    setState(() {
      _selectedClasses[className] = !(_selectedClasses[className] ?? false);
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
    }
    if (selectedClasses.length == 1) {
      return selectedClasses.first;
    }
    return '${selectedClasses.length} classes selected';
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
    final topicController = TextEditingController();

    await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
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
        );
      },
    );
  }

  Future<void> _selectDueDate() async {
    final now = DateTime.now();
    final minDate =
        widget.isEdit &&
                _selectedDueDate != null &&
                _selectedDueDate!.isBefore(now)
            ? _selectedDueDate!.subtract(const Duration(days: 365))
            : now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: minDate,
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

    if (pickedDate == null) {
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime:
          _selectedDueDate != null
              ? TimeOfDay.fromDateTime(_selectedDueDate!)
              : TimeOfDay.now(),
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

    if (pickedTime == null) {
      return;
    }

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (!combined.isAfter(DateTime.now())) {
      Get.snackbar(
        'Error',
        'Due date and time must be in the future',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    setState(() {
      _selectedDueDate = combined;
    });
  }

  void _validateAndSubmit() {
    setState(() {
      _showTitleError = _titleController.text.trim().isEmpty;
    });

    if (!_showTitleError) {
      _submitPIT();
    }
  }

  Future<void> _submitPIT() async {
    if (_selectedDueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a due date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_selectedDueDate!.isAfter(DateTime.now())) {
      Get.snackbar(
        'Error',
        'Due date and time must be in the future',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    final selectedClasses =
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

    final attachmentUrls = <dynamic>[];

    if (widget.isEdit &&
        widget.initialData != null &&
        widget.initialData!['attachments'] is List) {
      attachmentUrls.addAll(
        widget.initialData!['attachments'] as List<dynamic>,
      );
    }

    if (_fileController.selectedFiles.isNotEmpty) {
      try {
        _createController.isLoading.value = true;

        final uploadSuccess = await _fileController.uploadFiles(
          folder: 'greenquest/pits',
          tags: {'type': 'pit', 'period': widget.period ?? 'current'},
        );

        if (!uploadSuccess) {
          _createController.isLoading.value = false;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload files. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        attachmentUrls.addAll(_fileController.uploadedFiles.toList());
      } catch (e) {
        _createController.isLoading.value = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading files: $e'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    var categoryToSave = _selectedCategory;
    if (widget.period == 'Final' && categoryToSave == 'midterm_exam') {
      categoryToSave = 'final_exam';
    } else if (widget.period != 'Final' && categoryToSave == 'final_exam') {
      categoryToSave = 'midterm_exam';
    }

    if (widget.isEdit && widget.itemId != null) {
      final success = await _createController.updatePIT(
        pitId: widget.itemId!,
        title: _titleController.text.trim(),
        instruction: _instructionController.text.trim(),
        selectedClasses: selectedClasses,
        points: _pointsController.text.trim(),
        dueDate: _selectedDueDate!,
        period: widget.period,
        category: categoryToSave,
        attachments: attachmentUrls,
        topicId: _selectedTopicId,
        topicName: _selectedTopicName,
      );

      if (success && mounted) {
        _fileController.clearFiles();
        Navigator.of(context).pop();
      }
      return;
    }

    final success = await _createController.createPIT(
      title: _titleController.text.trim(),
      instruction: _instructionController.text.trim(),
      selectedClasses: selectedClasses,
      points: _pointsController.text.trim(),
      dueDate: _selectedDueDate!,
      period: widget.period,
      category: categoryToSave,
      attachments: attachmentUrls,
      topicId: _selectedTopicId,
      topicName: _selectedTopicName,
    );

    if (success && mounted) {
      _fileController.clearFiles();
      _resetForm();
      Navigator.of(context).pop();
    }
  }

  void _resetForm() {
    setState(() {
      _titleController.clear();
      _instructionController.clear();
      _pointsController.text = '100';
      _selectedDueDate = null;
      _selectedCategory = 'pit';
      _selectedTopicId = null;
      _selectedTopicName = null;
      _selectedClasses = Map.fromEntries(
        _classes.map((e) => MapEntry(e, false)),
      );
      _existingAttachments = [];
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
                }),
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
          ResponsiveFormField(
            label: 'Instruction',
            controller: _instructionController,
            hintText: 'Instruction (optional)',
            maxLines: 6,
          ),
          const SizedBox(height: 32),
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
                                              onChanged: (_) {
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
                          _categories[_selectedCategory] ?? _categories['pit']!,
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
                              if (widget.period == 'Final') {
                                return entry.key != 'midterm_exam';
                              }
                              return entry.key != 'final_exam';
                            })
                            .map((entry) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = entry.key;
                                    _showCategoryDropdown = false;
                                    _updateCategoryBasedOnPeriod();
                                  });
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

            if (widget.isEdit && _existingAttachments.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Current Attachments:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children:
                    _existingAttachments.map((attachment) {
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blue[100]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.attach_file,
                              color: Colors.blue[700],
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                getAttachmentDisplayName(attachment),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              onPressed: () => previewAttachment(attachment),
                              icon: const Icon(
                                Icons.visibility,
                                size: 16,
                                color: Colors.blue,
                              ),
                              tooltip: 'Preview attachment',
                            ),
                            IconButton(
                              onPressed: () => downloadAttachment(attachment),
                              icon: const Icon(
                                Icons.download,
                                size: 16,
                                color: Colors.green,
                              ),
                              tooltip: 'Download attachment',
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ],

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
                              getFileIcon(file.extension),
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

  @override
  void dispose() {
    _titleController.dispose();
    _instructionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }
}
