import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/admin/admin_sidebar.dart';
import '../shared/admin/admin_navigation_constants.dart';
import '../shared/widgets/safe_asset_image.dart';

class AdminClassManagementScreen extends StatefulWidget {
  const AdminClassManagementScreen({super.key});

  @override
  State<AdminClassManagementScreen> createState() =>
      _AdminClassManagementScreenState();
}

class _AdminClassManagementScreenState extends State<AdminClassManagementScreen>
    with AutomaticKeepAliveClientMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AdminNavigationItem _selectedItem = AdminNavigationItem.manageClasses;

  // Data storage
  final List<Map<String, dynamic>> _allClasses = [];
  List<Map<String, dynamic>> _instructors = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedInstructorFilter = 'All';
  final Map<String, List<Map<String, dynamic>>> _classStudents = {};
  final Map<String, List<Map<String, dynamic>>> _instructorClasses =
      {}; // Group classes by instructor
  final Map<String, Map<String, int>> _instructorStats =
      {}; // Cache instructor stats

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
    // Defer loading to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

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

  Future<void> _loadData() async {
    if (!mounted) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      if (!mounted) return;
      // Load all instructors
      await _loadInstructors();

      if (!mounted) return;
      // Load all classes from all instructors
      await _loadAllClasses();

      if (!mounted) return;
      // Load students for each class
      await _loadAllClassStudents();

      if (!mounted) return;
      // Load instructor stats
      await _loadInstructorStats();
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to load data: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadInstructors() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('instructors').get();

      List<Map<String, dynamic>> instructorsList = [];

      for (var doc in snapshot.docs) {
        if (!mounted) return;

        final data = doc.data() as Map<String, dynamic>;
        final instructorName = data['name']?.toString().trim() ?? '';
        final instructorStatus = data['status']?.toString() ?? 'Pending';

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

        // Load assigned departments from assignments array
        Set<String> departmentNames = {};
        final assignments = data['assignments'];
        if (assignments != null &&
            assignments is List &&
            assignments.isNotEmpty) {
          for (var assignmentData in assignments) {
            if (!mounted) return;

            if (assignmentData is Map) {
              final departmentId = assignmentData['departmentId']?.toString();

              if (departmentId != null) {
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
                        'Unknown';

                    departmentNames.add(deptName);
                  }
                } catch (e) {
                  print('Error fetching department $departmentId: $e');
                }
              }
            }
          }
        }

        // Fallback to instructor's department field if no assignments
        String departmentName =
            departmentNames.isNotEmpty
                ? departmentNames.join(', ')
                : (data['department']?.toString() ?? 'N/A');

        instructorsList.add({
          'id': doc.id,
          'name': instructorName,
          'email': data['email'] ?? '',
          'department': departmentName,
          'phone': data['phone'] ?? '',
          'profileUrl': data['profileUrl'] ?? data['profileImageUrl'] ?? '',
          'status': instructorStatus,
        });
      }

      if (mounted) {
        _instructors = instructorsList;
      }
    } catch (e) {
      print('Error loading instructors: $e');
    }
  }

  Future<void> _loadAllClasses() async {
    try {
      _allClasses.clear();
      _instructorClasses.clear();

      for (var instructor in _instructors) {
        if (!mounted) return; // Check if widget is still mounted

        // Skip if instructor data is invalid
        if (instructor['name']?.toString().trim().isEmpty ?? true) {
          continue;
        }

        final classesSnapshot =
            await _firestore
                .collection('instructors')
                .doc(instructor['id'])
                .collection('classes')
                .get();

        List<Map<String, dynamic>> instructorClassList = [];

        for (var classDoc in classesSnapshot.docs) {
          final classData = classDoc.data();
          final classInfo = {
            'id': classDoc.id,
            'instructorId': instructor['id'],
            'instructorName': instructor['name'],
            'instructorEmail': instructor['email'],
            'section': classData['section'] ?? '',
            'course': classData['course'] ?? '',
            'room': classData['room'] ?? '',
            'day': classData['day'] ?? '',
            'startTime': classData['startTime'] ?? '',
            'endTime': classData['endTime'] ?? '',
            'sectionId': classData['sectionId'] ?? '',
            'createdAt': classData['createdAt'],
          };

          _allClasses.add(classInfo);
          instructorClassList.add(classInfo);
        }

        // Sort classes by creation date (newest first)
        instructorClassList.sort((a, b) {
          final aTime = a['createdAt'] as Timestamp?;
          final bTime = b['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        _instructorClasses[instructor['id']] = instructorClassList;
      }
    } catch (e) {
      print('Error loading classes: $e');
    }
  }

  Future<void> _loadAllClassStudents() async {
    try {
      _classStudents.clear();

      for (var classData in _allClasses) {
        if (!mounted) return; // Check if widget is still mounted

        final studentsSnapshot =
            await _firestore
                .collection('instructors')
                .doc(classData['instructorId'])
                .collection('classes')
                .doc(classData['id'])
                .collection('students')
                .get();

        List<Map<String, dynamic>> students = [];
        for (var doc in studentsSnapshot.docs) {
          if (!mounted) return;

          final data = doc.data();

          // Fetch idNumber and profileImage from users collection using doc.id as user document ID
          String idNumber = '';
          String profileImage = '';
          try {
            final userDoc =
                await _firestore.collection('users').doc(doc.id).get();
            if (userDoc.exists) {
              final userData = userDoc.data() ?? {};
              idNumber = userData['idNumber']?.toString() ?? '';
              profileImage =
                  userData['profileImage']?.toString() ??
                  userData['profileImageUrl']?.toString() ??
                  userData['profileUrl']?.toString() ??
                  '';
            } else {
              // Fallback: try matching by studentId
              final studentId = data['studentId']?.toString() ?? '';
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
                }
              }
            }
          } catch (e) {
            print('Error fetching user data for student ${doc.id}: $e');
          }

          students.add({
            'id': doc.id,
            'studentId': data['studentId'] ?? '',
            'idNumber': idNumber,
            'profileImage': profileImage,
            'studentName': data['studentName'] ?? 'Unknown Student',
            'enrollmentStatus': data['enrollmentStatus'] ?? 'pending',
            'enrolledAt': data['enrolledAt'],
            'isActive': data['isActive'] ?? true,
          });
        }

        _classStudents[classData['id']] = students;
      }
    } catch (e) {
      print('Error loading class students: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredInstructors {
    var filtered = _instructors;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered.where((instructor) {
            return instructor['name'].toString().toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                instructor['email'].toString().toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                instructor['department'].toString().toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );
          }).toList();
    }

    // Filter by instructor name
    if (_selectedInstructorFilter != 'All') {
      filtered =
          filtered.where((instructor) {
            return instructor['name'] == _selectedInstructorFilter;
          }).toList();
    }

    return filtered;
  }

  Future<void> _loadInstructorStats() async {
    try {
      _instructorStats.clear();

      for (var instructor in _instructors) {
        if (!mounted) return; // Check if widget is still mounted

        final instructorId = instructor['id'];
        final stats = await _getInstructorStatsAsync(instructorId);
        if (mounted) {
          _instructorStats[instructorId] = stats;
        }
      }
    } catch (e) {
      print('Error loading instructor stats: $e');
    }
  }

  Future<Map<String, int>> _getInstructorStatsAsync(String instructorId) async {
    try {
      // Get classes count
      final classesSnapshot =
          await _firestore
              .collection('instructors')
              .doc(instructorId)
              .collection('classes')
              .get();

      // Load all students from the flat collection (same as admin_dashboard)
      final studentsSnapshot =
          await _firestore
              .collection('instructors')
              .doc(instructorId)
              .collection('students')
              .get();

      int activeStudents = 0;
      int inactiveStudents = 0;

      for (var studentDoc in studentsSnapshot.docs) {
        final studentData = studentDoc.data();
        final isActive = studentData['isActive'] == true;
        if (isActive) {
          activeStudents++;
        } else {
          inactiveStudents++;
        }
      }

      return {
        'totalClasses': classesSnapshot.docs.length,
        'totalStudents': studentsSnapshot.docs.length,
        'activeStudents': activeStudents,
        'inactiveStudents': inactiveStudents,
      };
    } catch (e) {
      print('Error getting instructor stats: $e');
      return {
        'totalClasses': 0,
        'totalStudents': 0,
        'activeStudents': 0,
        'inactiveStudents': 0,
      };
    }
  }

  Map<String, int> _getInstructorStats(String instructorId) {
    // Return cached stats if available
    if (_instructorStats.containsKey(instructorId)) {
      return _instructorStats[instructorId]!;
    }

    // Fallback to old method if stats not loaded yet
    final classes = _instructorClasses[instructorId] ?? [];
    int totalStudents = 0;
    int pendingStudents = 0;
    int approvedStudents = 0;
    int rejectedStudents = 0;

    for (var classData in classes) {
      final stats = _getEnrollmentStats(classData['id']);
      totalStudents += stats['total']!;
      pendingStudents += stats['pending']!;
      approvedStudents += stats['approved']!;
      rejectedStudents += stats['rejected']!;
    }

    return {
      'totalClasses': classes.length,
      'totalStudents': totalStudents,
      'pendingStudents': pendingStudents,
      'approvedStudents': approvedStudents,
      'rejectedStudents': rejectedStudents,
    };
  }

  Map<String, int> _getEnrollmentStats(String classId) {
    final students = _classStudents[classId] ?? [];
    final stats = {
      'total': students.length,
      'pending': 0,
      'approved': 0,
      'rejected': 0,
    };

    for (var student in students) {
      final status = student['enrollmentStatus'] ?? 'pending';
      if (stats.containsKey(status)) {
        stats[status] = stats[status]! + 1;
      }
    }

    return stats;
  }

  void _showInstructorDetails(Map<String, dynamic> instructor) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.9,
            padding: const EdgeInsets.all(24),
            child: InstructorDetailView(
              instructor: instructor,
              firestore: _firestore,
            ),
          ),
        );
      },
    );
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
                                        'assets/admin_icons/lucide_users-round.png',
                                    width: 28,
                                    height: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Class Management',
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
                                'View and manage all classes and students',
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
                                    'assets/admin_icons/lucide_users-round.png',
                                width: 32,
                                height: 32,
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Class Management',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      'View and manage all classes and students',
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
                                      'Class & Student Management',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'View all classes, instructors, and manage student enrollments',
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

                        // Search and Filter Section
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText:
                                      'Search instructors, classes, or rooms...',
                                  prefixIcon: const Icon(Icons.search),
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
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButton<String>(
                                value: _selectedInstructorFilter,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedInstructorFilter = value!;
                                  });
                                },
                                items:
                                    [
                                      'All',
                                      ..._instructors.map((i) => i['name']),
                                    ].map((instructor) {
                                      return DropdownMenuItem<String>(
                                        value: instructor,
                                        child: Text(instructor),
                                      );
                                    }).toList(),
                                underline: const SizedBox(),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Instructors List
                        if (_isLoading)
                          const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF34A853),
                              ),
                            ),
                          )
                        else if (_filteredInstructors.isEmpty)
                          Center(
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
                                    Icons.person_outline,
                                    size: 40,
                                    color: Color(0xFF34A853),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'No instructors found',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Instructors will appear here when they register',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _filteredInstructors.length,
                            itemBuilder: (context, index) {
                              final instructor = _filteredInstructors[index];
                              final instructorId = instructor['id'];
                              final instructorStats = _getInstructorStats(
                                instructorId,
                              );

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
                                    // Instructor Header
                                    InkWell(
                                      onTap:
                                          () => _showInstructorDetails(
                                            instructor,
                                          ),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 25,
                                              backgroundColor:
                                                  (instructor['profileUrl']
                                                                  ?.toString() ??
                                                              '')
                                                          .isEmpty
                                                      ? const Color(
                                                        0xFF34A853,
                                                      ).withOpacity(0.1)
                                                      : Colors.transparent,
                                              backgroundImage:
                                                  (instructor['profileUrl']
                                                                  ?.toString() ??
                                                              '')
                                                          .isNotEmpty
                                                      ? NetworkImage(
                                                        instructor['profileUrl'],
                                                      )
                                                      : null,
                                              child:
                                                  (instructor['profileUrl']
                                                                  ?.toString() ??
                                                              '')
                                                          .isEmpty
                                                      ? Text(
                                                        (instructor['name']
                                                                    ?.toString()
                                                                    .isNotEmpty ??
                                                                false)
                                                            ? instructor['name'][0]
                                                                .toUpperCase()
                                                            : '?',
                                                        style: const TextStyle(
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Color(
                                                            0xFF34A853,
                                                          ),
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
                                                    instructor['name']
                                                            ?.toString() ??
                                                        'Unknown',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    instructor['email'],
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Department: ${instructor['department']}',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Row(
                                                  children: [
                                                    _buildMiniStatCard(
                                                      'Classes',
                                                      instructorStats['totalClasses'] ??
                                                          0,
                                                      Colors.blue,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    _buildMiniStatCard(
                                                      'Students',
                                                      instructorStats['totalStudents'] ??
                                                          0,
                                                      Colors.green,
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    _buildMiniStatCard(
                                                      'Active',
                                                      instructorStats['activeStudents'] ??
                                                          0,
                                                      Colors.green,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    _buildMiniStatCard(
                                                      'Inactive',
                                                      instructorStats['inactiveStudents'] ??
                                                          0,
                                                      Colors.grey,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 16),
                                            const Icon(
                                              Icons.arrow_forward_ios,
                                              color: Colors.grey,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Classes List (Expandable) - Removed since we show instructor details instead
                                  ],
                                ),
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

  Widget _buildMiniStatCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class InstructorDetailView extends StatefulWidget {
  final Map<String, dynamic> instructor;
  final FirebaseFirestore firestore;

  const InstructorDetailView({
    super.key,
    required this.instructor,
    required this.firestore,
  });

  @override
  State<InstructorDetailView> createState() => _InstructorDetailViewState();
}

class _InstructorDetailViewState extends State<InstructorDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _assignments = [];
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _quizzes = [];
  List<Map<String, dynamic>> _pits = [];
  List<Map<String, dynamic>> _materials = [];
  final List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  int _expandedSectionIndex = -1;
  Map<String, dynamic> _instructorData = {};

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    // Defer loading to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadInstructorData();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInstructorData() async {
    if (!mounted) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      if (!mounted) return;
      final instructorId = widget.instructor['id'];

      // Load full instructor data including 'about' field
      if (!mounted) return;
      final instructorDoc =
          await widget.firestore
              .collection('instructors')
              .doc(instructorId)
              .get();

      if (instructorDoc.exists && mounted) {
        _instructorData = instructorDoc.data() ?? {};
        // Merge with widget.instructor to ensure we have all data
        _instructorData = {...widget.instructor, ..._instructorData};
      } else {
        _instructorData = widget.instructor;
      }

      if (!mounted) return;
      // Load assignments
      await _loadAssignments(instructorId);

      if (!mounted) return;
      // Load activities
      await _loadActivities(instructorId);

      if (!mounted) return;
      // Load quizzes
      await _loadQuizzes(instructorId);

      if (!mounted) return;
      // Load PITs
      await _loadPITs(instructorId);

      if (!mounted) return;
      // Load materials (if any)
      await _loadMaterials(instructorId);

      if (!mounted) return;
      // Load students from all classes
      await _loadStudents(instructorId);
    } catch (e) {
      print('Error loading instructor data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAssignments(String instructorId) async {
    try {
      final snapshot =
          await widget.firestore
              .collection('instructors')
              .doc(instructorId)
              .collection('assignments')
              .orderBy('createdAt', descending: true)
              .get();

      _assignments =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'title': data['title'] ?? 'No Title',
              'instruction': data['instruction'] ?? '',
              'points': data['points']?.toString() ?? '0',
              'dueDate': _formatDate(data['dueDate']),
              'topic': data['topic'] ?? 'No Topic',
              'selectedClasses': data['selectedClasses'] ?? [],
              'status': data['status'] ?? 'active',
              'createdAt': _formatDate(data['createdAt']),
            };
          }).toList();
    } catch (e) {
      print('Error loading assignments: $e');
    }
  }

  Future<void> _loadActivities(String instructorId) async {
    try {
      final snapshot =
          await widget.firestore
              .collection('instructors')
              .doc(instructorId)
              .collection('activities')
              .orderBy('createdAt', descending: true)
              .get();

      _activities =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'title': data['title'] ?? 'No Title',
              'instruction': data['instruction'] ?? '',
              'points': data['points']?.toString() ?? '0',
              'dueDate': _formatDate(data['dueDate']),
              'topic': data['topic'] ?? 'No Topic',
              'selectedClasses': data['selectedClasses'] ?? [],
              'status': data['status'] ?? 'active',
              'createdAt': _formatDate(data['createdAt']),
            };
          }).toList();
    } catch (e) {
      print('Error loading activities: $e');
    }
  }

  Future<void> _loadQuizzes(String instructorId) async {
    try {
      final snapshot =
          await widget.firestore
              .collection('instructors')
              .doc(instructorId)
              .collection('quizzes')
              .orderBy('createdAt', descending: true)
              .get();

      _quizzes =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'title': data['title'] ?? 'No Title',
              'instruction': data['instruction'] ?? '',
              'points': data['points']?.toString() ?? '0',
              'dueDate': _formatDate(data['dueDate']),
              'topic': data['topic'] ?? 'No Topic',
              'selectedClasses': data['selectedClasses'] ?? [],
              'status': data['status'] ?? 'active',
              'createdAt': _formatDate(data['createdAt']),
            };
          }).toList();
    } catch (e) {
      print('Error loading quizzes: $e');
    }
  }

  Future<void> _loadPITs(String instructorId) async {
    try {
      final snapshot =
          await widget.firestore
              .collection('instructors')
              .doc(instructorId)
              .collection('pits')
              .orderBy('createdAt', descending: true)
              .get();

      _pits =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'title': data['title'] ?? 'No Title',
              'instruction': data['instruction'] ?? '',
              'points': data['points']?.toString() ?? '0',
              'dueDate': _formatDate(data['dueDate']),
              'topic': data['topic'] ?? 'No Topic',
              'selectedClasses': data['selectedClasses'] ?? [],
              'status': data['status'] ?? 'active',
              'createdAt': _formatDate(data['createdAt']),
            };
          }).toList();
    } catch (e) {
      print('Error loading PITs: $e');
    }
  }

  Future<void> _loadMaterials(String instructorId) async {
    try {
      final snapshot =
          await widget.firestore
              .collection('instructors')
              .doc(instructorId)
              .collection('materials')
              .orderBy('createdAt', descending: true)
              .get();

      _materials =
          snapshot.docs.map((doc) {
            final data = doc.data();

            // Extract attachments (files/images)
            final attachments = data['attachments'] as List? ?? [];
            final attachmentsList =
                attachments
                    .map((attachment) {
                      if (attachment is Map) {
                        return {
                          'name': attachment['name'] ?? 'Unknown',
                          'url': attachment['url'] ?? '',
                          'type': attachment['type'] ?? 'file',
                          'size': attachment['size'] ?? 0,
                          'publicId': attachment['publicId'] ?? '',
                        };
                      }
                      return null;
                    })
                    .whereType<Map<String, dynamic>>()
                    .toList();

            return {
              'id': doc.id,
              'title': data['title'] ?? 'No Title',
              'description': data['description'] ?? '',
              'instruction':
                  data['description'] ??
                  '', // For consistency with other content types
              'points': '0', // Materials typically don't have points
              'type': data['type'] ?? 'Material',
              'selectedClasses': data['selectedClasses'] ?? [],
              'status': data['status'] ?? 'active',
              'attachments': attachmentsList,
              'createdAt': _formatDate(data['createdAt']),
              'updatedAt': _formatDate(data['updatedAt']),
            };
          }).toList();
    } catch (e) {
      print('❌ Error loading materials: $e');
      _materials = [];
    }
  }

  Future<void> _loadStudents(String instructorId) async {
    if (!mounted) return;

    try {
      // Get all classes for this instructor
      final classesSnapshot =
          await widget.firestore
              .collection('instructors')
              .doc(instructorId)
              .collection('classes')
              .get();

      if (!mounted) return;

      // Load all students from the flat collection (same as admin_dashboard)
      final studentsSnapshot =
          await widget.firestore
              .collection('instructors')
              .doc(instructorId)
              .collection('students')
              .get();

      if (!mounted) return;

      // Group students by their selectedSectionCode
      Map<String, List<Map<String, dynamic>>> studentsBySection = {};
      for (var studentDoc in studentsSnapshot.docs) {
        if (!mounted) return;
        final studentData = studentDoc.data();
        final sectionCode =
            studentData['selectedSectionCode']?.toString().trim() ?? 'Unknown';

        if (!studentsBySection.containsKey(sectionCode)) {
          studentsBySection[sectionCode] = [];
        }

        // Fetch idNumber and profileImage from users collection
        String idNumber = '';
        String profileImage = '';
        try {
          final userDoc =
              await widget.firestore
                  .collection('users')
                  .doc(studentDoc.id)
                  .get();
          if (userDoc.exists) {
            final userData = userDoc.data() ?? {};
            idNumber = userData['idNumber']?.toString() ?? '';
            profileImage =
                userData['profileImage']?.toString() ??
                userData['profileImageUrl']?.toString() ??
                userData['profileUrl']?.toString() ??
                '';
          } else {
            // Fallback: try matching by studentId
            final studentId =
                studentData['studentId']?.toString() ?? studentDoc.id;
            if (studentId.isNotEmpty) {
              final userQuery =
                  await widget.firestore
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
              }
            }
          }
        } catch (e) {
          print('Error fetching user data for student ${studentDoc.id}: $e');
        }

        studentsBySection[sectionCode]!.add({
          'id': studentDoc.id,
          'studentId': studentData['studentId'] ?? studentDoc.id,
          'idNumber': idNumber,
          'profileImage': profileImage,
          'studentName':
              studentData['studentName'] ??
              studentData['name'] ??
              studentData['displayName'] ??
              'Unknown',
          'email': studentData['email'] ?? '',
          'status': studentData['isActive'] == true ? 'active' : 'inactive',
        });
      }

      if (!mounted) return;

      _students.clear();

      // Match students to classes by section name
      for (var classDoc in classesSnapshot.docs) {
        if (!mounted) return;

        final classData = classDoc.data();
        final sectionName = classData['section'] ?? 'Unknown Section';

        // Get students for this section
        final students = studentsBySection[sectionName] ?? [];
        final activeStudents =
            students.where((s) => s['status'] == 'active').length;

        // Add section as a group including student list and count
        if (mounted) {
          _students.add({
            'id': classDoc.id,
            'type': 'section',
            'sectionName': sectionName,
            'sectionCode': sectionName,
            'studentCount': students.length,
            'activeCount': activeStudents,
            'students': students,
            'classId': classDoc.id,
            'instructorId': instructorId,
          });
        }
      }
    } catch (e) {
      print('Error loading students: $e');
    }
  }

  String? _formatDate(dynamic date) {
    if (date == null) return null;
    if (date is Timestamp) {
      return '${date.toDate().day}/${date.toDate().month}/${date.toDate().year}';
    }
    return date.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor:
                  (widget.instructor['profileUrl']?.toString() ?? '').isEmpty
                      ? const Color(0xFF34A853).withOpacity(0.1)
                      : Colors.transparent,
              backgroundImage:
                  (widget.instructor['profileUrl']?.toString() ?? '').isNotEmpty
                      ? NetworkImage(widget.instructor['profileUrl'])
                      : null,
              child:
                  (widget.instructor['profileUrl']?.toString() ?? '').isEmpty
                      ? Text(
                        widget.instructor['name'][0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF34A853),
                        ),
                      )
                      : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.instructor['name'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    widget.instructor['email'],
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  Text(
                    'Department: ${widget.instructor['department']}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
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

        // Tabs
        TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF34A853),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF34A853),
          isScrollable: true,
          tabs: const [
            Tab(text: 'Profile', icon: Icon(Icons.person)),
            Tab(text: 'Activities', icon: Icon(Icons.assignment)),
            Tab(text: 'Assignments', icon: Icon(Icons.assignment_turned_in)),
            Tab(text: 'Materials', icon: Icon(Icons.folder)),
            Tab(text: 'Quizzes', icon: Icon(Icons.quiz)),
            Tab(text: 'PIT', icon: Icon(Icons.psychology)),
            Tab(text: 'Section', icon: Icon(Icons.people)),
          ],
        ),

        const SizedBox(height: 16),

        // Tab Content
        Expanded(
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildProfileView(),
                      _buildContentList(_activities, 'activities'),
                      _buildContentList(_assignments, 'assignments'),
                      _buildContentList(_materials, 'materials'),
                      _buildContentList(_quizzes, 'quizzes'),
                      _buildContentList(_pits, 'pits'),
                      _buildStudentsList(),
                    ],
                  ),
        ),
      ],
    );
  }

  Widget _buildProfileView() {
    // Get initials from name
    String getInitials(String name) {
      if (name.isEmpty) return '?';
      final parts = name.trim().split(' ');
      if (parts.length == 1) {
        return parts[0].substring(0, 1).toUpperCase();
      }
      return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
          .toUpperCase();
    }

    final initials = getInitials(widget.instructor['name'] ?? '');
    final hasImage =
        (widget.instructor['profileUrl']?.toString() ?? '').isNotEmpty;
    final profileImageUrl = widget.instructor['profileUrl']?.toString() ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  widget.instructor['name'] ?? 'Unknown',
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
                      (_instructorData.isNotEmpty
                              ? _instructorData['email']
                              : widget.instructor['email']) ??
                          'N/A',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.phone_outlined,
                      'Phone',
                      ((_instructorData.isNotEmpty
                                      ? _instructorData['phone']
                                      : widget.instructor['phone'])
                                  ?.toString()
                                  .isEmpty ??
                              true)
                          ? 'Not provided'
                          : (_instructorData.isNotEmpty
                              ? _instructorData['phone']
                              : widget.instructor['phone']),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.business_outlined,
                      'Department',
                      ((_instructorData.isNotEmpty
                                      ? _instructorData['department']
                                      : widget.instructor['department'])
                                  ?.toString()
                                  .isEmpty ??
                              true)
                          ? 'Not specified'
                          : (_instructorData.isNotEmpty
                              ? _instructorData['department']
                              : widget.instructor['department']),
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
                  (_instructorData['about']?.toString().isNotEmpty ?? false)
                      ? _instructorData['about']
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

  Widget _buildContentList(List<Map<String, dynamic>> items, String type) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getIconForType(type), size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No $type found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This instructor hasn\'t created any $type yet',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getIconForType(type),
                    color: const Color(0xFF34A853),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  if (type != 'materials')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34A853).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${item['points']} pts',
                        style: const TextStyle(
                          color: Color(0xFF34A853),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (type == 'materials' && item['attachments'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.attach_file,
                            size: 14,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(item['attachments'] as List).length}',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item['instruction'],
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // Show attachments for materials
              if (type == 'materials' && item['attachments'] != null) ...[
                const SizedBox(height: 12),
                const Text(
                  'Attachments:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      (item['attachments'] as List).map((attachment) {
                        final fileName = attachment['name'] ?? 'File';
                        final fileType = attachment['type'] ?? 'file';
                        final fileSize = attachment['size'] ?? 0;

                        // Format file size
                        String formattedSize =
                            fileSize > 0
                                ? '${(fileSize / 1024).toStringAsFixed(1)} KB'
                                : '';

                        // Choose icon based on file type
                        IconData fileIcon;
                        Color fileColor;

                        if (fileType.toLowerCase().contains('image') ||
                            fileType.toLowerCase().contains('png') ||
                            fileType.toLowerCase().contains('jpg') ||
                            fileType.toLowerCase().contains('jpeg')) {
                          fileIcon = Icons.image;
                          fileColor = Colors.purple;
                        } else if (fileType.toLowerCase().contains('pdf')) {
                          fileIcon = Icons.picture_as_pdf;
                          fileColor = Colors.red;
                        } else if (fileType.toLowerCase().contains('doc') ||
                            fileType.toLowerCase().contains('docx')) {
                          fileIcon = Icons.description;
                          fileColor = Colors.blue;
                        } else if (fileType.toLowerCase().contains('xls') ||
                            fileType.toLowerCase().contains('xlsx')) {
                          fileIcon = Icons.table_chart;
                          fileColor = Colors.green;
                        } else {
                          fileIcon = Icons.attach_file;
                          fileColor = Colors.grey;
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: fileColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: fileColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(fileIcon, size: 16, color: fileColor),
                              const SizedBox(width: 6),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fileName.length > 20
                                        ? '${fileName.substring(0, 20)}...'
                                        : fileName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: fileColor,
                                    ),
                                  ),
                                  if (formattedSize.isNotEmpty)
                                    Text(
                                      formattedSize,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  if (type != 'materials')
                    Text(
                      'Due: ${item['dueDate'] ?? 'No due date'}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  if (type == 'materials')
                    Text(
                      'Type: ${item['type'] ?? 'Material'}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  const Spacer(),
                  Text(
                    'Created: ${item['createdAt'] ?? 'Unknown'}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStudentsList() {
    if (_students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No sections found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This instructor doesn\'t have any sections yet',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final section = _students[index];
        final studentCount = section['studentCount'] ?? 0;

        return Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _expandedSectionIndex =
                      _expandedSectionIndex == index ? -1 : index;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF34A853).withOpacity(0.1),
                      child: const Icon(
                        Icons.school,
                        color: Color(0xFF34A853),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Section',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Class: ${section['sectionName']}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
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
                        color: const Color(0xFF34A853).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF34A853).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        studentCount == 1
                            ? '1 student'
                            : '$studentCount students',
                        style: const TextStyle(
                          color: Color(0xFF34A853),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
            if (_expandedSectionIndex == index)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    if ((section['students'] as List?)?.isEmpty ?? true)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'No students found for this section',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: (section['students'] as List).length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, sIdx) {
                          final s =
                              (section['students'] as List)[sIdx]
                                  as Map<String, dynamic>;
                          final studentName =
                              s['studentName']?.toString() ?? 'Unknown';
                          final profileImage =
                              s['profileImage']?.toString() ?? '';
                          final hasImage = profileImage.isNotEmpty;

                          return ListTile(
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  hasImage
                                      ? Colors.transparent
                                      : const Color(
                                        0xFF34A853,
                                      ).withOpacity(0.1),
                              backgroundImage:
                                  hasImage ? NetworkImage(profileImage) : null,
                              child:
                                  hasImage
                                      ? null
                                      : Text(
                                        _getInitials(studentName),
                                        style: const TextStyle(
                                          color: Color(0xFF34A853),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                            ),
                            title: Text(s['studentName'] ?? 'Unknown'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s['email'] ?? ''),
                                if (s['idNumber'] != null &&
                                    (s['idNumber'] as String).isNotEmpty)
                                  Text(
                                    'ID Number: ${s['idNumber']}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  // Section details are now shown inline; legacy dialog method removed.

  IconData _getIconForType(String type) {
    switch (type) {
      case 'activities':
        return Icons.assignment;
      case 'assignments':
        return Icons.assignment_turned_in;
      case 'materials':
        return Icons.folder;
      case 'quizzes':
        return Icons.quiz;
      case 'pits':
        return Icons.psychology;
      default:
        return Icons.description;
    }
  }
}

class SectionDetailView extends StatefulWidget {
  final Map<String, dynamic> section;
  final FirebaseFirestore firestore;

  const SectionDetailView({
    super.key,
    required this.section,
    required this.firestore,
  });

  @override
  State<SectionDetailView> createState() => _SectionDetailViewState();
}

class _SectionDetailViewState extends State<SectionDetailView> {
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  bool _showAllDemStudents = false;

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

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final studentsSnapshot =
          await widget.firestore
              .collection('instructors')
              .doc(widget.section['instructorId'])
              .collection('classes')
              .doc(widget.section['classId'])
              .collection('students')
              .get();

      _students = [];
      for (var doc in studentsSnapshot.docs) {
        if (!mounted) return;

        final data = doc.data();

        // Fetch idNumber and profileImage from users collection using doc.id as user document ID
        String idNumber = '';
        String profileImage = '';
        try {
          final userDoc =
              await widget.firestore.collection('users').doc(doc.id).get();
          if (userDoc.exists) {
            final userData = userDoc.data() ?? {};
            idNumber = userData['idNumber']?.toString() ?? '';
            profileImage =
                userData['profileImage']?.toString() ??
                userData['profileImageUrl']?.toString() ??
                userData['profileUrl']?.toString() ??
                '';
          } else {
            // Fallback: try matching by studentId
            final studentId = data['studentId']?.toString() ?? '';
            if (studentId.isNotEmpty) {
              final userQuery =
                  await widget.firestore
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
              }
            }
          }
        } catch (e) {
          print('Error fetching user data for student ${doc.id}: $e');
        }

        _students.add({
          'id': doc.id,
          'studentId': data['studentId'] ?? '',
          'idNumber': idNumber,
          'profileImage': profileImage,
          'studentName': data['studentName'] ?? 'Unknown Student',
          'enrollmentStatus': data['enrollmentStatus'] ?? 'pending',
          'enrolledAt': _formatDate(data['enrolledAt']),
          'isActive': data['isActive'] ?? true,
          'section': widget.section['sectionName'] ?? 'Unknown Section',
        });
      }

      // If no students found in this specific section, check if instructor is "dem"
      // and load all students enrolled under "dem"
      if (_students.isEmpty) {
        final instructorName = await _getInstructorName(
          widget.section['instructorId'],
        );
        if (instructorName?.toLowerCase() == 'dem') {
          print(
            'No students in section, loading all students for instructor "dem"',
          );
          await _loadAllDemStudents();
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading students: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String?> _getInstructorName(String instructorId) async {
    try {
      final instructorDoc =
          await widget.firestore
              .collection('instructors')
              .doc(instructorId)
              .get();

      if (instructorDoc.exists) {
        final data = instructorDoc.data() as Map<String, dynamic>;
        return data['name']?.toString();
      }
      return null;
    } catch (e) {
      print('Error getting instructor name: $e');
      return null;
    }
  }

  Future<void> _loadAllDemStudents() async {
    try {
      List<Map<String, dynamic>> allStudents = [];

      // Find instructor "dem" by name
      final instructorsSnapshot =
          await widget.firestore
              .collection('instructors')
              .where('name', isEqualTo: 'dem')
              .get();

      if (instructorsSnapshot.docs.isEmpty) {
        print('Instructor "dem" not found');
        return;
      }

      final demInstructorId = instructorsSnapshot.docs.first.id;
      print('Found instructor "dem" with ID: $demInstructorId');

      // Method 1: Get students from instructor's classes
      final classesSnapshot =
          await widget.firestore
              .collection('instructors')
              .doc(demInstructorId)
              .collection('classes')
              .get();

      for (var classDoc in classesSnapshot.docs) {
        final classData = classDoc.data();
        final sectionName = classData['section'] ?? 'Unknown Section';

        final studentsSnapshot =
            await widget.firestore
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
            'studentId': studentData['studentId'] ?? studentDoc.id,
            'studentName': studentData['studentName'] ?? 'Unknown Student',
            'enrollmentStatus': studentData['enrollmentStatus'] ?? 'pending',
            'enrolledAt': _formatDate(studentData['enrolledAt']),
            'isActive': studentData['isActive'] ?? true,
            'section': sectionName,
            'classId': classDoc.id,
            'source': 'instructor_classes',
          });
        }
      }

      // Method 2: Get students from users collection who selected instructor "dem"
      final usersSnapshot =
          await widget.firestore
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
                userData['fullName'] ??
                userData['name'] ??
                userData['displayName'] ??
                'Unknown Student',
            'enrollmentStatus': userData['enrollmentStatus'] ?? 'pending',
            'enrolledAt': _formatDate(
              userData['updatedAt'] ?? userData['createdAt'],
            ),
            'isActive': true,
            'section': userData['selectedSectionCode'] ?? 'Unknown Section',
            'classId': 'users_collection',
            'source': 'users_collection',
          });
        }
      }

      print('Loaded ${allStudents.length} students for instructor "dem"');

      setState(() {
        _students = allStudents;
        _showAllDemStudents = true;
      });
    } catch (e) {
      print('Error loading all dem students: $e');
    }
  }

  String? _formatDate(dynamic date) {
    if (date == null) return null;
    if (date is Timestamp) {
      return '${date.toDate().day}/${date.toDate().month}/${date.toDate().year}';
    }
    return date.toString();
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
                    Icons.school,
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
                        'Section Details',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Class: ${widget.section['sectionName']}',
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
            // Student count and info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF34A853).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF34A853).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people, color: Color(0xFF34A853), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _showAllDemStudents
                          ? '${_students.length} ${_students.length == 1 ? 'student' : 'students'} enrolled under instructor "dem"'
                          : '${_students.length} ${_students.length == 1 ? 'student' : 'students'} enrolled',
                      style: const TextStyle(
                        color: Color(0xFF34A853),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_showAllDemStudents)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'All Dem Students',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Action buttons
            if (!_showAllDemStudents)
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      setState(() {
                        _isLoading = true;
                      });
                      await _loadAllDemStudents();
                    },
                    icon: const Icon(Icons.people, size: 16),
                    label: const Text('Show All Dem Students'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      setState(() {
                        _isLoading = true;
                      });
                      await _loadStudents();
                      setState(() {
                        _showAllDemStudents = false;
                      });
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh Section'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF34A853),
                      side: const BorderSide(color: Color(0xFF34A853)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            if (!_showAllDemStudents) const SizedBox(height: 16),
            // Students list
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _students.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No students found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This section doesn\'t have any students yet',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final student = _students[index];
                          final status =
                              student['enrollmentStatus'] ?? 'pending';
                          Color statusColor;
                          switch (status) {
                            case 'approved':
                              statusColor = Colors.green;
                              break;
                            case 'rejected':
                              statusColor = Colors.red;
                              break;
                            default:
                              statusColor = Colors.orange;
                          }

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
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor:
                                      (student['profileImage']?.toString() ??
                                                  '')
                                              .isNotEmpty
                                          ? Colors.transparent
                                          : const Color(
                                            0xFF34A853,
                                          ).withOpacity(0.1),
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
                                              student['studentName']
                                                      ?.toString() ??
                                                  'Unknown',
                                            ),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF34A853),
                                            ),
                                          )
                                          : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        student['studentName'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (student['idNumber'] != null &&
                                          (student['idNumber'] as String)
                                              .isNotEmpty)
                                        Text(
                                          'ID Number: ${student['idNumber']}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      if (_showAllDemStudents &&
                                          student['section'] != null)
                                        Text(
                                          'Section: ${student['section']}',
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      if (student['enrolledAt'] != null)
                                        Text(
                                          'Enrolled: ${student['enrolledAt']}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 10,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: statusColor.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (_showAllDemStudents &&
                                        student['source'] != null)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              student['source'] ==
                                                      'instructor_classes'
                                                  ? Colors.green.withOpacity(
                                                    0.1,
                                                  )
                                                  : Colors.orange.withOpacity(
                                                    0.1,
                                                  ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          student['source'] ==
                                                  'instructor_classes'
                                              ? 'Class'
                                              : 'Users',
                                          style: TextStyle(
                                            color:
                                                student['source'] ==
                                                        'instructor_classes'
                                                    ? Colors.green
                                                    : Colors.orange,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
