// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/instructor/instructor_appbar.dart';
import '../../shared/instructor/instructor_sidebar.dart';
import '../../shared/instructor/instructor_navigation_constants.dart';
import '../../shared/widgets/safe_asset_image.dart';
import '../../shared/widgets/skeleton_loading.dart';
import '../../shared/widgets/filter/created_items_filter_bar.dart';
import '../../shared/services/instructor_class_service.dart';
import '../../shared/utils/date_range_filter.dart';
import '../../shared/utils/item_filter_utils.dart';
import '../instructor_dashboard_controller.dart';
import 'activity_screen.dart';
import 'assignment_screen.dart';
import 'create_controller.dart';
import 'material_screen.dart';
import 'pit_screen.dart';
import 'quiz_controller.dart';
import 'quiz_screen_new.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen>
    with WidgetsBindingObserver {
  final CreateController _createController = Get.put(CreateController());
  final QuizController _quizController = Get.put(QuizController());
  final InstructorController instructorController = Get.put(
    InstructorController(),
  );
  InstructorNavigationItem _selectedItem = InstructorNavigationItem.create;
  bool _showTypeDropdown = false;
  bool _showPeriodDropdown = false;
  String? _selectedType;
  String? _selectedPeriod;
  String? _hoveredType; // Track which type is being hovered
  String? _hoveredPeriod; // Track which period is being hovered
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _typeFilter;
  String? _classFilter;
  String? _periodFilter;
  DateRangePreset _selectedPreset = DateRangePreset.all;
  DateTimeRange? _customDateRange;

  final List<String> _types = [
    'Assignment',
    'Activity',
    'Material',
    'Quiz',
    'PIT',
  ];
  final List<String> _periods = ['Prelim', 'Midterm', 'Final'];
  final List<String> _pitPeriods = ['Midterm', 'Final'];
  bool _hasAssignedSections = true;
  bool _isCheckingSections = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkSectionsOnInit();
  }

  Future<void> _checkSectionsOnInit() async {
    setState(() {
      _isCheckingSections = true;
    });

    try {
      final hasSections = await _checkInstructorSections();
      setState(() {
        _hasAssignedSections = hasSections;
        _isCheckingSections = false;
      });

      if (!hasSections) {
        // Show error message when screen loads
        Future.delayed(const Duration(milliseconds: 500), () {
          _showNoSectionsError();
        });
      }
    } catch (e) {
      setState(() {
        _hasAssignedSections = false;
        _isCheckingSections = false;
      });
      print('Error checking sections on init: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  DateTimeRange? _currentDateRange() {
    return resolveDateRange(_selectedPreset, customRange: _customDateRange);
  }

  void _handlePresetChange(DateRangePreset preset) {
    setState(() {
      _selectedPreset = preset;
      if (preset != DateRangePreset.custom) {
        _customDateRange = null;
      }
    });
  }

  Future<DateTimeRange?> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final initialRange =
        _customDateRange ??
        DateTimeRange(start: now.subtract(const Duration(days: 6)), end: now);

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF34A853)),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
              child: child!,
            ),
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedPreset = DateRangePreset.custom;
      });
    }

    return picked;
  }

  void _refreshData() {
    // Refresh both controllers to ensure data is up to date
    _createController.forceRefresh();
    _quizController.loadQuizzes();
  }

  void _handleNavigationSelect(InstructorNavigationItem item) {
    setState(() {
      _selectedItem = item;
    });
    String route = InstructorNavigationHelper.getRoute(item);
    Navigator.of(context).pushNamed(route);
  }

  Future<void> _toggleTypeDropdown() async {
    // Don't allow opening if no sections assigned
    if (!_hasAssignedSections || _isCheckingSections) {
      _showNoSectionsError();
      return;
    }

    // If dropdowns are already open, close them (avoid double-handling with overlay)
    if (_showTypeDropdown || _showPeriodDropdown) {
      _closeDropdowns();
      return;
    }
    setState(() {
      _showTypeDropdown = true;
      _showPeriodDropdown = false; // Only show type dropdown initially
    });
  }

  Future<void> _selectType(String type) async {
    // Check if instructor has assigned sections (except for Material)
    if (type != 'Material') {
      final hasSections = await _checkInstructorSections();
      if (!hasSections) {
        // Show error message and don't proceed
        _showNoSectionsError();
        return;
      }
    }

    setState(() {
      _selectedType = type;
      _selectedPeriod = null; // Reset period when type changes

      if (type == 'Assignment' ||
          type == 'Activity' ||
          type == 'Quiz' ||
          type == 'PIT') {
        // Show period dropdown first, don't navigate yet
        _showPeriodDropdown = true;
        // Keep type dropdown visible until period is selected
        _showTypeDropdown = true;
      } else if (type == 'Material') {
        // For Material, navigate directly without period selection
        _showTypeDropdown = false;
        _showPeriodDropdown = false;
        _navigateToMaterial();
      }
    });
  }

  Future<bool> _checkInstructorSections() async {
    try {
      final sectionCodes =
          await InstructorClassService.getInstructorSectionCodes();
      return sectionCodes.isNotEmpty;
    } catch (e) {
      print('Error checking instructor sections: $e');
      return false;
    }
  }

  void _showNoSectionsError() {
    Get.snackbar(
      'No Assigned Sections',
      'You have no assigned sections yet. Please contact the administrator.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      dismissDirection: DismissDirection.endToStart,
      margin: const EdgeInsets.all(16),
    );
    // Close dropdowns
    _closeDropdowns();
  }

  void _navigateToMaterial() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const MaterialScreen())).then((
      result,
    ) {
      // Always refresh data when returning to show newly created/updated items
      if (result == true) {
        // Material was created/updated successfully
        _refreshData();
        // Show success message
        Get.snackbar(
          'Success',
          'Material created successfully!',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF34A853),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        // Just refresh data if returning without success
        _refreshData();
      }
    });
  }

  void _closeDropdowns() {
    setState(() {
      _showTypeDropdown = false;
      _showPeriodDropdown = false;
      _selectedType = null; // Reset selection
      _selectedPeriod = null; // Reset selection
      _hoveredType = null; // Reset hover state
      _hoveredPeriod = null; // Reset hover state
    });
  }

  void _closePeriodDropdown() {
    setState(() {
      _showPeriodDropdown = false;
      _selectedPeriod = null; // Reset period selection
      _hoveredPeriod = null; // Reset hover state
      // Keep type dropdown open
    });
  }

  void _selectPeriod(String period) {
    setState(() {
      _selectedPeriod = period;
      _showPeriodDropdown = false;
      _showTypeDropdown = false; // Close both dropdowns when period is selected
    });

    // Navigate to the appropriate screen based on selected type
    if (_selectedType == 'Assignment') {
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (context) => AssignmentScreen(period: period),
            ),
          )
          .then((_) => _refreshData()); // Refresh data when returning
    } else if (_selectedType == 'Activity') {
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (context) => ActivityScreen(period: period),
            ),
          )
          .then((_) => _refreshData()); // Refresh data when returning
    } else if (_selectedType == 'Quiz') {
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (context) => QuizzesScreen(period: period),
            ),
          )
          .then((_) => _refreshData()); // Refresh data when returning
    } else if (_selectedType == 'PIT') {
      Navigator.of(context)
          .push(
            MaterialPageRoute(builder: (context) => PITScreen(period: period)),
          )
          .then((_) => _refreshData()); // Refresh data when returning
    }
  }

  Widget _buildEmptyState([bool isSearching = false]) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
            child: SafeAssetImage(
              assetPath:
                  'assets/instructor/images/solar_documents-line-duotone.png',
              width: 48,
              height: 48,
              color: Colors.grey.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isSearching ? 'No items found' : 'No items created yet',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'Try adjusting your search query to find what you\'re looking for.'
                : 'Create assignments, activities, materials, or quizzes for your classes.',
            style: const TextStyle(fontSize: 16, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          if (!isSearching) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _toggleTypeDropdown,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Create Your First Item',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34A853),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredItems() {
    final items = _createController.createdItems.toList();
    return filterCreatedItems(
      items: items,
      typeFilter: _typeFilter,
      dateRange: _currentDateRange(),
      searchQuery: _searchQuery,
      classFilter: _classFilter,
      periodFilter: _periodFilter,
    );
  }

  Widget _buildCreatedItemsList() {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Created Items',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              // Refresh button
              IconButton(
                onPressed: _refreshData,
                icon: const Icon(Icons.refresh, color: Colors.black54),
                tooltip: 'Refresh',
              ),
              // Item count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF34A853).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_getFilteredItems().length} items',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF34A853),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CreatedItemsFilterBar(
            typeOptions: _types,
            selectedType: _typeFilter,
            onTypeChanged: (value) {
              setState(() {
                _typeFilter = value;
              });
            },
            classOptions: _createController.instructorClasses.toList(),
            selectedClass: _classFilter,
            onClassChanged: (value) {
              setState(() {
                _classFilter = value;
              });
            },
            periodOptions: _periods,
            selectedPeriod: _periodFilter,
            onPeriodChanged: (value) {
              setState(() {
                _periodFilter = value;
              });
            },
            datePreset: _selectedPreset,
            customRange: _customDateRange,
            onPresetChanged: _handlePresetChange,
            onRequestCustomRange: () => _pickCustomRange(context),
          ),
          const SizedBox(height: 16),
          // Search bar
          Container(
            width: double.infinity,
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                SafeAssetImage(
                  assetPath: 'assets/instructor/icons/akar-icons_search.png',
                  width: 20,
                  color: Color(0xFFBDBDBD),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText:
                          'Search by title (Assignment, Activity, Material, Quiz, PIT)...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Color(0xFFBDBDBD)),
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
          // Error message
          if (_createController.errorMessage.value.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _createController.errorMessage.value,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _createController.clearError(),
                    icon: const Icon(Icons.close, color: Colors.red, size: 16),
                  ),
                ],
              ),
            ),
          SizedBox(
            height: 600, // Fixed height for the list area
            child:
                _createController.isLoading.value
                    ? ListView.builder(
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return const SkeletonInstructorCreateItemCard();
                      },
                    )
                    : _getFilteredItems().isEmpty
                    ? _buildEmptyState(_searchQuery.isNotEmpty)
                    : ListView.builder(
                      itemCount: _getFilteredItems().length,
                      itemBuilder: (context, index) {
                        final item = _getFilteredItems()[index];
                        return _buildCreatedItemCard(item);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatedItemCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Type Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Color(0xFF34A853).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                _getTypeIcon(item['type']),
                color: Color(0xFF34A853),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item['type'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    if (item['period'] != null &&
                        item['period'].toString().isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item['period'].toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item['title'] ?? 'No Title',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                // Instruction/Description preview
                if (item['instruction'] != null &&
                    item['instruction'].toString().isNotEmpty) ...[
                  Text(
                    () {
                      final instruction = item['instruction'].toString();
                      return instruction.length > 100
                          ? '${instruction.substring(0, 100)}...'
                          : instruction;
                    }(),
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                ] else if (item['description'] != null &&
                    item['description'].toString().isNotEmpty) ...[
                  Text(
                    () {
                      final description = item['description'].toString();
                      return description.length > 100
                          ? '${description.substring(0, 100)}...'
                          : description;
                    }(),
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                ],
                Row(
                  children: [
                    if (item['points'] != null &&
                        item['points'].toString().isNotEmpty &&
                        item['points'] != '0') ...[
                      Text(
                        'Points: ',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        item['points'].toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (item['dueDate'] != null &&
                        item['dueDate'].toString().isNotEmpty) ...[
                      Text(
                        'Due: ',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        item['dueDate'].toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Created: ',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black38,
                      ),
                    ),
                    Text(
                      item['createdAt']?.toString() ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    // Status indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            item['status'] == 'active'
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item['status']?.toString().toUpperCase() ?? 'ACTIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color:
                              item['status'] == 'active'
                                  ? Colors.green
                                  : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black54, size: 20),
            onSelected: (value) {
              if (value == 'edit') {
                // Edit functionality - navigate to edit screen
                if (item['type'] == 'Assignment') {
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder:
                              (context) => AssignmentScreen(
                                period: item['period'],
                                isEdit: true,
                                itemId: item['id'],
                                initialData: item,
                              ),
                        ),
                      )
                      .then(
                        (_) => _refreshData(),
                      ); // Refresh data when returning
                } else if (item['type'] == 'Activity') {
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder:
                              (context) => ActivityScreen(
                                period: item['period'],
                                isEdit: true,
                                itemId: item['id'],
                                initialData: item,
                              ),
                        ),
                      )
                      .then(
                        (_) => _refreshData(),
                      ); // Refresh data when returning
                } else if (item['type'] == 'Quiz') {
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder:
                              (context) => QuizzesScreen(
                                period: item['period'] ?? 'Prelim',
                                isEdit: true,
                                itemId: item['id'],
                                initialData: item,
                              ),
                        ),
                      )
                      .then(
                        (_) => _refreshData(),
                      ); // Refresh data when returning
                } else if (item['type'] == 'Material') {
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder:
                              (context) => MaterialScreen(
                                isEdit: true,
                                itemId: item['id'],
                                initialData: item,
                              ),
                        ),
                      )
                      .then(
                        (_) => _refreshData(),
                      ); // Refresh data when returning
                } else if (item['type'] == 'PIT') {
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder:
                              (context) => PITScreen(
                                period: item['period'],
                                isEdit: true,
                                itemId: item['id'],
                                initialData: item,
                              ),
                        ),
                      )
                      .then(
                        (_) => _refreshData(),
                      ); // Refresh data when returning
                }
              } else if (value == 'delete') {
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Confirm Delete'),
                      content: Text(
                        'Are you sure you want to delete this ${item['type']?.toString().toLowerCase()}?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _createController.deleteItem(
                              item['id'],
                              item['type'],
                            );
                          },
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  },
                );
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18, color: Colors.black54),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Assignment':
        return Icons.assignment;
      case 'Activity':
        return Icons.assignment_turned_in;
      case 'Material':
        return Icons.description;
      case 'Quiz':
        return Icons.quiz_outlined;
      case 'PIT':
        return Icons.school;
      default:
        return Icons.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Invisible overlay to detect taps outside dropdowns (placed first so it's behind other widgets)
          if (_showTypeDropdown || _showPeriodDropdown)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  // Don't close on outside tap - keep dialog open
                  // Only close when explicitly selecting an option
                },
                behavior:
                    HitTestBehavior
                        .opaque, // Block all interactions behind the dialog
                child: Container(
                  color:
                      Colors
                          .transparent, // Transparent - keep original background
                ),
              ),
            ),
          Row(
            children: [
              // Sidebar
              InstructorSidebar(
                selectedItem: _selectedItem,
                onItemSelected: _handleNavigationSelect,
              ),
              // Main content
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
                    // Main content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
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
                            // Create button with dropdowns
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Warning message if no sections
                                if (!_isCheckingSections &&
                                    !_hasAssignedSections) ...[
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.orange.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.warning_amber_rounded,
                                          color: Colors.orange,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'You have no assigned sections yet. Please contact the administrator to get sections assigned to you.',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.orange[900],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                // Main Create Button
                                Opacity(
                                  opacity:
                                      _isCheckingSections ||
                                              !_hasAssignedSections
                                          ? 0.5
                                          : 1.0,
                                  child: GestureDetector(
                                    onTap:
                                        _isCheckingSections ||
                                                !_hasAssignedSections
                                            ? null
                                            : _toggleTypeDropdown,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 30,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            _isCheckingSections ||
                                                    !_hasAssignedSections
                                                ? Colors.grey
                                                : const Color(0xFF34A853),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow:
                                            _isCheckingSections ||
                                                    !_hasAssignedSections
                                                ? []
                                                : [
                                                  BoxShadow(
                                                    color: const Color(
                                                      0xFF34A853,
                                                    ).withOpacity(0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.add,
                                            color:
                                                _isCheckingSections ||
                                                        !_hasAssignedSections
                                                    ? Colors.grey[300]
                                                    : Colors.white,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            _selectedType ?? 'Create',
                                            style: TextStyle(
                                              color:
                                                  _isCheckingSections ||
                                                          !_hasAssignedSections
                                                      ? Colors.grey[300]
                                                      : Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.keyboard_arrow_down,
                                            color:
                                                _isCheckingSections ||
                                                        !_hasAssignedSections
                                                    ? Colors.grey[300]
                                                    : Colors.white,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),

                            const SizedBox(height: 48),
                            // Content Area - Shows either created items or empty state
                            _buildCreatedItemsList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Type Dropdown (right side of Create button)
          if (_showTypeDropdown)
            Positioned(
              top:
                  MediaQuery.of(context).padding.top +
                  200, // Responsive top position
              left:
                  MediaQuery.of(context).size.width > 768
                      ? 300
                      : 24, // Responsive left position
              right:
                  MediaQuery.of(context).size.width > 768
                      ? null
                      : 24, // Ensure dropdown doesn't go off-screen on mobile
              child: Material(
                elevation: 8,
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: () {
                    // Prevent closing when tapping inside the dropdown
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight:
                          MediaQuery.of(context).size.height *
                          0.6, // Max 60% of screen height
                      maxWidth: 200,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Select Type',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: _closeDropdowns,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Close',
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children:
                                  _types
                                      .map(
                                        (type) => MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          onEnter: (_) {
                                            setState(() {
                                              _hoveredType = type;
                                            });
                                          },
                                          onExit: (_) {
                                            setState(() {
                                              _hoveredType = null;
                                            });
                                          },
                                          child: GestureDetector(
                                            onTap: () => _selectType(type),
                                            child: Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                              margin: const EdgeInsets.only(
                                                bottom: 8,
                                                left: 8,
                                                right: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    _selectedType == type ||
                                                            _hoveredType == type
                                                        ? const Color(
                                                          0xFF34A853,
                                                        ).withOpacity(0.1)
                                                        : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  SafeAssetImage(
                                                    assetPath:
                                                        type == 'Material'
                                                            ? 'assets/instructor/images/arcticons_onlyoffice-documents.png'
                                                            : 'assets/instructor/images/arcticons_documents.png',
                                                    width: 20,
                                                    height: 20,
                                                    color: Colors.black,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    type,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14,
                                                      color:
                                                          _selectedType ==
                                                                      type ||
                                                                  _hoveredType ==
                                                                      type
                                                              ? Colors.black
                                                              : Colors.black45,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // Period Dropdown (side by side with type dropdown)
          if (_showPeriodDropdown &&
              (_selectedType == 'Assignment' ||
                  _selectedType == 'Activity' ||
                  _selectedType == 'Quiz' ||
                  _selectedType == 'PIT'))
            Positioned(
              top:
                  MediaQuery.of(context).padding.top +
                  (MediaQuery.of(context).size.width > 768
                      ? 200
                      : 350), // Same top as type dropdown on desktop, below on mobile
              left:
                  MediaQuery.of(context).size.width > 768
                      ? 520
                      : 24, // Responsive left position
              right:
                  MediaQuery.of(context).size.width > 768
                      ? null
                      : 24, // Ensure dropdown doesn't go off-screen on mobile
              child: Material(
                elevation: 8,
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: () {
                    // Prevent closing when tapping inside the dropdown
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight:
                          MediaQuery.of(context).size.height *
                          0.6, // Max 60% of screen height
                      maxWidth: 200,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Select Period',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: _closePeriodDropdown,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Close',
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children:
                                  (_selectedType == 'PIT'
                                          ? _pitPeriods
                                          : _periods)
                                      .map(
                                        (period) => MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          onEnter: (_) {
                                            setState(() {
                                              _hoveredPeriod = period;
                                            });
                                          },
                                          onExit: (_) {
                                            setState(() {
                                              _hoveredPeriod = null;
                                            });
                                          },
                                          child: GestureDetector(
                                            onTap: () => _selectPeriod(period),
                                            child: Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                              margin: const EdgeInsets.only(
                                                bottom: 8,
                                                left: 8,
                                                right: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    _selectedPeriod == period ||
                                                            _hoveredPeriod ==
                                                                period
                                                        ? const Color(
                                                          0xFF34A853,
                                                        ).withOpacity(0.1)
                                                        : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    period,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14,
                                                      color:
                                                          _selectedPeriod ==
                                                                      period ||
                                                                  _hoveredPeriod ==
                                                                      period
                                                              ? Colors.black
                                                              : Colors.black45,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
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
}
