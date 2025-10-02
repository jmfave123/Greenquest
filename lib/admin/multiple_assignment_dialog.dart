import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MultipleAssignmentDialog extends StatefulWidget {
  final String instructorId;
  final String instructorName;
  final List<Map<String, dynamic>>? existingAssignments;

  const MultipleAssignmentDialog({
    Key? key,
    required this.instructorId,
    required this.instructorName,
    this.existingAssignments,
  }) : super(key: key);

  @override
  State<MultipleAssignmentDialog> createState() =>
      _MultipleAssignmentDialogState();
}

class _MultipleAssignmentDialogState extends State<MultipleAssignmentDialog> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> selectedAssignments = [];
  String? selectedDepartmentId;
  String? selectedSectionId;
  List<Map<String, dynamic>> departments = [];
  List<Map<String, dynamic>> sections = [];

  @override
  void initState() {
    super.initState();
    selectedAssignments = List<Map<String, dynamic>>.from(
      widget.existingAssignments ?? [],
    );

    // Debug: Print existing assignments
    print('Existing assignments: ${widget.existingAssignments}');
    print('Selected assignments: $selectedAssignments');

    // Load assignments from Firestore if not provided
    if (selectedAssignments.isEmpty) {
      _loadAssignmentsFromFirestore();
    }
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
        final assignments = data['assignments'] as List<dynamic>?;

        if (assignments != null && assignments.isNotEmpty) {
          setState(() {
            selectedAssignments =
                assignments
                    .map((assignment) => Map<String, dynamic>.from(assignment))
                    .toList();
          });
          print('Loaded assignments from Firestore: $selectedAssignments');
        }
      }
    } catch (e) {
      print('Error loading assignments from Firestore: $e');
    }
  }

  Future<void> _loadSections(String departmentId) async {
    final snapshot =
        await _firestore
            .collection('sections')
            .where('departmentId', isEqualTo: departmentId)
            .get();

    setState(() {
      sections =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'sectionCode': data['sectionCode'],
              'year': data['year'],
              'sectionLetter': data['sectionLetter'],
            };
          }).toList();
      selectedSectionId = null;
    });
  }

  void _addAssignment() {
    if (selectedDepartmentId != null && selectedSectionId != null) {
      final department = departments.firstWhere(
        (d) => d['id'] == selectedDepartmentId,
      );
      final section = sections.firstWhere((s) => s['id'] == selectedSectionId);

      final assignment = {
        'departmentId': selectedDepartmentId,
        'sectionId': selectedSectionId,
        'departmentName': department['name'],
        'sectionName':
            department['name'], // Section name matches department name
        'departmentCode': department['code'],
        'sectionCode': section['sectionCode'],
      };

      // Check if assignment already exists
      final exists = selectedAssignments.any(
        (a) =>
            a['departmentId'] == selectedDepartmentId &&
            a['sectionId'] == selectedSectionId,
      );

      if (!exists) {
        setState(() {
          selectedAssignments.add(assignment);
          selectedDepartmentId = null;
          selectedSectionId = null;
          sections = [];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This assignment already exists'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _removeAssignment(int index) {
    setState(() {
      selectedAssignments.removeAt(index);
    });
  }

  Future<void> _saveAssignments() async {
    try {
      // Validate assignments before saving
      for (var assignment in selectedAssignments) {
        if (assignment['departmentId'] == null ||
            assignment['sectionId'] == null ||
            assignment['departmentName'] == null ||
            assignment['sectionName'] == null ||
            assignment['departmentCode'] == null ||
            assignment['sectionCode'] == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid assignment data. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      await _firestore
          .collection('instructors')
          .doc(widget.instructorId)
          .update({
            'assignments': selectedAssignments,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              selectedAssignments.isEmpty
                  ? 'All assignments removed successfully!'
                  : 'Assignments saved successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving assignments: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
            const SizedBox(height: 24),

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
            Container(
              height: 120,
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
                          final assignment = selectedAssignments[index];
                          return Container(
                            margin: const EdgeInsets.all(4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF34A853).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF34A853).withOpacity(0.3),
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
                                        '${assignment['departmentCode']}-${assignment['sectionCode']}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF34A853),
                                        ),
                                      ),
                                      Text(
                                        assignment['departmentName'] ??
                                            'Unknown Department',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _removeAssignment(index),
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

            Row(
              children: [
                // Department Dropdown
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('departments').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        departments =
                            snapshot.data!.docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return {
                                'id': doc.id,
                                'name': data['name'],
                                'code': data['code'],
                              };
                            }).toList();
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE5E7EB)),
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
                                  value: dept['id'],
                                  child: Text(
                                    '${dept['name']} (${dept['code']})',
                                  ),
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
                      border: Border.all(color: const Color(0xFFE5E7EB)),
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
                              value: section['id'],
                              child: Text('${section['sectionCode']}'),
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
                      selectedDepartmentId != null && selectedSectionId != null
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

            const SizedBox(height: 24),

            // Action Buttons
            Row(
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
          ],
        ),
      ),
    );
  }
}
