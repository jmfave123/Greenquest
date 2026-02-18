import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenquest/user/select/select_controller.dart';
import 'package:greenquest/shared/widgets/instructor_info_header.dart';
import 'package:greenquest/shared/widgets/department_section_picker.dart';
import 'package:greenquest/shared/widgets/continue_button_footer.dart';

class SelectCourseScreen extends StatefulWidget {
  const SelectCourseScreen({super.key});

  @override
  State<SelectCourseScreen> createState() => _SelectCourseScreenState();
}

class _SelectCourseScreenState extends State<SelectCourseScreen> {
  final controller = Get.put(SelectController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Obx(() {
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

                // Show instructor info with profile image
                InstructorInfoHeader(
                  instructorName: controller.selectedInstructorName,
                  studentName: controller.studentName,
                  profileImageUrl:
                      controller.selectedInstructorProfileImage.value,
                  isWeb: false,
                ),

                // Department and section picker
                DepartmentSectionPicker(
                  instructorAssignments: controller.instructorAssignments,
                  selectedDepartmentId: controller.selectedDepartmentId,
                  selectedSectionCode: controller.selectedSectionCode,
                  onSectionSelected: (deptId, sectionCode) {
                    controller.selectedDepartmentId.value = deptId;
                    controller.selectedSectionCode.value = sectionCode;
                  },
                  isWeb: false,
                ),
                const SizedBox(height: 20),
                ContinueButtonFooter(
                  selectedDepartmentId: controller.selectedDepartmentId,
                  selectedSectionCode: controller.selectedSectionCode,
                  onContinue: () => Get.toNamed('/upload-cor'),
                  isWeb: false,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
