import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

        setState(() {
          instructorName = name;
          instructorId = id;
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

  Future<void> _logout() async {
    await _auth.signOut();
    Get.offAllNamed('/login');
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: WebTheme.backgroundLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: WebTheme.borderLight),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 20,
                                color: WebTheme.primaryGreen,
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  'Instructor: $instructorName',
                                  style: WebTheme.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isMobile ? 32 : 40),
                      ],

                      // Action Buttons
                      Flex(
                        direction: isMobile ? Axis.vertical : Axis.horizontal,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: isMobile ? double.infinity : null,
                            child: OutlinedButton.icon(
                              onPressed: _logout,
                              icon: const Icon(Icons.logout_rounded),
                              label: const Text('Logout'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          if (isMobile)
                            const SizedBox(height: 12)
                          else
                            const SizedBox(width: 16),
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
                                  horizontal: 24,
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
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Footer info
              const Text(
                'Need help? Contact support at support@greenquest.com',
                style: WebTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
