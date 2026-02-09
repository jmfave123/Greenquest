import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/web_theme.dart';
import '../../config/web_routes.dart';
import '../../utils/web_responsive_utils.dart';
import '../../widgets/layout/web_app_bar.dart';
import '../../widgets/layout/web_sidebar.dart';
import '../../controllers/web_profile_controller.dart';

class WebProfileScreen extends StatelessWidget {
  const WebProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WebProfileController());
    final isDesktop = WebResponsiveUtils.isDesktop(context);
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      appBar: WebAppBar(
        title: 'Profile',
        onMenuPressed:
            isDesktop ? null : () => scaffoldKey.currentState?.openDrawer(),
      ),
      drawer:
          !isDesktop
              ? Drawer(child: WebSidebar(currentRoute: WebRoutes.profile))
              : null,
      body: Row(
        children: [
          if (isDesktop) const WebSidebar(currentRoute: WebRoutes.profile),
          Expanded(
            child: Container(
              color: WebTheme.backgroundLight,
              child: Obx(() {
                if (controller.isLoading.value && controller.userData.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: WebTheme.primaryGreen,
                    ),
                  );
                }
                return _buildContent(context, controller);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WebProfileController controller) {
    return SingleChildScrollView(
      padding: WebResponsiveUtils.getResponsivePadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(context, controller),
              const SizedBox(height: 32),
              if (WebResponsiveUtils.isDesktop(context))
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildPersonalInfo(controller)),
                    const SizedBox(width: 32),
                    Expanded(flex: 2, child: _buildAccountStats(controller)),
                  ],
                )
              else
                Column(
                  children: [
                    _buildAccountStats(controller),
                    const SizedBox(height: 24),
                    _buildPersonalInfo(controller),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    WebProfileController controller,
  ) {
    final userData = controller.userData;
    final initials = controller.getInitials();
    final profileImg = userData['profileImage'] ?? '';

    return Container(
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
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: WebTheme.primaryGreen.withOpacity(0.2),
                    width: 3,
                  ),
                ),
                child: Obx(() {
                  final isUploading = controller.isImageLoading.value;
                  return CircleAvatar(
                    radius: 50,
                    backgroundColor: WebTheme.primaryGreen.withOpacity(0.1),
                    backgroundImage:
                        profileImg.isNotEmpty ? NetworkImage(profileImg) : null,
                    child:
                        isUploading
                            ? const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: WebTheme.primaryGreen,
                            )
                            : (profileImg.isEmpty
                                ? Text(
                                  initials,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: WebTheme.primaryGreen,
                                  ),
                                )
                                : null),
                  );
                }),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: () => controller.updateProfilePicture(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: WebTheme.primaryGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userData['fullName'] ?? userData['name'] ?? 'Student Name',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: WebTheme.textPrimary,
                  ),
                ),
                Text(
                  userData['email'] ?? 'email@example.com',
                  style: const TextStyle(
                    fontSize: 16,
                    color: WebTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: WebTheme.hoverGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    userData['selectedSectionCode'] ?? 'No Section',
                    style: const TextStyle(
                      color: WebTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              _showEditDialog(context, controller);
            },
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: WebTheme.primaryGreen,
              side: const BorderSide(color: WebTheme.primaryGreen),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo(WebProfileController controller) {
    final userData = controller.userData;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WebTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildInfoRow(
            Icons.person_outline,
            'Full Name',
            userData['fullName'] ?? userData['name'] ?? 'N/A',
          ),
          const Divider(height: 32),
          _buildInfoRow(
            Icons.phone_outlined,
            'Phone Number',
            userData['phone'] ?? 'Not set',
          ),
          const Divider(height: 32),
          _buildInfoRow(
            Icons.description_outlined,
            'About',
            userData['about'] ?? 'No bio available.',
          ),
          const Divider(height: 32),
          _buildInfoRow(
            Icons.school_outlined,
            'Department',
            userData['department'] ?? 'Not set',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: WebTheme.primaryGreen),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: WebTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: WebTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountStats(WebProfileController controller) {
    final userData = controller.userData;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WebTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Stats',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildStatCard(Icons.eco, 'Trees Planted', '3', Colors.green),
          const SizedBox(height: 16),
          _buildStatCard(
            Icons.star,
            'Total Points',
            '${userData['points'] ?? 0}',
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WebProfileController controller) {
    showDialog(
      context: context,
      builder: (context) => _WebEditProfileDialog(controller: controller),
    );
  }
}

class _WebEditProfileDialog extends StatelessWidget {
  final WebProfileController controller;

  const _WebEditProfileDialog({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Profile',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              'Full Name',
              controller.nameController,
              Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Phone Number',
              controller.phoneController,
              Icons.phone_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'About',
              controller.aboutController,
              Icons.info_outline,
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: WebTheme.textSecondary),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    await controller.saveEditedData();
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WebTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController textController,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: WebTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: textController,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: WebTheme.primaryGreen, size: 20),
            filled: true,
            fillColor: WebTheme.backgroundLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: WebTheme.primaryGreen),
            ),
          ),
        ),
      ],
    );
  }
}
