import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../shared/admin/admin_sidebar.dart';
import '../shared/admin/admin_navigation_constants.dart';
import '../shared/admin/widgets/admin_page_hero.dart';
import '../shared/widgets/safe_asset_image.dart';
import 'multiple_assignment_dialog.dart';
import '../shared/widgets/skeleton_loading.dart';
import 'widgets/reapplication_request_dialog.dart';
import '../shared/models/instructor_assignment_model.dart';
import '../shared/models/assigned_period_model.dart';

class ManageInstructorsScreen extends StatefulWidget {
  const ManageInstructorsScreen({super.key});

  @override
  State<ManageInstructorsScreen> createState() =>
      _ManageInstructorsScreenState();
}

class _ManageInstructorsScreenState extends State<ManageInstructorsScreen>
    with AutomaticKeepAliveClientMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AdminNavigationItem _selectedItem = AdminNavigationItem.manageInstructors;
  String _searchQuery = '';
  String _selectedStatus = 'All';
  String _selectedActivityStatus = 'All'; // New filter for active/inactive

  final List<String> _statusOptions = [
    'All',
    'Pending',
    'Approved',
    'Rejected',
  ];

  final List<String> _activityStatusOptions = ['All', 'Active', 'Inactive'];

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

  void _showApproveConfirmation(String instructorId, String instructorName) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Approve Instructor',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Are you sure you want to approve "$instructorName"? They will be able to access their dashboard after approval.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 15),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      'Approve',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black54,
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
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
    ).then((shouldApprove) {
      if (shouldApprove == true) {
        _approveInstructor(instructorId);
      }
    });
  }

  /// Sends an approval / rejection email to the instructor via the
  /// `/api/notify-instructor` serverless function.
  Future<void> _notifyInstructor(String instructorId, String action) async {
    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken(true);
      if (idToken == null) return;

      final baseUrl =
          kDebugMode
              ? (dotenv.env['VERCEL_BASE_URL_LOCAL'] ?? 'http://localhost:3000')
              : (dotenv.env['VERCEL_BASE_URL'] ??
                  'https://greenquest-seven.vercel.app');

      await http.post(
        Uri.parse('$baseUrl/api/notify-instructor'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'instructorId': instructorId, 'action': action}),
      );
    } catch (_) {
      // Email notification is non-critical; don't surface errors to the user.
    }
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

      // Send approval email notification (fire-and-forget)
      _notifyInstructor(instructorId, 'approved');

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

  void _showRejectConfirmation(String instructorId, String instructorName) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.cancel_outlined,
                  color: Colors.orange,
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Reject Instructor',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Are you sure you want to reject "$instructorName"? They will not be able to access their dashboard.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 15),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      'Reject',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black54,
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
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
    ).then((shouldReject) {
      if (shouldReject == true) {
        _rejectInstructor(instructorId);
      }
    });
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

      // Send rejection email notification (fire-and-forget)
      _notifyInstructor(instructorId, 'rejected');

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

  void _showAssignmentDialog(
    String instructorId,
    String instructorName,
    List<InstructorAssignment>? existingAssignments,
    String? instructorStatus,
  ) {
    // Prevent assigning pending instructors
    if (instructorStatus == 'Pending') {
      Get.snackbar(
        'Cannot Assign',
        'Pending instructors cannot be assigned. Please approve the instructor first.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => MultipleAssignmentDialog(
            instructorId: instructorId,
            instructorName: instructorName,
            existingAssignments: existingAssignments,
          ),
    );
  }

  Future<void> _toggleInstructorStatus(
    String instructorId,
    bool currentStatus,
    String instructorName,
  ) async {
    try {
      final newStatus = !currentStatus;
      final action = newStatus ? 'set as active' : 'set as inactive';
      final actionCapitalized = newStatus ? 'Set as Active' : 'Set as Inactive';

      final shouldToggle = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: (newStatus ? Colors.green : Colors.orange)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    newStatus ? Icons.check_circle_outline : Icons.block,
                    color: newStatus ? Colors.green : Colors.orange,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  actionCapitalized,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Are you sure you want to $action "$instructorName"? ${newStatus ? 'They will be able to access their account and manage classes.' : 'They will no longer be able to access their account.'}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, fontSize: 15),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            newStatus ? Colors.green : Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(
                        actionCapitalized,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black54,
                        side: const BorderSide(color: Color(0xFF34A853)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
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

      if (shouldToggle == true) {
        await _firestore.collection('instructors').doc(instructorId).update({
          'isActive': newStatus,
          'statusUpdatedAt': FieldValue.serverTimestamp(),
        });
        Get.snackbar(
          'Success',
          'Instructor set as ${newStatus ? "active" : "inactive"} successfully!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update instructor status: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final double responsivePadding = getResponsivePadding();
    final bool mobile = isMobile;
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
                AdminPageHero(
                  leading: SafeAssetImage(
                    assetPath: 'assets/admin_icons/lucide_users-round.png',
                    width: mobile ? 28 : 32,
                    height: mobile ? 28 : 32,
                  ),
                  title: 'Manage Instructors',
                  subtitle: 'View, approve, and manage all instructor accounts',
                  heroTitle: 'Instructor Oversight',
                  heroDescription:
                      'Review approvals, assignments, and instructor activity in one place.',
                  headerPadding: EdgeInsets.symmetric(
                    horizontal: responsivePadding,
                    vertical: mobile ? 12 : 16,
                  ),
                  heroPadding: EdgeInsets.all(mobile ? 16 : 24),
                  heroMargin: EdgeInsets.fromLTRB(
                    responsivePadding,
                    mobile ? 12 : 20,
                    responsivePadding,
                    24,
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(getResponsivePadding()),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search and Filter
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isMobile ? 12 : 20),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child:
                              isMobile
                                  ? Column(
                                    children: [
                                      TextField(
                                        onChanged:
                                            (value) => setState(
                                              () => _searchQuery = value,
                                            ),
                                        decoration: const InputDecoration(
                                          hintText:
                                              'Search by name or email...',
                                          prefixIcon: Icon(
                                            Icons.search,
                                            color: Color(0xFF34A853),
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(8),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(8),
                                            ),
                                            borderSide: BorderSide(
                                              color: Color(0xFF34A853),
                                            ),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 50,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: const Color(0xFFE5E7EB),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: DropdownButton<String>(
                                            value: _selectedStatus,
                                            onChanged:
                                                (value) => setState(
                                                  () =>
                                                      _selectedStatus = value!,
                                                ),
                                            items:
                                                _statusOptions.map((status) {
                                                  return DropdownMenuItem<
                                                    String
                                                  >(
                                                    value: status,
                                                    child: Text(status),
                                                  );
                                                }).toList(),
                                            underline: const SizedBox(),
                                            isExpanded: true,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                  : Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          onChanged:
                                              (value) => setState(
                                                () => _searchQuery = value,
                                              ),
                                          decoration: const InputDecoration(
                                            hintText:
                                                'Search by name or email...',
                                            prefixIcon: Icon(
                                              Icons.search,
                                              color: Color(0xFF34A853),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(8),
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(8),
                                              ),
                                              borderSide: BorderSide(
                                                color: Color(0xFF34A853),
                                              ),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 12,
                                                ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                        width: 120,
                                        height: 50,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: const Color(0xFFE5E7EB),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: DropdownButton<String>(
                                          value: _selectedStatus,
                                          onChanged:
                                              (value) => setState(
                                                () => _selectedStatus = value!,
                                              ),
                                          items:
                                              _statusOptions.map((status) {
                                                return DropdownMenuItem<String>(
                                                  value: status,
                                                  child: Text(status),
                                                );
                                              }).toList(),
                                          underline: const SizedBox(),
                                          isExpanded: false,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                        width: 120,
                                        height: 50,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: const Color(0xFFE5E7EB),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: DropdownButton<String>(
                                          value: _selectedActivityStatus,
                                          onChanged:
                                              (value) => setState(
                                                () =>
                                                    _selectedActivityStatus =
                                                        value!,
                                              ),
                                          items:
                                              _activityStatusOptions.map((
                                                status,
                                              ) {
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
                            stream:
                                _firestore
                                    .collection('instructors')
                                    .snapshots(),
                            builder: (context, snapshot) {
                              debugPrint(
                                'StreamBuilder state: ${snapshot.connectionState}',
                              );
                              debugPrint(
                                'StreamBuilder hasData: ${snapshot.hasData}',
                              );
                              debugPrint(
                                'StreamBuilder hasError: ${snapshot.hasError}',
                              );
                              if (snapshot.hasData) {
                                debugPrint(
                                  'Instructors count: ${snapshot.data!.docs.length}',
                                );
                              }

                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SkeletonInstructorList();
                              }

                              if (snapshot.hasError) {
                                debugPrint(
                                  'StreamBuilder error: ${snapshot.error}',
                                );
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

                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(32),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF34A853,
                                          ).withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.school_outlined,
                                          size: 80,
                                          color: Color(0xFF34A853),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      const Text(
                                        'No Instructors Yet',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'The system is ready for instructors to register',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black54,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 32),
                                      Container(
                                        padding: const EdgeInsets.all(24),
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 40,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(
                                                0xFF34A853,
                                              ).withOpacity(0.1),
                                              const Color(
                                                0xFF34A853,
                                              ).withOpacity(0.05),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: const Color(
                                              0xFF34A853,
                                            ).withOpacity(0.3),
                                            width: 2,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.how_to_reg,
                                              size: 48,
                                              color: const Color(0xFF34A853),
                                            ),
                                            const SizedBox(height: 16),
                                            const Text(
                                              'How It Works',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            const Text(
                                              '1. Instructors register through the app\n'
                                              '2. They appear here with "Pending" status\n'
                                              '3. Review and approve or reject them\n'
                                              '4. Approved instructors can access their dashboard',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black54,
                                                height: 1.6,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              List<QueryDocumentSnapshot> instructors =
                                  snapshot.data!.docs;

                              // Filter by search query
                              if (_searchQuery.isNotEmpty) {
                                instructors =
                                    instructors.where((doc) {
                                      final data =
                                          doc.data() as Map<String, dynamic>;
                                      final name =
                                          data['name']
                                              ?.toString()
                                              .toLowerCase() ??
                                          '';
                                      final email =
                                          data['email']
                                              ?.toString()
                                              .toLowerCase() ??
                                          '';
                                      return name.contains(
                                            _searchQuery.toLowerCase(),
                                          ) ||
                                          email.contains(
                                            _searchQuery.toLowerCase(),
                                          );
                                    }).toList();
                              }

                              // Filter by status
                              if (_selectedStatus != 'All') {
                                instructors =
                                    instructors.where((doc) {
                                      final data =
                                          doc.data() as Map<String, dynamic>;
                                      final status =
                                          data['status']?.toString() ??
                                          'Pending';
                                      return status == _selectedStatus;
                                    }).toList();
                              }

                              // Filter by activity status
                              if (_selectedActivityStatus != 'All') {
                                instructors =
                                    instructors.where((doc) {
                                      final data =
                                          doc.data() as Map<String, dynamic>;
                                      final isActive = data['isActive'] ?? true;
                                      if (_selectedActivityStatus == 'Active') {
                                        return isActive == true;
                                      } else {
                                        return isActive == false;
                                      }
                                    }).toList();
                              }

                              // Filter out "Unknown" instructors
                              instructors =
                                  instructors.where((doc) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    final name =
                                        data['name']
                                            ?.toString()
                                            .toLowerCase() ??
                                        '';
                                    return name != 'unknown' && name.isNotEmpty;
                                  }).toList();

                              // Check if filtered list is empty
                              if (instructors.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(32),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF34A853,
                                          ).withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.person_search_outlined,
                                          size: 80,
                                          color: Color(0xFF34A853),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        _searchQuery.isNotEmpty ||
                                                _selectedStatus != 'All'
                                            ? 'No Instructors Match Your Filters'
                                            : 'No Instructors Found',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _searchQuery.isNotEmpty ||
                                                _selectedStatus != 'All'
                                            ? 'Try adjusting your search or filter criteria'
                                            : 'No instructors have been added to the system yet',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black54,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (_searchQuery.isNotEmpty ||
                                          _selectedStatus != 'All') ...[
                                        const SizedBox(height: 24),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              _searchQuery = '';
                                              _selectedStatus = 'All';
                                            });
                                          },
                                          icon: const Icon(Icons.clear_all),
                                          label: const Text('Clear Filters'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF34A853,
                                            ),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ] else ...[
                                        const SizedBox(height: 24),
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 40,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.blue.shade200,
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                color: Colors.blue.shade700,
                                                size: 24,
                                              ),
                                              const SizedBox(width: 12),
                                              Flexible(
                                                child: Text(
                                                  'Instructors will appear here once they register',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.blue.shade900,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }

                              return ListView.builder(
                                shrinkWrap: true,
                                padding: const EdgeInsets.all(16),
                                itemCount: instructors.length,
                                itemBuilder: (context, index) {
                                  final doc = instructors[index];
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final status =
                                      data['status']?.toString() ?? 'Pending';
                                  final isActive = data['isActive'] ?? false;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFE5E7EB),
                                      ),
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
                                          backgroundColor:
                                              (data['profileUrl']?.toString() ??
                                                              '')
                                                          .isEmpty &&
                                                      (data['profileImageUrl']
                                                                  ?.toString() ??
                                                              '')
                                                          .isEmpty
                                                  ? const Color(
                                                    0xFF34A853,
                                                  ).withOpacity(0.1)
                                                  : Colors.transparent,
                                          backgroundImage:
                                              (data['profileUrl']?.toString() ??
                                                          '')
                                                      .isNotEmpty
                                                  ? NetworkImage(
                                                    data['profileUrl'],
                                                  )
                                                  : (data['profileImageUrl']
                                                              ?.toString() ??
                                                          '')
                                                      .isNotEmpty
                                                  ? NetworkImage(
                                                    data['profileImageUrl'],
                                                  )
                                                  : null,
                                          child:
                                              (data['profileUrl']?.toString() ??
                                                              '')
                                                          .isEmpty &&
                                                      (data['profileImageUrl']
                                                                  ?.toString() ??
                                                              '')
                                                          .isEmpty
                                                  ? Text(
                                                    () {
                                                      final name =
                                                          data['name']
                                                              ?.toString() ??
                                                          '';
                                                      return name.isNotEmpty
                                                          ? name
                                                              .substring(0, 1)
                                                              .toUpperCase()
                                                          : 'I';
                                                    }(),
                                                    style: const TextStyle(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF34A853),
                                                    ),
                                                  )
                                                  : null,
                                        ),
                                        const SizedBox(width: 16),
                                        // Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
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
                                              // ── Assigned-period chips ──
                                              if (() {
                                                final raw =
                                                    data['assignedPeriods'];
                                                return raw is List &&
                                                    raw.isNotEmpty;
                                              }()) ...[
                                                const SizedBox(height: 4),
                                                Wrap(
                                                  spacing: 4,
                                                  runSpacing: 4,
                                                  children:
                                                      (data['assignedPeriods']
                                                              as List)
                                                          .whereType<
                                                            Map<String, dynamic>
                                                          >()
                                                          .map(
                                                            AssignedPeriod
                                                                .fromMap,
                                                          )
                                                          .map<Widget>((
                                                            period,
                                                          ) {
                                                            final label =
                                                                period.label;
                                                            return Container(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical: 4,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: Colors
                                                                    .blue
                                                                    .withOpacity(
                                                                      0.08,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                                border: Border.all(
                                                                  color: Colors
                                                                      .blue
                                                                      .withOpacity(
                                                                        0.3,
                                                                      ),
                                                                  width: 1,
                                                                ),
                                                              ),
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  const Icon(
                                                                    Icons
                                                                        .calendar_today_outlined,
                                                                    size: 11,
                                                                    color:
                                                                        Colors
                                                                            .blue,
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 4,
                                                                  ),
                                                                  Text(
                                                                    label,
                                                                    style: const TextStyle(
                                                                      fontSize:
                                                                          11,
                                                                      color:
                                                                          Colors
                                                                              .blue,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          })
                                                          .toList(),
                                                ),
                                              ],
                                              // ── Department-section assignment chips ──
                                              if (() {
                                                final raw = data['assignments'];
                                                return raw is List &&
                                                    raw.isNotEmpty;
                                              }()) ...[
                                                const SizedBox(height: 4),
                                                Wrap(
                                                  spacing: 4,
                                                  runSpacing: 4,
                                                  children:
                                                      (data['assignments']
                                                              as List)
                                                          .whereType<
                                                            Map<String, dynamic>
                                                          >()
                                                          .map(
                                                            InstructorAssignment
                                                                .fromMap,
                                                          )
                                                          .map<Widget>((
                                                            assignment,
                                                          ) {
                                                            return Container(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical: 4,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: const Color(
                                                                  0xFF34A853,
                                                                ).withOpacity(
                                                                  0.1,
                                                                ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                                border: Border.all(
                                                                  color: const Color(
                                                                    0xFF34A853,
                                                                  ).withOpacity(
                                                                    0.3,
                                                                  ),
                                                                  width: 1,
                                                                ),
                                                              ),
                                                              child: Text(
                                                                assignment
                                                                    .label,
                                                                style: const TextStyle(
                                                                  fontSize: 11,
                                                                  color: Color(
                                                                    0xFF34A853,
                                                                  ),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                            );
                                                          })
                                                          .toList(),
                                                ),
                                              ],
                                              // ── NSTP Component badge ──
                                              if ((data['nstpComponent']
                                                          ?.toString() ??
                                                      '')
                                                  .isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.deepPurple
                                                            .withOpacity(0.08),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        border: Border.all(
                                                          color: Colors
                                                              .deepPurple
                                                              .withOpacity(0.3),
                                                        ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          const Icon(
                                                            Icons
                                                                .account_tree_outlined,
                                                            size: 11,
                                                            color:
                                                                Colors
                                                                    .deepPurple,
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Text(
                                                            data['nstpComponent']
                                                                .toString(),
                                                            style: const TextStyle(
                                                              fontSize: 11,
                                                              color:
                                                                  Colors
                                                                      .deepPurple,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: _getStatusColor(
                                                        status,
                                                      ).withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                      border: Border.all(
                                                        color: _getStatusColor(
                                                          status,
                                                        ).withOpacity(0.3),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      status,
                                                      style: TextStyle(
                                                        color: _getStatusColor(
                                                          status,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: (isActive
                                                              ? Colors.green
                                                              : Colors.grey)
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                      border: Border.all(
                                                        color: (isActive
                                                                ? Colors.green
                                                                : Colors.grey)
                                                            .withOpacity(0.3),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      isActive
                                                          ? 'Active'
                                                          : 'Inactive',
                                                      style: TextStyle(
                                                        color:
                                                            isActive
                                                                ? Colors.green
                                                                : Colors.grey,
                                                        fontWeight:
                                                            FontWeight.w600,
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            // Status Badge (for Approved/Rejected)
                                            if (status == 'Approved') ...[
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.green
                                                        .withOpacity(0.3),
                                                  ),
                                                ),
                                                child: const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
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
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                            ] else if (status ==
                                                'Rejected') ...[
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withOpacity(
                                                    0.1,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.red
                                                        .withOpacity(0.3),
                                                  ),
                                                ),
                                                child: const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
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
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                            ],
                                            // Primary Actions (for Pending status)
                                            if (status == 'Pending') ...[
                                              SizedBox(
                                                width: 140,
                                                child: ElevatedButton.icon(
                                                  onPressed:
                                                      () => _showApproveConfirmation(
                                                        doc.id,
                                                        data['name'] ??
                                                            'Unknown Instructor',
                                                      ),
                                                  icon: const Icon(
                                                    Icons.check,
                                                    size: 18,
                                                  ),
                                                  label: const Text('Approve'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.green,
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                          vertical: 12,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              SizedBox(
                                                width: 140,
                                                child: ElevatedButton.icon(
                                                  onPressed:
                                                      () => _showRejectConfirmation(
                                                        doc.id,
                                                        data['name'] ??
                                                            'Unknown Instructor',
                                                      ),
                                                  icon: const Icon(
                                                    Icons.close,
                                                    size: 18,
                                                  ),
                                                  label: const Text('Reject'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.orange,
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                          vertical: 12,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                            ],
                                            // Secondary Actions
                                            // View Profile button (not for rejected instructors)
                                            if (status != 'Rejected')
                                              SizedBox(
                                                width: 140,
                                                child: OutlinedButton.icon(
                                                  onPressed: () {
                                                    final instructorData = {
                                                      'id': doc.id,
                                                      'name':
                                                          data['name'] ??
                                                          'Unknown',
                                                      'email':
                                                          data['email'] ??
                                                          'No email',
                                                      'phone':
                                                          data['phone'] ?? '',
                                                      'department':
                                                          data['department'] ??
                                                          '',
                                                      'profileUrl':
                                                          data['profileUrl'] ??
                                                          data['profileImageUrl'] ??
                                                          '',
                                                      'about':
                                                          data['about'] ?? '',
                                                    };
                                                    _showInstructorProfile(
                                                      instructorData,
                                                    );
                                                  },
                                                  icon: const Icon(
                                                    Icons.person_outline,
                                                    size: 18,
                                                  ),
                                                  label: const Text(
                                                    'View Profile',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor:
                                                        const Color(0xFF34A853),
                                                    side: const BorderSide(
                                                      color: Color(0xFF34A853),
                                                      width: 1.5,
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                          vertical: 12,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            // Show Reapplication Request button (only for rejected instructors)
                                            if (status == 'Rejected')
                                              SizedBox(
                                                width: 140,
                                                child: OutlinedButton.icon(
                                                  onPressed: () {
                                                    showDialog(
                                                      context: context,
                                                      builder:
                                                          (
                                                            context,
                                                          ) => ReapplicationRequestDialog(
                                                            instructorId:
                                                                doc.id,
                                                            instructorName:
                                                                data['name'] ??
                                                                'Unknown',
                                                          ),
                                                    );
                                                  },
                                                  icon: const Icon(
                                                    Icons.message_outlined,
                                                    size: 18,
                                                  ),
                                                  label: const Text(
                                                    'View Requests',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.blue,
                                                    side: const BorderSide(
                                                      color: Colors.blue,
                                                      width: 1.5,
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                          vertical: 12,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(height: 8),
                                            // Department/section Assign button (only for Approved instructors)
                                            if (status == 'Approved') ...[
                                              SizedBox(
                                                width: 140,
                                                child: OutlinedButton.icon(
                                                  onPressed:
                                                      () => _showAssignmentDialog(
                                                        doc.id,
                                                        data['name'] ??
                                                            'Unknown',
                                                        data['assignments'] !=
                                                                null
                                                            ? (data['assignments']
                                                                    as List<
                                                                      dynamic
                                                                    >)
                                                                .whereType<
                                                                  Map<
                                                                    String,
                                                                    dynamic
                                                                  >
                                                                >()
                                                                .map(
                                                                  InstructorAssignment
                                                                      .fromMap,
                                                                )
                                                                .toList()
                                                            : null,
                                                        status,
                                                      ),
                                                  icon: const Icon(
                                                    Icons.school_outlined,
                                                    size: 18,
                                                  ),
                                                  label: const Text(
                                                    'Assign',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor:
                                                        const Color(0xFF34A853),
                                                    side: const BorderSide(
                                                      color: Color(0xFF34A853),
                                                      width: 1.5,
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                          vertical: 12,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                            ],
                                            // Toggle Active Status (only for Approved instructors)
                                            if (status == 'Approved') ...[
                                              // Divider
                                              Container(
                                                width: 140,
                                                height: 1,
                                                color: Colors.grey[300],
                                              ),
                                              const SizedBox(height: 12),
                                              SizedBox(
                                                width: 140,
                                                child: OutlinedButton.icon(
                                                  onPressed:
                                                      () => _toggleInstructorStatus(
                                                        doc.id,
                                                        isActive,
                                                        data['name'] ??
                                                            'Unknown Instructor',
                                                      ),
                                                  icon: Icon(
                                                    isActive
                                                        ? Icons.block
                                                        : Icons
                                                            .check_circle_outline,
                                                    size: 18,
                                                  ),
                                                  label: Text(
                                                    isActive
                                                        ? 'Set Inactive'
                                                        : 'Set Active',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor:
                                                        isActive
                                                            ? Colors.orange
                                                            : Colors.green,
                                                    side: BorderSide(
                                                      color:
                                                          isActive
                                                              ? Colors.orange
                                                              : Colors.green,
                                                      width: 1.5,
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                          vertical: 12,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
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

// Instructor Profile View Widget
class InstructorProfileView extends StatefulWidget {
  final Map<String, dynamic> instructor;

  const InstructorProfileView({super.key, required this.instructor});

  @override
  State<InstructorProfileView> createState() => _InstructorProfileViewState();
}

class _InstructorProfileViewState extends State<InstructorProfileView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoadingDepartments = true;
  List<Map<String, dynamic>> _departments = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    try {
      setState(() {
        _isLoadingDepartments = true;
        _errorMessage = '';
      });

      final instructorId = widget.instructor['id'];
      if (instructorId == null || instructorId.toString().isEmpty) {
        setState(() {
          _isLoadingDepartments = false;
        });
        return;
      }

      // Fetch instructor document to get assignments
      final instructorDoc =
          await _firestore.collection('instructors').doc(instructorId).get();

      if (!instructorDoc.exists) {
        setState(() {
          _isLoadingDepartments = false;
        });
        return;
      }

      final instructorData = instructorDoc.data();
      final assignments = instructorData?['assignments'] as List<dynamic>?;

      if (assignments == null || assignments.isEmpty) {
        setState(() {
          _isLoadingDepartments = false;
        });
        return;
      }

      // Extract unique department IDs from assignments
      final Set<String> uniqueDepartmentIds = {};
      for (var assignment in assignments) {
        if (assignment is Map<String, dynamic>) {
          final departmentId = assignment['departmentId']?.toString();
          if (departmentId != null && departmentId.isNotEmpty) {
            uniqueDepartmentIds.add(departmentId);
          }
        }
      }

      if (uniqueDepartmentIds.isEmpty) {
        setState(() {
          _isLoadingDepartments = false;
        });
        return;
      }

      // Fetch department details for each unique department
      final List<Map<String, dynamic>> departments = [];
      for (var departmentId in uniqueDepartmentIds) {
        try {
          final departmentDoc =
              await _firestore
                  .collection('departments')
                  .doc(departmentId)
                  .get();

          if (departmentDoc.exists) {
            final departmentData = departmentDoc.data();
            if (departmentData != null) {
              final departmentName =
                  departmentData['displayName'] ??
                  departmentData['name'] ??
                  departmentData['code'] ??
                  'Unknown';
              final departmentCode = departmentData['code'] ?? '';

              departments.add({
                'id': departmentId,
                'name': departmentName.toString(),
                'code': departmentCode.toString(),
              });
            }
          }
        } catch (e) {
          print('Error fetching department $departmentId: $e');
        }
      }

      if (mounted) {
        setState(() {
          _departments = departments;
          _isLoadingDepartments = false;
        });
      }
    } catch (e) {
      print('Error loading departments: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load departments';
          _isLoadingDepartments = false;
        });
      }
    }
  }

  String getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  String _getDepartmentDisplayText() {
    if (_isLoadingDepartments) {
      return 'Loading...';
    }

    if (_errorMessage.isNotEmpty) {
      return _errorMessage;
    }

    if (_departments.isEmpty) {
      // Fallback to instructor's department field if no assignments
      final fallbackDept = widget.instructor['department']?.toString();
      if (fallbackDept != null && fallbackDept.isNotEmpty) {
        return fallbackDept;
      }
      return 'Not assigned';
    }

    // Display all departments, format: "Name (Code)" or just "Name"
    return _departments
        .map((dept) {
          final name = dept['name'] ?? 'Unknown';
          final code = dept['code']?.toString() ?? '';
          if (code.isNotEmpty && code != name) {
            return '$name ($code)';
          }
          return name;
        })
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final initials = getInitials(widget.instructor['name'] ?? '');
    final hasImage =
        (widget.instructor['profileUrl']?.toString() ?? '').isNotEmpty;
    final profileImageUrl = widget.instructor['profileUrl']?.toString() ?? '';

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
                      widget.instructor['email'] ?? 'N/A',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.phone_outlined,
                      'Phone',
                      widget.instructor['phone']?.toString().isEmpty ?? true
                          ? 'Not provided'
                          : widget.instructor['phone'],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.business_outlined,
                      'Department',
                      _getDepartmentDisplayText(),
                      isLoading: _isLoadingDepartments,
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
                  (widget.instructor['about']?.toString().isNotEmpty ?? false)
                      ? widget.instructor['about']
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

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isLoading = false,
  }) {
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
              isLoading
                  ? Row(
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF34A853),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                  : Text(
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
