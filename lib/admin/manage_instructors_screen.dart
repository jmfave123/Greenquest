import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/admin/admin_sidebar.dart';
import '../shared/admin/admin_navigation_constants.dart';
import '../shared/widgets/safe_asset_image.dart';
import 'multiple_assignment_dialog.dart';

class ManageInstructorsScreen extends StatefulWidget {
  const ManageInstructorsScreen({Key? key}) : super(key: key);

  @override
  State<ManageInstructorsScreen> createState() => _ManageInstructorsScreenState();
}

class _ManageInstructorsScreenState extends State<ManageInstructorsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AdminNavigationItem _selectedItem = AdminNavigationItem.manageInstructors;
  String _searchQuery = '';
  String _selectedStatus = 'All';

  final List<String> _statusOptions = ['All', 'Pending', 'Approved', 'Rejected'];

  void _handleNavigationSelect(AdminNavigationItem item) {
    debugPrint('Navigation selected: $item');
    setState(() {
      _selectedItem = item;
    });
    String route = AdminNavigationHelper.getRoute(item);
    debugPrint('Navigating to route: $route');
    Navigator.of(context).pushNamed(route);
  }


  Future<void> _approveInstructor(String instructorId) async {
    try {
      await _firestore.collection('instructors').doc(instructorId).update({
        'isVerified': true,
        'isActive': true,
        'status': 'Approved',
        'verifiedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Success',
        'Instructor approved successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to approve instructor: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _rejectInstructor(String instructorId) async {
    try {
      await _firestore.collection('instructors').doc(instructorId).update({
        'isVerified': false,
        'isActive': false,
        'status': 'Rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Success',
        'Instructor rejected successfully!',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to reject instructor: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }


  void _showAssignmentDialog(String instructorId, String instructorName, List<Map<String, dynamic>>? existingAssignments) {
    showDialog(
      context: context,
      builder: (context) => MultipleAssignmentDialog(
        instructorId: instructorId,
        instructorName: instructorName,
        existingAssignments: existingAssignments,
      ),
    );
  }

  Future<void> _deleteInstructor(String instructorId) async {
    try {
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.delete_forever,
                    color: Colors.red,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Delete Instructor',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Are you sure you want to permanently delete this instructor? This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black54,
                        side: const BorderSide(color: Color(0xFF34A853)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );

      if (shouldDelete == true) {
        await _firestore.collection('instructors').doc(instructorId).delete();
        Get.snackbar(
          'Success',
          'Instructor deleted successfully!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete instructor: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
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
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      SafeAssetImage(
                        assetPath: 'assets/admin_icons/lucide_users-round.png',
                        width: 32,
                        height: 32,
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Manage Instructors',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              'View, approve, and manage all instructor accounts',
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
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                       
                        // Search and Filter
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  onChanged: (value) => setState(() => _searchQuery = value),
                                  decoration: const InputDecoration(
                                    hintText: 'Search by name or email...',
                                    prefixIcon: Icon(Icons.search, color: Color(0xFF34A853)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(8)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(8)),
                                      borderSide: BorderSide(color: Color(0xFF34A853)),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 120,
                                height: 50,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButton<String>(
                                  value: _selectedStatus,
                                  onChanged: (value) => setState(() => _selectedStatus = value!),
                                  items: _statusOptions.map((status) {
                                    return DropdownMenuItem<String>(
                                      value: status,
                                      child: Text(status),
                                    );
                                  }).toList(),
                                  underline: const SizedBox(),
                                  isExpanded: false,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Test button
                        // Center(
                        //   child: ElevatedButton.icon(
                        //     onPressed: _createTestInstructor,
                        //     icon: const Icon(Icons.add),
                        //     label: const Text('Create Test Instructor'),
                        //     style: ElevatedButton.styleFrom(
                        //       backgroundColor: Colors.blue,
                        //       foregroundColor: Colors.white,
                        //       shape: RoundedRectangleBorder(
                        //         borderRadius: BorderRadius.circular(8),
                        //       ),
                        //       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        //     ),
                        //   ),
                        // ),
                        // const SizedBox(height: 24),
                        // Instructors List
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(
                            minHeight: 400,
                            maxHeight: 600,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: StreamBuilder<QuerySnapshot>(
                            stream: _firestore.collection('instructors').snapshots(),
                            builder: (context, snapshot) {
                              debugPrint('StreamBuilder state: ${snapshot.connectionState}');
                              debugPrint('StreamBuilder hasData: ${snapshot.hasData}');
                              debugPrint('StreamBuilder hasError: ${snapshot.hasError}');
                              if (snapshot.hasData) {
                                debugPrint('Instructors count: ${snapshot.data!.docs.length}');
                              }
                              
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 16),
                                      Text('Loading instructors...'),
                                    ],
                                  ),
                                );
                              }

                              if (snapshot.hasError) {
                                debugPrint('StreamBuilder error: ${snapshot.error}');
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.error, size: 64, color: Colors.red),
                                      const SizedBox(height: 16),
                                      Text('Error: ${snapshot.error}'),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () {
                                          setState(() {}); // Refresh
                                        },
                                        child: const Text('Retry'),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                return const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                                      SizedBox(height: 16),
                                      Text(
                                        'No instructors found',
                                        style: TextStyle(fontSize: 18, color: Colors.black54),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Click "Create Test Instructor" to add a sample',
                                        style: TextStyle(fontSize: 14, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              List<QueryDocumentSnapshot> instructors = snapshot.data!.docs;
                              
                              // Filter by search query
                              if (_searchQuery.isNotEmpty) {
                                instructors = instructors.where((doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  final name = data['name']?.toString().toLowerCase() ?? '';
                                  final email = data['email']?.toString().toLowerCase() ?? '';
                                  return name.contains(_searchQuery.toLowerCase()) ||
                                         email.contains(_searchQuery.toLowerCase());
                                }).toList();
                              }

                              // Filter by status
                              if (_selectedStatus != 'All') {
                                instructors = instructors.where((doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  final status = data['status']?.toString() ?? 'Pending';
                                  return status == _selectedStatus;
                                }).toList();
                              }

                              return ListView.builder(
                                shrinkWrap: true,
                                padding: const EdgeInsets.all(16),
                                itemCount: instructors.length,
                                itemBuilder: (context, index) {
                                  final doc = instructors[index];
                                  final data = doc.data() as Map<String, dynamic>;
                                  final status = data['status']?.toString() ?? 'Pending';
                                  final isActive = data['isActive'] ?? false;
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE5E7EB)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        // Avatar
                                        CircleAvatar(
                                          radius: 30,
                                          backgroundColor: const Color(0xFF34A853).withOpacity(0.1),
                                          child: Text(
                                            (data['name']?.toString().substring(0, 1).toUpperCase() ?? 'I'),
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF34A853),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                data['name'] ?? 'Unknown',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                data['email'] ?? 'No email',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Phone: ${data['phone'] ?? 'Not provided'}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              if (data['assignments'] != null && (data['assignments'] as List).isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Wrap(
                                                  spacing: 4,
                                                  runSpacing: 4,
                                                  children: (data['assignments'] as List).map<Widget>((assignment) {
                                                    return Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF34A853).withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(12),
                                                        border: Border.all(
                                                          color: const Color(0xFF34A853).withOpacity(0.3),
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        '${assignment['departmentCode']}-${assignment['sectionCode']}',
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: Color(0xFF34A853),
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              ],
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: _getStatusColor(status).withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(
                                                        color: _getStatusColor(status).withOpacity(0.3),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      status,
                                                      style: TextStyle(
                                                        color: _getStatusColor(status),
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: (isActive ? Colors.green : Colors.grey).withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(
                                                        color: (isActive ? Colors.green : Colors.grey).withOpacity(0.3),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      isActive ? 'Active' : 'Inactive',
                                                      style: TextStyle(
                                                        color: isActive ? Colors.green : Colors.grey,
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Actions
                                        Column(
                                          children: [
                                            if (status == 'Pending') ...[
                                              ElevatedButton.icon(
                                                onPressed: () => _approveInstructor(doc.id),
                                                icon: const Icon(Icons.check, size: 18),
                                                label: const Text('Approve'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              ElevatedButton.icon(
                                                onPressed: () => _rejectInstructor(doc.id),
                                                icon: const Icon(Icons.close, size: 18),
                                                label: const Text('Reject'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.orange,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                              ),
                                            ] else if (status == 'Approved') ...[
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.green.withOpacity(0.3),
                                                  ),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.check_circle,
                                                      color: Colors.green,
                                                      size: 18,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'Approved',
                                                      style: TextStyle(
                                                        color: Colors.green,
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ] else if (status == 'Rejected') ...[
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.red.withOpacity(0.3),
                                                  ),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.cancel,
                                                      color: Colors.red,
                                                      size: 18,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'Rejected',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 8),
                                            // Assign Department & Section button
                                            OutlinedButton.icon(
                                              onPressed: () => _showAssignmentDialog(
                                                doc.id, 
                                                data['name'] ?? 'Unknown',
                                                data['assignments'] != null ? List<Map<String, dynamic>>.from(data['assignments']) : null,
                                              ),
                                              icon: const Icon(Icons.school_rounded, size: 16),
                                              label: const Text('Assign'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: const Color(0xFF34A853),
                                                side: const BorderSide(color: Color(0xFF34A853)),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            // Delete button for all statuses
                                            OutlinedButton.icon(
                                              onPressed: () => _deleteInstructor(doc.id),
                                              icon: const Icon(Icons.delete, size: 16),
                                              label: const Text('Delete'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.red,
                                                side: const BorderSide(color: Colors.red),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Pending':
      default:
        return Colors.orange;
    }
  }
}