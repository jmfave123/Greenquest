import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../user/select/select_controller.dart';
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
  final Map<String, bool> _expandedDepts = {};

  @override
  Widget build(BuildContext context) {
    final isMobile = WebResponsiveUtils.isMobile(context);

    return Scaffold(
      backgroundColor: WebTheme.backgroundLight,
      appBar: WebAppBar(
        title: 'Select Course & Section',
        showNotifications: false,
        showProfileDropdown: false,
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
                  return _buildDepartmentList(assignments);
                }),
              ),
              _buildFooter(),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: WebTheme.borderLight),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, color: WebTheme.primaryGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Instructor', style: WebTheme.bodySmall),
                      Text(
                        controller.selectedInstructorName.value,
                        style: WebTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentList(List assignments) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var a in assignments) {
      final deptId = a['departmentId'] ?? 'other';
      if (!grouped.containsKey(deptId)) grouped[deptId] = [];
      grouped[deptId]!.add(Map<String, dynamic>.from(a));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children:
          grouped.entries.map((entry) {
            final deptName =
                entry.value.first['departmentName'] ?? 'Department';
            final deptCode = entry.value.first['departmentCode'] ?? '';
            final isExpanded = _expandedDepts[entry.key] ?? false;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                initiallyExpanded: isExpanded,
                onExpansionChanged:
                    (val) => setState(() => _expandedDepts[entry.key] = val),
                leading: const Icon(Icons.school, color: WebTheme.primaryGreen),
                title: Text(
                  deptName,
                  style: WebTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text('Code: $deptCode', style: WebTheme.bodySmall),
                children: entry.value.map((a) => _buildSectionItem(a)).toList(),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildSectionItem(Map<String, dynamic> assignment) {
    final section = assignment['sectionCode'] ?? '';
    final deptId = assignment['departmentId'] ?? '';

    return Obx(() {
      final isSelected =
          controller.selectedSectionCode.value == section &&
          controller.selectedDepartmentId.value == deptId;
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 32),
        onTap: () => controller.selectSection(deptId, section),
        leading: Icon(
          isSelected ? Icons.check_circle : Icons.radio_button_off,
          color: isSelected ? WebTheme.primaryGreen : WebTheme.textHint,
        ),
        title: Text(
          'Section $section',
          style: WebTheme.bodyMedium.copyWith(
            color: isSelected ? WebTheme.primaryGreen : WebTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        tileColor: isSelected ? WebTheme.primaryGreen.withOpacity(0.05) : null,
      );
    });
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

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: WebTheme.borderLight)),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
          ),
          const Spacer(),
          Obx(
            () => ElevatedButton(
              onPressed:
                  controller.selectedSectionCode.value.isNotEmpty
                      ? () => Get.toNamed(WebRoutes.uploadCor)
                      : null,
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              child: const Text('Continue to COR'),
            ),
          ),
        ],
      ),
    );
  }
}
