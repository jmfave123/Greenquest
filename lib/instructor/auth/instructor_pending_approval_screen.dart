import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'instructor_pending_approval_controller.dart';
import 'widgets/status_card.dart';
import 'widgets/info_message_card.dart';
import 'widgets/reapplication_dialog.dart';

class InstructorPendingApprovalScreen extends StatelessWidget {
  const InstructorPendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(InstructorPendingApprovalController());

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Obx(
                  () => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.pending_actions,
                            size: 64,
                            color: controller.getStatusColor(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Welcome text
                      Text(
                        'Welcome, ${controller.instructorName.value}!',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        controller.instructorEmail.value,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Status Card
                      StatusCard(
                        status: controller.accountStatus.value,
                        icon: controller.getStatusIcon(),
                        color: controller.getStatusColor(),
                      ),
                      const SizedBox(height: 24),

                      // Info Message
                      InfoMessageCard(
                        title: 'Account Under Review',
                        message:
                            'Your instructor account is currently pending admin approval. '
                            'You will receive an email notification once your account has been reviewed. '
                            'This process typically takes 1-2 business days.',
                        icon: Icons.info_outline,
                      ),
                      const SizedBox(height: 32),

                      // Refresh Status Button
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed:
                              controller.isLoading.value
                                  ? null
                                  : controller.refreshStatus,
                          icon:
                              controller.isLoading.value
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Icon(Icons.refresh),
                          label: Text(
                            controller.isLoading.value
                                ? 'Checking...'
                                : 'Refresh Status',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF34A853),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Apply Again Button (only for rejected status)
                      if (controller.accountStatus.value.toLowerCase() ==
                          'rejected')
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Get.dialog(
                                ReapplicationDialog(
                                  onSubmit: controller.submitReapplication,
                                ),
                                barrierDismissible: true,
                              );
                            },
                            icon: const Icon(Icons.replay),
                            label: const Text('Apply Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      if (controller.accountStatus.value.toLowerCase() ==
                          'rejected')
                        const SizedBox(height: 16),

                      // Logout Button
                      SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: controller.logout,
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
