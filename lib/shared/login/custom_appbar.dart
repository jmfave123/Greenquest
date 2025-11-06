import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenquest/user/profile/profile_controller.dart';
import 'package:greenquest/user/notification/notifications_list_screen.dart';
import 'package:greenquest/user/notification/notification_controller.dart';
import 'package:greenquest/user/home_screen_controller.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  const CustomAppBar({super.key, this.title, this.actions});

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(70);
}

class _CustomAppBarState extends State<CustomAppBar> {
  final profileController = Get.put(ProfileController());
  late NotificationController notificationController;

  @override
  void initState() {
    super.initState();
    // Try to find existing controller, if not found create new one
    try {
      notificationController = Get.find<NotificationController>();
    } catch (e) {
      notificationController = Get.put(NotificationController());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.black),
      title: Row(
        children: [
          Obx(() {
            final profileImage = profileController.userData['profileImage'];
            return CircleAvatar(
              radius: 18,
              backgroundColor:
                  profileImage != null && profileImage.isNotEmpty
                      ? null
                      : const Color(0xFF34A853),
              backgroundImage:
                  profileImage != null && profileImage.isNotEmpty
                      ? NetworkImage(profileImage)
                      : null,
              child:
                  profileImage == null || profileImage.isEmpty
                      ? Text(
                        profileController.getInitials(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                      : null,
            );
          }),
          const SizedBox(width: 12),

          Obx(
            () => Text(
              'Hello,\n${profileController.userData['fullName'] ?? ''}',
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Spacer(),
          // Notification Icon - only show if user is approved
          Obx(() {
            // Check if user is approved before showing notifications
            try {
              final homeController = Get.find<HomeScreenController>();
              if (!homeController.isApproved.value) {
                return const SizedBox.shrink(); // Hide notification icon if not approved
              }
            } catch (e) {
              // If HomeScreenController is not found, hide notification icon
              return const SizedBox.shrink();
            }

            // User is approved, show notification icon
            return Stack(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: Colors.black,
                    size: 24,
                  ),
                  onPressed: () {
                    Get.to(() => const NotificationsListScreen());
                  },
                ),
                if (notificationController.unreadCount.value > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF34A853),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        notificationController.unreadCount.value > 99
                            ? '99+'
                            : '${notificationController.unreadCount.value}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
      toolbarHeight: 70,
      actions: widget.actions,
    );
  }
}
