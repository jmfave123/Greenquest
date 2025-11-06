import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_controller.dart';
import '../../shared/widgets/responsive_layout.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String instructorName = '';
  String instructorId = '';
  String instructorProfileImage = '';
  String selectedSectionCode = '';
  String enrollmentStatus = 'pending';
  bool isLoading = true;
  StreamSubscription<DocumentSnapshot>? _statusListener;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _setupStatusListener();
    _debugUserDocument(); // Add debug function

    // Check for approval status periodically
    _startPeriodicApprovalCheck();
  }

  // Debug function to check user document
  Future<void> _debugUserDocument() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      print('🔍 DEBUG: Checking user document for: ${user.uid}');
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        print('🔍 DEBUG: User document data:');
        data.forEach((key, value) {
          print('🔍 DEBUG: $key: $value');
        });

        // Check specific fields
        final enrollmentStatus = data['enrollmentStatus'] ?? 'NOT_SET';
        final selectedInstructorId = data['selectedInstructorId'] ?? 'NOT_SET';
        final selectedInstructorName =
            data['selectedInstructorName'] ?? 'NOT_SET';
        final selectionComplete = data['selectionComplete'] ?? false;

        print('🔍 DEBUG: enrollmentStatus: $enrollmentStatus');
        print('🔍 DEBUG: selectedInstructorId: $selectedInstructorId');
        print('🔍 DEBUG: selectedInstructorName: $selectedInstructorName');
        print('🔍 DEBUG: selectionComplete: $selectionComplete');

        // Check if this user should be approved
        if (enrollmentStatus == 'pending') {
          print(
            '🔍 DEBUG: User is still pending - checking instructor approval...',
          );
          // Check if instructor has approved this user
          if (selectedInstructorId != 'NOT_SET' &&
              selectedInstructorId.isNotEmpty) {
            await _checkInstructorApproval(selectedInstructorId, user.uid);
          }
        }
      } else {
        print('🔍 DEBUG: User document does not exist!');
      }
    } catch (e) {
      print('🔍 DEBUG: Error checking user document: $e');
    }
  }

  // Check if instructor has approved this student
  Future<void> _checkInstructorApproval(
    String instructorId,
    String studentId,
  ) async {
    try {
      print(
        '🔍 DEBUG: Checking instructor approval for student $studentId in instructor $instructorId',
      );

      // Check if student exists in instructor's classes
      final classesSnapshot =
          await _firestore
              .collection('instructors')
              .doc(instructorId)
              .collection('classes')
              .get();

      for (var classDoc in classesSnapshot.docs) {
        final studentDoc =
            await _firestore
                .collection('instructors')
                .doc(instructorId)
                .collection('classes')
                .doc(classDoc.id)
                .collection('students')
                .doc(studentId)
                .get();

        if (studentDoc.exists) {
          final studentData = studentDoc.data() as Map<String, dynamic>;
          final enrollmentStatus = studentData['enrollmentStatus'] ?? 'NOT_SET';
          print(
            '🔍 DEBUG: Found student in class ${classDoc.id} with status: $enrollmentStatus',
          );

          if (enrollmentStatus == 'approved') {
            print(
              '🔍 DEBUG: Student is approved in instructor class but not in user document!',
            );
            print(
              '🔍 DEBUG: This suggests the approval process failed to update the user document.',
            );
          }
        }
      }
    } catch (e) {
      print('🔍 DEBUG: Error checking instructor approval: $e');
    }
  }

  // Check and sync approval status from instructor class to user document
  Future<void> _checkAndSyncApprovalStatus(
    String instructorId,
    String studentId,
  ) async {
    try {
      print('🔄 SYNC: Checking and syncing approval status...');

      // Check if student exists in instructor's classes
      final classesSnapshot =
          await _firestore
              .collection('instructors')
              .doc(instructorId)
              .collection('classes')
              .get();

      for (var classDoc in classesSnapshot.docs) {
        final studentDoc =
            await _firestore
                .collection('instructors')
                .doc(instructorId)
                .collection('classes')
                .doc(classDoc.id)
                .collection('students')
                .doc(studentId)
                .get();

        if (studentDoc.exists) {
          final studentData = studentDoc.data() as Map<String, dynamic>;
          final studentEnrollmentStatus =
              studentData['enrollmentStatus'] ?? 'NOT_SET';
          print(
            '🔄 SYNC: Found student in class ${classDoc.id} with status: $studentEnrollmentStatus',
          );

          if (studentEnrollmentStatus == 'approved') {
            print(
              '🔄 SYNC: Student is approved in instructor class! Syncing to user document...',
            );

            // Update user document to reflect approval
            await _firestore.collection('users').doc(studentId).update({
              'enrollmentStatus': 'approved',
              'approvedAt': FieldValue.serverTimestamp(),
              'lastStatusUpdate': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });

            print('✅ SYNC: User document updated to approved status');

            // Update local state and redirect
            setState(() {
              enrollmentStatus = 'approved';
            });

            Get.snackbar(
              'Approved!',
              'Your enrollment has been approved. Redirecting to dashboard...',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.green,
              colorText: Colors.white,
              duration: const Duration(seconds: 2),
            );

            Future.delayed(const Duration(milliseconds: 1500), () {
              print('🏠 SYNC: Navigating to home dashboard');
              Get.offAllNamed('/home');
            });

            return; // Exit after first successful sync
          }
        }
      }

      print('🔄 SYNC: No approval found in instructor classes');
    } catch (e) {
      print('❌ SYNC: Error syncing approval status: $e');
    }
  }

  Timer? _approvalCheckTimer;

  void _startPeriodicApprovalCheck() {
    // Check for approval every 10 seconds
    _approvalCheckTimer = Timer.periodic(const Duration(seconds: 10), (
      timer,
    ) async {
      if (!mounted || enrollmentStatus == 'approved') {
        timer.cancel();
        return;
      }

      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final selectedInstructorId = data['selectedInstructorId'] ?? '';

        if (selectedInstructorId.isNotEmpty) {
          await _checkAndSyncApprovalStatus(selectedInstructorId, user.uid);
        }
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final status = data['enrollmentStatus'] ?? 'pending';
        final instructorNameData = data['selectedInstructorName'] ?? '';
        final instructorIdData = data['selectedInstructorId'] ?? '';
        final sectionCodeData = data['selectedSectionCode'] ?? '';

        // Fetch instructor profile image if instructor ID exists
        String instructorProfileImageData = '';
        if (instructorIdData.isNotEmpty) {
          try {
            final instructorDoc =
                await _firestore
                    .collection('instructors')
                    .doc(instructorIdData)
                    .get();
            if (instructorDoc.exists) {
              final instructorData =
                  instructorDoc.data() as Map<String, dynamic>;
              // Check multiple possible field names for profile image
              instructorProfileImageData =
                  instructorData['profileUrl'] ??
                  instructorData['profileImageUrl'] ??
                  instructorData['profileImage'] ??
                  '';
              print(
                '📸 Instructor profile image URL: $instructorProfileImageData',
              );
            } else {
              print(
                '⚠️ Instructor document not found for ID: $instructorIdData',
              );
            }
          } catch (e) {
            print('❌ Error fetching instructor profile: $e');
          }
        }

        setState(() {
          instructorName = instructorNameData;
          instructorId = instructorIdData;
          instructorProfileImage = instructorProfileImageData;
          selectedSectionCode = sectionCodeData;
          enrollmentStatus = status;
          isLoading = false;
        });

        // If user is already approved, redirect immediately
        if (status == 'approved') {
          print(
            '🎉 User already approved on load! Redirecting to dashboard...',
          );

          Get.snackbar(
            'Approved!',
            'Your enrollment has been approved. Redirecting to dashboard...',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );

          Future.delayed(const Duration(milliseconds: 1500), () {
            print('🏠 Navigating to home dashboard');
            Get.offAllNamed('/home');
          });
          return;
        }

        // If user is rejected, show rejection dialog
        if (status == 'rejected') {
          _showRejectionDialog(data['rejectionReason'] ?? 'No reason provided');
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _statusListener?.cancel();
    _approvalCheckTimer?.cancel();
    super.dispose();
  }

  void _setupStatusListener() {
    final user = _auth.currentUser;
    if (user == null) {
      print('❌ Cannot setup listener - no user found');
      return;
    }

    // Cancel any existing listener first
    _statusListener?.cancel();

    print('🔍 Setting up status listener for user: ${user.uid}');

    _statusListener = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(
          (snapshot) {
            print('📱 ===== LISTENER TRIGGERED =====');
            print('📱 Timestamp: ${DateTime.now()}');
            print(
              '📱 Listener triggered - snapshot exists: ${snapshot.exists}',
            );
            if (snapshot.exists) {
              final data = snapshot.data() as Map<String, dynamic>;
              print('📱 Listener - Full document data: $data');

              final status = data['enrollmentStatus'] ?? 'pending';
              final lastStatusUpdate = data['lastStatusUpdate'];
              final selectedInstructorId = data['selectedInstructorId'] ?? '';
              final selectedInstructorName =
                  data['selectedInstructorName'] ?? '';

              print('📱 Status from document: $status');
              print('📱 Current local status: $enrollmentStatus');
              print('📱 Last status update: $lastStatusUpdate');
              print('📱 Instructor ID: $selectedInstructorId');
              print('📱 Instructor Name: $selectedInstructorName');

              print('📱 Status update received: $status');
              print('📱 Last status update: $lastStatusUpdate');
              print('📱 Current enrollmentStatus: $enrollmentStatus');
              print('📱 Instructor ID: $selectedInstructorId');
              print('📱 Instructor Name: $selectedInstructorName');

              if (status == 'approved' && enrollmentStatus != 'approved') {
                print('📱 Status changed from $enrollmentStatus to $status');

                setState(() {
                  enrollmentStatus = status;
                  instructorName = selectedInstructorName;
                });

                if (status == 'approved') {
                  print('🎉 Student approved! Redirecting to dashboard...');

                  // Show success message before redirecting
                  Get.snackbar(
                    'Approved!',
                    'Your enrollment has been approved. Redirecting to dashboard...',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 2),
                  );

                  // Small delay to show the message, then navigate
                  Future.delayed(const Duration(milliseconds: 1500), () {
                    print('🏠 Navigating to home dashboard');
                    print('🏠 Current route: ${Get.currentRoute}');
                    print('🏠 Routing to: /home');
                    Get.offAllNamed('/home');
                    print('🏠 Navigation called');
                  });
                } else if (status == 'rejected') {
                  print('❌ Student rejected');
                  // Show rejection message and allow re-selection
                  _showRejectionDialog(
                    data['rejectionReason'] ?? 'No reason provided',
                  );
                }
              } else {
                print(
                  '📱 Status unchanged: $status (current: $enrollmentStatus)',
                );
              }
            } else {
              print('⚠️ User document does not exist');
            }
          },
          onError: (error) {
            print('❌ Error in status listener: $error');
            // Don't automatically retry to prevent multiple listeners
            // The user can manually refresh if needed
          },
        );
  }

  void _showRejectionDialog(String reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Enrollment Rejected'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your enrollment request has been rejected.'),
                const SizedBox(height: 8),
                Text('Reason: $reason'),
                const SizedBox(height: 16),
                const Text(
                  'You can select a different instructor and try again.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Reset selection and go back to instructor selection
                  _resetSelectionAndReselect();
                },
                child: const Text('Select Different Instructor'),
              ),
            ],
          ),
    );
  }

  Future<void> _resetSelectionAndReselect() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Reset user selection
      await _firestore.collection('users').doc(user.uid).update({
        'selectedInstructorId': '',
        'selectedInstructorName': '',
        'selectedSectionCode': '',
        'selectionComplete': false,
        'enrollmentStatus': 'none',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Navigate to instructor selection
      Get.offAllNamed('/select-instructor');
    } catch (e) {
      print('Error resetting selection: $e');
    }
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Request'),
          content: const Text(
            'Are you sure you want to cancel your enrollment request? You will be able to select a different instructor.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Keep Request'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _cancelRequest();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel Request'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelRequest() async {
    try {
      setState(() {
        isLoading = true;
      });

      final user = _auth.currentUser;
      if (user == null) return;

      // Get current user data to find instructor and section
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final instructorId = userData['selectedInstructorId'] ?? '';
        final sectionCode = userData['selectedSectionCode'] ?? '';

        // Remove student from instructor's class if they were enrolled
        if (instructorId.isNotEmpty && sectionCode.isNotEmpty) {
          await _removeStudentFromInstructorClass(
            instructorId,
            sectionCode,
            user.uid,
          );
        }
      }

      // Reset user selection
      await _firestore.collection('users').doc(user.uid).update({
        'selectedInstructorId': '',
        'selectedInstructorName': '',
        'selectedSectionCode': '',
        'selectionComplete': false,
        'enrollmentStatus': 'none',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Show success message
      Get.snackbar(
        'Request Cancelled',
        'Your enrollment request has been cancelled. You can now select a different instructor.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );

      // Navigate to instructor selection
      Get.offAllNamed('/select-instructor');
    } catch (e) {
      print('Error cancelling request: $e');
      Get.snackbar(
        'Error',
        'Failed to cancel request. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _removeStudentFromInstructorClass(
    String instructorId,
    String sectionCode,
    String studentId,
  ) async {
    try {
      // Extract section part from full section code (e.g., "BSIT-4D" -> "4D")
      String sectionOnly = sectionCode;
      if (sectionCode.contains('-')) {
        sectionOnly = sectionCode.split('-').last;
      }

      // Find the instructor's class for this section
      final classesSnapshot =
          await _firestore
              .collection('instructors')
              .doc(instructorId)
              .collection('classes')
              .where('section', isEqualTo: sectionOnly)
              .get();

      // Remove student from all matching classes
      for (QueryDocumentSnapshot classDoc in classesSnapshot.docs) {
        await _firestore
            .collection('instructors')
            .doc(instructorId)
            .collection('classes')
            .doc(classDoc.id)
            .collection('students')
            .doc(studentId)
            .delete();

        print(
          'Student $studentId removed from instructor class ${classDoc.id}',
        );
      }
    } catch (e) {
      print('Error removing student from instructor class: $e');
      // Don't throw error here as the main cancellation should still proceed
    }
  }

  void _refreshStatus() async {
    setState(() {
      isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ Manual refresh - No user found');
        setState(() {
          isLoading = false;
        });
        return;
      }

      print('🔄 Manual refresh - checking user status for: ${user.uid}');

      // Force a fresh read from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      print('🔄 Manual refresh - Document exists: ${userDoc.exists}');

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        print('🔄 Manual refresh - Full document data: $data');

        final status = data['enrollmentStatus'] ?? 'pending';
        final lastStatusUpdate = data['lastStatusUpdate'];
        final selectedInstructorId = data['selectedInstructorId'] ?? '';
        final selectedInstructorName = data['selectedInstructorName'] ?? '';
        final selectionComplete = data['selectionComplete'] ?? false;

        print('🔄 Manual refresh - Current status: $status');
        print('🔄 Manual refresh - Last update: $lastStatusUpdate');
        print('🔄 Manual refresh - Instructor ID: $selectedInstructorId');
        print('🔄 Manual refresh - Instructor Name: $selectedInstructorName');
        print('🔄 Manual refresh - Selection Complete: $selectionComplete');
        print('🔄 Manual refresh - Previous status: $enrollmentStatus');

        setState(() {
          instructorName = selectedInstructorName;
          enrollmentStatus = status;
          isLoading = false;
        });

        // Check if status changed and handle accordingly
        if (status == 'approved') {
          print('🎉 Manual refresh - Student approved! Redirecting...');

          Get.snackbar(
            'Approved!',
            'Your enrollment has been approved. Redirecting to dashboard...',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );

          Future.delayed(const Duration(milliseconds: 1500), () {
            print('🏠 Manual refresh - Navigating to home dashboard');
            Get.offAllNamed('/home');
          });
        } else if (status == 'rejected') {
          print('❌ Manual refresh - Student rejected');
          _showRejectionDialog(data['rejectionReason'] ?? 'No reason provided');
        } else {
          print('⏳ Manual refresh - Still pending approval');

          // Check if student is actually approved in instructor's class
          if (selectedInstructorId.isNotEmpty) {
            print('🔍 Checking if student is approved in instructor class...');
            await _checkAndSyncApprovalStatus(selectedInstructorId, user.uid);
          }

          Get.snackbar(
            'Status Checked',
            'Your enrollment is still pending approval.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }
      } else {
        print('⚠️ Manual refresh - User document not found');
        setState(() {
          isLoading = false;
        });

        Get.snackbar(
          'Error',
          'User document not found. Please try logging in again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      print('❌ Manual refresh error: $e');
      setState(() {
        isLoading = false;
      });

      Get.snackbar(
        'Refresh Failed',
        'Failed to check status: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  // Helper method to get initials from full name
  String _getInitials(String fullName) {
    if (fullName.isEmpty) return 'S';

    // Split the name by spaces and filter out empty strings
    final nameParts =
        fullName.trim().split(' ').where((part) => part.isNotEmpty).toList();

    if (nameParts.isEmpty) return 'S';

    // If only one name part, return first letter
    if (nameParts.length == 1) {
      return nameParts[0][0].toUpperCase();
    }

    // Get first letter of first name and first letter of last name
    final firstInitial = nameParts.first[0].toUpperCase();
    final lastInitial = nameParts.last[0].toUpperCase();

    return '$firstInitial$lastInitial';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: FutureBuilder<DocumentSnapshot>(
          future:
              _firestore.collection('users').doc(_auth.currentUser?.uid).get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }

            final userData = snapshot.data?.data() as Map<String, dynamic>?;
            final fullName = userData?['fullName'] ?? 'Student';
            final profileImage = userData?['profileImage'];

            return Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF34A853),
                  backgroundImage:
                      profileImage != null && profileImage.isNotEmpty
                          ? NetworkImage(profileImage)
                          : null,
                  child:
                      profileImage == null || profileImage.isEmpty
                          ? Text(
                            _getInitials(fullName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          )
                          : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    fullName,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.06,
                      vertical: MediaQuery.of(context).size.height * 0.02,
                    ),
                    child: _buildContent(context),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        // Status Icon
        _buildStatusIcon(),

        ResponsiveSpacing(height: 32),

        // Status Title
        ResponsiveText(
          enrollmentStatus == 'rejected'
              ? 'Enrollment Rejected'
              : 'Pending Instructor Approval',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          textAlign: TextAlign.center,
        ),

        ResponsiveSpacing(height: 16),

        // Status Description
        ResponsiveText(
          enrollmentStatus == 'rejected'
              ? 'Your enrollment request has been rejected. Please select a different instructor.'
              : 'Your enrollment request is pending approval from your selected instructor.',
          fontSize: 16,
          color: Colors.black54,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),

        if (instructorName.isNotEmpty) ...[
          ResponsiveSpacing(height: 24),
          _buildInstructorCard(),
        ],

        if (selectedSectionCode.isNotEmpty) ...[
          ResponsiveSpacing(height: 16),
          _buildSectionCard(),
        ],

        ResponsiveSpacing(height: 32),

        // Status Indicator
        _buildStatusIndicator(),

        ResponsiveSpacing(height: 32),

        // Action Buttons
        _buildActionButtons(),

        ResponsiveSpacing(height: 24),

        // Help text
        ResponsiveText(
          enrollmentStatus == 'rejected'
              ? 'You can select a different instructor and try again.'
              : 'You will be automatically redirected once your instructor approves your enrollment.',
          fontSize: 14,
          color: Colors.grey[600],
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStatusIcon() {
    return ResponsiveContainer(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color:
            enrollmentStatus == 'rejected'
                ? Colors.red.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        enrollmentStatus == 'rejected'
            ? Icons.cancel_outlined
            : Icons.hourglass_empty,
        size: 60,
        color: enrollmentStatus == 'rejected' ? Colors.red : Colors.orange,
      ),
    );
  }

  Widget _buildInstructorCard() {
    return ResponsiveCard(
      child: Column(
        children: [
          // Instructor profile picture or icon
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFF34A853),
            backgroundImage:
                instructorProfileImage.isNotEmpty
                    ? NetworkImage(instructorProfileImage)
                    : null,
            child:
                instructorProfileImage.isEmpty
                    ? Text(
                      _getInitials(instructorName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    )
                    : null,
          ),
          ResponsiveSpacing(height: 12),
          ResponsiveText(
            'Selected Instructor',
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          ResponsiveSpacing(height: 4),
          ResponsiveText(
            instructorName,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard() {
    return ResponsiveCard(
      child: Column(
        children: [
          const Icon(Icons.school, color: Color(0xFF2196F3), size: 32),
          ResponsiveSpacing(height: 12),
          ResponsiveText(
            'Section',
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          ResponsiveSpacing(height: 4),
          ResponsiveText(
            selectedSectionCode,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color:
            enrollmentStatus == 'rejected'
                ? Colors.red.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              enrollmentStatus == 'rejected'
                  ? Colors.red.withOpacity(0.3)
                  : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color:
                  enrollmentStatus == 'rejected' ? Colors.red : Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          ResponsiveText(
            enrollmentStatus == 'rejected' ? 'Rejected' : 'Pending Approval',
            color:
                enrollmentStatus == 'rejected'
                    ? Colors.red[700]
                    : Colors.orange[700],
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (enrollmentStatus == 'rejected') {
      return ResponsiveButton(
        onPressed: _resetSelectionAndReselect,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF34A853),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const ResponsiveText(
          'Select Different Instructor',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      );
    } else {
      return Column(
        children: [
          // Cancel request button for pending status
          ResponsiveButton(
            onPressed: isLoading ? null : _showCancelConfirmation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cancel_outlined, size: 20),
                const SizedBox(width: 8),
                const Flexible(
                  child: ResponsiveText(
                    'Cancel Request',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),

          ResponsiveSpacing(height: 16),

          // Refresh button for pending status
          ResponsiveButton(
            onPressed: isLoading ? null : _refreshStatus,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF34A853),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF34A853)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return Colors.grey.shade100;
                }
                return Colors.white;
              }),
              overlayColor: WidgetStateProperty.all(
                const Color(0xFF34A853).withOpacity(0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF34A853),
                    ),
                  )
                else
                  const Icon(Icons.refresh, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: ResponsiveText(
                    isLoading ? 'Checking...' : 'Refresh Status',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF34A853),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),

          ResponsiveSpacing(height: 16),

          // Logout button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                await _handleLogout(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                backgroundColor: Colors.white,
                side: const BorderSide(color: Colors.black45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.logout, size: 20, color: Colors.black87),
                  SizedBox(width: 8),
                  Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF34A853),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        // Show loading indicator
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

        // Use AuthController for proper logout
        final authController = Get.find<AuthController>();
        await authController.logout();

        // Close loading dialog
        Navigator.of(context).pop();

        // Navigate to login screen
        Get.offAllNamed('/login_app');
      } catch (e) {
        // Close loading dialog if it's open
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        // Show error and still try to navigate
        Get.snackbar(
          'Error',
          'Logout failed, but redirecting to login...',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );

        // Force navigation even if logout failed
        Get.offAllNamed('/login_app');
      }
    }
  }
}
