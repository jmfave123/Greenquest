import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenquest/user/profile/profile_controller.dart';
import '../../shared/login/custom_drawer.dart';
import 'edit_profile_screen.dart';
import 'about_screen.dart';
import 'privacy_policy_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int selectedDrawerIndex = 5;
  final controller = Get.put(ProfileController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomDrawer(
        selectedIndex: selectedDrawerIndex,
        onSelect: (i) {
          setState(() => selectedDrawerIndex = i);
          Navigator.pop(context);
        },
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.black),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Obx(() {
        RxMap userData = controller.userData;
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            SizedBox(height: 32),
            GestureDetector(
              onTap: () => controller.uploadProfileImage(),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Obx(() {
                    final profileImage = controller.userData['profileImage'];
                    return CircleAvatar(
                      radius: 48,
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
                                controller.getInitials(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                              : null,
                    );
                  }),
                  if (controller.isUploadingImage.value)
                    const CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.black54,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF34A853),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              userData['fullName'] ?? '',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              userData['email'] ?? '',
              style: TextStyle(color: Colors.black54),
            ),

            // Section Information
            if (userData['selectedSectionCode'] != null &&
                userData['selectedSectionCode'].toString().isNotEmpty) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFFF0F8FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Color(0xFFB3D9FF)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school, color: Color(0xFF2196F3), size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Section: ${userData['selectedSectionCode']}',
                      style: TextStyle(
                        color: Color(0xFF2196F3),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 32),
            ListTile(
              leading: Image.asset(
                'assets/icons/akar-icons_chat-edit.png',
                width: 26,
              ),
              title: const Text('Edit Profile'),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.black,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
              },
            ),
            ListTile(
              leading: Image.asset(
                'assets/icons/ic_outline-show-chart.png',
                width: 26,
              ),
              title: const Text('About'),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.black,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                );
              },
            ),
            ListTile(
              leading: Image.asset(
                'assets/icons/akar-icons_heart.png',
                width: 26,
              ),
              title: const Text('Privacy Policy'),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.black,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyScreen(),
                  ),
                );
              },
            ),
          ],
        );
      }),
    );
  }
}
