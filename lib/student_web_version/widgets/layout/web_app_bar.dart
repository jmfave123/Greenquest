import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../config/web_theme.dart';
import '../../config/web_routes.dart';
import '../../utils/web_responsive_utils.dart';
import '../../controllers/web_home_controller.dart';
import '../../../user/notification/notification_controller.dart';
import '../web_notification_dropdown.dart';

/// Web-optimized app bar for student portal
/// Displays logo, navigation items, and user profile

class WebAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onMenuPressed;
  final bool showNotifications;
  final bool showProfileDropdown;
  final bool logoutOnly;

  const WebAppBar({
    super.key,
    this.title = 'GreenQuest',
    this.onMenuPressed,
    this.showNotifications = true,
    this.showProfileDropdown = true,
    this.logoutOnly = false,
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
      automaticallyImplyLeading: false, // Remove default back button
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
      if (showNotifications)
        Obx(() {
          final notificationController = Get.find<NotificationController>();
          final count = notificationController.unreadCount.value;

          return Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  count > 0
                      ? Icons.notifications
                      : Icons.notifications_outlined,
                  color:
                      count > 0
                          ? WebTheme.primaryGreen
                          : WebTheme.textSecondary,
                ),
                onPressed: () {
                  _showNotificationDropdown(context);
                },
                tooltip: 'Notifications',
              ),
              if (count > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: WebTheme.errorRed,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        }),

      if (isDesktop && showNotifications) const SizedBox(width: 8),

      // User profile
      if (user != null)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child:
              showProfileDropdown
                  ? PopupMenuButton<String>(
                    offset: const Offset(0, 50),
                    child: _buildProfileInfo(isDesktop),
                    itemBuilder: (context) => _buildDropdownItems(),
                    onSelected: (value) => _handleDropdownAction(value),
                  )
                  : _buildProfileInfo(isDesktop),
        ),

      const SizedBox(width: 8),
    ];
  }

  Widget _buildProfileInfo(bool isDesktop) {
    return Row(
      children: [
        _buildAvatar(),
        if (isDesktop) ...[
          const SizedBox(width: 8),
          _buildUserName(),
          if (showProfileDropdown) ...[
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: WebTheme.textSecondary),
          ],
        ],
      ],
    );
  }

  Widget _buildAvatar() {
    try {
      final controller = Get.find<WebHomeController>();
      return Obx(() {
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
      });
    } catch (e) {
      // Fallback when WebHomeController is not available (auth screens)
      final user = FirebaseAuth.instance.currentUser;
      final initials = _getInitials(user?.displayName ?? user?.email ?? 'User');
      return CircleAvatar(
        radius: 18,
        backgroundColor: WebTheme.primaryGreen,
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  Widget _buildUserName() {
    try {
      final controller = Get.find<WebHomeController>();
      return Obx(() {
        return Text(
          controller.fullName.value.split(' ').first,
          style: const TextStyle(
            color: WebTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        );
      });
    } catch (e) {
      // Fallback when WebHomeController is not available
      final user = FirebaseAuth.instance.currentUser;
      final name =
          (user?.displayName ?? user?.email ?? 'User').split(' ').first;
      return Text(
        name,
        style: const TextStyle(
          color: WebTheme.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      );
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  List<PopupMenuEntry<String>> _buildDropdownItems() {
    if (logoutOnly) {
      // Show only logout option for auth screens
      return [
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 20, color: WebTheme.errorRed),
              SizedBox(width: 12),
              Text('Logout', style: TextStyle(color: WebTheme.errorRed)),
            ],
          ),
        ),
      ];
    }

    // Full menu for authenticated screens
    return [
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
            Text('Logout', style: TextStyle(color: WebTheme.errorRed)),
          ],
        ),
      ),
    ];
  }

  Future<void> _handleDropdownAction(String value) async {
    switch (value) {
      case 'profile':
        Get.toNamed(WebRoutes.profile);
        break;
      case 'settings':
        // TODO: Navigate to settings
        break;
      case 'logout':
        await FirebaseAuth.instance.signOut();
        Get.offAllNamed('/login');
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
  }

  void _showNotificationDropdown(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    // Get button position and size
    final Offset buttonOffset = button.localToGlobal(
      Offset.zero,
      ancestor: overlay,
    );
    final Size buttonSize = button.size;
    final Size overlaySize = overlay.size;

    // Responsive width calculation
    final bool isMobile = overlaySize.width < 600;
    final double dropdownWidth = isMobile ? overlaySize.width * 0.92 : 400.0;

    double left;
    double top = buttonOffset.dy + buttonSize.height + 12;
    double right;

    if (isMobile) {
      // Center on mobile
      left = (overlaySize.width - dropdownWidth) / 2;
      right = left;
    } else {
      // Right-aligned with the button on desktop
      left = buttonOffset.dx + buttonSize.width - dropdownWidth;
      right = overlaySize.width - (buttonOffset.dx + buttonSize.width);

      // Ensure it doesn't go off the left edge
      if (left < 10) {
        left = 10;
        right = overlaySize.width - (left + dropdownWidth);
      }
    }

    final RelativeRect position = RelativeRect.fromLTRB(
      left,
      top,
      right > 0 ? right : 0,
      0,
    );

    showMenu(
      context: context,
      position: position,
      elevation: 0,
      color: Colors.transparent,
      constraints: BoxConstraints(
        maxWidth: dropdownWidth,
        minWidth: dropdownWidth,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          padding: EdgeInsets.zero,
          enabled: false,
          child: const WebNotificationDropdown(),
        ),
      ],
    );
  }
}
