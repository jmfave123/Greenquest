// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../shared/instructor/instructor_appbar.dart';
import '../../shared/instructor/instructor_sidebar.dart';
import 'material_screen.dart';
import 'assignment_screen.dart';
import 'activity_screen.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({Key? key}) : super(key: key);

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  int _selectedSidebarIndex = 1; // Create index
  bool _showTypeDropdown = false;
  bool _showPeriodDropdown = false;
  String? _selectedType;
  String? _selectedPeriod;

  final List<String> _types = ['Assignment', 'Activity', 'Material'];
  final List<String> _periods = ['Prelim', 'Midterm', 'Prefinal', 'Final'];
  
  // Sample data for created items - in real app this would come from backend
  final List<Map<String, dynamic>> _createdItems = [
    {
      'type': 'Assignment',
      'title': 'Programming Assignment 1',
      'period': 'Prelim',
      'dueDate': '2024-01-15',
      'points': '100',
      'topic': 'Programming',
      'createdAt': '2024-01-10',
    },
    {
      'type': 'Activity',
      'title': 'Database Design Workshop',
      'period': 'Midterm',
      'dueDate': '2024-01-20',
      'points': '50',
      'topic': 'Database',
      'createdAt': '2024-01-12',
    },
    {
      'type': 'Material',
      'title': 'Web Development Fundamentals',
      'period': null,
      'dueDate': null,
      'points': null,
      'topic': 'Web Development',
      'createdAt': '2024-01-08',
    },
  ];

  void _handleSidebarSelection(int index) {
    setState(() {
      _selectedSidebarIndex = index;
    });
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

  void _togglePeriodDropdown() {
    if (_selectedType != null && _selectedType != 'Material') {
      setState(() {
        _showPeriodDropdown = !_showPeriodDropdown;
        if (_showPeriodDropdown) {
          _showTypeDropdown = false;
        }
      });
    }
  }

  void _selectType(String type) {
    setState(() {
      _selectedType = type;
      _selectedPeriod = null; // Reset period when type changes
      
      if (type == 'Material') {
        _showPeriodDropdown = false;
        // Navigate to Material screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const MaterialScreen(),
          ),
        );
      } else if (type == 'Assignment' || type == 'Activity') {
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
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const AssignmentScreen(),
        ),
      );
    } else if (_selectedType == 'Activity') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const ActivityScreen(),
        ),
      );
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
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Image.asset(
              'assets/instructor/images/solar_documents-line-duotone.png',
              width: 48,
              height: 48,
              color: Colors.grey.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'This is where you\'ll sign work',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You can add assignments and other activities for the class.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatedItemsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Created Items',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _createdItems.length,
            itemBuilder: (context, index) {
              final item = _createdItems[index];
              return _buildCreatedItemCard(item);
            },
          ),
        ),
      ],
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
              color:  Color(0xFF34A853).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                _getTypeIcon(item['type']),
                          color:  Color(0xFF34A853),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item['type'],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    if (item['period'] != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item['period'],
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
                  item['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (item['topic'] != null) ...[
                      Text(
                        'Topic: ${item['topic']}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (item['points'] != null) ...[
                      Text(
                        'Points: ${item['points']}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (item['dueDate'] != null) ...[
                      Text(
                        'Due: ${item['dueDate']}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Created: ${item['createdAt']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          // Actions Menu
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.black54,
              size: 20,
            ),
            onSelected: (value) {
              if (value == 'edit') {
                // Edit functionality
              } else if (value == 'delete') {
                // Delete functionality
              }
            },
            itemBuilder: (context) => [
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
                selectedIndex: _selectedSidebarIndex,
                onItemSelected: _handleSidebarSelection,
              ),
              // Main content
              Expanded(
                child: Column(
                  children: [
                    // AppBar
                    const InstructorAppBar(
                      instructorName: 'Mia Castro',
                      instructorRole: 'Instructor',
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
                                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF34A853),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF34A853).withOpacity(0.3),
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
                            Expanded(
                              child: _createdItems.isEmpty 
                                ? _buildEmptyState()
                                : _buildCreatedItemsList(),
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
                    ..._types.map((type) => GestureDetector(
                      onTap: () => _selectType(type),
                      child: Container(
                        width: 160,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
                        decoration: BoxDecoration(
                          color: _selectedType == type 
                              ? const Color(0xFF34A853).withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Image.asset(
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
                                color:   _selectedType == type 
                                    ?  Colors.black
                                    : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )).toList(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          // Period Dropdown (side by side with type dropdown)
          if (_showPeriodDropdown && (_selectedType == 'Assignment' || _selectedType == 'Activity'))
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
                    ..._periods.map((period) => GestureDetector(
                      onTap: () => _selectPeriod(period),
                      child: Container(
                        width: 160,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
                        decoration: BoxDecoration(
                          color: _selectedPeriod == period 
                              ? const Color(0xFF34A853).withOpacity(0.1)
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
                                color: _selectedPeriod == period 
                                    ?  Colors.black
                                    : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )).toList(),
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