import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:greenquest/student_web_version/widgets/footer_apporoval_screen.dart';
import '../../config/web_theme.dart';
import '../../config/web_routes.dart';
import '../../utils/web_responsive_utils.dart';
import '../../widgets/layout/web_app_bar.dart';

class WebPendingApprovalScreen extends StatefulWidget {
  const WebPendingApprovalScreen({super.key});

  @override
  State<WebPendingApprovalScreen> createState() =>
      _WebPendingApprovalScreenState();
}

class _WebPendingApprovalScreenState extends State<WebPendingApprovalScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String instructorName = '';
  String instructorId = '';
  String instructorProfileImage = '';
  String enrollmentStatus = 'pending';
  bool isLoading = true;
  StreamSubscription<DocumentSnapshot>? _statusListener;
  Timer? _approvalCheckTimer;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _setupStatusListener();
    _startPeriodicApprovalCheck();
  }

  @override
  void dispose() {
    _statusListener?.cancel();
    _approvalCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final status = data['enrollmentStatus'] ?? 'pending';
        final name = data['selectedInstructorName'] ?? '';
        final id = data['selectedInstructorId'] ?? '';

        // Fetch instructor profile image from instructors collection
        String profileImg = '';
        if (id.isNotEmpty) {
          try {
            final instructorDoc =
                await _firestore.collection('instructors').doc(id).get();
            if (instructorDoc.exists) {
              final instructorData =
                  instructorDoc.data() as Map<String, dynamic>;
              profileImg = instructorData['profileImageUrl'] ?? '';
            }
          } catch (e) {
            debugPrint('Error fetching instructor profile: $e');
          }
        }

        setState(() {
          instructorName = name;
          instructorId = id;
          instructorProfileImage = profileImg;
          enrollmentStatus = status;
          isLoading = false;
        });

        if (status == 'approved') {
          _redirectToHome();
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() => isLoading = false);
    }
  }

  void _setupStatusListener() {
    final user = _auth.currentUser;
    if (user == null) return;

    _statusListener = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data() as Map<String, dynamic>;
            final status = data['enrollmentStatus'] ?? 'pending';

            if (status == 'approved' && enrollmentStatus != 'approved') {
              setState(() => enrollmentStatus = status);
              _redirectToHome();
            } else if (status == 'rejected' && enrollmentStatus != 'rejected') {
              setState(() => enrollmentStatus = status);
            }
          }
        });
  }

  void _startPeriodicApprovalCheck() {
    _approvalCheckTimer = Timer.periodic(const Duration(seconds: 15), (
      timer,
    ) async {
      if (!mounted || enrollmentStatus == 'approved') {
        timer.cancel();
        return;
      }
      _loadUserData();
    });
  }

  void _redirectToHome() {
    Get.snackbar(
      'Approved!',
      'Your enrollment has been approved. Redirecting...',
      snackPosition: SnackPosition.TOP,
      backgroundColor: WebTheme.successGreen,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      Get.offAllNamed(WebRoutes.home);
    });
  }

  Future<void> _cancelRequest() async {
    try {
      setState(() => isLoading = true);

      final user = _auth.currentUser;
      if (user == null) return;

      // Reset user selection in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'selectedInstructorId': '',
        'selectedInstructorName': '',
        'selectedSectionCode': '',
        'selectionComplete': false,
        'enrollmentStatus': 'none',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Request Cancelled',
        'You can now select a different instructor.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );

      Get.offAllNamed(WebRoutes.selectInstructor);
    } catch (e) {
      debugPrint('Error cancelling request: $e');
      Get.snackbar('Error', 'Failed to cancel request. Please try again.');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showCancelDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Cancel Enrollment?'),
        content: const Text(
          'Are you sure you want to cancel your enrollment request? You will be able to select a different instructor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Keep',
              style: TextStyle(color: WebTheme.primaryGreen),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _cancelRequest();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: WebTheme.primaryGreen,
            ),
            child: const Text(
              'Cancel Request',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider? _getProfileImage() {
    if (instructorProfileImage.isEmpty) return null;
    if (instructorProfileImage.startsWith('data:image/') ||
        instructorProfileImage.startsWith('/9j/')) {
      try {
        return MemoryImage(base64Decode(instructorProfileImage));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(instructorProfileImage);
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF43A047),
      const Color(0xFF2196F3),
      const Color(0xFF9C27B0),
      const Color(0xFFF57C00),
      const Color(0xFFE91E63),
      const Color(0xFF00BCD4),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0]
          .substring(0, parts[0].length > 2 ? 2 : parts[0].length)
          .toUpperCase();
    } else {
      final first = parts[0].isNotEmpty ? parts[0][0] : '';
      final last =
          parts[parts.length - 1].isNotEmpty ? parts[parts.length - 1][0] : '';
      return (first + last).toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = WebResponsiveUtils.isMobile(context);
    final cardPadding = isMobile ? 24.0 : 48.0;

    return Scaffold(
      backgroundColor: WebTheme.backgroundLight,
      appBar: WebAppBar(
        title: 'GreenQuest Enrollment Status',
        onMenuPressed: null,
        showNotifications: false,
        showProfileDropdown: true,
        logoutOnly: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: WebResponsiveUtils.getResponsivePadding(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Main Card
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(cardPadding),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isMobile ? 24 : 32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Illustration or Icon
                      Container(
                        width: isMobile ? 80 : 120,
                        height: isMobile ? 80 : 120,
                        decoration: BoxDecoration(
                          color:
                              enrollmentStatus == 'rejected'
                                  ? Colors.red.withOpacity(0.1)
                                  : WebTheme.primaryGreen.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          enrollmentStatus == 'rejected'
                              ? Icons.error_outline_rounded
                              : Icons.hourglass_empty_rounded,
                          size: isMobile ? 40 : 60,
                          color:
                              enrollmentStatus == 'rejected'
                                  ? Colors.red
                                  : WebTheme.primaryGreen,
                        ),
                      ),
                      SizedBox(height: isMobile ? 24 : 32),

                      // Title
                      Text(
                        enrollmentStatus == 'rejected'
                            ? 'Enrollment Rejected'
                            : 'Pending Approval',
                        style: WebTheme.headingLarge.copyWith(
                          fontSize: isMobile ? 24 : 32,
                          color:
                              enrollmentStatus == 'rejected'
                                  ? Colors.red
                                  : WebTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Description
                      Text(
                        enrollmentStatus == 'rejected'
                            ? 'We regret to inform you that your enrollment has been rejected by the instructor. Please contact your instructor for more information.'
                            : 'Your enrollment request is currently being reviewed. Once approved, you will have full access to the student portal.',
                        style: WebTheme.bodyLarge.copyWith(
                          height: 1.6,
                          fontSize: isMobile ? 14 : 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isMobile ? 32 : 40),

                      // Instructor Info if pending
                      if (enrollmentStatus != 'rejected' &&
                          instructorName.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: WebTheme.backgroundLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: WebTheme.borderLight),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundImage: _getProfileImage(),
                                backgroundColor: _getAvatarColor(
                                  instructorName,
                                ),
                                child:
                                    _getProfileImage() == null
                                        ? Text(
                                          _getInitials(instructorName),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
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
                                      'Instructor',
                                      style: WebTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      instructorName,
                                      style: WebTheme.bodyLarge.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isMobile ? 32 : 40),
                      ],

                      // Action Buttons
                      SizedBox(
                        width: isMobile ? double.infinity : null,
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : _loadUserData,
                          icon:
                              isLoading
                                  ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Icon(Icons.refresh_rounded),
                          label: Text(
                            isLoading ? 'Updating...' : 'Refresh Status',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: WebTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Change Instructor Option
              if (enrollmentStatus != 'approved')
                TextButton.icon(
                  onPressed: isLoading ? null : _showCancelDialog,
                  icon: const Icon(Icons.edit_note_rounded, size: 20),
                  label: const Text('Select a different instructor'),
                  style: TextButton.styleFrom(
                    foregroundColor: WebTheme.textSecondary,
                  ),
                ),

              const SizedBox(height: 24),

              // Footer info
              footerText(
                'Need help? Contact support at greenquest01@gmail.com',
                WebTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
