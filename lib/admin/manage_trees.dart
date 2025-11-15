import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../shared/admin/admin_navigation_constants.dart';
import '../shared/admin/admin_sidebar.dart';

class ManageTreesScreen extends StatefulWidget {
  const ManageTreesScreen({super.key});

  @override
  State<ManageTreesScreen> createState() => _ManageTreesScreenState();
}

class _ManageTreesScreenState extends State<ManageTreesScreen> {
  AdminNavigationItem _selectedItem = AdminNavigationItem.manageTrees;

  void _handleNavigationSelect(AdminNavigationItem item) {
    setState(() => _selectedItem = item);
    final route = AdminNavigationHelper.getRoute(item);
    if (route != '/admin-manage-trees') {
      Get.toNamed(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Row(
        children: [
          AdminSidebar(
            selectedItem: _selectedItem,
            onItemSelected: _handleNavigationSelect,
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    ),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.nature, color: Color(0xFF34A853), size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tree Management',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Monitor NSTP environmental initiatives',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF34A853), Color(0xFF1B5E20)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF34A853).withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Environmental Impact Tracker',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Celebrate NSTP tree-planting efforts and keep the green initiative thriving.',
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
