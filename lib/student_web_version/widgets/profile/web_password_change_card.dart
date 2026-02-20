import 'package:flutter/material.dart';
import '../../config/web_theme.dart';
import '../../utils/web_responsive_utils.dart';

typedef PasswordSubmitCallback =
    Future<void> Function({
      required String currentPassword,
      required String newPassword,
      required String confirmPassword,
    });

class WebPasswordChangeCard extends StatefulWidget {
  const WebPasswordChangeCard({
    super.key,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    this.onSubmit,
    this.onForgotPassword,
    this.securityTips = const [
      'Use at least 8 characters with a mix of letters and numbers.',
      'Avoid reusing passwords from other accounts.',
      'Update passwords regularly to keep your account safe.',
    ],
    this.isProcessing = false,
  });

  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final PasswordSubmitCallback? onSubmit;
  final VoidCallback? onForgotPassword;
  final List<String> securityTips;
  final bool isProcessing;

  @override
  State<WebPasswordChangeCard> createState() => _WebPasswordChangeCardState();
}

class _WebPasswordChangeCardState extends State<WebPasswordChangeCard> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = WebResponsiveUtils.isDesktop(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WebTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            if (isDesktop) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildPasswordField(
                      label: 'Current Password',
                      hint: 'Enter your current password',
                      controller: widget.currentPasswordController,
                      obscureText: !_showCurrent,
                      onToggleVisibility:
                          () => _toggleVisibility(FieldType.current),
                      validator:
                          (value) =>
                              (value == null || value.isEmpty)
                                  ? 'Current password is required'
                                  : null,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildPasswordField(
                      label: 'New Password',
                      hint: 'Minimum of 8 characters',
                      controller: widget.newPasswordController,
                      obscureText: !_showNew,
                      onToggleVisibility:
                          () => _toggleVisibility(FieldType.newPassword),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'New password is required';
                        }
                        if (value.trim().length < 8) {
                          return 'Use at least 8 characters';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                label: 'Confirm Password',
                hint: 'Retype the new password',
                controller: widget.confirmPasswordController,
                obscureText: !_showConfirm,
                onToggleVisibility:
                    () => _toggleVisibility(FieldType.confirmPassword),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (value != widget.newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
              ),
            ] else ...[
              _buildPasswordField(
                label: 'Current Password',
                hint: 'Enter your current password',
                controller: widget.currentPasswordController,
                obscureText: !_showCurrent,
                onToggleVisibility: () => _toggleVisibility(FieldType.current),
                validator:
                    (value) =>
                        (value == null || value.isEmpty)
                            ? 'Current password is required'
                            : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                label: 'New Password',
                hint: 'Minimum of 8 characters',
                controller: widget.newPasswordController,
                obscureText: !_showNew,
                onToggleVisibility:
                    () => _toggleVisibility(FieldType.newPassword),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'New password is required';
                  }
                  if (value.trim().length < 8) {
                    return 'Use at least 8 characters';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                label: 'Confirm Password',
                hint: 'Retype the new password',
                controller: widget.confirmPasswordController,
                obscureText: !_showConfirm,
                onToggleVisibility:
                    () => _toggleVisibility(FieldType.confirmPassword),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (value != widget.newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
              ),
            ],
            const SizedBox(height: 24),
            _buildSecurityTips(),
            const SizedBox(height: 24),
            _buildActionRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Account Security',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: WebTheme.textPrimary,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Keep your account secure by updating your password regularly.',
                style: TextStyle(color: WebTheme.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: WebTheme.hoverGreen,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Security',
            style: TextStyle(
              color: WebTheme.primaryGreen,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityTips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password tips',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: WebTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...widget.securityTips.map(
          (tip) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 16,
                  color: WebTheme.primaryGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip,
                    style: const TextStyle(
                      fontSize: 13,
                      color: WebTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow() {
    return Row(
      children: [
        TextButton.icon(
          onPressed: widget.onForgotPassword,
          icon: const Icon(Icons.lock_open, size: 18),
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all(WebTheme.primaryGreen),
          ),
          label: const Text(
            'Forgot password?',
            style: TextStyle(color: WebTheme.primaryGreen),
          ),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: widget.isProcessing ? null : _handleSubmit,
          icon:
              widget.isProcessing
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.check_circle_outline),
          label: Text(widget.isProcessing ? 'Saving...' : 'Update password'),
          style: ElevatedButton.styleFrom(
            backgroundColor: WebTheme.primaryGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
    required TextInputAction textInputAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: WebTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          enableSuggestions: false,
          autocorrect: false,
          textInputAction: textInputAction,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: WebTheme.backgroundLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: WebTheme.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: WebTheme.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: WebTheme.primaryGreen,
                width: 1.3,
              ),
            ),
            suffixIcon: IconButton(
              onPressed: onToggleVisibility,
              icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
            ),
          ),
        ),
      ],
    );
  }

  void _toggleVisibility(FieldType type) {
    setState(() {
      switch (type) {
        case FieldType.current:
          _showCurrent = !_showCurrent;
          break;
        case FieldType.newPassword:
          _showNew = !_showNew;
          break;
        case FieldType.confirmPassword:
          _showConfirm = !_showConfirm;
          break;
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (widget.onSubmit == null) {
      return;
    }

    FocusScope.of(context).unfocus();
    await widget.onSubmit!(
      currentPassword: widget.currentPasswordController.text.trim(),
      newPassword: widget.newPasswordController.text.trim(),
      confirmPassword: widget.confirmPasswordController.text.trim(),
    );
  }
}

enum FieldType { current, newPassword, confirmPassword }
