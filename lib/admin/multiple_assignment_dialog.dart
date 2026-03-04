import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:greenquest/shared/models/assigned_period_model.dart';
import 'package:greenquest/shared/models/department_model.dart';
import 'package:greenquest/shared/models/instructor_assignment_model.dart';
import 'package:greenquest/shared/models/nstp_component_model.dart';
import 'package:greenquest/shared/models/period_model.dart';
import 'package:greenquest/shared/models/section_model.dart';

class MultipleAssignmentDialog extends StatefulWidget {
  final String instructorId;
  final String instructorName;
  final List<InstructorAssignment>? existingAssignments;

  const MultipleAssignmentDialog({
    super.key,
    required this.instructorId,
    required this.instructorName,
    this.existingAssignments,
  });

  @override
  State<MultipleAssignmentDialog> createState() =>
      _MultipleAssignmentDialogState();
}

class _MultipleAssignmentDialogState extends State<MultipleAssignmentDialog> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<InstructorAssignment> selectedAssignments = [];
  List<InstructorAssignment> _initialAssignments = [];
  String? selectedDepartmentId;
  String? selectedSectionId;
  List<Department> departments = [];
  List<Section> sections = [];

  // NSTP Component
  String? _selectedNstpComponent;
  String _initialNstpComponent = '';
  String? _selectedNstpComponentId;
  String _initialNstpComponentId = '';

  // Semester Periods
  Set<String> _selectedPeriodIds = {};
  Set<String> _initialPeriodIds = {};
  List<Period> _cachedPeriods = [];

  @override
  void initState() {
    super.initState();
    selectedAssignments = List<InstructorAssignment>.from(
      widget.existingAssignments ?? [],
    );
    _initialAssignments = List<InstructorAssignment>.from(selectedAssignments);

    // Always load assignments from Firestore to ensure we have the latest data
    _loadAssignmentsFromFirestore();
  }

  Future<void> _loadAssignmentsFromFirestore() async {
    try {
      final doc =
          await _firestore
              .collection('instructors')
              .doc(widget.instructorId)
              .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        // Load current NSTP component
        final nstp = data['nstpComponent']?.toString() ?? '';
        final nstpId = data['nstpComponentId']?.toString() ?? '';
        _initialNstpComponent = nstp;
        _initialNstpComponentId = nstpId;

        // Load current assigned periods
        final assignedPeriods =
            (data['assignedPeriods'] as List<dynamic>?) ?? [];
        final periodIds =
            assignedPeriods
                .map(
                  (p) =>
                      (p as Map<String, dynamic>)['periodId']?.toString() ?? '',
                )
                .where((id) => id.isNotEmpty)
                .toSet();
        _initialPeriodIds = Set<String>.from(periodIds);

        setState(() {
          _selectedNstpComponent = nstp.isNotEmpty ? nstp : null;
          _selectedNstpComponentId = nstpId.isNotEmpty ? nstpId : null;
          _selectedPeriodIds = Set<String>.from(periodIds);
        });

        final assignments = data['assignments'] as List<dynamic>?;

        if (assignments != null && assignments.isNotEmpty) {
          setState(() {
            selectedAssignments =
                assignments
                    .whereType<Map<String, dynamic>>()
                    .map(InstructorAssignment.fromMap)
                    .toList();
            _initialAssignments = List<InstructorAssignment>.from(
              selectedAssignments,
            );
          });
        } else {
          setState(() {
            _initialAssignments = [];
          });
        }
      }
    } catch (e) {
      // TODO: replace with proper logger
    }
  }

  Future<void> _loadSections(String departmentId) async {
    final snapshot =
        await _firestore
            .collection('sections')
            .where('departmentId', isEqualTo: departmentId)
            .get();

    setState(() {
      sections = snapshot.docs.map(Section.fromDoc).toList();
      selectedSectionId = null;
    });
  }

  // Check if a section is already assigned to another instructor
  Future<Map<String, dynamic>?> _checkSectionDuplicate(
    String? sectionId,
    String sectionCode,
  ) async {
    try {
      // Query all instructors
      final instructorsSnapshot =
          await _firestore.collection('instructors').get();

      // Check each instructor's assignments (excluding current instructor)
      for (var instructorDoc in instructorsSnapshot.docs) {
        // Skip the current instructor
        if (instructorDoc.id == widget.instructorId) {
          continue;
        }

        final instructorData = instructorDoc.data();

        // Only check approved instructors - skip pending and rejected
        final instructorStatus =
            instructorData['status']?.toString() ?? 'Pending';
        if (instructorStatus != 'Approved') {
          continue;
        }

        final assignments = instructorData['assignments'] as List<dynamic>?;

        if (assignments != null && assignments.isNotEmpty) {
          // Check if any assignment has the same sectionId or sectionCode
          for (var assignment in assignments) {
            if (assignment is Map<String, dynamic>) {
              final assignedSectionId = assignment['sectionId']?.toString();
              final assignedSectionCode = assignment['sectionCode']?.toString();

              // Check if section matches by ID or Code
              if ((sectionId != null &&
                      assignedSectionId != null &&
                      assignedSectionId == sectionId) ||
                  (assignedSectionCode != null &&
                      assignedSectionCode == sectionCode)) {
                // Found duplicate - return instructor info
                return {
                  'instructorId': instructorDoc.id,
                  'instructorName':
                      instructorData['name']?.toString() ??
                      'Unknown Instructor',
                  'sectionCode': sectionCode,
                };
              }
            }
          }
        }
      }

      // No duplicate found
      return null;
    } catch (e) {
      // TODO: replace with proper logger
      return null;
    }
  }

  Future<void> _addAssignment() async {
    if (selectedDepartmentId != null && selectedSectionId != null) {
      final department = departments.firstWhere(
        (d) => d.id == selectedDepartmentId,
      );
      final section = sections.firstWhere((s) => s.id == selectedSectionId);

      final assignment = InstructorAssignment(
        departmentId: selectedDepartmentId!,
        sectionId: selectedSectionId!,
        departmentName: department.displayName,
        sectionName: section.sectionCode,
        departmentCode: department.code,
        sectionCode: section.sectionCode,
      );

      final existsInCurrentList = selectedAssignments.any(
        (a) =>
            a.departmentId == selectedDepartmentId &&
            a.sectionId == selectedSectionId,
      );

      if (existsInCurrentList) {
        Get.snackbar(
          'Warning',
          'This assignment already exists in your list',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      // Check if section is already assigned to another instructor
      final sectionCodeString = section.sectionCode;
      final duplicateCheck = await _checkSectionDuplicate(
        selectedSectionId,
        sectionCodeString,
      );

      if (duplicateCheck != null) {
        Get.snackbar(
          'Cannot Assign',
          'Section ${duplicateCheck['sectionCode']} is already assigned to ${duplicateCheck['instructorName']}. Each section can only be assigned to one instructor.',
          // duplicate info comes from the internal map returned by _checkSectionDuplicate
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        );
        return;
      }

      // All checks passed - add assignment
      setState(() {
        selectedAssignments.add(assignment);
        selectedDepartmentId = null;
        selectedSectionId = null;
        sections = [];
      });

      // Show success message
      Get.snackbar(
        'Success',
        'Assignment added successfully! Click Save to confirm.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _removeAssignment(int index) {
    setState(() {
      selectedAssignments.removeAt(index);
    });
  }

  // Helper: returns true when both lists contain the same assignments in the same order.
  bool _areListsIdentical(
    List<InstructorAssignment> list1,
    List<InstructorAssignment> list2,
  ) {
    if (list1.length != list2.length) return false;
    for (var i = 0; i < list1.length; i++) {
      if (list1[i].departmentId != list2[i].departmentId ||
          list1[i].sectionId != list2[i].sectionId ||
          list1[i].departmentCode != list2[i].departmentCode ||
          list1[i].sectionCode != list2[i].sectionCode) {
        return false;
      }
    }
    return true;
  }

  Future<void> _saveAssignments() async {
    try {
      // Check if instructor is pending - prevent assignment
      final instructorDoc =
          await _firestore
              .collection('instructors')
              .doc(widget.instructorId)
              .get();

      if (instructorDoc.exists) {
        final instructorData = instructorDoc.data() as Map<String, dynamic>;
        final instructorStatus =
            instructorData['status']?.toString() ?? 'Pending';

        if (instructorStatus == 'Pending') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Cannot assign pending instructor. Please approve the instructor first.',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      // STRICT VALIDATION: Block save if:
      // 1. No assignments in list at all, OR
      // 2. Dropdowns are empty AND no new assignments were added (same as initial state)
      if (selectedAssignments.isEmpty) {
        if (mounted) {
          Get.snackbar(
            'Cannot Save',
            'Please select a department and section, then click Add before saving.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
        }
        return; // Stop - do not save
      }

      // Check if dropdowns are empty AND no new assignments were added
      final nstpChanged =
          _selectedNstpComponent !=
          (_initialNstpComponent.isNotEmpty ? _initialNstpComponent : null);
      final periodsChanged =
          !_selectedPeriodIds.containsAll(_initialPeriodIds) ||
          !_initialPeriodIds.containsAll(_selectedPeriodIds);
      final hasNewAssignments =
          nstpChanged ||
          periodsChanged ||
          selectedAssignments.length > _initialAssignments.length ||
          !_areListsIdentical(selectedAssignments, _initialAssignments);

      if (!hasNewAssignments &&
          (selectedDepartmentId == null || selectedSectionId == null)) {
        if (mounted) {
          Get.snackbar(
            'Cannot Save',
            'Please select a department and section from the dropdowns, then click Add before saving.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
        }
        return; // Stop - do not save
      }

      // Validate assignments before saving — use the model's isValid guard.
      for (final assignment in selectedAssignments) {
        if (!assignment.isValid) {
          if (mounted) {
            Get.snackbar(
              'Cannot Save',
              'One or more assignments have missing department or section information. Please remove invalid assignments and try again.',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              duration: const Duration(seconds: 4),
            );
          }
          return;
        }
      }

      // Validate that no section is assigned to another instructor
      for (final assignment in selectedAssignments) {
        final duplicateCheck = await _checkSectionDuplicate(
          assignment.sectionId,
          assignment.sectionCode,
        );

        if (duplicateCheck != null) {
          if (mounted) {
            Get.snackbar(
              'Cannot Save',
              'Section ${duplicateCheck['sectionCode']} is already assigned to ${duplicateCheck['instructorName']}. Each section can only be assigned to one instructor. Please remove this assignment and try again.',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
              icon: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
              ),
            );
          }
          return;
        }
      }

      // Build assignedPeriods list from selected IDs + cached Period models.
      // AssignedPeriod.toMap() writes exactly {periodId, semesterName, type, isActive}.
      final updatedPeriods =
          _selectedPeriodIds.map((id) {
            final period = _cachedPeriods.firstWhere(
              (p) => p.id == id,
              orElse: () => Period(id: id, semesterName: ''),
            );
            return AssignedPeriod(
              periodId: id,
              semesterName: period.semesterName,
              type: period.type,
              isActive: period.isActive,
            ).toMap();
          }).toList();

      await _firestore
          .collection('instructors')
          .doc(widget.instructorId)
          .update({
            'assignments': selectedAssignments.map((a) => a.toMap()).toList(),
            if (_selectedNstpComponent != null)
              'nstpComponent': _selectedNstpComponent,
            if (_selectedNstpComponentId != null)
              'nstpComponentId': _selectedNstpComponentId,
            'assignedPeriods': updatedPeriods,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        Navigator.of(context).pop(true);
        Get.snackbar(
          'Success',
          selectedAssignments.isEmpty
              ? 'All assignments removed successfully!'
              : 'Assignments saved successfully!',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Error saving assignments: $e',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 620,
          maxHeight: screenHeight * 0.88,
          minWidth: screenWidth < 620 ? screenWidth * 0.95 : 500,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header (not scrollable) ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF34A853).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
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
                        const Text(
                          'Assign Sections',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Assign department-sections for ${widget.instructorName}',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // ── Scrollable body ──────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Assignments
                    Row(
                      children: [
                        const Text(
                          'Current Assignments:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _loadAssignmentsFromFirestore,
                          icon: const Icon(
                            Icons.refresh,
                            size: 20,
                            color: Color(0xFF34A853),
                          ),
                          tooltip: 'Refresh assignments',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: 60,
                        maxHeight: 160,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child:
                            selectedAssignments.isEmpty
                                ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.assignment_outlined,
                                        size: 32,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'No assignments yet',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        'Add assignments below',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : ListView.builder(
                                  itemCount: selectedAssignments.length,
                                  itemBuilder: (context, index) {
                                    final assignment =
                                        selectedAssignments[index];
                                    return Container(
                                      margin: const EdgeInsets.all(4),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF34A853,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF34A853,
                                          ).withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  assignment.label,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF34A853),
                                                  ),
                                                ),
                                                Text(
                                                  assignment
                                                          .departmentName
                                                          .isNotEmpty
                                                      ? assignment
                                                          .departmentName
                                                      : 'Unknown Department',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            onPressed:
                                                () => _removeAssignment(index),
                                            icon: const Icon(
                                              Icons.close,
                                              size: 16,
                                              color: Colors.red,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Add New Assignment
                    const Text(
                      'Add New Assignment:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Warning note
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Note: Please select a department and section, then click the + button to add the assignment before saving.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[900],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Row(
                      children: [
                        // Department Dropdown
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream:
                                _firestore
                                    .collection('departments')
                                    .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                departments =
                                    snapshot.data!.docs
                                        .map(Department.fromDoc)
                                        .toList();
                              }

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButton<String>(
                                  value: selectedDepartmentId,
                                  hint: const Text('Select Department'),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedDepartmentId = value;
                                      selectedSectionId = null;
                                    });
                                    if (value != null) {
                                      _loadSections(value);
                                    }
                                  },
                                  items:
                                      departments.map((dept) {
                                        return DropdownMenuItem<String>(
                                          value: dept.id,
                                          child: Text(dept.label),
                                        );
                                      }).toList(),
                                  underline: const SizedBox(),
                                  isExpanded: true,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Section Dropdown
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<String>(
                              value: selectedSectionId,
                              hint: const Text('Select Section'),
                              onChanged:
                                  selectedDepartmentId != null
                                      ? (value) {
                                        setState(() {
                                          selectedSectionId = value;
                                        });
                                      }
                                      : null,
                              items:
                                  sections.map((section) {
                                    return DropdownMenuItem<String>(
                                      value: section.id,
                                      child: Text(section.sectionCode),
                                    );
                                  }).toList(),
                              underline: const SizedBox(),
                              isExpanded: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Add Button
                        ElevatedButton(
                          onPressed:
                              selectedDepartmentId != null &&
                                      selectedSectionId != null
                                  ? _addAssignment
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF34A853),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          child: const Icon(Icons.add, size: 20),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // NSTP Component
                    Row(
                      children: [
                        const Icon(
                          Icons.account_tree_outlined,
                          size: 18,
                          color: Color(0xFF34A853),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'NSTP Component',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        if (_selectedNstpComponent != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF34A853).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _selectedNstpComponent!,
                              style: const TextStyle(
                                color: Color(0xFF34A853),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    StreamBuilder<QuerySnapshot>(
                      stream:
                          _firestore
                              .collection('nstp_components')
                              .orderBy('createdAt')
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                            height: 32,
                            child: Center(
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF34A853),
                                ),
                              ),
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Text(
                            'No active components found.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          );
                        }
                        final components =
                            snapshot.data!.docs
                                .map(NstpComponent.fromDoc)
                                .where((c) => c.isActive)
                                .toList();
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              components.map((component) {
                                final name = component.name;
                                final isSelected =
                                    _selectedNstpComponent == name;
                                return ChoiceChip(
                                  label: Text(name),
                                  selected: isSelected,
                                  onSelected:
                                      (_) => setState(() {
                                        _selectedNstpComponent =
                                            isSelected ? null : name;
                                        _selectedNstpComponentId =
                                            isSelected ? null : component.id;
                                      }),

                                  selectedColor: const Color(
                                    0xFF34A853,
                                  ).withOpacity(0.15),
                                  checkmarkColor: const Color(0xFF34A853),
                                  backgroundColor: Colors.grey.shade100,
                                  labelStyle: TextStyle(
                                    color:
                                        isSelected
                                            ? const Color(0xFF34A853)
                                            : Colors.black87,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                  side: BorderSide(
                                    color:
                                        isSelected
                                            ? const Color(0xFF34A853)
                                            : Colors.grey.shade300,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                );
                              }).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Semester / Period
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: Color(0xFF34A853),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Semester / Period',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        if (_selectedPeriodIds.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_selectedPeriodIds.length} selected',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    StreamBuilder<QuerySnapshot>(
                      stream:
                          _firestore
                              .collection('periods')
                              .orderBy('createdAt')
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                            height: 32,
                            child: Center(
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF34A853),
                                ),
                              ),
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Text(
                            'No periods found.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          );
                        }
                        // Cache typed Period models for use in _saveAssignments
                        _cachedPeriods =
                            snapshot.data!.docs.map(Period.fromDoc).toList();
                        return Column(
                          children:
                              _cachedPeriods.map((period) {
                                final id = period.id;
                                final label = period.label;
                                final isActive = period.isActive;
                                final isChecked = _selectedPeriodIds.contains(
                                  id,
                                );
                                return InkWell(
                                  onTap:
                                      () => setState(() {
                                        if (isChecked) {
                                          _selectedPeriodIds.remove(id);
                                        } else {
                                          _selectedPeriodIds.add(id);
                                        }
                                      }),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isChecked
                                              ? Colors.blue.withOpacity(0.08)
                                              : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            isChecked
                                                ? Colors.blue
                                                : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isChecked
                                              ? Icons.check_box_rounded
                                              : Icons
                                                  .check_box_outline_blank_rounded,
                                          color:
                                              isChecked
                                                  ? Colors.blue
                                                  : Colors.grey,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                label,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight:
                                                      isChecked
                                                          ? FontWeight.w600
                                                          : FontWeight.normal,
                                                  color:
                                                      isChecked
                                                          ? Colors.blue
                                                          : Colors.black87,
                                                ),
                                              ),
                                              if (isActive)
                                                const Text(
                                                  'Active',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF34A853),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                )
                                              else
                                                const Text(
                                                  'Inactive',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.black38,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // ── Action buttons (pinned) ──────────────────────────────
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black54,
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saveAssignments,
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
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
