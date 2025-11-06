import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/instructor/instructor_appbar.dart';
import '../../shared/instructor/instructor_sidebar.dart';
import '../../shared/instructor/instructor_navigation_constants.dart';
import '../../shared/widgets/skeleton_loading.dart';
import 'report_controller.dart';

class InstructorReportScreen extends StatefulWidget {
  const InstructorReportScreen({super.key});

  @override
  State<InstructorReportScreen> createState() => _InstructorReportScreenState();
}

class _InstructorReportScreenState extends State<InstructorReportScreen> {
  InstructorNavigationItem _selectedItem = InstructorNavigationItem.reports;
  late final ReportController _reportController;
  final TextEditingController _searchController = TextEditingController();
  final _searchQuery = ''.obs;

  @override
  void initState() {
    super.initState();
    _reportController = Get.put(ReportController());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchQuery.value = query;
  }

  List<Map<String, dynamic>> get _filteredClasses {
    if (_searchQuery.value.isEmpty) {
      return _reportController.classes;
    }

    return _reportController.classes.where((classData) {
      final name = classData['name']?.toString().toLowerCase() ?? '';
      final desc = classData['desc']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.value.toLowerCase();

      return name.contains(query) || desc.contains(query);
    }).toList();
  }

  void _onNavigationSelect(InstructorNavigationItem item) {
    setState(() => _selectedItem = item);
    String route = InstructorNavigationHelper.getRoute(item);
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          InstructorSidebar(
            selectedItem: _selectedItem,
            onItemSelected: _onNavigationSelect,
          ),
          Expanded(
            child: Column(
              children: [
                Obx(
                  () => InstructorAppBar(
                    instructorName: _reportController.instructorName.value,
                    instructorRole: 'Instructor',
                    profileImageUrl: _reportController.profileImageUrl.value,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reports',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Manage your classes  and track environmental impact through education',
                          style: TextStyle(color: Colors.black38, fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        // Search Bar
                        Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: 'Search classes...',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.grey[500],
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Expanded(
                          child: Obx(() {
                            if (_reportController.isLoading.value) {
                              return LayoutBuilder(
                                builder: (context, constraints) {
                                  // Calculate responsive grid parameters
                                  final screenWidth = constraints.maxWidth;
                                  int crossAxisCount;
                                  double childAspectRatio;

                                  if (screenWidth > 1400) {
                                    crossAxisCount = 4;
                                    childAspectRatio = 2.2;
                                  } else if (screenWidth > 1200) {
                                    crossAxisCount = 3;
                                    childAspectRatio = 2.1;
                                  } else if (screenWidth > 900) {
                                    crossAxisCount = 2;
                                    childAspectRatio = 2.0;
                                  } else {
                                    crossAxisCount = 1;
                                    childAspectRatio = 3.8;
                                  }

                                  return GridView.builder(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: crossAxisCount,
                                          crossAxisSpacing: 20,
                                          mainAxisSpacing: 20,
                                          childAspectRatio: childAspectRatio,
                                        ),
                                    itemCount: 6,
                                    itemBuilder: (context, i) {
                                      return const SkeletonInstructorReportClassCard();
                                    },
                                  );
                                },
                              );
                            }

                            if (_reportController
                                .errorMessage
                                .value
                                .isNotEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 64,
                                      color: Colors.red[300],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Error loading classes',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red[700],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _reportController.errorMessage.value,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.red[600]),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed:
                                          () =>
                                              _reportController
                                                  .refreshClasses(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF34A853,
                                        ),
                                      ),
                                      child: const Text(
                                        'Retry',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final filteredClasses = _filteredClasses;

                            if (filteredClasses.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _searchQuery.value.isNotEmpty
                                          ? Icons.search_off
                                          : Icons.school_outlined,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _searchQuery.value.isNotEmpty
                                          ? 'No classes found'
                                          : 'No classes found',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _searchQuery.value.isNotEmpty
                                          ? 'No classes match your search "${_searchQuery.value}"'
                                          : 'You don\'t have any assigned classes yet.',
                                      style: TextStyle(color: Colors.grey[500]),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        if (_searchQuery.value.isNotEmpty) {
                                          _searchController.clear();
                                          _searchQuery.value = '';
                                        } else {
                                          _reportController.refreshClasses();
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF34A853,
                                        ),
                                      ),
                                      child: Text(
                                        _searchQuery.value.isNotEmpty
                                            ? 'Clear Search'
                                            : 'Refresh',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Column(
                              children: [
                                // Search results counter
                                if (_searchQuery.value.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Row(
                                      children: [
                                        Text(
                                          '${filteredClasses.length} class${filteredClasses.length == 1 ? '' : 'es'} found',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                        const Spacer(),
                                        TextButton(
                                          onPressed: () {
                                            _searchController.clear();
                                            _searchQuery.value = '';
                                          },
                                          child: Text(
                                            'Clear search',
                                            style: TextStyle(
                                              color: const Color(0xFF34A853),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Expanded(
                                  child: RefreshIndicator(
                                    onRefresh:
                                        () =>
                                            _reportController.refreshClasses(),
                                    color: const Color(0xFF34A853),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        // Calculate responsive grid parameters
                                        final screenWidth =
                                            constraints.maxWidth;
                                        int crossAxisCount;
                                        double childAspectRatio;

                                        if (screenWidth > 1400) {
                                          // Large desktop screens
                                          crossAxisCount = 4;
                                          childAspectRatio = 2.2;
                                        } else if (screenWidth > 1200) {
                                          // Medium desktop screens
                                          crossAxisCount = 3;
                                          childAspectRatio = 2.1;
                                        } else if (screenWidth > 900) {
                                          // Small desktop/large tablet
                                          crossAxisCount = 2;
                                          childAspectRatio = 2.0;
                                        } else {
                                          // Mobile/tablet
                                          crossAxisCount = 1;
                                          childAspectRatio = 3.8;
                                        }

                                        return GridView.builder(
                                          gridDelegate:
                                              SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: crossAxisCount,
                                                crossAxisSpacing: 20,
                                                mainAxisSpacing: 20,
                                                childAspectRatio:
                                                    childAspectRatio,
                                              ),
                                          itemCount: filteredClasses.length,
                                          itemBuilder: (context, i) {
                                            final c = filteredClasses[i];
                                            return Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black12,
                                                    blurRadius: 8,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              padding: EdgeInsets.all(
                                                screenWidth > 1200 ? 16 : 12,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // Title with responsive font size
                                                  Flexible(
                                                    flex: 2,
                                                    child: Text(
                                                      c['name'],
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize:
                                                            screenWidth > 1200
                                                                ? 20
                                                                : 18,
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  // Description
                                                  Flexible(
                                                    flex: 1,
                                                    child: Text(
                                                      c['desc'],
                                                      style: const TextStyle(
                                                        color: Colors.black54,
                                                        fontSize: 12,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  // Student count and status
                                                  Flexible(
                                                    flex: 1,
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.people_outline,
                                                          size: 18,
                                                          color: Colors.black54,
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        Flexible(
                                                          child: Text(
                                                            '${c['students']} Students',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 13,
                                                                ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                        const Spacer(),
                                                        const Icon(
                                                          Icons.circle,
                                                          size: 10,
                                                          color: Color(
                                                            0xFF34A853,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        const Text(
                                                          'Active',
                                                          style: TextStyle(
                                                            color: Color(
                                                              0xFF34A853,
                                                            ),
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  // Manage Class button
                                                  Flexible(
                                                    flex: 1,
                                                    child: SizedBox(
                                                      width: double.infinity,
                                                      height: 32,
                                                      child: ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              const Color(
                                                                0xFF34A853,
                                                              ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  6,
                                                                ),
                                                          ),
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                vertical: 4,
                                                              ),
                                                        ),
                                                        onPressed: () {
                                                          Navigator.of(
                                                            context,
                                                          ).pushReplacementNamed(
                                                            '/instructor-class-report',
                                                            arguments: {
                                                              'classId':
                                                                  c['id'],
                                                              'className':
                                                                  c['name'],
                                                              'courseDescription':
                                                                  c['desc'],
                                                            },
                                                          );
                                                        },
                                                        child: const Text(
                                                          'Manage Class',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
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
    );
  }
}
