import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../instructor/profile/profile_screen_controller.dart';

/// Reusable Edit Profile Dialog with modern UI
/// Matches the GreenQuest app aesthetic with green accents and clean design
class EditProfileDialog extends StatelessWidget {
  final InstructorController controller;

  const EditProfileDialog({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: Container(
        width: 550,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF34A853).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34A853),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Update your personal information',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      controller.cancelEditing();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close),
                    color: Colors.black54,
                  ),
                ],
              ),
            ),

            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name Field
                    _buildFieldLabel('Full Name', Icons.person),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller.nameController,
                      decoration: _buildInputDecoration(
                        hintText: 'Enter your full name',
                        prefixIcon: Icons.person_outline,
                      ),
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 20),

                    // Email Field (Read-only)
                    _buildFieldLabel('Email Address', Icons.email),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller.emailController,
                      decoration: _buildInputDecoration(
                        hintText: 'Email cannot be changed',
                        prefixIcon: Icons.email_outlined,
                        suffixIcon: Icons.lock_outline,
                        isReadOnly: true,
                      ),
                      readOnly: true,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Phone Field
                    _buildFieldLabel('Phone Number', Icons.phone),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller.phoneController,
                      decoration: _buildInputDecoration(
                        hintText: '09XXXXXXXXX',
                        prefixIcon: Icons.phone_outlined,
                        helperText: 'Enter 11-digit Philippine mobile number',
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 11,
                      style: const TextStyle(fontSize: 15),
                      onChanged: (value) {
                        // Only allow numbers
                        if (value.isNotEmpty &&
                            !RegExp(r'^[0-9]+$').hasMatch(value)) {
                          controller.phoneController.value = TextEditingValue(
                            text: value.replaceAll(RegExp(r'[^0-9]'), ''),
                            selection: TextSelection.collapsed(
                              offset:
                                  value
                                      .replaceAll(RegExp(r'[^0-9]'), '')
                                      .length,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // About Field
                    _buildFieldLabel('About', Icons.info),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller.aboutController,
                      decoration: _buildInputDecoration(
                        hintText: 'Tell us about yourself...',
                        prefixIcon: Icons.info_outline,
                        isMultiline: true,
                      ),
                      maxLines: 5,
                      minLines: 3,
                      style: const TextStyle(fontSize: 15),
                      textAlignVertical: TextAlignVertical.top,
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Cancel Button
                    TextButton(
                      onPressed:
                          controller.isLoading.value
                              ? null
                              : () {
                                controller.cancelEditing();
                                Navigator.of(context).pop();
                              },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Save Button
                    ElevatedButton(
                      onPressed:
                          controller.isLoading.value
                              ? null
                              : () async {
                                await controller.saveEditedData();
                                // Only close dialog if editing was successful
                                if (!controller.isEditing.value) {
                                  Navigator.of(context).pop();
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF34A853),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child:
                          controller.isLoading.value
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
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

  /// Build field label with icon
  Widget _buildFieldLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF34A853)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  /// Build consistent input decoration
  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    IconData? suffixIcon,
    String? helperText,
    bool isReadOnly = false,
    bool isMultiline = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      helperText: helperText,
      helperStyle: const TextStyle(fontSize: 12, color: Colors.black54),
      prefixIcon: Icon(
        prefixIcon,
        color: isReadOnly ? Colors.grey.shade400 : const Color(0xFF34A853),
        size: 20,
      ),
      suffixIcon:
          suffixIcon != null
              ? Icon(suffixIcon, color: Colors.grey.shade400, size: 18)
              : null,
      filled: true,
      fillColor:
          isReadOnly
              ? Colors.grey.shade100
              : const Color(0xFF34A853).withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF34A853), width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isMultiline ? 16 : 14,
      ),
    );
  }
}
