import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DepartmentSectionPicker extends StatefulWidget {
  final RxList instructorAssignments;
  final RxString selectedDepartmentId;
  final RxString selectedSectionCode;
  final Function(String departmentId, String sectionCode) onSectionSelected;
  final bool isWeb;

  const DepartmentSectionPicker({
    super.key,
    required this.instructorAssignments,
    required this.selectedDepartmentId,
    required this.selectedSectionCode,
    required this.onSectionSelected,
    this.isWeb = false,
  });

  @override
  State<DepartmentSectionPicker> createState() =>
      _DepartmentSectionPickerState();
}

class _DepartmentSectionPickerState extends State<DepartmentSectionPicker> {
  final Map<String, bool> _expandedDepartments = {};

  Map<String, List<Map<String, dynamic>>> _groupAssignments() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var assignment in widget.instructorAssignments) {
      final deptId = assignment['departmentId'] ?? 'other';
      if (!grouped.containsKey(deptId)) {
        grouped[deptId] = [];
      }
      grouped[deptId]!.add(Map<String, dynamic>.from(assignment));
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (widget.instructorAssignments.isEmpty) {
        return _buildEmptyState();
      }

      final grouped = _groupAssignments();
      return Column(
        children:
            grouped.entries.map((entry) {
              final departmentId = entry.key;
              final sections = entry.value;
              final departmentName =
                  sections.first['departmentName'] ?? 'Unknown Department';
              final departmentCode = sections.first['departmentCode'] ?? '';
              final isExpanded = _expandedDepartments[departmentId] ?? false;

              return widget.isWeb
                  ? _buildWebDepartmentCard(
                    departmentId,
                    departmentName,
                    departmentCode,
                    sections,
                    isExpanded,
                  )
                  : _buildMobileDepartmentCard(
                    departmentId,
                    departmentName,
                    departmentCode,
                    sections,
                    isExpanded,
                  );
            }).toList(),
      );
    });
  }

  Widget _buildWebDepartmentCard(
    String departmentId,
    String departmentName,
    String departmentCode,
    List<Map<String, dynamic>> sections,
    bool isExpanded,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        onExpansionChanged:
            (val) => setState(() => _expandedDepartments[departmentId] = val),
        leading: const Icon(Icons.school, color: Color(0xFF43A047)),
        title: Text(
          departmentName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Code: $departmentCode',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        children:
            sections.map((section) {
              return _buildSectionTile(
                section['departmentId'] ?? '',
                section['sectionCode'] ?? '',
              );
            }).toList(),
      ),
    );
  }

  Widget _buildMobileDepartmentCard(
    String departmentId,
    String departmentName,
    String departmentCode,
    List<Map<String, dynamic>> sections,
    bool isExpanded,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap:
                () => setState(
                  () => _expandedDepartments[departmentId] = !isExpanded,
                ),
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF34A853).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          departmentName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Code: $departmentCode',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Column(
              children:
                  sections.map((section) {
                    return _buildSectionTile(
                      section['departmentId'] ?? '',
                      section['sectionCode'] ?? '',
                    );
                  }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTile(String deptId, String sectionCode) {
    return Obx(() {
      final isSelected =
          widget.selectedSectionCode.value == sectionCode &&
          widget.selectedDepartmentId.value == deptId;

      return GestureDetector(
        onTap: () => widget.onSectionSelected(deptId, sectionCode),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.isWeb ? 32 : 12,
            vertical: widget.isWeb ? 16 : 10,
          ),
          color: isSelected ? const Color(0xFF43A047).withOpacity(0.05) : null,
          child: Row(
            children: [
              if (!widget.isWeb) const SizedBox(width: 66),
              if (widget.isWeb)
                Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_off,
                  color: isSelected ? const Color(0xFF43A047) : Colors.grey,
                  size: 20,
                ),
              if (widget.isWeb) const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Section $sectionCode',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color:
                        isSelected ? const Color(0xFF34A853) : Colors.black87,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF34A853),
                  size: 20,
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildEmptyState() {
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
            Icon(Icons.info_outline, size: 48, color: Colors.grey),
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
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
