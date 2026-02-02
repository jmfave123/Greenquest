import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../shared/admin/admin_navigation_constants.dart';
import '../shared/admin/admin_sidebar.dart';
import '../shared/admin/widgets/admin_page_hero.dart';
import '../shared/widgets/monthly_tree_trends_chart.dart';
import '../shared/widgets/year_filter_dropdown.dart';

class ManageTreesScreen extends StatefulWidget {
  const ManageTreesScreen({super.key});

  @override
  State<ManageTreesScreen> createState() => _ManageTreesScreenState();
}

class _ManageTreesScreenState extends State<ManageTreesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AdminNavigationItem _selectedItem = AdminNavigationItem.manageTrees;
  int? _selectedYear; // null means "All Years"

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
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AdminPageHero(
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
                  const SizedBox(height: 24),
                  // Year Filter
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        YearFilterDropdown(
                          selectedYear: _selectedYear,
                          onYearChanged: (year) {
                            setState(() {
                              _selectedYear = year;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tree Trends Chart
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: MonthlyTreeTrendsChart(
                      key: ValueKey(
                        _selectedYear,
                      ), // Force rebuild on year change
                      title: 'Tree Planting Trends',
                      year: _selectedYear,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
