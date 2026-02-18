import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../user/select/select_controller.dart';
import '../../../shared/widgets/instructor_info_header.dart';
import '../../../shared/widgets/department_section_picker.dart';
import '../../../shared/widgets/continue_button_footer.dart';
import '../../config/web_theme.dart';
import '../../config/web_routes.dart';
import '../../utils/web_responsive_utils.dart';
import '../../widgets/layout/web_app_bar.dart';

class WebSelectCourseScreen extends StatefulWidget {
  const WebSelectCourseScreen({super.key});

  @override
  State<WebSelectCourseScreen> createState() => _WebSelectCourseScreenState();
}

class _WebSelectCourseScreenState extends State<WebSelectCourseScreen> {
  final controller = Get.put(SelectController());

  @override
  Widget build(BuildContext context) {
    final isMobile = WebResponsiveUtils.isMobile(context);

    return Scaffold(
      backgroundColor: WebTheme.backgroundLight,
      appBar: WebAppBar(
        title: 'Select Course & Section',
        showNotifications: false,
        showProfileDropdown: true,
        logoutOnly: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              _buildHeader(isMobile),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final assignments = controller.instructorAssignments;
                  if (assignments.isEmpty) return _buildEmptyState();
                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      DepartmentSectionPicker(
                        instructorAssignments: controller.instructorAssignments,
                        selectedDepartmentId: controller.selectedDepartmentId,
                        selectedSectionCode: controller.selectedSectionCode,
                        onSectionSelected: (deptId, sectionCode) {
                          controller.selectedDepartmentId.value = deptId;
                          controller.selectedSectionCode.value = sectionCode;
                        },
                        isWeb: true,
                      ),
                    ],
                  );
                }),
              ),
              ContinueButtonFooter(
                selectedDepartmentId: controller.selectedDepartmentId,
                selectedSectionCode: controller.selectedSectionCode,
                onContinue: () => Get.toNamed(WebRoutes.uploadCor),
                onBack: () => Get.back(),
                buttonText: 'Continue to COR',
                isWeb: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      child: Column(
        children: [
          Text('Available Sections', style: WebTheme.headingMedium),
          const SizedBox(height: 16),
          InstructorInfoHeader(
            instructorName: controller.selectedInstructorName,
            studentName: controller.studentName,
            profileImageUrl: controller.selectedInstructorProfileImage.value,
            isWeb: true,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 64, color: WebTheme.textHint),
          const SizedBox(height: 16),
          Text(
            'No assignments found for this instructor',
            style: WebTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
