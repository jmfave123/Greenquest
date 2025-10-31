import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenquest/user/select/select_controller.dart';

class SelectCourseScreen extends StatefulWidget {
  const SelectCourseScreen({super.key});

  @override
  State<SelectCourseScreen> createState() => _SelectCourseScreenState();
}

class _SelectCourseScreenState extends State<SelectCourseScreen> {
  final controller = Get.put(SelectController());

  String? selectedDepartment;
  String? selectedSectionCode;
  Map<String, List<Map<String, dynamic>>> groupedAssignments = {};
  Map<String, bool> expandedDepartments = {};

  // final courses = [
  //   {
  //     'name': 'Bachelor of Science in Information Technology',
  //     'img': 'assets/images/image 331.png',
  //   },
  //   {
  //     'name': 'Bachelor of Science in Food Processing and Technology',
  //     'img': 'assets/images/image 337.png',
  //   },
  //   {
  //     'name': 'Bachelor of Technology and Livelihood Education',
  //     'img': 'assets/images/image 349.png',
  //   },
  // ];
  @override
  void initState() {
    super.initState();
    _groupAssignmentsByDepartment();
    // Listen to changes in instructor assignments
    controller.instructorAssignments.listen((_) {
      print('Instructor assignments changed in select_course_screen');
      print('New assignment count: ${controller.instructorAssignments.length}');
      if (mounted) {
        setState(() {
          _groupAssignmentsByDepartment();
        });
      }
    });
  }

  void _groupAssignmentsByDepartment() {
    print('Grouping assignments by department...');
    print('Total assignments: ${controller.instructorAssignments.length}');

    groupedAssignments.clear();
    expandedDepartments.clear();

    for (var assignment in controller.instructorAssignments) {
      String departmentId = assignment['departmentId'] ?? '';
      print(
        'Processing assignment: ${assignment['departmentCode']}-${assignment['sectionCode']}',
      );

      if (!groupedAssignments.containsKey(departmentId)) {
        groupedAssignments[departmentId] = [];
        expandedDepartments[departmentId] = false;
      }
      groupedAssignments[departmentId]!.add(assignment);
    }

    print('Grouped into ${groupedAssignments.length} departments');
  }

  void _toggleDepartment(String departmentId) {
    setState(() {
      expandedDepartments[departmentId] =
          !(expandedDepartments[departmentId] ?? false);
    });
    // No need to fetch sections - they're already available in groupedAssignments
  }

  void _selectSection(String departmentId, String sectionCode) {
    setState(() {
      // Clear any previous selection - user can only select ONE section total
      selectedDepartment = departmentId;
      selectedSectionCode = sectionCode;
    });
    // Update controller with selection
    controller.selectedDepartmentId.value = departmentId;
    controller.selectedSectionCode.value = sectionCode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Obx(() {
            final courses = controller.courses;
            if (controller.isLoading.value) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading courses...'),
                  ],
                ),
              );
            }
            if (courses.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No courses found'),
                    SizedBox(height: 8),
                    Text(
                      'Please try again later',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                const Text(
                  'Course and Sections',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select your course and section',
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 24),

                // Show instructor info with student name
                Obx(() {
                  if (controller.selectedInstructorName.value.isNotEmpty) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person,
                            color: Color(0xFF34A853),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Instructor: ${controller.selectedInstructorName.value}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  controller.studentName.value.isNotEmpty
                                      ? 'Student: ${controller.studentName.value}'
                                      : 'Select your department and section',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),

                // Grouped departments with section dropdowns
                Obx(() {
                  if (controller.instructorAssignments.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: const Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No assignments available',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'This instructor has no department-section assignments',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children:
                        groupedAssignments.entries.map<Widget>((entry) {
                          String departmentId = entry.key;
                          List<Map<String, dynamic>> sections = entry.value;
                          String departmentName =
                              sections.isNotEmpty
                                  ? sections.first['departmentName'] ??
                                      'Unknown Department'
                                  : 'Unknown Department';
                          String departmentCode =
                              sections.isNotEmpty
                                  ? sections.first['departmentCode'] ?? ''
                                  : '';
                          bool isExpanded =
                              expandedDepartments[departmentId] ?? false;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE0E0E0),
                              ),
                            ),
                            child: Column(
                              children: [
                                // Department header
                                GestureDetector(
                                  onTap: () => _toggleDepartment(departmentId),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF34A853,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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
                                                departmentName,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              Text(
                                                'Code: $departmentCode',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          isExpanded
                                              ? Icons.keyboard_arrow_up
                                              : Icons.keyboard_arrow_down,
                                          color: const Color(0xFF34A853),
                                          size: 24,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Sections dropdown
                                if (isExpanded)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: Obx(
                                      () => Column(
                                        children:
                                            (groupedAssignments[departmentId] ?? []).map<
                                              Widget
                                            >((assignment) {
                                              String sectionCode =
                                                  assignment['sectionCode'] ??
                                                  '';
                                              bool isSelected =
                                                  controller
                                                          .selectedDepartmentId
                                                          .value ==
                                                      departmentId &&
                                                  controller
                                                          .selectedSectionCode
                                                          .value ==
                                                      sectionCode;

                                              return GestureDetector(
                                                onTap:
                                                    () => _selectSection(
                                                      departmentId,
                                                      sectionCode,
                                                    ),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        isSelected
                                                            ? const Color(
                                                              0xFFE8F5E8,
                                                            )
                                                            : Colors
                                                                .transparent,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const SizedBox(
                                                        width: 66,
                                                      ), // Align with department content
                                                      Expanded(
                                                        child: Text(
                                                          'Section $sectionCode',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                isSelected
                                                                    ? FontWeight
                                                                        .w600
                                                                    : FontWeight
                                                                        .normal,
                                                            color:
                                                                isSelected
                                                                    ? const Color(
                                                                      0xFF34A853,
                                                                    )
                                                                    : Colors
                                                                        .black87,
                                                          ),
                                                        ),
                                                      ),
                                                      if (isSelected)
                                                        const Icon(
                                                          Icons.check_circle,
                                                          color: Color(
                                                            0xFF34A853,
                                                          ),
                                                          size: 20,
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                  );
                }),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: Obx(
                      () => ElevatedButton(
                        onPressed:
                            controller.selectedDepartmentId.value.isNotEmpty &&
                                    controller
                                        .selectedSectionCode
                                        .value
                                        .isNotEmpty
                                ? () async {
                                  // Show loading indicator
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder:
                                        (context) => const Center(
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF34A853),
                                                ),
                                          ),
                                        ),
                                  );

                                  try {
                                    await controller.completeSelection();
                                    // Close loading dialog
                                    Navigator.of(context).pop();
                                    // Navigate to home dashboard
                                    Get.offAllNamed('/home');
                                  } catch (e) {
                                    // Close loading dialog
                                    Navigator.of(context).pop();
                                    // Show error message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error completing selection: $e',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              controller
                                          .selectedDepartmentId
                                          .value
                                          .isNotEmpty &&
                                      controller
                                          .selectedSectionCode
                                          .value
                                          .isNotEmpty
                                  ? const Color(0xFF43A047)
                                  : Colors.grey,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text('Complete Selection'),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
