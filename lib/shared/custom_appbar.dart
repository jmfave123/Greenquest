import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenquest/user/notification/announcement_list_screen.dart';
import 'package:greenquest/user/profile/profile_controller.dart';
// import '../user/announcement_list_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final profileController = Get.put(ProfileController());
  CustomAppBar({Key? key, this.title, this.actions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.black),
      title: Row(
        children: [
          const CircleAvatar(
            backgroundImage: AssetImage('assets/images/Photo.png'),
            radius: 18,
          ),
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
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications,
                  color: Colors.green,
                  size: 30,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AnnouncementListScreen(),
                    ),
                  );
                },
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      toolbarHeight: 70,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}
