import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../shared/admin/admin_sidebar.dart';
import '../shared/admin/admin_navigation_constants.dart';
import '../shared/widgets/safe_asset_image.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with AutomaticKeepAliveClientMixin {
  AdminNavigationItem _selectedItem = AdminNavigationItem.dashboard;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> instructors = [];
  List<String> programs = ['All Programs'];
  int expandedInstructor = -1;
  int expandedSection = -1;
  String searchQuery = '';
  String selectedProgram = 'All Programs';
  bool _isLoading = true;
  final ScrollController _programScrollController = ScrollController();
  int _totalTreeCount = 0;
  bool _isTreeCountLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _showInstructorProfile(Map<String, dynamic> instructorData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.5,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            padding: const EdgeInsets.all(24),
            child: InstructorProfileView(instructor: instructorData),
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;

  void _handleNavigationSelect(AdminNavigationItem item) {
    setState(() {
      _selectedItem = item;
    });
    String route = AdminNavigationHelper.getRoute(item);
    Get.toNamed(route);
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _isTreeCountLoading = true;
      });

      // Load departments for program filtering
      await _loadPrograms();

      // Load instructors with their classes and students
      await _loadInstructors();

      // Load planted tree statistics
      await _loadTreeStats();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      Get.snackbar(
        'Error',
        'Failed to load dashboard data: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      setState(() {
        _isLoading = false;
        _isTreeCountLoading = false;
      });
    }
  }

  Future<void> _loadTreeStats() async {
    try {
      final treesSnapshot = await _firestore.collectionGroup('trees').get();
      int totalQuantity = 0;
      for (final doc in treesSnapshot.docs) {
        final data = doc.data();
        final quantity = data['quantity'];
        if (quantity is num) {
          totalQuantity += quantity.toInt();
        } else {
          totalQuantity += 1;
        }
      }

      if (!mounted) return;
      setState(() {
        _totalTreeCount = totalQuantity;
        _isTreeCountLoading = false;
      });
    } catch (e) {
      print('Error loading tree stats: $e');
      if (!mounted) return;
      setState(() {
        _totalTreeCount = 0;
        _isTreeCountLoading = false;
      });
    }
  }

  Future<void> _loadPrograms() async {
    try {
      final departmentsSnapshot =
          await _firestore.collection('departments').get();
      final departmentCodes =
          departmentsSnapshot.docs
              .map((doc) => doc.data()['code'] as String? ?? '')
              .where((code) => code.isNotEmpty)
              .toList();

      setState(() {
        programs = ['All Programs', ...departmentCodes];
      });
    } catch (e) {
      print('Error loading programs: $e');
    }
  }

  Future<void> _loadInstructors() async {
    try {
      final instructorsSnapshot =
          await _firestore.collection('instructors').get();

      instructors.clear();

      for (var instructorDoc in instructorsSnapshot.docs) {
        final instructorData = instructorDoc.data();
        final instructorName = instructorData['name']?.toString().trim() ?? '';
        final instructorStatus =
            instructorData['status']?.toString() ?? 'Pending';

        // Filter out instructors without names or with "unknown" names
        if (instructorName.isEmpty ||
            instructorName.toLowerCase() == 'unknown') {
          continue;
        }

        // Only include approved instructors - exclude pending and rejected
        if (instructorStatus != 'Approved') {
          print(
            '⏭️ Skipping instructor $instructorName - Status: $instructorStatus',
          );
          continue;
        }

        // Debug: Print all fields in instructor document
        print('🔍 Instructor: $instructorName');
        print('   Document ID: ${instructorDoc.id}');

        // Build a map of departmentCode -> departmentId from assignments
        Map<String, String> departmentCodeToId = {};
        Set<String> departmentCodes = {};
        Set<String> departmentNames = {};

        final assignments = instructorData['assignments'];
        if (assignments != null &&
            assignments is List &&
            assignments.isNotEmpty) {
          print('   📋 Found ${assignments.length} assignments');

          for (var i = 0; i < assignments.length; i++) {
            final assignmentData = assignments[i];

            if (assignmentData is Map) {
              final departmentId = assignmentData['departmentId']?.toString();
              final departmentCode =
                  assignmentData['departmentCode']?.toString();

              if (departmentId != null && departmentCode != null) {
                departmentCodeToId[departmentCode] = departmentId;
                departmentCodes.add(departmentCode);

                print(
                  '   🔍 Assignment $i - DeptCode: $departmentCode, DeptId: $departmentId',
                );

                // Fetch department details from departments collection
                try {
                  final departmentDoc =
                      await _firestore
                          .collection('departments')
                          .doc(departmentId)
                          .get();

                  if (departmentDoc.exists) {
                    final departmentData = departmentDoc.data();
                    final deptName =
                        departmentData?['displayName'] ??
                        departmentData?['name'] ??
                        departmentData?['code'] ??
                        departmentCode;

                    departmentNames.add(deptName);
                    print('   ✅ Assignment $i - Department: $deptName');
                  }
                } catch (e) {
                  print('   ❌ Error fetching department $departmentId: $e');
                }
              }
            }
          }
        }

        // Fallback to instructor's department field if no assignments
        String departmentName =
            departmentNames.isNotEmpty
                ? departmentNames.join(', ')
                : (instructorData['department']?.toString() ?? 'N/A');

        print('   ✅ Final department: $departmentName');
        print('   ✅ Department codes: ${departmentCodes.join(', ')}');

        // Load classes for this instructor (schedules only)
        final classesSnapshot =
            await _firestore
                .collection('instructors')
                .doc(instructorDoc.id)
                .collection('classes')
                .get();

        // Load approved students from instructors/{instructorId}/students
        final studentsSnapshot =
            await _firestore
                .collection('instructors')
                .doc(instructorDoc.id)
                .collection('students')
                .get();

        List<Map<String, dynamic>> sections = [];
        int totalStudents = studentsSnapshot.docs.length;

        // Group students by section
        Map<String, List<Map<String, dynamic>>> studentsBySection = {};
        for (var studentDoc in studentsSnapshot.docs) {
          final studentData = studentDoc.data();
          final sectionName =
              studentData['selectedSectionCode']?.toString().trim() ??
              'Unknown';

          if (!studentsBySection.containsKey(sectionName)) {
            studentsBySection[sectionName] = [];
          }

          // Extract program code from student's selectedSectionCode (e.g., "BSIT-1A" -> "BSIT")
          String studentProgramCode = 'N/A';
          final studentSectionCode =
              studentData['selectedSectionCode']?.toString().trim() ?? '';
          if (studentSectionCode.isNotEmpty) {
            final studentSectionMatch = RegExp(
              r'^([A-Z]+)',
            ).firstMatch(studentSectionCode);
            if (studentSectionMatch != null) {
              studentProgramCode = studentSectionMatch.group(1) ?? 'N/A';
            }
          }

          // Fetch idNumber and profileImage from users collection using doc.id as user document ID
          String idNumber = '';
          String profileImage = '';
          try {
            // The document ID in students subcollection is often the user document ID
            final userDoc =
                await _firestore.collection('users').doc(studentDoc.id).get();

            if (userDoc.exists) {
              final userData = userDoc.data() ?? {};
              idNumber = userData['idNumber']?.toString() ?? '';
              profileImage =
                  userData['profileImage']?.toString() ??
                  userData['profileImageUrl']?.toString() ??
                  userData['profileUrl']?.toString() ??
                  '';
              print(
                '✅ Found idNumber via doc.id (${studentDoc.id}): "$idNumber"',
              );
            } else {
              // Fallback: try matching by studentId field
              final studentId = studentData['studentId']?.toString() ?? '';
              print(
                '⚠️ User doc not found for ${studentDoc.id}, trying studentId: "$studentId"',
              );
              if (studentId.isNotEmpty) {
                final userQuery =
                    await _firestore
                        .collection('users')
                        .where('studentId', isEqualTo: studentId)
                        .limit(1)
                        .get();

                if (userQuery.docs.isNotEmpty) {
                  final userData = userQuery.docs.first.data();
                  idNumber = userData['idNumber']?.toString() ?? '';
                  profileImage =
                      userData['profileImage']?.toString() ??
                      userData['profileImageUrl']?.toString() ??
                      userData['profileUrl']?.toString() ??
                      '';
                  print(
                    '✅ Found idNumber via studentId query ("$studentId"): "$idNumber"',
                  );
                } else {
                  print('❌ No user found with studentId: "$studentId"');
                }
              }
            }
          } catch (e) {
            print(
              '❌ Error fetching user data for student ${studentDoc.id}: $e',
            );
          }

          print(
            '📝 Student: ${studentData['studentName']}, idNumber: "$idNumber"',
          );

          studentsBySection[sectionName]!.add({
            'name': studentData['studentName']?.toString() ?? 'Unknown',
            'studentName': studentData['studentName']?.toString() ?? 'Unknown',
            'email': studentData['email']?.toString() ?? '',
            'studentId': studentData['studentId']?.toString() ?? '',
            'idNumber': idNumber,
            'profileImage': profileImage,
            'status': studentData['isActive'] == true ? 'active' : 'inactive',
            'program':
                studentProgramCode, // Store each student's actual program code
          });
        }

        // Create sections from classes (schedules)
        for (var classDoc in classesSnapshot.docs) {
          final classData = classDoc.data();
          final sectionName = classData['section']?.toString().trim() ?? '';

          if (sectionName.isEmpty) continue;

          final students = studentsBySection[sectionName] ?? [];
          final activeStudents =
              students.where((s) => s['status'] == 'active').length;
          final inactiveStudents = students.length - activeStudents;

          // Extract department code from section name (e.g., "BSIT-4D" -> "BSIT")
          String sectionDeptCode = 'N/A';
          final sectionCodeMatch = RegExp(r'^([A-Z]+)').firstMatch(sectionName);
          if (sectionCodeMatch != null) {
            sectionDeptCode = sectionCodeMatch.group(1) ?? 'N/A';
          }

          // Use department code from section if it matches instructor's assignments
          String programCode = sectionDeptCode;
          if (!departmentCodes.contains(sectionDeptCode) &&
              departmentCodes.isNotEmpty) {
            // If section's dept code doesn't match assignments, use first assignment's dept code
            programCode = departmentCodes.first;
          }

          // Format schedule from schedules array or fallback to old format
          String scheduleString = _formatSchedule(classData);

          sections.add({
            'id': classDoc.id,
            'name': sectionName,
            'code': classData['course'] ?? 'N/A',
            'schedule': scheduleString,
            'program':
                programCode, // Use the extracted/matched department code for filtering
            'active': activeStudents,
            'inactive': inactiveStudents,
            'students': students,
          });
        }

        instructors.add({
          'id': instructorDoc.id,
          'name': instructorName,
          'email': instructorData['email'] ?? 'N/A',
          'phone': instructorData['phone'] ?? '',
          'department': departmentName,
          'departmentCodes':
              departmentCodes.toList(), // Store codes for filtering
          'profileUrl':
              instructorData['profileUrl'] ??
              instructorData['profileImageUrl'] ??
              '',
          'about': instructorData['about'] ?? '',
          'sections': sections,
          'totalSections': sections.length,
          'totalStudents': totalStudents,
        });
      }
    } catch (e) {
      print('Error loading instructors: $e');
    }
  }

  /// Load all students enrolled under instructor "dem" from all sources
  Future<List<Map<String, dynamic>>> _loadAllDemStudents() async {
    List<Map<String, dynamic>> allStudents = [];

    try {
      // Find instructor "dem" by name
      final instructorsSnapshot =
          await _firestore
              .collection('instructors')
              .where('name', isEqualTo: 'dem')
              .get();

      if (instructorsSnapshot.docs.isEmpty) {
        print('Instructor "dem" not found');
        return allStudents;
      }

      final demInstructorId = instructorsSnapshot.docs.first.id;
      print('Found instructor "dem" with ID: $demInstructorId');

      // Method 1: Get students from instructor's classes
      final classesSnapshot =
          await _firestore
              .collection('instructors')
              .doc(demInstructorId)
              .collection('classes')
              .get();

      for (var classDoc in classesSnapshot.docs) {
        final classData = classDoc.data();
        final sectionName = classData['section'] ?? 'Unknown Section';

        final studentsSnapshot =
            await _firestore
                .collection('instructors')
                .doc(demInstructorId)
                .collection('classes')
                .doc(classDoc.id)
                .collection('students')
                .get();

        for (var studentDoc in studentsSnapshot.docs) {
          final studentData = studentDoc.data();
          allStudents.add({
            'id': studentDoc.id,
            'studentId': studentDoc.id,
            'studentName':
                studentData['fullName']?.toString() ??
                studentData['name']?.toString() ??
                studentData['displayName']?.toString() ??
                'Unknown Student',
            'email': studentData['email']?.toString() ?? 'No email',
            'enrollmentStatus':
                studentData['enrollmentStatus']?.toString() ?? 'pending',
            'enrolledAt': _formatDate(
              studentData['enrolledAt'] ?? studentData['createdAt'],
            ),
            'isActive': true,
            'section': sectionName,
            'source': 'instructor_classes',
          });
        }
      }

      // Method 2: Get students from users collection who selected instructor "dem"
      final usersSnapshot =
          await _firestore
              .collection('users')
              .where('selectedInstructorId', isEqualTo: demInstructorId)
              .where('selectionComplete', isEqualTo: true)
              .get();

      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final studentId = userDoc.id;

        // Check if this student is already in our list
        bool alreadyExists = allStudents.any(
          (student) =>
              student['studentId'] == studentId || student['id'] == studentId,
        );

        if (!alreadyExists) {
          allStudents.add({
            'id': studentId,
            'studentId': studentId,
            'studentName':
                userData['fullName']?.toString() ??
                userData['name']?.toString() ??
                userData['displayName']?.toString() ??
                'Unknown Student',
            'email': userData['email']?.toString() ?? 'No email',
            'enrollmentStatus':
                userData['enrollmentStatus']?.toString() ?? 'pending',
            'enrolledAt': _formatDate(
              userData['updatedAt'] ?? userData['createdAt'],
            ),
            'isActive': true,
            'section':
                userData['selectedSectionCode']?.toString() ??
                'Unknown Section',
            'source': 'users_collection',
          });
        }
      }

      print('Loaded ${allStudents.length} students for instructor "dem"');
    } catch (e) {
      print('Error loading all dem students: $e');
    }

    return allStudents;
  }

  String? _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    try {
      if (date is Timestamp) {
        final dateTime = date.toDate();
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      } else if (date is DateTime) {
        return '${date.day}/${date.month}/${date.year}';
      } else if (date is String) {
        // If it's already a string, return as is
        return date;
      }
      return 'Unknown';
    } catch (e) {
      print('Error formatting date: $e, date type: ${date.runtimeType}');
      return 'Unknown';
    }
  }

  /// Show modal with all students enrolled under instructor "dem"
  Future<void> _showDemStudentsModal() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF34A853)),
            ),
          ),
    );

    try {
      // Load all students for instructor "dem"
      final students = await _loadAllDemStudents();

      // Close loading dialog
      Navigator.of(context).pop();

      // Show students modal
      showDialog(
        context: context,
        builder:
            (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
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
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF34A853).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.people,
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
                                'Students - Instructor "dem"',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              Text(
                                '${students.length} students enrolled',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
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
                    const SizedBox(height: 20),
                    // Students list
                    Expanded(
                      child:
                          students.isEmpty
                              ? const Center(
                                child: Text(
                                  'No students found for instructor "dem"',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                              : ListView.builder(
                                itemCount: students.length,
                                itemBuilder: (context, index) {
                                  try {
                                    final student = students[index];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey[200]!,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.05,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor:
                                                (student['profileImage']
                                                                ?.toString() ??
                                                            '')
                                                        .isNotEmpty
                                                    ? Colors.transparent
                                                    : const Color(
                                                      0xFF34A853,
                                                    ).withOpacity(0.1),
                                            backgroundImage:
                                                (student['profileImage']
                                                                ?.toString() ??
                                                            '')
                                                        .isNotEmpty
                                                    ? NetworkImage(
                                                      student['profileImage'],
                                                    )
                                                    : null,
                                            child:
                                                (student['profileImage']
                                                                ?.toString() ??
                                                            '')
                                                        .isEmpty
                                                    ? Text(
                                                      _getInitials(
                                                        student['studentName']
                                                                ?.toString() ??
                                                            'Unknown',
                                                      ),
                                                      style: const TextStyle(
                                                        color: Color(
                                                          0xFF34A853,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    )
                                                    : null,
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  student['studentName']
                                                          ?.toString() ??
                                                      'Unknown Student',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  student['email']
                                                          ?.toString() ??
                                                      'No email',
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  student['idNumber'] != null &&
                                                          (student['idNumber']
                                                                  as String)
                                                              .isNotEmpty
                                                      ? 'ID Number: ${student['idNumber']}'
                                                      : 'ID Number: N/A',
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                if (student['section'] != null)
                                                  Text(
                                                    'Section: ${student['section']?.toString() ?? 'Unknown'}',
                                                    style: const TextStyle(
                                                      color: Colors.blue,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      student['enrollmentStatus'] ==
                                                              'approved'
                                                          ? Colors.green
                                                              .withOpacity(0.1)
                                                          : student['enrollmentStatus'] ==
                                                              'rejected'
                                                          ? Colors.red
                                                              .withOpacity(0.1)
                                                          : Colors.orange
                                                              .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  (student['enrollmentStatus']
                                                              ?.toString() ??
                                                          'pending')
                                                      .toUpperCase(),
                                                  style: TextStyle(
                                                    color:
                                                        (student['enrollmentStatus']
                                                                        ?.toString() ??
                                                                    'pending') ==
                                                                'approved'
                                                            ? Colors.green
                                                            : (student['enrollmentStatus']
                                                                        ?.toString() ??
                                                                    'pending') ==
                                                                'rejected'
                                                            ? Colors.red
                                                            : Colors.orange,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              if (student['source'] != null)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        student['source'] ==
                                                                'instructor_classes'
                                                            ? Colors.blue
                                                                .withOpacity(
                                                                  0.1,
                                                                )
                                                            : Colors.purple
                                                                .withOpacity(
                                                                  0.1,
                                                                ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    (student['source']
                                                                    ?.toString() ??
                                                                'unknown') ==
                                                            'instructor_classes'
                                                        ? 'Class'
                                                        : 'Users',
                                                    style: TextStyle(
                                                      color:
                                                          (student['source']
                                                                          ?.toString() ??
                                                                      'unknown') ==
                                                                  'instructor_classes'
                                                              ? Colors.blue
                                                              : Colors.purple,
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  } catch (e) {
                                    print(
                                      'Error displaying student at index $index: $e',
                                    );
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.red),
                                      ),
                                      child: Text(
                                        'Error loading student data: $e',
                                        style: const TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                    ),
                  ],
                ),
              ),
            ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error
      Get.snackbar(
        'Error',
        'Failed to load students: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  List<Map<String, dynamic>> get filteredInstructors {
    List<Map<String, dynamic>> filtered = List.from(instructors);

    // Apply program filter first
    if (selectedProgram != 'All Programs') {
      filtered =
          filtered.where((inst) {
            // Check if instructor has any assignments matching the selected program code
            final departmentCodes = inst['departmentCodes'] as List?;
            if (departmentCodes != null &&
                departmentCodes.contains(selectedProgram)) {
              return true;
            }

            // Also check sections for backward compatibility
            final sections = inst['sections'] as List?;
            if (sections == null || sections.isEmpty) return false;
            return sections.any(
              (section) => (section as Map)['program'] == selectedProgram,
            );
          }).toList();
    }

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();
      if (query.isNotEmpty) {
        filtered =
            filtered.where((inst) {
              // Search in instructor name
              final name = (inst['name'] as String? ?? '').toLowerCase();
              if (name.contains(query)) return true;

              // Search in instructor email
              final email = (inst['email'] as String? ?? '').toLowerCase();
              if (email.contains(query)) return true;

              // Search in department
              final department =
                  (inst['department'] as String? ?? '').toLowerCase();
              if (department.contains(query)) return true;

              // Search in sections
              final sections = inst['sections'] as List?;
              if (sections != null) {
                for (var section in sections) {
                  final sectionMap = section as Map<String, dynamic>;
                  final sectionName =
                      (sectionMap['name'] as String? ?? '').toLowerCase();
                  final sectionCode =
                      (sectionMap['code'] as String? ?? '').toLowerCase();
                  if (sectionName.contains(query) ||
                      sectionCode.contains(query)) {
                    return true;
                  }

                  // Search in students
                  final students = sectionMap['students'] as List?;
                  if (students != null) {
                    for (var student in students) {
                      final studentMap = student as Map<String, dynamic>;
                      final studentName =
                          (studentMap['name'] as String? ?? '').toLowerCase();
                      final studentEmail =
                          (studentMap['email'] as String? ?? '').toLowerCase();
                      if (studentName.contains(query) ||
                          studentEmail.contains(query)) {
                        return true;
                      }
                    }
                  }
                }
              }

              return false;
            }).toList();
      }
    }

    return filtered;
  }

  int get totalInstructors => filteredInstructors.length;
  int get totalSections => filteredInstructors.fold(
    0,
    (sum, inst) => sum + ((inst['sections'] as List?)?.length ?? 0),
  );
  int get totalStudents => filteredInstructors.fold(0, (sum, inst) {
    final sections = inst['sections'] as List?;
    if (sections == null) return sum;
    final studentsCount = sections.fold<int>(0, (s, sec) {
      final students = (sec as Map)['students'] as List?;
      return s + (students?.length ?? 0);
    });
    return sum + studentsCount;
  });
  int get totalTrees => _totalTreeCount;

  // Helper function to get initials from name (e.g., "Jv P. Tenefrancia" -> "JT")
  String _getInitials(String name) {
    if (name.isEmpty) return 'U';

    final nameParts =
        name.trim().split(' ').where((part) => part.isNotEmpty).toList();
    if (nameParts.isEmpty) return 'U';

    if (nameParts.length == 1) {
      // If only one part, return first letter
      return nameParts[0][0].toUpperCase();
    }

    // Get first letter of first name and first letter of last name
    return '${nameParts.first[0].toUpperCase()}${nameParts.last[0].toUpperCase()}';
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
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF34A853),
                        ),
                      ),
                    )
                    : SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: getResponsivePadding(),
                          vertical: isMobile ? 12 : 18,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(isMobile ? 16 : 28),
                              decoration: BoxDecoration(
                                color: const Color(0xFF34A853),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child:
                                  isMobile
                                      ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              SafeAssetImage(
                                                assetPath:
                                                    'assets/admin_icons/fluent_hat-graduation-12-regular.png',
                                                width: 32,
                                                height: 32,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: const Text(
                                                  'Admin Dashboard',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 22,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: _loadData,
                                                icon: const Icon(
                                                  Icons.refresh,
                                                  color: Colors.white,
                                                  size: 22,
                                                ),
                                                tooltip: 'Refresh Data',
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'National Service Training Program',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      )
                                      : Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SafeAssetImage(
                                            assetPath:
                                                'assets/admin_icons/fluent_hat-graduation-12-regular.png',
                                            width: 40,
                                            height: 40,
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: const [
                                                Text(
                                                  'Admin Dashboard',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 32,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  'National Service Training Program - Manage instructors, sections, and students',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: _loadData,
                                            icon: const Icon(
                                              Icons.refresh,
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                            tooltip: 'Refresh Data',
                                          ),
                                        ],
                                      ),
                            ),
                            const SizedBox(height: 28),
                            // Summary Cards
                            isMobile
                                ? Column(
                                  children: [
                                    _summaryCard(
                                      'Total Instructors',
                                      totalInstructors.toString(),
                                      'NSTP instructors',
                                      'assets/admin_icons/lucide_users-round.png',
                                    ),
                                    const SizedBox(height: 12),
                                    _summaryCard(
                                      'Total Sections',
                                      totalSections.toString(),
                                      'NSTP program sections',
                                      'assets/admin_icons/lucide_users-round (1).png',
                                    ),
                                    const SizedBox(height: 12),
                                    _summaryCard(
                                      'Total Students',
                                      totalStudents.toString(),
                                      'Enrolled in NSTP program',
                                      'assets/admin_icons/lucide_users-round (2).png',
                                      highlight: true,
                                    ),
                                    const SizedBox(height: 12),
                                    _summaryCard(
                                      'Total Trees',
                                      _isTreeCountLoading
                                          ? '...'
                                          : totalTrees.toString(),
                                      'Trees planted across NSTP',
                                      'assets/instructor/icons/lucide_trees.png',
                                      highlight: true,
                                    ),
                                  ],
                                )
                                : isTablet
                                ? Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    _summaryCard(
                                      'Total Instructors',
                                      totalInstructors.toString(),
                                      'NSTP instructors',
                                      'assets/admin_icons/lucide_users-round.png',
                                    ),
                                    _summaryCard(
                                      'Total Sections',
                                      totalSections.toString(),
                                      'NSTP program sections',
                                      'assets/admin_icons/lucide_users-round (1).png',
                                    ),
                                    _summaryCard(
                                      'Total Students',
                                      totalStudents.toString(),
                                      'Enrolled in NSTP program',
                                      'assets/admin_icons/lucide_users-round (2).png',
                                      highlight: true,
                                    ),
                                    _summaryCard(
                                      'Total Trees',
                                      _isTreeCountLoading
                                          ? '...'
                                          : totalTrees.toString(),
                                      'Trees planted across NSTP',
                                      'assets/instructor/icons/lucide_trees.png',
                                      highlight: true,
                                    ),
                                  ],
                                )
                                : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _summaryCard(
                                      'Total Instructors',
                                      totalInstructors.toString(),
                                      'NSTP instructors',
                                      'assets/admin_icons/lucide_users-round.png',
                                    ),
                                    _summaryCard(
                                      'Total Sections',
                                      totalSections.toString(),
                                      'NSTP program sections',
                                      'assets/admin_icons/lucide_users-round (1).png',
                                    ),
                                    _summaryCard(
                                      'Total Students',
                                      totalStudents.toString(),
                                      'Enrolled in NSTP program',
                                      'assets/admin_icons/lucide_users-round (2).png',
                                      highlight: true,
                                    ),
                                    _summaryCard(
                                      'Total Trees',
                                      _isTreeCountLoading
                                          ? '...'
                                          : totalTrees.toString(),
                                      'Trees planted across NSTP',
                                      'assets/instructor/icons/lucide_trees.png',
                                      highlight: true,
                                    ),
                                  ],
                                ),
                            const SizedBox(height: 24),
                            // Search and Filter
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 12 : 25,
                                vertical: isMobile ? 12 : 15,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    height: 48,
                                    width:
                                        isMobile
                                            ? double.infinity
                                            : MediaQuery.of(
                                                  context,
                                                ).size.width *
                                                0.35,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(7),
                                      border: Border.all(
                                        color: const Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Image.asset(
                                          'assets/admin_icons/akar-icons_search.png',
                                          width: 22,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: TextField(
                                            decoration: InputDecoration(
                                              hintText: 'Search Name',
                                              border: InputBorder.none,
                                              suffixIcon:
                                                  searchQuery.isNotEmpty
                                                      ? IconButton(
                                                        icon: const Icon(
                                                          Icons.clear,
                                                          size: 20,
                                                          color: Colors.grey,
                                                        ),
                                                        onPressed: () {
                                                          setState(() {
                                                            searchQuery = '';
                                                          });
                                                        },
                                                      )
                                                      : null,
                                            ),
                                            cursorColor: Colors.black54,
                                            style: const TextStyle(
                                              color: Color(0xFF222B45),
                                            ),
                                            onChanged: (value) {
                                              setState(() {
                                                searchQuery = value;
                                              });
                                              print('Search query: "$value"');
                                              print(
                                                'Filtered instructors count: ${filteredInstructors.length}',
                                              );
                                            },
                                            controller:
                                                TextEditingController.fromValue(
                                                  TextEditingValue(
                                                    text: searchQuery,
                                                    selection:
                                                        TextSelection.collapsed(
                                                          offset:
                                                              searchQuery
                                                                  .length,
                                                        ),
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Replace the FilterChip row with a custom Row for program chips:
                                  Expanded(
                                    child: SizedBox(
                                      height: 50,
                                      child: RawScrollbar(
                                        thumbVisibility: true,
                                        thickness: 6,
                                        radius: const Radius.circular(3),
                                        thumbColor: Colors.grey.shade400,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          controller: _programScrollController,
                                          itemCount: programs.length,
                                          itemBuilder: (context, index) {
                                            final p = programs[index];
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                  ),
                                              child: GestureDetector(
                                                onTap:
                                                    () => setState(
                                                      () => selectedProgram = p,
                                                    ),
                                                onPanUpdate: (details) {
                                                  // Scroll horizontally when dragging
                                                  _programScrollController
                                                      .position
                                                      .jumpTo(
                                                        _programScrollController
                                                                .offset -
                                                            details.delta.dx,
                                                      );
                                                },
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 18,
                                                        vertical: 10,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        selectedProgram == p
                                                            ? const Color(
                                                              0xFF34A853,
                                                            )
                                                            : Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFFE5E7EB,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      if (selectedProgram == p)
                                                        Icon(
                                                          Icons.check,
                                                          size: 18,
                                                          color: Colors.white,
                                                        ),
                                                      if (selectedProgram == p)
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                      Text(
                                                        p,
                                                        style: TextStyle(
                                                          color:
                                                              selectedProgram ==
                                                                      p
                                                                  ? Colors.white
                                                                  : const Color(
                                                                    0xFF222B45,
                                                                  ),
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Instructors',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                                if (searchQuery.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF34A853,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF34A853,
                                        ).withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      '${filteredInstructors.length} result${filteredInstructors.length != 1 ? 's' : ''} found',
                                      style: const TextStyle(
                                        color: Color(0xFF34A853),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Instructor List - Fixed Height Container
                            SizedBox(
                              height: 600, // Fixed height to prevent collapse
                              child:
                                  filteredInstructors.isEmpty
                                      ? Center(
                                        child: Text(
                                          'No instructors found',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 16,
                                          ),
                                        ),
                                      )
                                      : SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ...List.generate(filteredInstructors.length, (
                                              i,
                                            ) {
                                              final instructor =
                                                  filteredInstructors[i];
                                              final isExpanded =
                                                  expandedInstructor == i;
                                              return Container(
                                                margin: const EdgeInsets.only(
                                                  bottom: 18,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Color(0xFFBDBDBD),
                                                      blurRadius:
                                                          2, // more blur for smoothness
                                                      spreadRadius: 2,
                                                      offset: const Offset(
                                                        0,
                                                        2,
                                                      ), // more vertical lift
                                                    ),
                                                  ],
                                                ),

                                                child: Column(
                                                  children: [
                                                    ListTile(
                                                      leading: CircleAvatar(
                                                        backgroundColor:
                                                            (instructor['profileUrl']
                                                                            ?.toString() ??
                                                                        '')
                                                                    .isEmpty
                                                                ? const Color.fromARGB(
                                                                  255,
                                                                  228,
                                                                  245,
                                                                  229,
                                                                )
                                                                : Colors
                                                                    .transparent,
                                                        backgroundImage:
                                                            (instructor['profileUrl']
                                                                            ?.toString() ??
                                                                        '')
                                                                    .isNotEmpty
                                                                ? NetworkImage(
                                                                  instructor['profileUrl'],
                                                                )
                                                                : null,
                                                        radius: 35,
                                                        child:
                                                            (instructor['profileUrl']
                                                                            ?.toString() ??
                                                                        '')
                                                                    .isEmpty
                                                                ? Image.asset(
                                                                  'assets/admin_icons/ri_user-line.png',
                                                                  width: 25,
                                                                )
                                                                : null,
                                                      ),
                                                      title: Text(
                                                        instructor['name']
                                                            as String,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 18,
                                                        ),
                                                      ),
                                                      subtitle: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            instructor['email']
                                                                as String,
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 13,
                                                                ),
                                                          ),
                                                          Text(
                                                            instructor['department']
                                                                as String,
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 13,
                                                                  color:
                                                                      Colors
                                                                          .black,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                      trailing: SizedBox(
                                                        width: 200,
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .end,
                                                          children: [
                                                            Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    Image.asset(
                                                                      'assets/admin_icons/lucide_users-round (3).png',
                                                                      width: 18,
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 10,
                                                                    ),
                                                                    Text(
                                                                      '${instructor['totalSections']} sections',
                                                                      style: const TextStyle(
                                                                        fontSize:
                                                                            13,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    Image.asset(
                                                                      'assets/admin_icons/lucide_users-round (4).png',
                                                                      width: 18,
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 10,
                                                                    ),
                                                                    Text(
                                                                      '${instructor['totalStudents']} students',
                                                                      style: const TextStyle(
                                                                        fontSize:
                                                                            13,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(
                                                              width: 10,
                                                            ),
                                                            IconButton(
                                                              icon: const Icon(
                                                                Icons
                                                                    .person_outline,
                                                                color: Color(
                                                                  0xFF34A853,
                                                                ),
                                                                size: 20,
                                                              ),
                                                              onPressed: () {
                                                                _showInstructorProfile(
                                                                  instructor,
                                                                );
                                                              },
                                                              tooltip:
                                                                  'View Profile',
                                                            ),
                                                            InkWell(
                                                              onTap:
                                                                  () => setState(
                                                                    () =>
                                                                        expandedInstructor =
                                                                            isExpanded
                                                                                ? -1
                                                                                : i,
                                                                  ),
                                                              child: Image.asset(
                                                                isExpanded
                                                                    ? 'assets/admin_icons/gridicons_dropdown (2).png'
                                                                    : 'assets/admin_icons/gridicons_dropdown.png',
                                                                width: 22,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      onTap:
                                                          () => setState(
                                                            () =>
                                                                expandedInstructor =
                                                                    isExpanded
                                                                        ? -1
                                                                        : i,
                                                          ),
                                                      contentPadding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 18,
                                                            vertical: 10,
                                                          ),
                                                    ),
                                                    if (isExpanded &&
                                                        instructor['sections'] !=
                                                            null &&
                                                        (instructor['sections']
                                                                as List)
                                                            .isNotEmpty)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 18,
                                                              vertical: 8,
                                                            ),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            const Divider(
                                                              color:
                                                                  Colors
                                                                      .black26,
                                                            ),
                                                            const SizedBox(
                                                              height: 10,
                                                            ),
                                                            const Text(
                                                              'Sections',
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 15,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 8,
                                                            ),
                                                            ...List.generate(
                                                              (instructor['sections']
                                                                      as List)
                                                                  .length,
                                                              (j) {
                                                                final section =
                                                                    (instructor['sections']
                                                                        as List)[j];
                                                                final isSectionExpanded =
                                                                    expandedSection ==
                                                                    j;
                                                                return GestureDetector(
                                                                  onTap: () {
                                                                    // Check if this instructor is "dem" - show all dem students for any section
                                                                    if (instructor['name'] ==
                                                                        'dem') {
                                                                      _showDemStudentsModal();
                                                                    } else {
                                                                      setState(
                                                                        () =>
                                                                            expandedSection =
                                                                                isSectionExpanded
                                                                                    ? -1
                                                                                    : j,
                                                                      );
                                                                    }
                                                                  },
                                                                  child: Container(
                                                                    margin:
                                                                        const EdgeInsets.only(
                                                                          bottom:
                                                                              10,
                                                                        ),
                                                                    padding: const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          15,
                                                                      vertical:
                                                                          20,
                                                                    ),
                                                                    decoration: BoxDecoration(
                                                                      color:
                                                                          Colors
                                                                              .white,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            10,
                                                                          ),
                                                                      border: Border(
                                                                        top: BorderSide(
                                                                          color: const Color(
                                                                            0xFF34A853,
                                                                          ).withOpacity(
                                                                            0.2,
                                                                          ),
                                                                        ),
                                                                        bottom: BorderSide(
                                                                          color: const Color(
                                                                            0xFF34A853,
                                                                          ).withOpacity(
                                                                            0.2,
                                                                          ),
                                                                        ),
                                                                        right: BorderSide(
                                                                          color: const Color(
                                                                            0xFF34A853,
                                                                          ).withOpacity(
                                                                            0.2,
                                                                          ),
                                                                        ),
                                                                        left: BorderSide(
                                                                          color: const Color(
                                                                            0xFF34A853,
                                                                          ).withOpacity(
                                                                            0.2,
                                                                          ),
                                                                          width:
                                                                              7,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    child: Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        Row(
                                                                          children: [
                                                                            Container(
                                                                              padding: const EdgeInsets.symmetric(
                                                                                horizontal:
                                                                                    10,
                                                                                vertical:
                                                                                    10,
                                                                              ),
                                                                              decoration: BoxDecoration(
                                                                                borderRadius: BorderRadius.circular(
                                                                                  10,
                                                                                ),
                                                                                color: const Color.fromARGB(
                                                                                  255,
                                                                                  228,
                                                                                  245,
                                                                                  229,
                                                                                ),
                                                                              ),
                                                                              child: Image.asset(
                                                                                'assets/admin_icons/ri_user-line.png',
                                                                                height:
                                                                                    20,
                                                                              ),
                                                                            ),
                                                                            const SizedBox(
                                                                              width:
                                                                                  20,
                                                                            ),
                                                                            Expanded(
                                                                              child: Column(
                                                                                crossAxisAlignment:
                                                                                    CrossAxisAlignment.start,
                                                                                children: [
                                                                                  Text(
                                                                                    section['name'],
                                                                                    style: const TextStyle(
                                                                                      fontWeight:
                                                                                          FontWeight.bold,
                                                                                    ),
                                                                                  ),
                                                                                  const SizedBox(
                                                                                    height:
                                                                                        10,
                                                                                  ),
                                                                                  Row(
                                                                                    children: [
                                                                                      Container(
                                                                                        padding: const EdgeInsets.symmetric(
                                                                                          horizontal:
                                                                                              8,
                                                                                          vertical:
                                                                                              2,
                                                                                        ),
                                                                                        decoration: BoxDecoration(
                                                                                          color:
                                                                                              Colors.white,
                                                                                          borderRadius: BorderRadius.circular(
                                                                                            15,
                                                                                          ),
                                                                                          border: Border.all(
                                                                                            color: Color(
                                                                                              0xFFBDBDBD,
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                        child: Text(
                                                                                          section['code'],
                                                                                          style: const TextStyle(
                                                                                            fontSize:
                                                                                                12,
                                                                                            color:
                                                                                                Colors.black,
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                      const SizedBox(
                                                                                        width:
                                                                                            8,
                                                                                      ),
                                                                                      Image.asset(
                                                                                        'assets/admin_icons/iconamoon_clock-thin.png',
                                                                                        width:
                                                                                            16,
                                                                                      ),
                                                                                      const SizedBox(
                                                                                        width:
                                                                                            2,
                                                                                      ),
                                                                                      Text(
                                                                                        section['schedule'],
                                                                                        style: const TextStyle(
                                                                                          fontSize:
                                                                                              12,
                                                                                          color:
                                                                                              Colors.black54,
                                                                                        ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                            if (section['inactive'] >
                                                                                0) ...[
                                                                              const SizedBox(
                                                                                width:
                                                                                    8,
                                                                              ),
                                                                              Text(
                                                                                '${section['inactive']} inactive',
                                                                                style: const TextStyle(
                                                                                  color:
                                                                                      Colors.black54,
                                                                                  fontSize:
                                                                                      12,
                                                                                ),
                                                                              ),
                                                                            ],
                                                                            const SizedBox(
                                                                              width:
                                                                                  10,
                                                                            ),
                                                                            Image.asset(
                                                                              isSectionExpanded
                                                                                  ? 'assets/admin_icons/gridicons_dropdown (2).png'
                                                                                  : 'assets/admin_icons/gridicons_dropdown.png',
                                                                              width:
                                                                                  22,
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        if (isSectionExpanded &&
                                                                            section['students'] !=
                                                                                null &&
                                                                            section['students'].isNotEmpty)
                                                                          Padding(
                                                                            padding: const EdgeInsets.only(
                                                                              top:
                                                                                  12,
                                                                            ),
                                                                            child: Column(
                                                                              crossAxisAlignment:
                                                                                  CrossAxisAlignment.start,
                                                                              children: [
                                                                                const Divider(
                                                                                  color:
                                                                                      Colors.black26,
                                                                                ),
                                                                                const SizedBox(
                                                                                  height:
                                                                                      10,
                                                                                ),
                                                                                const Text(
                                                                                  'Students',
                                                                                  style: TextStyle(
                                                                                    fontWeight:
                                                                                        FontWeight.bold,
                                                                                    fontSize:
                                                                                        14,
                                                                                  ),
                                                                                ),
                                                                                const SizedBox(
                                                                                  height:
                                                                                      6,
                                                                                ),
                                                                                SizedBox(
                                                                                  height:
                                                                                      220,
                                                                                  child: LayoutBuilder(
                                                                                    builder: (
                                                                                      context,
                                                                                      constraints,
                                                                                    ) {
                                                                                      return ListView.builder(
                                                                                        itemCount:
                                                                                            section['students'].length,
                                                                                        shrinkWrap:
                                                                                            true,
                                                                                        physics:
                                                                                            const ClampingScrollPhysics(),
                                                                                        itemBuilder: (
                                                                                          context,
                                                                                          k,
                                                                                        ) {
                                                                                          final student =
                                                                                              section['students'][k];
                                                                                          return Container(
                                                                                            margin: const EdgeInsets.only(
                                                                                              bottom:
                                                                                                  6,
                                                                                            ),
                                                                                            padding: const EdgeInsets.symmetric(
                                                                                              horizontal:
                                                                                                  10,
                                                                                              vertical:
                                                                                                  8,
                                                                                            ),
                                                                                            decoration: BoxDecoration(
                                                                                              color:
                                                                                                  Colors.white,
                                                                                              borderRadius: BorderRadius.circular(
                                                                                                20,
                                                                                              ),
                                                                                              border: Border(
                                                                                                top: BorderSide(
                                                                                                  color: Color(
                                                                                                    0xFFBDBDBD,
                                                                                                  ).withOpacity(
                                                                                                    .3,
                                                                                                  ),
                                                                                                  width:
                                                                                                      3,
                                                                                                ),
                                                                                                bottom: BorderSide(
                                                                                                  color: Color(
                                                                                                    0xFFBDBDBD,
                                                                                                  ).withOpacity(
                                                                                                    .3,
                                                                                                  ),
                                                                                                  width:
                                                                                                      3,
                                                                                                ),
                                                                                                right: BorderSide(
                                                                                                  color: Color(
                                                                                                    0xFFBDBDBD,
                                                                                                  ).withOpacity(
                                                                                                    .3,
                                                                                                  ),
                                                                                                ),
                                                                                                left: BorderSide(
                                                                                                  color: Color(
                                                                                                    0xFFBDBDBD,
                                                                                                  ).withOpacity(
                                                                                                    .3,
                                                                                                  ),
                                                                                                ),
                                                                                              ),
                                                                                            ),
                                                                                            child: Row(
                                                                                              children: [
                                                                                                if (student['status'] ==
                                                                                                    'active')
                                                                                                  Container(
                                                                                                    height:
                                                                                                        50,
                                                                                                    padding: const EdgeInsets.symmetric(
                                                                                                      horizontal:
                                                                                                          10,
                                                                                                      vertical:
                                                                                                          4,
                                                                                                    ),
                                                                                                    decoration: BoxDecoration(
                                                                                                      shape:
                                                                                                          BoxShape.circle,
                                                                                                      color: const Color(
                                                                                                        0xFF34A853,
                                                                                                      ).withOpacity(
                                                                                                        0.1,
                                                                                                      ),
                                                                                                    ),
                                                                                                    child: Image.asset(
                                                                                                      'assets/admin_icons/solar_user-check-broken.png',
                                                                                                      width:
                                                                                                          18,
                                                                                                    ),
                                                                                                  )
                                                                                                else
                                                                                                  Container(
                                                                                                    height:
                                                                                                        50,
                                                                                                    padding: const EdgeInsets.symmetric(
                                                                                                      horizontal:
                                                                                                          10,
                                                                                                      vertical:
                                                                                                          4,
                                                                                                    ),
                                                                                                    decoration: BoxDecoration(
                                                                                                      shape:
                                                                                                          BoxShape.circle,
                                                                                                      color: const Color(
                                                                                                        0xFF34A853,
                                                                                                      ).withOpacity(
                                                                                                        0.1,
                                                                                                      ),
                                                                                                    ),
                                                                                                    child: Image.asset(
                                                                                                      'assets/admin_icons/solar_user-cross-broken.png',
                                                                                                      width:
                                                                                                          18,
                                                                                                    ),
                                                                                                  ),
                                                                                                const SizedBox(
                                                                                                  width:
                                                                                                      10,
                                                                                                ),
                                                                                                CircleAvatar(
                                                                                                  radius:
                                                                                                      20,
                                                                                                  backgroundColor:
                                                                                                      (student['profileImage']
                                                                                                                      ?.toString() ??
                                                                                                                  '')
                                                                                                              .isNotEmpty
                                                                                                          ? Colors.transparent
                                                                                                          : const Color(
                                                                                                            0xFF34A853,
                                                                                                          ).withOpacity(
                                                                                                            0.1,
                                                                                                          ),
                                                                                                  backgroundImage:
                                                                                                      (student['profileImage']?.toString() ??
                                                                                                                  '')
                                                                                                              .isNotEmpty
                                                                                                          ? NetworkImage(
                                                                                                            student['profileImage'],
                                                                                                          )
                                                                                                          : null,
                                                                                                  child:
                                                                                                      (student['profileImage']?.toString() ??
                                                                                                                  '')
                                                                                                              .isEmpty
                                                                                                          ? Text(
                                                                                                            _getInitials(
                                                                                                              student['name']?.toString() ??
                                                                                                                  student['studentName']?.toString() ??
                                                                                                                  'Unknown',
                                                                                                            ),
                                                                                                            style: const TextStyle(
                                                                                                              color: Color(
                                                                                                                0xFF34A853,
                                                                                                              ),
                                                                                                              fontWeight:
                                                                                                                  FontWeight.bold,
                                                                                                              fontSize:
                                                                                                                  14,
                                                                                                            ),
                                                                                                          )
                                                                                                          : null,
                                                                                                ),
                                                                                                const SizedBox(
                                                                                                  width:
                                                                                                      10,
                                                                                                ),
                                                                                                Column(
                                                                                                  crossAxisAlignment:
                                                                                                      CrossAxisAlignment.start,
                                                                                                  children: [
                                                                                                    Text(
                                                                                                      student['name'] ??
                                                                                                          student['studentName'] ??
                                                                                                          'Unknown',
                                                                                                      style: const TextStyle(
                                                                                                        fontWeight:
                                                                                                            FontWeight.w500,
                                                                                                      ),
                                                                                                    ),
                                                                                                    Text(
                                                                                                      student['email'],
                                                                                                      style: const TextStyle(
                                                                                                        fontSize:
                                                                                                            12,
                                                                                                        color:
                                                                                                            Colors.black54,
                                                                                                      ),
                                                                                                    ),
                                                                                                    const SizedBox(
                                                                                                      height:
                                                                                                          4,
                                                                                                    ),
                                                                                                    Text(
                                                                                                      student['idNumber'] !=
                                                                                                                  null &&
                                                                                                              (student['idNumber']
                                                                                                                      as String)
                                                                                                                  .isNotEmpty
                                                                                                          ? 'ID Number: ${student['idNumber']}'
                                                                                                          : 'ID Number: N/A',
                                                                                                      style: const TextStyle(
                                                                                                        fontSize:
                                                                                                            11,
                                                                                                        color:
                                                                                                            Colors.grey,
                                                                                                        fontWeight:
                                                                                                            FontWeight.w500,
                                                                                                      ),
                                                                                                    ),
                                                                                                  ],
                                                                                                ),
                                                                                                const SizedBox(
                                                                                                  width:
                                                                                                      20,
                                                                                                ),
                                                                                                Container(
                                                                                                  padding: const EdgeInsets.symmetric(
                                                                                                    horizontal:
                                                                                                        10,
                                                                                                    vertical:
                                                                                                        2,
                                                                                                  ),
                                                                                                  decoration: BoxDecoration(
                                                                                                    color:
                                                                                                        Colors.white,
                                                                                                    border: Border.all(
                                                                                                      color: Color(
                                                                                                        0xFFBDBDBD,
                                                                                                      ),
                                                                                                    ),
                                                                                                    borderRadius: BorderRadius.circular(
                                                                                                      20,
                                                                                                    ),
                                                                                                  ),
                                                                                                  child: Text(
                                                                                                    student['program'] ??
                                                                                                        section['program'] ??
                                                                                                        'N/A',
                                                                                                    style: const TextStyle(
                                                                                                      fontSize:
                                                                                                          10,
                                                                                                      color:
                                                                                                          Colors.black,
                                                                                                      fontWeight:
                                                                                                          FontWeight.bold,
                                                                                                    ),
                                                                                                  ),
                                                                                                ),
                                                                                                const Spacer(),
                                                                                              ],
                                                                                            ),
                                                                                          );
                                                                                        },
                                                                                      );
                                                                                    },
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              );
                                            }),
                                          ],
                                        ),
                                      ),
                            ),
                          ],
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(
    String title,
    String value,
    String subtitle,
    String iconPath, {
    bool highlight = false,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Image.asset(
                  iconPath,
                  width: 26,
                  color: highlight ? const Color(0xFF34A853) : null,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: const Color(0xFF34A853),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  /// Format schedule from schedules array or fallback to old format
  String _formatSchedule(Map<String, dynamic> classData) {
    // Handle new format: schedules array
    if (classData.containsKey('schedules') && classData['schedules'] is List) {
      final schedules = List<Map<String, dynamic>>.from(classData['schedules']);
      if (schedules.isNotEmpty) {
        // Check if all schedules have the same time
        final allSameTime = schedules.every(
          (s) =>
              s['startTime'] == schedules[0]['startTime'] &&
              s['endTime'] == schedules[0]['endTime'],
        );

        if (allSameTime && schedules.length > 1) {
          // Show as "Mon/Wed 9:00 AM - 10:30 AM"
          final days = schedules
              .map((s) => _getDayAbbreviation(s['day']?.toString() ?? ''))
              .join('/');
          return '$days ${schedules[0]['startTime']} - ${schedules[0]['endTime']}';
        } else {
          // Show all schedules separated by commas
          final scheduleStrings =
              schedules.map((schedule) {
                final dayAbbr = _getDayAbbreviation(
                  schedule['day']?.toString() ?? '',
                );
                return '$dayAbbr ${schedule['startTime']} - ${schedule['endTime']}';
              }).toList();
          return scheduleStrings.join(', ');
        }
      }
    }

    // Fallback to old format for backward compatibility
    if (classData.containsKey('day') &&
        classData.containsKey('startTime') &&
        classData.containsKey('endTime')) {
      final dayAbbr = _getDayAbbreviation(classData['day']?.toString() ?? '');
      return '$dayAbbr ${classData['startTime']} - ${classData['endTime']}';
    }

    // If no schedule data found
    return 'TBA';
  }

  /// Get day abbreviation
  String _getDayAbbreviation(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
        return 'Mon';
      case 'tuesday':
        return 'Tue';
      case 'wednesday':
        return 'Wed';
      case 'thursday':
        return 'Thu';
      case 'friday':
        return 'Fri';
      case 'saturday':
        return 'Sat';
      case 'sunday':
        return 'Sun';
      default:
        return day;
    }
  }
}

// Instructor Profile View Widget
class InstructorProfileView extends StatelessWidget {
  final Map<String, dynamic> instructor;

  const InstructorProfileView({super.key, required this.instructor});

  String getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = getInitials(instructor['name'] ?? '');
    final hasImage = (instructor['profileUrl']?.toString() ?? '').isNotEmpty;
    final profileImageUrl = instructor['profileUrl']?.toString() ?? '';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Instructor Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                tooltip: 'Close',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Profile Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
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
                // Profile Image
                CircleAvatar(
                  radius: 60,
                  backgroundColor:
                      hasImage
                          ? Colors.transparent
                          : const Color(0xFF34A853).withOpacity(0.1),
                  backgroundImage:
                      hasImage ? NetworkImage(profileImageUrl) : null,
                  child:
                      !hasImage
                          ? Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF34A853),
                            ),
                          )
                          : null,
                ),
                const SizedBox(height: 24),

                // Name
                Text(
                  instructor['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34A853).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Instructor',
                    style: TextStyle(
                      color: Color(0xFF34A853),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Contact Information
                Column(
                  children: [
                    _buildInfoRow(
                      Icons.email_outlined,
                      'Email',
                      instructor['email'] ?? 'N/A',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.phone_outlined,
                      'Phone',
                      instructor['phone']?.toString().isEmpty ?? true
                          ? 'Not provided'
                          : instructor['phone'],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.business_outlined,
                      'Department',
                      instructor['department']?.toString().isEmpty ?? true
                          ? 'Not specified'
                          : instructor['department'],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFF34A853),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'About',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  (instructor['about']?.toString().trim().isNotEmpty ?? false)
                      ? instructor['about'].toString()
                      : 'No information provided yet.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF34A853).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF34A853), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
