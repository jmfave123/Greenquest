import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../shared/admin/admin_navigation_constants.dart';
import '../shared/admin/admin_sidebar.dart';
import '../shared/admin/widgets/admin_page_hero.dart';

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
              children: const [
                AdminPageHero(
                  leading: Icon(
                    Icons.nature,
                    color: Color(0xFF34A853),
                    size: 28,
                  ),
                  title: 'Tree Management',
                  subtitle: 'Monitor NSTP environmental initiatives',
                  heroTitle: 'Environmental Impact Tracker',
                  heroDescription:
                      'Celebrate NSTP tree-planting efforts and keep the green initiative thriving.',
                ),
                Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
