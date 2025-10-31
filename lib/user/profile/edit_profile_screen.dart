import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenquest/user/profile/profile_controller.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final controller = Get.put(ProfileController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: () {},
          ),
        ],
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
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _ProfileField(
                    label: 'Full Name',
                    value: userData['fullName'] ?? '',
                  ),
                  _ProfileField(label: 'Email', value: userData['email'] ?? ''),
                  _ProfileField(
                    label: 'Phone Number',
                    value: userData['phoneNumber'] ?? '',
                  ),
                  _ProfileField(
                    label: 'ID Number',
                    value: userData['idNumber'] ?? '',
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
