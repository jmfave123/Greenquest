// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/instructor/instructor_appbar.dart';
import '../../shared/instructor/instructor_sidebar.dart';
import '../../shared/instructor/instructor_navigation_constants.dart';
import '../../shared/widgets/safe_asset_image.dart';
import 'assignment_screen.dart';
import 'activity_screen.dart';
import 'quiz_screen_new.dart';
import 'create_controller.dart';
import 'quiz_controller.dart';
import '../instructor_dashboard_controller.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({Key? key}) : super(key: key);

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

  final List<String> _types = ['Assignment', 'Activity', 'Material', 'Quiz'];
  final List<String> _periods = ['Prelim', 'Midterm', 'Final'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initial data load
    _refreshData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when screen becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshData();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app becomes active
      _refreshData();
    }
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

  void _toggleTypeDropdown() {
    setState(() {
      _showTypeDropdown = !_showTypeDropdown;
      if (_showTypeDropdown) {
        // Show both dropdowns when Create button is clicked
        _showPeriodDropdown = true;
      } else {
        _showPeriodDropdown = false;
      }
    });
  }

  void _selectType(String type) {
    setState(() {
      _selectedType = type;
      _selectedPeriod = null; // Reset period when type changes

      if (type == 'Assignment' || type == 'Activity' || type == 'Quiz') {
        // Show period dropdown first, don't navigate yet
        _showPeriodDropdown = true;
        // Keep type dropdown visible until period is selected
        _showTypeDropdown = true;
      }
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
    }
  }

  Widget _buildEmptyState() {
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
          const Text(
            'No items created yet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create assignments, activities, materials, or quizzes for your classes.',
            style: TextStyle(fontSize: 16, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
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
                  '${_createController.createdItems.length} items',
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
          Expanded(
            child:
                _createController.isLoading.value
                    ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF34A853),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading your items...',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                    : _createController.createdItems.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                      itemCount: _createController.createdItems.length,
                      itemBuilder: (context, index) {
                        final item = _createController.createdItems[index];
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
                    item['instruction'].toString().length > 100
                        ? '${item['instruction'].toString().substring(0, 100)}...'
                        : item['instruction'].toString(),
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                ] else if (item['description'] != null &&
                    item['description'].toString().isNotEmpty) ...[
                  Text(
                    item['description'].toString().length > 100
                        ? '${item['description'].toString().substring(0, 100)}...'
                        : item['description'].toString(),
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                ],
                Row(
                  children: [
                    if (item['topic'] != null &&
                        item['topic'].toString().isNotEmpty) ...[
                      Text(
                        'Topic: ',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        item['topic'].toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
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
                      ),
                    ),
                    // Main content
                    Expanded(
                      child: Padding(
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
                                // Main Create Button
                                GestureDetector(
                                  onTap: _toggleTypeDropdown,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 30,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF34A853),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
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
                                        const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          _selectedType ?? 'Create',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.keyboard_arrow_down,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),

                            const SizedBox(height: 48),
                            // Content Area - Shows either created items or empty state
                            Expanded(child: _buildCreatedItemsList()),
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
              top: 300, // Position next to the Create button
              left: 300, // Position to the right of Create button
              child: Container(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Select Type',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    ..._types
                        .map(
                          (type) => GestureDetector(
                            onTap: () => _selectType(type),
                            child: Container(
                              width: 160,
                              padding: const EdgeInsets.symmetric(
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
                                    _selectedType == type
                                        ? const Color(
                                          0xFF34A853,
                                        ).withOpacity(0.1)
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
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
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color:
                                          _selectedType == type
                                              ? Colors.black
                                              : Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          // Period Dropdown (side by side with type dropdown)
          if (_showPeriodDropdown &&
              (_selectedType == 'Assignment' ||
                  _selectedType == 'Activity' ||
                  _selectedType == 'Quiz'))
            Positioned(
              top: 350, // Same top position as type dropdown
              left: 500, // Position to the right of type dropdown with gap
              child: Container(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Select Period',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    ..._periods
                        .map(
                          (period) => GestureDetector(
                            onTap: () => _selectPeriod(period),
                            child: Container(
                              width: 160,
                              padding: const EdgeInsets.symmetric(
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
                                    _selectedPeriod == period
                                        ? const Color(
                                          0xFF34A853,
                                        ).withOpacity(0.1)
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 12),
                                  Text(
                                    period,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color:
                                          _selectedPeriod == period
                                              ? Colors.black
                                              : Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
