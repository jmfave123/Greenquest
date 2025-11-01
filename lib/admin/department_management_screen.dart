import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/admin/admin_sidebar.dart';
import '../shared/admin/admin_navigation_constants.dart';
import '../shared/widgets/safe_asset_image.dart';
import '../shared/widgets/confirmation_dialog.dart';

class DepartmentManagementScreen extends StatefulWidget {
  const DepartmentManagementScreen({super.key});

  @override
  State<DepartmentManagementScreen> createState() =>
      _DepartmentManagementScreenState();
}

class _DepartmentManagementScreenState
    extends State<DepartmentManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AdminNavigationItem _selectedItem = AdminNavigationItem.manageDepartments;
  List<Map<String, dynamic>> _semesters = [];

  void _handleNavigationSelect(AdminNavigationItem item) {
    debugPrint('Navigation selected: $item');
    setState(() {
      _selectedItem = item;
    });
    String route = AdminNavigationHelper.getRoute(item);
    debugPrint('Navigating to route: $route');
    Navigator.of(context).pushNamed(route);
  }

  Future<void> _createDepartment() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController codeController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                        Icons.school_rounded,
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
                            'Create Department',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Add a new department to the system',
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

                // Department Name
                const Text(
                  'Department Name',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  cursorColor: const Color(0xFF34A853),
                  decoration: const InputDecoration(
                    hintText: 'e.g., Education, Computer Science',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide(color: Color(0xFF34A853)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Department Code
                const Text(
                  'Department Code',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: codeController,
                  cursorColor: const Color(0xFF34A853),
                  decoration: const InputDecoration(
                    hintText: 'e.g., EDUC, CS, IT',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide(color: Color(0xFF34A853)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Description
                const Text(
                  'Description (Optional)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  cursorColor: const Color(0xFF34A853),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Brief description of the department',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide(color: Color(0xFF34A853)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
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
                      onPressed: () {
                        if (nameController.text.trim().isNotEmpty &&
                            codeController.text.trim().isNotEmpty) {
                          Navigator.of(context).pop();
                          _saveDepartment(
                            nameController.text.trim(),
                            codeController.text.trim().toUpperCase(),
                            descriptionController.text.trim(),
                          );
                        } else {
                          Get.snackbar(
                            'Validation Error',
                            'Please fill in both department name and code',
                            backgroundColor: Colors.orange,
                            colorText: Colors.white,
                          );
                        }
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
                      child: const Text('Create'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method to check for duplicate department names
  Future<bool> _isDuplicateName(String name) async {
    final allDepartmentsQuery =
        await _firestore.collection('departments').get();
    final normalizedName = name.trim().toLowerCase();

    for (var doc in allDepartmentsQuery.docs) {
      final data = doc.data();
      final existingName = data['name']?.toString().toLowerCase() ?? '';
      final existingDisplayName =
          data['displayName']?.toString().toLowerCase() ?? '';

      if (existingName == normalizedName ||
          existingDisplayName == normalizedName) {
        return true;
      }
    }
    return false;
  }

  // Helper method to check for duplicate department codes
  Future<bool> _isDuplicateCode(String code) async {
    final allDepartmentsQuery =
        await _firestore.collection('departments').get();
    final normalizedCode = code.trim().toUpperCase();

    for (var doc in allDepartmentsQuery.docs) {
      final data = doc.data();
      final existingCode = data['code']?.toString().toUpperCase() ?? '';

      if (existingCode == normalizedCode) {
        return true;
      }
    }
    return false;
  }

  // Helper method to check for duplicate section codes
  Future<bool> _isDuplicateSectionCode(String sectionCode) async {
    final allSectionsQuery = await _firestore.collection('sections').get();
    final normalizedSectionCode = sectionCode.trim().toUpperCase();

    for (var doc in allSectionsQuery.docs) {
      final data = doc.data();
      final existingSectionCode =
          data['sectionCode']?.toString().toUpperCase() ?? '';

      if (existingSectionCode == normalizedSectionCode) {
        return true;
      }
    }
    return false;
  }

  // Helper method to check for duplicate section codes within a specific department
  Future<bool> _isDuplicateSectionCodeInDepartment(
    String sectionCode,
    String departmentId,
  ) async {
    final sectionsQuery =
        await _firestore
            .collection('sections')
            .where('departmentId', isEqualTo: departmentId)
            .get();
    final normalizedSectionCode = sectionCode.trim().toUpperCase();

    for (var doc in sectionsQuery.docs) {
      final data = doc.data();
      final existingSectionCode =
          data['sectionCode']?.toString().toUpperCase() ?? '';

      if (existingSectionCode == normalizedSectionCode) {
        return true;
      }
    }
    return false;
  }

  // Helper method to check for duplicate section codes when updating (excludes current section)
  Future<bool> _isDuplicateSectionCodeForUpdate(
    String sectionCode,
    String currentSectionId,
  ) async {
    final allSectionsQuery = await _firestore.collection('sections').get();
    final normalizedSectionCode = sectionCode.trim().toUpperCase();

    for (var doc in allSectionsQuery.docs) {
      // Skip the current section being updated
      if (doc.id == currentSectionId) {
        continue;
      }

      final data = doc.data();
      final existingSectionCode =
          data['sectionCode']?.toString().toUpperCase() ?? '';

      if (existingSectionCode == normalizedSectionCode) {
        return true;
      }
    }
    return false;
  }

  Future<void> _saveDepartment(
    String name,
    String code,
    String description,
  ) async {
    try {
      // Validate input
      if (name.trim().isEmpty) {
        Get.snackbar(
          'Validation Error',
          'Department name cannot be empty!',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      if (code.trim().isEmpty) {
        Get.snackbar(
          'Validation Error',
          'Department code cannot be empty!',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Check for duplicate department name (case-insensitive)
      if (await _isDuplicateName(name)) {
        Get.snackbar(
          'Duplicate Error',
          'A department with the name "$name" already exists! Please choose a different name.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Check for duplicate department code (case-insensitive)
      if (await _isDuplicateCode(code)) {
        Get.snackbar(
          'Duplicate Error',
          'A department with the code "$code" already exists! Please choose a different code.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Create the department if no duplicates found
      await _firestore.collection('departments').add({
        'name':
            name
                .trim()
                .toLowerCase(), // Store in lowercase for consistent comparison
        'displayName': name.trim(), // Store original case for display
        'code': code.trim().toUpperCase(),
        'description': description.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Success',
        'Department "$name" created successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create department: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _editDepartment(
    String departmentId,
    Map<String, dynamic> departmentData,
  ) async {
    final TextEditingController nameController = TextEditingController(
      text: departmentData['displayName'] ?? departmentData['name'] ?? '',
    );
    final TextEditingController codeController = TextEditingController(
      text: departmentData['code'] ?? '',
    );
    final TextEditingController descriptionController = TextEditingController(
      text: departmentData['description'] ?? '',
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                            'Edit Department',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Update department information',
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

                // Department Name
                const Text(
                  'Department Name',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter department name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.school_rounded),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),

                // Department Code
                const Text(
                  'Department Code',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: codeController,
                  decoration: InputDecoration(
                    hintText: 'Enter department code (e.g., BSIT)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.tag_rounded),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 16),

                // Description
                const Text(
                  'Description (Optional)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter department description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.description_rounded),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
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
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty &&
                    codeController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop();
                  await _updateDepartment(
                    departmentId,
                    nameController.text.trim(),
                    codeController.text.trim().toUpperCase(),
                    descriptionController.text.trim(),
                  );
                } else {
                  Get.snackbar(
                    'Validation Error',
                    'Please fill in both department name and code',
                    backgroundColor: Colors.orange,
                    colorText: Colors.white,
                  );
                }
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
  }

  Future<void> _updateDepartment(
    String departmentId,
    String name,
    String code,
    String description,
  ) async {
    try {
      // Validate input
      if (name.trim().isEmpty) {
        Get.snackbar(
          'Validation Error',
          'Department name cannot be empty!',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      if (code.trim().isEmpty) {
        Get.snackbar(
          'Validation Error',
          'Department code cannot be empty!',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Get existing department data to compare
      final existingDoc =
          await _firestore.collection('departments').doc(departmentId).get();
      final existingData = existingDoc.data();

      // Check for duplicate department name (case-insensitive) if name changed
      if (existingData?['displayName']?.toString().toLowerCase() !=
          name.trim().toLowerCase()) {
        if (await _isDuplicateName(name)) {
          Get.snackbar(
            'Duplicate Error',
            'A department with the name "$name" already exists! Please choose a different name.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }
      }

      // Check for duplicate department code (case-insensitive) if code changed
      if (existingData?['code']?.toString().toUpperCase() !=
          code.trim().toUpperCase()) {
        if (await _isDuplicateCode(code)) {
          Get.snackbar(
            'Duplicate Error',
            'A department with the code "$code" already exists! Please choose a different code.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }
      }

      // Update the department
      await _firestore.collection('departments').doc(departmentId).update({
        'name': name.trim().toLowerCase(),
        'displayName': name.trim(),
        'code': code.trim().toUpperCase(),
        'description': description.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Success',
        'Department "$name" updated successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update department: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _addSection(
    String departmentId,
    String departmentName,
    String departmentCode,
  ) async {
    String selectedYear = '1st';
    String selectedSectionLetter = 'A';
    String? selectedSubCode; // Make it optional with null

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
                            Icons.group_work_rounded,
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
                                'Add Section',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add section to $departmentName',
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
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: selectedYear,
                        onChanged:
                            (value) => setState(() => selectedYear = value!),
                        items:
                            ['1st', '2nd', '3rd', '4th'].map((year) {
                              return DropdownMenuItem<String>(
                                value: year,
                                child: Text(year),
                              );
                            }).toList(),
                        underline: const SizedBox(),
                        isExpanded: true,
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
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: selectedSectionLetter,
                        onChanged:
                            (value) =>
                                setState(() => selectedSectionLetter = value!),
                        items:
                            ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'].map((
                              letter,
                            ) {
                              return DropdownMenuItem<String>(
                                value: letter,
                                child: Text(letter),
                              );
                            }).toList(),
                        underline: const SizedBox(),
                        isExpanded: true,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Sub-Code Selection (Only for BTLED)
                    if (departmentCode == 'BTLED') ...[
                      const Text(
                        'Sub-Code (Required for BTLED)',
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
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          value: selectedSubCode,
                          hint: const Text('Select subcode'),
                          onChanged:
                              (value) =>
                                  setState(() => selectedSubCode = value),
                          items:
                              ['ICT', 'HE', 'IA'].map((subCode) {
                                return DropdownMenuItem<String>(
                                  value: subCode,
                                  child: Text(subCode),
                                );
                              }).toList(),
                          underline: const SizedBox(),
                          isExpanded: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Preview Section Code
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34A853).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF34A853).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Section Code Preview:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selectedSubCode != null &&
                                    selectedSubCode!.isNotEmpty
                                ? '$departmentCode-$selectedSubCode-${selectedYear.replaceAll('st', '').replaceAll('nd', '').replaceAll('rd', '').replaceAll('th', '')}$selectedSectionLetter'
                                : '$departmentCode-${selectedYear.replaceAll('st', '').replaceAll('nd', '').replaceAll('rd', '').replaceAll('th', '')}$selectedSectionLetter',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF34A853),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
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
                          onPressed: () {
                            // Validate BTLED requires subcode
                            if (departmentCode == 'BTLED' &&
                                (selectedSubCode == null ||
                                    selectedSubCode!.isEmpty)) {
                              Get.snackbar(
                                'Validation Error',
                                'Sub-code is required for BTLED sections',
                                backgroundColor: Colors.orange,
                                colorText: Colors.white,
                              );
                              return;
                            }
                            Navigator.of(context).pop();
                            _saveSection(
                              departmentId,
                              selectedYear,
                              selectedSectionLetter,
                              departmentCode,
                              selectedSubCode,
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
                          child: const Text('Add Section'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveSection(
    String departmentId,
    String year,
    String sectionLetter,
    String departmentCode,
    String? subCode,
  ) async {
    try {
      // Generate section code with or without subCode
      final sectionCode =
          subCode != null && subCode.isNotEmpty
              ? '$departmentCode-$subCode-${year.replaceAll('st', '').replaceAll('nd', '').replaceAll('rd', '').replaceAll('th', '')}$sectionLetter'
              : '$departmentCode-${year.replaceAll('st', '').replaceAll('nd', '').replaceAll('rd', '').replaceAll('th', '')}$sectionLetter';

      // Check for duplicate section code across all departments
      if (await _isDuplicateSectionCode(sectionCode)) {
        Get.snackbar(
          'Duplicate Section Error',
          'Section "$sectionCode" already exists in the system! Please choose a different year, section letter, or sub-code.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // Check for duplicate section code within the same department
      if (await _isDuplicateSectionCodeInDepartment(
        sectionCode,
        departmentId,
      )) {
        Get.snackbar(
          'Duplicate Section Error',
          'Section "$sectionCode" already exists in this department! Please choose a different year, section letter, or sub-code.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      await _firestore.collection('sections').add({
        'departmentId': departmentId,
        'year': year,
        'sectionLetter': sectionLetter,
        'subCode': subCode,
        'sectionCode': sectionCode,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Success',
        'Section $sectionCode added successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add section: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
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
    try {
      // Get the section's department to regenerate section code
      final sectionDoc =
          await _firestore.collection('sections').doc(sectionId).get();
      final sectionData = sectionDoc.data();

      if (sectionData == null) {
        Get.snackbar(
          'Error',
          'Section not found',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Generate new section code with or without subCode
      final sectionCode =
          subCode != null && subCode.isNotEmpty
              ? '$departmentCode-$subCode-${year.replaceAll('st', '').replaceAll('nd', '').replaceAll('rd', '').replaceAll('th', '')}$sectionLetter'
              : '$departmentCode-${year.replaceAll('st', '').replaceAll('nd', '').replaceAll('rd', '').replaceAll('th', '')}$sectionLetter';

      // Check for duplicate section code (excluding current section)
      if (await _isDuplicateSectionCodeForUpdate(sectionCode, sectionId)) {
        Get.snackbar(
          'Duplicate Section Error',
          'Section "$sectionCode" already exists in the system! Please choose a different year, section letter, or sub-code.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // Update the section
      await _firestore.collection('sections').doc(sectionId).update({
        'year': year,
        'sectionLetter': sectionLetter,
        'subCode': subCode,
        'sectionCode': sectionCode,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Success',
        'Section $sectionCode updated successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update section: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _deleteDepartment(
    String departmentId,
    String departmentName,
  ) async {
    // Show confirmation dialog
    await ConfirmationDialog.showDeleteDepartmentDialog(
      context,
      departmentName: departmentName,
      onConfirm: () async {
        await _performDeleteDepartment(departmentId);
      },
    );
  }

  Future<void> _performDeleteDepartment(String departmentId) async {
    try {
      // First delete all sections under this department
      final sectionsQuery =
          await _firestore
              .collection('sections')
              .where('departmentId', isEqualTo: departmentId)
              .get();

      for (var doc in sectionsQuery.docs) {
        await doc.reference.delete();
      }

      // Then delete the department
      await _firestore.collection('departments').doc(departmentId).delete();

      Get.snackbar(
        'Success',
        'Department and all its sections deleted successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete department: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _deleteSection(String sectionId, String sectionCode) async {
    // Show confirmation dialog
    await ConfirmationDialog.showDeleteSectionDialog(
      context,
      sectionCode: sectionCode,
      onConfirm: () async {
        await _performDeleteSection(sectionId);
      },
    );
  }

  Future<void> _performDeleteSection(String sectionId) async {
    try {
      await _firestore.collection('sections').doc(sectionId).delete();

      Get.snackbar(
        'Success',
        'Section deleted successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete section: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Semester Management Methods
  Future<void> _createSemester() async {
    final TextEditingController yearController = TextEditingController();
    String selectedSemester = '1st Semester';

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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF34A853).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.calendar_month,
                            color: Color(0xFF34A853),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Create New Semester',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: yearController,
                      decoration: InputDecoration(
                        labelText: 'Academic Year',
                        hintText: 'e.g., 2024-2025',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF34A853),
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSemester,
                      decoration: InputDecoration(
                        labelText: 'Semester',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF34A853),
                          ),
                        ),
                      ),
                      items:
                          ['1st Semester', '2nd Semester', 'Summer'].map((
                            String semester,
                          ) {
                            return DropdownMenuItem<String>(
                              value: semester,
                              child: Text(semester),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedSemester = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed:
                              () => _saveSemester(
                                yearController.text.trim(),
                                selectedSemester,
                              ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF34A853),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Create Semester'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveSemester(String year, String semester) async {
    if (year.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter academic year',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      // Check for duplicate semester
      final existingSemester =
          await _firestore
              .collection('semesters')
              .where('year', isEqualTo: year)
              .where('semester', isEqualTo: semester)
              .get();

      if (existingSemester.docs.isNotEmpty) {
        Get.snackbar(
          'Error',
          'This semester already exists',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      await _firestore.collection('semesters').add({
        'year': year,
        'semester': semester,
        'displayName': '$semester $year',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      Navigator.of(context).pop();
      Get.snackbar(
        'Success',
        'Semester created successfully',
        backgroundColor: const Color(0xFF34A853),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create semester: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _loadSemesters() async {
    try {
      print('Loading semesters...');
      final snapshot =
          await _firestore
              .collection('semesters')
              .orderBy('createdAt', descending: true)
              .get();

      print('Found ${snapshot.docs.length} semesters');

      _semesters =
          snapshot.docs.map((doc) {
            final data = doc.data();
            print('Semester data: $data');
            return {
              'id': doc.id,
              'year': data['year'] ?? '',
              'semester': data['semester'] ?? '',
              'displayName': data['displayName'] ?? '',
              'isActive': data['isActive'] ?? true,
              'createdAt': data['createdAt'],
            };
          }).toList();

      print('Loaded semesters: $_semesters');
      setState(() {});
    } catch (e) {
      print('Error loading semesters: $e');
    }
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

  Future<void> _deleteSemester(String semesterId, String semesterName) async {
    // Show confirmation dialog
    await ConfirmationDialog.showDeleteSemesterDialog(
      context,
      semesterName: semesterName,
      onConfirm: () async {
        await _performDeleteSemester(semesterId);
      },
    );
  }

  Future<void> _performDeleteSemester(String semesterId) async {
    try {
      // Get all instructors assigned to this semester
      final assignedInstructorsSnapshot =
          await _firestore
              .collection('semesters')
              .doc(semesterId)
              .collection('instructors')
              .get();

      // Remove semester from each instructor's assignedSemesters array
      for (var instructorDoc in assignedInstructorsSnapshot.docs) {
        final instructorId = instructorDoc.id;
        final instructorRef = _firestore
            .collection('instructors')
            .doc(instructorId);
        final instructorSnapshot = await instructorRef.get();

        if (instructorSnapshot.exists) {
          final instructorData =
              instructorSnapshot.data() as Map<String, dynamic>;
          final assignedSemesters =
              (instructorData['assignedSemesters'] as List<dynamic>?) ?? [];

          // Remove this semester from the array
          final updatedSemesters =
              assignedSemesters
                  .where((sem) => sem['semesterId'] != semesterId)
                  .toList();

          await instructorRef.update({
            'assignedSemesters': updatedSemesters,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // Delete the semester document (this will cascade delete subcollections)
      await _firestore.collection('semesters').doc(semesterId).delete();

      // Reload semesters to update the UI
      _loadSemesters();

      Get.snackbar(
        'Success',
        'Semester deleted successfully',
        backgroundColor: const Color(0xFF34A853),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete semester: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
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
                // Header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(getResponsivePadding()),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    ),
                  ),
                  child:
                      isMobile
                          ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  SafeAssetImage(
                                    assetPath:
                                        'assets/admin_icons/fluent_hat-graduation-12-regular.png',
                                    width: 28,
                                    height: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Department Management',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Manage departments and sections',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          )
                          : Row(
                            children: [
                              SafeAssetImage(
                                assetPath:
                                    'assets/admin_icons/fluent_hat-graduation-12-regular.png',
                                width: 32,
                                height: 32,
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Department Management',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      'Manage departments and sections',
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(getResponsivePadding()),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Section
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isMobile ? 16 : 24),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF34A853), Color(0xFF2E7D32)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF34A853).withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.school_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Department & Section Management',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Create departments and sections, assign instructors to specific areas',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Action Buttons
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

                                          return Column(
                                            children:
                                                sectionsSnapshot.data!.docs.map((
                                                  sectionDoc,
                                                ) {
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
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  semester['isActive'] == true
                                                      ? const Color(
                                                        0xFF34A853,
                                                      ).withOpacity(0.1)
                                                      : Colors.grey.withOpacity(
                                                        0.1,
                                                      ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color:
                                                    semester['isActive'] == true
                                                        ? const Color(
                                                          0xFF34A853,
                                                        )
                                                        : Colors.grey,
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              semester['isActive'] == true
                                                  ? 'Active'
                                                  : 'Inactive',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    semester['isActive'] == true
                                                        ? const Color(
                                                          0xFF34A853,
                                                        )
                                                        : Colors.grey,
                                              ),
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
                                                () => _deleteSemester(
                                                  semester['id'],
                                                  semester['displayName'] ??
                                                      'Unknown Semester',
                                                ),
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            tooltip: 'Delete Semester',
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

  @override
  void initState() {
    super.initState();
    _loadSemesterData();
  }

  Future<void> _loadSemesterData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final semesterId = widget.semester['id'];

      // Load assigned departments
      final assignedDeptsSnapshot =
          await widget.firestore
              .collection('semesters')
              .doc(semesterId)
              .collection('departments')
              .get();

      _departments.clear();
      for (var assignedDept in assignedDeptsSnapshot.docs) {
        final deptSnapshot =
            await widget.firestore
                .collection('departments')
                .doc(assignedDept.id)
                .get();

        if (deptSnapshot.exists) {
          final data = deptSnapshot.data()!;
          final name = data['displayName'] ?? data['name'] ?? '';
          if (name.trim().isNotEmpty) {
            _departments.add({
              'id': deptSnapshot.id,
              'name': name,
              'code': data['code'] ?? 'N/A',
              'description': data['description'] ?? '',
            });
          }
        }
      }

      // Load assigned instructors
      final assignedInstructorsSnapshot =
          await widget.firestore
              .collection('semesters')
              .doc(semesterId)
              .collection('instructors')
              .get();

      _instructors.clear();
      for (var assignedInstructor in assignedInstructorsSnapshot.docs) {
        final instructorSnapshot =
            await widget.firestore
                .collection('instructors')
                .doc(assignedInstructor.id)
                .get();

        if (instructorSnapshot.exists) {
          final data = instructorSnapshot.data()!;
          final name = data['name'] ?? '';
          if (name.trim().isNotEmpty && name.toLowerCase() != 'unknown') {
            _instructors.add({
              'id': instructorSnapshot.id,
              'name': name,
              'email': data['email'] ?? 'N/A',
              'department': data['department'] ?? 'N/A',
            });
          }
        }
      }

      // Load assigned classes
      final assignedClassesSnapshot =
          await widget.firestore
              .collection('semesters')
              .doc(semesterId)
              .collection('classes')
              .get();

      _classes.clear();
      for (var assignedClass in assignedClassesSnapshot.docs) {
        // Find the class in instructors collection
        for (var instructor in _instructors) {
          final classSnapshot =
              await widget.firestore
                  .collection('instructors')
                  .doc(instructor['id'])
                  .collection('classes')
                  .doc(assignedClass.id)
                  .get();

          if (classSnapshot.exists) {
            final classData = classSnapshot.data()!;
            final sectionName = classData['section']?.toString().trim() ?? '';
            if (sectionName.isNotEmpty) {
              _classes.add({
                'id': classSnapshot.id,
                'section': sectionName,
                'instructorName': instructor['name'],
                'instructorId': instructor['id'],
                'department': instructor['department'],
              });
              break; // Found the class, no need to continue searching
            }
          }
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading semester data: $e');
      setState(() {
        _isLoading = false;
      });
    }
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
              const Icon(Icons.class_, color: Color(0xFF34A853), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classItem['section'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Instructor: ${classItem['instructorName']}',
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load departments
      final departmentsSnapshot =
          await widget.firestore.collection('departments').get();
      _departments =
          departmentsSnapshot.docs
              .map((doc) {
                final data = doc.data();
                return {
                  'id': doc.id,
                  'name': data['displayName'] ?? data['name'] ?? '',
                  'code': data['code'] ?? 'N/A',
                };
              })
              .where((dept) => dept['name'].toString().trim().isNotEmpty)
              .toList();

      // Load instructors
      final instructorsSnapshot =
          await widget.firestore.collection('instructors').get();
      _instructors =
          instructorsSnapshot.docs
              .map((doc) {
                final data = doc.data();
                return {
                  'id': doc.id,
                  'name': data['name'] ?? '',
                  'email': data['email'] ?? 'N/A',
                  'department': data['department'] ?? 'N/A',
                };
              })
              .where(
                (instructor) => instructor['name'].toString().trim().isNotEmpty,
              )
              .toList();

      // Load classes from all instructors
      _classes.clear();
      for (var instructor in _instructors) {
        final classesSnapshot =
            await widget.firestore
                .collection('instructors')
                .doc(instructor['id'])
                .collection('classes')
                .get();

        for (var classDoc in classesSnapshot.docs) {
          final classData = classDoc.data();
          final sectionName = classData['section']?.toString().trim() ?? '';
          if (sectionName.isNotEmpty) {
            _classes.add({
              'id': classDoc.id,
              'section': sectionName,
              'instructorName': instructor['name'],
              'instructorId': instructor['id'],
              'department': instructor['department'],
            });
          }
        }
      }

      // Load existing assignments for this semester
      await _loadExistingAssignments();

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

  Future<void> _loadExistingAssignments() async {
    try {
      final semesterId = widget.semester['id'];

      // Load assigned departments
      final assignedDeptsSnapshot =
          await widget.firestore
              .collection('semesters')
              .doc(semesterId)
              .collection('departments')
              .get();
      _selectedDepartments =
          assignedDeptsSnapshot.docs.map((doc) => doc.id).toList();

      // Load assigned instructors
      final assignedInstructorsSnapshot =
          await widget.firestore
              .collection('semesters')
              .doc(semesterId)
              .collection('instructors')
              .get();
      _selectedInstructors =
          assignedInstructorsSnapshot.docs.map((doc) => doc.id).toList();

      // Load assigned classes
      final assignedClassesSnapshot =
          await widget.firestore
              .collection('semesters')
              .doc(semesterId)
              .collection('classes')
              .get();
      _selectedClasses =
          assignedClassesSnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error loading existing assignments: $e');
    }
  }

  Future<void> _saveAssignments() async {
    try {
      final semesterId = widget.semester['id'];

      // Save department assignments
      await _saveDepartmentAssignments(semesterId);

      // Save instructor assignments
      await _saveInstructorAssignments(semesterId);

      // Save class assignments
      await _saveClassAssignments(semesterId);

      Get.snackbar(
        'Success',
        'Assignments saved successfully',
        backgroundColor: const Color(0xFF34A853),
        colorText: Colors.white,
      );

      Navigator.of(context).pop();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save assignments: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _saveDepartmentAssignments(String semesterId) async {
    // Remove all existing department assignments
    final existingDeptsSnapshot =
        await widget.firestore
            .collection('semesters')
            .doc(semesterId)
            .collection('departments')
            .get();

    for (var doc in existingDeptsSnapshot.docs) {
      await doc.reference.delete();
    }

    // Add new department assignments
    for (var deptId in _selectedDepartments) {
      await widget.firestore
          .collection('semesters')
          .doc(semesterId)
          .collection('departments')
          .doc(deptId)
          .set({'assignedAt': FieldValue.serverTimestamp()});
    }
  }

  Future<void> _saveInstructorAssignments(String semesterId) async {
    // Get semester data for the array
    // Note: Using Timestamp.now() instead of FieldValue.serverTimestamp()
    // because serverTimestamp() is not supported inside arrays
    final semesterData = {
      'semesterId': semesterId,
      'displayName': widget.semester['displayName'] ?? '',
      'year': widget.semester['year'] ?? '',
      'semester': widget.semester['semester'] ?? '',
      'isActive': widget.semester['isActive'] ?? true,
      'assignedAt': Timestamp.now(),
    };

    // Remove all existing instructor assignments from subcollection
    final existingInstructorsSnapshot =
        await widget.firestore
            .collection('semesters')
            .doc(semesterId)
            .collection('instructors')
            .get();

    // Get list of previously assigned instructors
    final previouslyAssignedInstructors =
        existingInstructorsSnapshot.docs.map((doc) => doc.id).toList();

    // Remove semester from instructors who are no longer selected
    for (var instructorId in previouslyAssignedInstructors) {
      if (!_selectedInstructors.contains(instructorId)) {
        // Remove from subcollection
        await widget.firestore
            .collection('semesters')
            .doc(semesterId)
            .collection('instructors')
            .doc(instructorId)
            .delete();

        // Remove semester from instructor's assignedSemesters array
        final instructorRef = widget.firestore
            .collection('instructors')
            .doc(instructorId);
        final instructorDoc = await instructorRef.get();

        if (instructorDoc.exists) {
          final instructorData = instructorDoc.data() as Map<String, dynamic>;
          final assignedSemesters =
              (instructorData['assignedSemesters'] as List<dynamic>?) ?? [];

          // Remove this semester from the array
          final updatedSemesters =
              assignedSemesters
                  .where((sem) => sem['semesterId'] != semesterId)
                  .toList();

          await instructorRef.update({
            'assignedSemesters': updatedSemesters,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    }

    // Add new instructor assignments
    for (var instructorId in _selectedInstructors) {
      // Add to semester subcollection
      await widget.firestore
          .collection('semesters')
          .doc(semesterId)
          .collection('instructors')
          .doc(instructorId)
          .set({'assignedAt': FieldValue.serverTimestamp()});

      // Add semester to instructor's assignedSemesters array
      final instructorRef = widget.firestore
          .collection('instructors')
          .doc(instructorId);
      final instructorDoc = await instructorRef.get();

      if (instructorDoc.exists) {
        final instructorData = instructorDoc.data() as Map<String, dynamic>;
        final assignedSemesters =
            (instructorData['assignedSemesters'] as List<dynamic>?) ?? [];

        // Check if semester already exists in array
        final semesterExists = assignedSemesters.any(
          (sem) => sem['semesterId'] == semesterId,
        );

        if (!semesterExists) {
          // Add semester to array
          assignedSemesters.add(semesterData);

          await instructorRef.update({
            'assignedSemesters': assignedSemesters,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        // If instructor document doesn't exist, create it with the semester array
        await instructorRef.set({
          'assignedSemesters': [semesterData],
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }
  }

  Future<void> _saveClassAssignments(String semesterId) async {
    // Remove all existing class assignments
    final existingClassesSnapshot =
        await widget.firestore
            .collection('semesters')
            .doc(semesterId)
            .collection('classes')
            .get();

    for (var doc in existingClassesSnapshot.docs) {
      await doc.reference.delete();
    }

    // Add new class assignments
    for (var classId in _selectedClasses) {
      await widget.firestore
          .collection('semesters')
          .doc(semesterId)
          .collection('classes')
          .doc(classId)
          .set({'assignedAt': FieldValue.serverTimestamp()});
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
