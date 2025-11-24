import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../shared/admin/admin_navigation_constants.dart';
import '../shared/admin/admin_sidebar.dart';
import '../shared/admin/widgets/admin_page_hero.dart';
import '../shared/widgets/tree_analytics_chart.dart';

class ManageTreesScreen extends StatefulWidget {
  const ManageTreesScreen({super.key});

  @override
  State<ManageTreesScreen> createState() => _ManageTreesScreenState();
}

class _ManageTreesScreenState extends State<ManageTreesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AdminNavigationItem _selectedItem = AdminNavigationItem.manageTrees;
  List<TreeMetricPoint> _treeMetrics = const [];
  bool _isChartLoading = true;
  String? _chartError;

  void _handleNavigationSelect(AdminNavigationItem item) {
    setState(() => _selectedItem = item);
    final route = AdminNavigationHelper.getRoute(item);
    if (route != '/admin-manage-trees') {
      Get.toNamed(route);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTreeMetrics();
  }

  Future<void> _loadTreeMetrics() async {
    setState(() {
      _isChartLoading = true;
      _chartError = null;
    });

    try {
      final snapshot = await _firestore.collectionGroup('trees').get();
      final Map<String, double> totalsByLabel = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final rawLocation = data['location']?.toString().trim();
        final rawSection = data['plantedBy']?.toString().trim();
        final label =
            (rawLocation != null && rawLocation.isNotEmpty)
                ? rawLocation
                : (rawSection != null && rawSection.isNotEmpty
                    ? rawSection
                    : 'Uncategorized');

        final quantity = data['quantity'];
        final double qtyValue =
            quantity is num ? quantity.toDouble() : 1.0; // fallback

        totalsByLabel[label] = (totalsByLabel[label] ?? 0) + qtyValue;
      }

      final sortedEntries =
          totalsByLabel.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      if (!mounted) return;
      setState(() {
        _treeMetrics =
            sortedEntries
                .map(
                  (entry) =>
                      TreeMetricPoint(label: entry.key, value: entry.value),
                )
                .toList();
        _isChartLoading = false;
      });
    } catch (e) {
      print('Error loading tree metrics: $e');
      if (!mounted) return;
      setState(() {
        _treeMetrics = const [];
        _isChartLoading = false;
        _chartError = 'Failed to load tree metrics. Please try again later.';
      });
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: SizedBox(
                      height: 360,
                      child:
                          _isChartLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _chartError != null
                              ? Center(
                                child: Text(
                                  _chartError!,
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                              )
                              : TreeAnalyticsChart(
                                data: _treeMetrics,
                                title: 'Trees Planted by Location/Section',
                                subtitle:
                                    'Aggregated totals across all instructors',
                              ),
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
