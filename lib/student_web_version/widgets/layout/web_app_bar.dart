import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../config/web_theme.dart';
import '../../config/web_routes.dart';
import '../../utils/web_responsive_utils.dart';
import '../../controllers/web_home_controller.dart';

/// Web-optimized app bar for student portal
/// Displays logo, navigation items, and user profile

class WebAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onMenuPressed;

  const WebAppBar({
    super.key,
    this.title = 'GreenQuest',
    this.showBackButton = false,
    this.onMenuPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final isDesktop = WebResponsiveUtils.isDesktop(context);
    final user = FirebaseAuth.instance.currentUser;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: WebTheme.borderLight, height: 1.0),
      ),
      leading: _buildLeading(context, isDesktop),
      title: _buildTitle(isDesktop),
      actions: _buildActions(context, user, isDesktop),
    );
  }

  Widget? _buildLeading(BuildContext context, bool isDesktop) {
    if (showBackButton) {
      return IconButton(
        icon: const Icon(Icons.arrow_back, color: WebTheme.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      );
    }

    if (!isDesktop && onMenuPressed != null) {
      return IconButton(
        icon: const Icon(Icons.menu, color: WebTheme.textPrimary),
        onPressed: onMenuPressed,
      );
    }

    return null;
  }

  Widget _buildTitle(bool isDesktop) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo
        Image.asset(
          'assets/images/GreenQuest Logo.jpg',
          height: 40,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.eco,
              color: WebTheme.primaryGreen,
              size: 32,
            );
          },
        ),
        if (isDesktop) ...[
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: WebTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildActions(BuildContext context, User? user, bool isDesktop) {
    return [
      // Notifications icon
      IconButton(
        icon: const Icon(
          Icons.notifications_outlined,
          color: WebTheme.textSecondary,
        ),
        onPressed: () {
          // TODO: Navigate to notifications
        },
        tooltip: 'Notifications',
      ),

      if (isDesktop) const SizedBox(width: 8),

      // User profile
      if (user != null)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: PopupMenuButton<String>(
            offset: const Offset(0, 50),
            child: Row(
              children: [
                Obx(() {
                  final controller = Get.find<WebHomeController>();
                  return CircleAvatar(
                    radius: 18,
                    backgroundColor: WebTheme.primaryGreen,
                    backgroundImage:
                        controller.profileImage.value.isNotEmpty
                            ? NetworkImage(controller.profileImage.value)
                            : null,
                    child:
                        controller.profileImage.value.isEmpty
                            ? Text(
                              controller.getInitials(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                            : null,
                  );
                }),
                if (isDesktop) ...[
                  const SizedBox(width: 8),
                  Obx(() {
                    final controller = Get.find<WebHomeController>();
                    return Text(
                      controller.fullName.value.split(' ').first,
                      style: const TextStyle(
                        color: WebTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: WebTheme.textSecondary,
                  ),
                ],
              ],
            ),
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, size: 20),
                        SizedBox(width: 12),
                        Text('Profile'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('Settings'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 20, color: WebTheme.errorRed),
                        SizedBox(width: 12),
                        Text(
                          'Logout',
                          style: TextStyle(color: WebTheme.errorRed),
                        ),
                      ],
                    ),
                  ),
                ],
            onSelected: (value) async {
              switch (value) {
                case 'profile':
                  Get.toNamed(WebRoutes.profile);
                  break;
                case 'settings':
                  // TODO: Navigate to settings
                  break;
                case 'logout':
                  // Sign out from Firebase
                  await FirebaseAuth.instance.signOut();

                  // Redirect to login screen
                  Get.offAllNamed('/login');

                  // Show success message
                  Get.snackbar(
                    'Logged Out',
                    'You have been successfully logged out.',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.orange,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 2),
                  );
                  break;
              }
            },
          ),
        ),

      const SizedBox(width: 8),
    ];
  }
}
