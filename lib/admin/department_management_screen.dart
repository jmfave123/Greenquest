import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/admin/admin_sidebar.dart';
import '../shared/admin/admin_navigation_constants.dart';
import '../shared/admin/widgets/admin_page_hero.dart';
import '../shared/widgets/safe_asset_image.dart';
import '../shared/widgets/confirmation_dialog.dart';
import '../shared/widgets/skeleton_loading.dart';
import 'services/department_service.dart';
import 'services/section_service.dart';
import 'services/semester_service.dart';
import 'services/semester_assignment_service.dart';
import 'widgets/dialogs/create_department_dialog.dart';
import 'widgets/dialogs/edit_department_dialog.dart';
import 'widgets/dialogs/add_section_dialog.dart';
import 'widgets/dialogs/create_semester_dialog.dart';
import 'widgets/dialogs/edit_semester_dialog.dart';

class DepartmentManagementScreen extends StatefulWidget {
  const DepartmentManagementScreen({super.key});

  @override
  State<DepartmentManagementScreen> createState() =>
      _DepartmentManagementScreenState();
}

class _DepartmentManagementScreenState extends State<DepartmentManagementScreen>
    with AutomaticKeepAliveClientMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AdminNavigationItem _selectedItem = AdminNavigationItem.manageDepartments;
  List<Map<String, dynamic>> _semesters = [];

  // Service instances
  late final DepartmentService _departmentService;
  late final SectionService _sectionService;
  late final SemesterService _semesterService;

  @override
  bool get wantKeepAlive => true;

  void _handleNavigationSelect(AdminNavigationItem item) {
    debugPrint('Navigation selected: $item');
    setState(() {
      _selectedItem = item;
    });
    String route = AdminNavigationHelper.getRoute(item);
    debugPrint('Navigating to route: $route');
    Get.toNamed(route);
  }

  void _createDepartment() {
    showDialog(
      context: context,
      builder:
          (context) => CreateDepartmentDialog(
            onSave: (name, code, description) {
              _departmentService.createDepartment(name, code, description);
            },
          ),
    );
  }

  void _editDepartment(
    String departmentId,
    Map<String, dynamic> departmentData,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => EditDepartmentDialog(
            departmentData: departmentData,
            onUpdate: (name, code, description) {
              _departmentService.updateDepartment(
                departmentId,
                name,
                code,
                description,
              );
            },
          ),
    );
  }

  void _addSection(
    String departmentId,
    String departmentName,
    String departmentCode,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AddSectionDialog(
            departmentName: departmentName,
            departmentCode: departmentCode,
            onSave: (year, letter, subCode) {
              _sectionService.createSection(
                departmentId,
                year,
                letter,
                departmentCode,
                subCode,
              );
            },
          ),
    );
  }

  Future<void> _editSection(
    String sectionId,
    Map<String, dynamic> sectionData,
  ) async {
    String selectedYear = sectionData['year'] ?? '1st';
    String selectedSectionLetter = sectionData['sectionLetter'] ?? 'A';
    String? selectedSubCode = sectionData['subCode'];

    // Get department code to check if it's BTLED
    final departmentId = sectionData['departmentId'];
    final departmentDoc =
        await _firestore.collection('departments').doc(departmentId).get();
    final departmentData = departmentDoc.data();
    final departmentCode = departmentData?['code'] ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF34A853).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Color(0xFF34A853),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit Section',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Update section information',
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
                    const SizedBox(height: 24),

                    // Year Selection
                    const Text(
                      'Year Level',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedYear,
                          isExpanded: true,
                          items:
                              ['1st', '2nd', '3rd', '4th'].map((year) {
                                return DropdownMenuItem(
                                  value: year,
                                  child: Text(year),
                                );
                              }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedYear = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section Letter Selection
                    const Text(
                      'Section Letter',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedSectionLetter,
                          isExpanded: true,
                          items:
                              ['A', 'B', 'C', 'D', 'E', 'F'].map((letter) {
                                return DropdownMenuItem(
                                  value: letter,
                                  child: Text(letter),
                                );
                              }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedSectionLetter = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sub-Code Selection (Only for BTLED)
                    if (departmentCode == 'BTLED') ...[
                      const Text(
                        'Sub-Code',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedSubCode,
                            isExpanded: true,
                            items:
                                ['ICT', 'HE', 'IA'].map((subCode) {
                                  return DropdownMenuItem(
                                    value: subCode,
                                    child: Text(subCode),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedSubCode = value;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black54,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    // Validate BTLED requires subcode
                    if (departmentCode == 'BTLED' &&
                        (selectedSubCode == null || selectedSubCode!.isEmpty)) {
                      Get.snackbar(
                        'Validation Error',
                        'Sub-code is required for BTLED sections',
                        backgroundColor: Colors.orange,
                        colorText: Colors.white,
                      );
                      return;
                    }
                    Navigator.of(context).pop();
                    _updateSection(
                      sectionId,
                      selectedYear,
                      selectedSectionLetter,
                      selectedSubCode,
                      departmentCode,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF34A853),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateSection(
    String sectionId,
    String year,
    String sectionLetter,
    String? subCode,
    String departmentCode,
  ) async {
    await _sectionService.updateSection(
      sectionId,
      year,
      sectionLetter,
      subCode,
      departmentCode,
    );
  }

  Future<void> _deleteDepartment(
    String departmentId,
    String departmentName,
  ) async {
    await ConfirmationDialog.showDeleteDepartmentDialog(
      context,
      departmentName: departmentName,
      onConfirm: () async {
        await _departmentService.deleteDepartment(departmentId);
      },
    );
  }

  Future<void> _deleteSection(String sectionId, String sectionCode) async {
    await ConfirmationDialog.showDeleteSectionDialog(
      context,
      sectionCode: sectionCode,
      onConfirm: () async {
        await _sectionService.deleteSection(sectionId);
      },
    );
  }

  // Semester Management Methods
  void _createSemester() {
    showDialog(
      context: context,
      builder:
          (context) => CreateSemesterDialog(
            onSave: (year, semester) {
              _semesterService.createSemester(year, semester);
            },
          ),
    );
  }

  Future<void> _loadSemesters() async {
    _semesters = await _semesterService.loadSemesters();
    setState(() {});
  }

  void _showSemesterDetails(Map<String, dynamic> semester) {
    showDialog(
      context: context,
      builder:
          (context) =>
              SemesterDetailView(semester: semester, firestore: _firestore),
    );
  }

  void _showSemesterAssignmentDialog(Map<String, dynamic> semester) {
    showDialog(
      context: context,
      builder:
          (context) => SemesterAssignmentDialog(
            semester: semester,
            firestore: _firestore,
          ),
    );
  }

  void _editSemester(Map<String, dynamic> semester) {
    final String semesterId = semester['id'] ?? '';
    showDialog(
      context: context,
      builder:
          (context) => EditSemesterDialog(
            semesterData: semester,
            onUpdate: (year, semesterName) {
              _semesterService.updateSemester(semesterId, year, semesterName);
            },
          ),
    );
  }

  // Responsive helpers
  bool get isMobile {
    return MediaQuery.of(context).size.width < 768;
  }

  bool get isTablet {
    final width = MediaQuery.of(context).size.width;
    return width >= 768 && width < 1024;
  }

  bool get isDesktop {
    return MediaQuery.of(context).size.width >= 1024;
  }

  double getResponsivePadding() {
    if (isMobile) return 16;
    if (isTablet) return 20;
    return 24;
  }

  @override
  void initState() {
    super.initState();
    // Initialize services
    _departmentService = DepartmentService(_firestore);
    _sectionService = SectionService(_firestore);
    _semesterService = SemesterService(_firestore);
    _loadSemesters();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload semesters when the screen becomes visible
    _loadSemesters();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Row(
        children: [
          // Sidebar
          AdminSidebar(
            selectedItem: _selectedItem,
            onItemSelected: _handleNavigationSelect,
          ),
          // Main content
          Expanded(
            child: Column(
              children: [
                AdminPageHero(
                  leading: SafeAssetImage(
                    assetPath:
                        'assets/admin_icons/fluent_hat-graduation-12-regular.png',
                    width: isMobile ? 28 : 32,
                    height: isMobile ? 28 : 32,
                  ),
                  title: 'Department Management',
                  subtitle: 'Manage departments and sections',
                  heroTitle: 'Department, Section and Semester Management',
                  heroDescription: 'Manage departments, section and semesters.',
                  headerPadding: EdgeInsets.all(getResponsivePadding()),
                  heroPadding: EdgeInsets.all(isMobile ? 16 : 24),
                  heroMargin: EdgeInsets.fromLTRB(
                    getResponsivePadding(),
                    12,
                    getResponsivePadding(),
                    24,
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(getResponsivePadding()),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Departments',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _createDepartment,
                              icon: const Icon(Icons.add_rounded, size: 20),
                              label: const Text('Create Department'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF34A853),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Departments List
                        StreamBuilder<QuerySnapshot>(
                          stream:
                              _firestore.collection('departments').snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const SkeletonDepartmentList();
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.error,
                                      size: 64,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(height: 16),
                                    Text('Error: ${snapshot.error}'),
                                  ],
                                ),
                              );
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF34A853,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(
                                        Icons.school_outlined,
                                        size: 40,
                                        color: Color(0xFF34A853),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'No departments found',
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.grey[800],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Create your first department to get started',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: snapshot.data!.docs.length,
                              itemBuilder: (context, index) {
                                final doc = snapshot.data!.docs[index];
                                final data = doc.data() as Map<String, dynamic>;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFE5E7EB),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      // Department Header
                                      Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF34A853,
                                                ).withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.school_rounded,
                                                color: Color(0xFF34A853),
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    data['displayName'] ??
                                                        data['name'] ??
                                                        '',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Code: ${data['code'] ?? 'N/A'}',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  if (data['description'] !=
                                                          null &&
                                                      data['description']
                                                          .isNotEmpty)
                                                    Text(
                                                      data['description'],
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              onPressed:
                                                  () => _editDepartment(
                                                    doc.id,
                                                    data,
                                                  ),
                                              icon: const Icon(
                                                Icons.edit_rounded,
                                                color: Color(0xFF34A853),
                                              ),
                                              tooltip: 'Edit Department',
                                            ),
                                            IconButton(
                                              onPressed:
                                                  () => _addSection(
                                                    doc.id,
                                                    data['displayName'] ??
                                                        data['name'],
                                                    data['code'],
                                                  ),
                                              icon: const Icon(
                                                Icons.add_rounded,
                                              ),
                                              tooltip: 'Add Section',
                                            ),
                                            IconButton(
                                              onPressed:
                                                  () => _deleteDepartment(
                                                    doc.id,
                                                    data['displayName'] ??
                                                        data['name'] ??
                                                        'Unknown',
                                                  ),
                                              icon: const Icon(
                                                Icons.delete_rounded,
                                                color: Colors.red,
                                              ),
                                              tooltip: 'Delete Department',
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Sections List
                                      StreamBuilder<QuerySnapshot>(
                                        stream:
                                            _firestore
                                                .collection('sections')
                                                .where(
                                                  'departmentId',
                                                  isEqualTo: doc.id,
                                                )
                                                .snapshots(),
                                        builder: (context, sectionsSnapshot) {
                                          if (sectionsSnapshot
                                                  .connectionState ==
                                              ConnectionState.waiting) {
                                            return const Padding(
                                              padding: EdgeInsets.all(20),
                                              child: Center(
                                                child: CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Color(0xFF34A853)),
                                                ),
                                              ),
                                            );
                                          }

                                          if (!sectionsSnapshot.hasData ||
                                              sectionsSnapshot
                                                  .data!
                                                  .docs
                                                  .isEmpty) {
                                            return Container(
                                              padding: const EdgeInsets.all(20),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[50],
                                                borderRadius:
                                                    const BorderRadius.only(
                                                      bottomLeft:
                                                          Radius.circular(16),
                                                      bottomRight:
                                                          Radius.circular(16),
                                                    ),
                                              ),
                                              child: const Center(
                                                child: Text(
                                                  'No sections yet. Click + to add sections.',
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }

                                          // Sort sections alphabetically by sectionCode
                                          final sortedDocs =
                                              sectionsSnapshot.data!.docs
                                                  .toList()
                                                ..sort((a, b) {
                                                  final aData =
                                                      a.data()
                                                          as Map<
                                                            String,
                                                            dynamic
                                                          >;
                                                  final bData =
                                                      b.data()
                                                          as Map<
                                                            String,
                                                            dynamic
                                                          >;
                                                  final aCode =
                                                      (aData['sectionCode'] ??
                                                              '')
                                                          .toString()
                                                          .toUpperCase();
                                                  final bCode =
                                                      (bData['sectionCode'] ??
                                                              '')
                                                          .toString()
                                                          .toUpperCase();
                                                  return aCode.compareTo(bCode);
                                                });

                                          return Column(
                                            children:
                                                sortedDocs.map((sectionDoc) {
                                                  final sectionData =
                                                      sectionDoc.data()
                                                          as Map<
                                                            String,
                                                            dynamic
                                                          >;
                                                  return Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                          left: 20,
                                                          right: 20,
                                                          bottom: 8,
                                                        ),
                                                    padding:
                                                        const EdgeInsets.all(
                                                          16,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[50],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      border: Border.all(
                                                        color:
                                                            Colors.grey[200]!,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons
                                                              .group_work_rounded,
                                                          color: Color(
                                                            0xFF34A853,
                                                          ),
                                                          size: 20,
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                '${sectionData['year'] ?? 'N/A'} Year - Section ${sectionData['sectionLetter'] ?? 'N/A'}',
                                                                style: const TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      Colors
                                                                          .black,
                                                                ),
                                                              ),
                                                              Text(
                                                                'Code: ${sectionData['sectionCode'] ?? 'N/A'}',
                                                                style: const TextStyle(
                                                                  fontSize: 12,
                                                                  color:
                                                                      Colors
                                                                          .grey,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        IconButton(
                                                          onPressed:
                                                              () =>
                                                                  _editSection(
                                                                    sectionDoc
                                                                        .id,
                                                                    sectionData,
                                                                  ),
                                                          icon: const Icon(
                                                            Icons.edit_rounded,
                                                            color: Color(
                                                              0xFF34A853,
                                                            ),
                                                            size: 18,
                                                          ),
                                                          tooltip:
                                                              'Edit Section',
                                                        ),
                                                        IconButton(
                                                          onPressed:
                                                              () => _deleteSection(
                                                                sectionDoc.id,
                                                                sectionData['sectionCode'] ??
                                                                    'Unknown',
                                                              ),
                                                          icon: const Icon(
                                                            Icons
                                                                .delete_rounded,
                                                            color: Colors.red,
                                                            size: 18,
                                                          ),
                                                          tooltip:
                                                              'Delete Section',
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 48),
                        // Semesters Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Semesters',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: _loadSemesters,
                                  icon: const Icon(Icons.refresh),
                                  tooltip: 'Refresh Semesters',
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: _createSemester,
                                  icon: const Icon(Icons.add_rounded, size: 20),
                                  label: const Text('Create Semester'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF34A853),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Semesters List
                        StreamBuilder<QuerySnapshot>(
                          stream:
                              _firestore
                                  .collection('semesters')
                                  .orderBy('createdAt', descending: true)
                                  .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF34A853),
                                  ),
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.error,
                                      size: 64,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(height: 16),
                                    Text('Error: ${snapshot.error}'),
                                  ],
                                ),
                              );
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF34A853,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(
                                        Icons.calendar_month,
                                        size: 40,
                                        color: Color(0xFF34A853),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'No semesters found',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Create your first semester to get started',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final semesters =
                                snapshot.data!.docs.map((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  return {
                                    'id': doc.id,
                                    'year': data['year'] ?? '',
                                    'semester': data['semester'] ?? '',
                                    'displayName': data['displayName'] ?? '',
                                    'isActive': data['isActive'] ?? true,
                                    'createdAt': data['createdAt'],
                                  };
                                }).toList();

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: semesters.length,
                              itemBuilder: (context, index) {
                                final semester = semesters[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: InkWell(
                                    onTap: () => _showSemesterDetails(semester),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF34A853,
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.calendar_month,
                                              color: Color(0xFF34A853),
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  semester['displayName'] ?? '',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Year: ${semester['year'] ?? 'N/A'}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                Text(
                                                  'Type: ${semester['semester'] ?? 'N/A'}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          IconButton(
                                            onPressed:
                                                () =>
                                                    _showSemesterAssignmentDialog(
                                                      semester,
                                                    ),
                                            icon: const Icon(
                                              Icons.assignment,
                                              color: Color(0xFF34A853),
                                              size: 20,
                                            ),
                                            tooltip: 'Assign to Semester',
                                          ),
                                          IconButton(
                                            onPressed:
                                                () => _editSemester(semester),
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Color(0xFF34A853),
                                              size: 20,
                                            ),
                                            tooltip: 'Edit Semester',
                                          ),
                                          const Icon(
                                            Icons.arrow_forward_ios,
                                            color: Colors.grey,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
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

class SemesterDetailView extends StatefulWidget {
  final Map<String, dynamic> semester;
  final FirebaseFirestore firestore;

  const SemesterDetailView({
    super.key,
    required this.semester,
    required this.firestore,
  });

  @override
  State<SemesterDetailView> createState() => _SemesterDetailViewState();
}

class _SemesterDetailViewState extends State<SemesterDetailView> {
  final List<Map<String, dynamic>> _departments = [];
  final List<Map<String, dynamic>> _instructors = [];
  final List<Map<String, dynamic>> _classes = [];
  bool _isLoading = true;
  int _expandedClassIndex = -1;

  @override
  void initState() {
    super.initState();
    // Defer loading to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // _loadSemesterData();
        SemesterService(widget.firestore)
            .loadSemesterData(widget.semester['id'])
            .then((data) {
              if (!mounted) return;
              setState(() {
                _departments.clear();
                _departments.addAll(data['departments'] ?? []);
                _instructors.clear();
                _instructors.addAll(data['instructors'] ?? []);
                _classes.clear();
                _classes.addAll(data['classes'] ?? []);
                _isLoading = false;
              });
            })
            .catchError((e) {
              print('Error loading semester data: $e');
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF34A853).withOpacity(0.1),
                  child: const Icon(
                    Icons.calendar_month,
                    color: Color(0xFF34A853),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Semester Details',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.semester['displayName'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Stats
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34A853).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF34A853).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.school,
                          color: Color(0xFF34A853),
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_departments.length}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF34A853),
                          ),
                        ),
                        const Text(
                          'Departments',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF34A853),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34A853).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF34A853).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.person,
                          color: Color(0xFF34A853),
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_instructors.length}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF34A853),
                          ),
                        ),
                        const Text(
                          'Instructors',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF34A853),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34A853).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF34A853).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.class_,
                          color: Color(0xFF34A853),
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_classes.length}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF34A853),
                          ),
                        ),
                        const Text(
                          'Classes',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF34A853),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Content
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : DefaultTabController(
                        length: 3,
                        child: Column(
                          children: [
                            const TabBar(
                              labelColor: Color(0xFF34A853),
                              unselectedLabelColor: Colors.grey,
                              indicatorColor: Color(0xFF34A853),
                              tabs: [
                                Tab(text: 'Departments'),
                                Tab(text: 'Instructors'),
                                Tab(text: 'Classes'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  _buildDepartmentsList(),
                                  _buildInstructorsList(),
                                  _buildClassesList(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentsList() {
    if (_departments.isEmpty) {
      return const Center(child: Text('No departments found'));
    }

    return ListView.builder(
      itemCount: _departments.length,
      itemBuilder: (context, index) {
        final department = _departments[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              const Icon(Icons.school, color: Color(0xFF34A853), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      department['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Code: ${department['code']}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstructorsList() {
    if (_instructors.isEmpty) {
      return const Center(child: Text('No instructors found'));
    }

    return ListView.builder(
      itemCount: _instructors.length,
      itemBuilder: (context, index) {
        final instructor = _instructors[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              const Icon(Icons.person, color: Color(0xFF34A853), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      instructor['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Department: ${instructor['department']}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClassesList() {
    if (_classes.isEmpty) {
      return const Center(child: Text('No classes found'));
    }

    return ListView.builder(
      itemCount: _classes.length,
      itemBuilder: (context, index) {
        final classItem = _classes[index];
        final isExpanded = _expandedClassIndex == index;
        final students =
            classItem['students'] as List<Map<String, dynamic>>? ?? [];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF34A853).withOpacity(0.2),
              width: isExpanded ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _expandedClassIndex = isExpanded ? -1 : index;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34A853).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.class_,
                          color: Color(0xFF34A853),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              classItem['section'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Instructor: ${classItem['instructorName']}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${students.length} student${students.length != 1 ? 's' : ''} enrolled',
                              style: const TextStyle(
                                color: Color(0xFF34A853),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: const Color(0xFF34A853),
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded && students.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.black26),
                      const SizedBox(height: 8),
                      const Text(
                        'Students',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: students.length > 5 ? 300 : null,
                        child:
                            students.length > 5
                                ? ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: students.length,
                                  itemBuilder: (context, studentIndex) {
                                    final student = students[studentIndex];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey[200]!,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: const Color(
                                                0xFF34A853,
                                              ).withOpacity(0.1),
                                            ),
                                            child: Center(
                                              child: Text(
                                                (student['name']
                                                        ?.toString()
                                                        .substring(0, 1)
                                                        .toUpperCase() ??
                                                    'U'),
                                                style: const TextStyle(
                                                  color: Color(0xFF34A853),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  student['name'] ?? 'Unknown',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  student['email'] ?? '',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                if (student['idNumber'] !=
                                                        null &&
                                                    (student['idNumber']
                                                            as String)
                                                        .isNotEmpty)
                                                  Text(
                                                    'ID Number: ${student['idNumber']}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                color: const Color(0xFFBDBDBD),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              student['program'] ?? 'N/A',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                                : Column(
                                  children:
                                      students.map((student) {
                                        return Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey[200]!,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: const Color(
                                                    0xFF34A853,
                                                  ).withOpacity(0.1),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    (student['name']
                                                            ?.toString()
                                                            .substring(0, 1)
                                                            .toUpperCase() ??
                                                        'U'),
                                                    style: const TextStyle(
                                                      color: Color(0xFF34A853),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      student['name'] ??
                                                          'Unknown',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    Text(
                                                      student['email'] ?? '',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFFBDBDBD,
                                                    ),
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  student['program'] ?? 'N/A',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class SemesterAssignmentDialog extends StatefulWidget {
  final Map<String, dynamic> semester;
  final FirebaseFirestore firestore;

  const SemesterAssignmentDialog({
    super.key,
    required this.semester,
    required this.firestore,
  });

  @override
  State<SemesterAssignmentDialog> createState() =>
      _SemesterAssignmentDialogState();
}

class _SemesterAssignmentDialogState extends State<SemesterAssignmentDialog> {
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _instructors = [];
  final List<Map<String, dynamic>> _classes = [];
  List<String> _selectedDepartments = [];
  List<String> _selectedInstructors = [];
  List<String> _selectedClasses = [];
  bool _isLoading = true;
  late final SemesterAssignmentService _assignmentService;

  @override
  void initState() {
    super.initState();
    _assignmentService = SemesterAssignmentService(widget.firestore);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load all assignment data
      final assignmentData = await _assignmentService.loadAssignmentData();
      _departments = assignmentData['departments'] ?? [];
      _instructors = assignmentData['instructors'] ?? [];
      _classes.clear();
      _classes.addAll(assignmentData['classes'] ?? []);

      // Load existing assignments for this semester
      final semesterId = widget.semester['id'];
      final existingAssignments = await _assignmentService
          .loadExistingAssignments(semesterId);
      _selectedDepartments = existingAssignments['departments'] ?? [];
      _selectedInstructors = existingAssignments['instructors'] ?? [];
      _selectedClasses = existingAssignments['classes'] ?? [];

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAssignments() async {
    try {
      final semesterId = widget.semester['id'];

      // Prepare semester data for instructor assignments
      final semesterData = {
        'semesterId': semesterId,
        'displayName': widget.semester['displayName'] ?? '',
        'year': widget.semester['year'] ?? '',
        'semester': widget.semester['semester'] ?? '',
        'isActive': widget.semester['isActive'] ?? true,
        'assignedAt': Timestamp.now(),
      };

      // Save all assignments using the service
      await _assignmentService.saveAllAssignments(
        semesterId,
        semesterData,
        _selectedDepartments,
        _selectedInstructors,
        _selectedClasses,
      );

      Navigator.of(context).pop();
    } catch (e) {
      // Error handling is done in the service
      print('Error in _saveAssignments: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF34A853).withOpacity(0.1),
                  child: const Icon(
                    Icons.assignment,
                    color: Color(0xFF34A853),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assign to Semester',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.semester['displayName'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Content
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : DefaultTabController(
                        length: 3,
                        child: Column(
                          children: [
                            const TabBar(
                              labelColor: Color(0xFF34A853),
                              unselectedLabelColor: Colors.grey,
                              indicatorColor: Color(0xFF34A853),
                              tabs: [
                                Tab(text: 'Departments'),
                                Tab(text: 'Instructors'),
                                Tab(text: 'Classes'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  _buildDepartmentsTab(),
                                  _buildInstructorsTab(),
                                  _buildClassesTab(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saveAssignments,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF34A853),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Assignments'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentsTab() {
    return ListView.builder(
      itemCount: _departments.length,
      itemBuilder: (context, index) {
        final department = _departments[index];
        final isSelected = _selectedDepartments.contains(department['id']);

        return CheckboxListTile(
          title: Text(department['name']),
          subtitle: Text('Code: ${department['code']}'),
          value: isSelected,
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                _selectedDepartments.add(department['id']);
              } else {
                _selectedDepartments.remove(department['id']);
              }
            });
          },
          activeColor: const Color(0xFF34A853),
        );
      },
    );
  }

  Widget _buildInstructorsTab() {
    return ListView.builder(
      itemCount: _instructors.length,
      itemBuilder: (context, index) {
        final instructor = _instructors[index];
        final isSelected = _selectedInstructors.contains(instructor['id']);

        return CheckboxListTile(
          title: Text(instructor['name']),
          subtitle: Text('Department: ${instructor['department']}'),
          value: isSelected,
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                _selectedInstructors.add(instructor['id']);
              } else {
                _selectedInstructors.remove(instructor['id']);
              }
            });
          },
          activeColor: const Color(0xFF34A853),
        );
      },
    );
  }

  Widget _buildClassesTab() {
    return ListView.builder(
      itemCount: _classes.length,
      itemBuilder: (context, index) {
        final classItem = _classes[index];
        final isSelected = _selectedClasses.contains(classItem['id']);

        return CheckboxListTile(
          title: Text(classItem['section']),
          subtitle: Text('Instructor: ${classItem['instructorName']}'),
          value: isSelected,
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                _selectedClasses.add(classItem['id']);
              } else {
                _selectedClasses.remove(classItem['id']);
              }
            });
          },
          activeColor: const Color(0xFF34A853),
        );
      },
    );
  }
}
