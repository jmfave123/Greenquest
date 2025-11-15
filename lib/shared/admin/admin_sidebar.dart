import 'package:flutter/material.dart';
import 'admin_navigation_constants.dart';
import '../widgets/safe_asset_image.dart';

// Data class for navigation items
class AdminNavigationItemData {
  final String label;
  final String iconPath;
  final AdminNavigationItem item;
  final String route;

  const AdminNavigationItemData({
    required this.label,
    required this.iconPath,
    required this.item,
    required this.route,
  });
}

class AdminSidebar extends StatefulWidget {
  final AdminNavigationItem selectedItem;
  final Function(AdminNavigationItem) onItemSelected;

  const AdminSidebar({
    super.key,
    required this.selectedItem,
    required this.onItemSelected,
  });

  @override
  State<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar> {
  // Navigation items configuration - easy to maintain and modify
  static const List<AdminNavigationItemData> _mainMenuItems = [
    AdminNavigationItemData(
      label: 'Dashboard',
      iconPath: 'assets/admin_icons/fluent_hat-graduation-12-regular.png',
      item: AdminNavigationItem.dashboard,
      route: '/admin-dashboard',
    ),
  ];

  static const List<AdminNavigationItemData> _managementItems = [
    AdminNavigationItemData(
      label: 'Manage Instructors',
      iconPath: 'assets/admin_icons/lucide_users-round.png',
      item: AdminNavigationItem.manageInstructors,
      route: '/admin-manage-instructors',
    ),
    AdminNavigationItemData(
      label: 'Manage Departments',
      iconPath: 'assets/admin_icons/fluent_hat-graduation-12-regular.png',
      item: AdminNavigationItem.manageDepartments,
      route: '/admin-manage-departments',
    ),
    AdminNavigationItemData(
      label: 'Manage Classes',
      iconPath: 'assets/admin_icons/lucide_users-round.png',
      item: AdminNavigationItem.manageClasses,
      route: '/admin-manage-classes',
    ),
    AdminNavigationItemData(
      label: 'Manage Trees',
      iconPath: 'assets/instructor/icons/lucide_trees.png',
      item: AdminNavigationItem.manageTrees,
      route: '/admin-manage-trees',
    ),
  ];

  void _handleNavigationSelect(AdminNavigationItem item) {
    widget.onItemSelected(item);
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(Icons.logout, color: Colors.red, size: 30),
              ),
              const SizedBox(height: 20),

              const Text(
                'Logout Confirmation',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Are you sure you want to logout?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 15),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/login', (route) => false);
                    },
                    child: const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black54,
                      side: const BorderSide(color: Color(0xFF34A853)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with logo and title
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade100, width: 1),
                ),
              ),
              child: Row(
                children: [
                  const SafeAssetImage(
                    assetPath: 'assets/images/GreenQuest Logo.jpg',
                    width: 72,
                    height: 72,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Panel',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'NSTP Management',
                          style: TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Main Menu Section
            _buildSectionHeader('MAIN MENU'),
            const SizedBox(height: 8),
            ..._mainMenuItems.map(
              (item) =>
                  _buildNavigationItem(item, widget.selectedItem == item.item),
            ),

            const SizedBox(height: 24),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Divider(color: Colors.grey.shade200, height: 1),
            ),

            const SizedBox(height: 24),

            // Management Section
            _buildSectionHeader('MANAGEMENT'),
            const SizedBox(height: 8),
            ..._managementItems.map(
              (item) =>
                  _buildNavigationItem(item, widget.selectedItem == item.item),
            ),

            const SizedBox(height: 24),

            // Logout Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _handleLogout,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        SafeAssetImage(
                          assetPath:
                              'assets/admin_icons/solar_user-cross-broken.png',
                          width: 22,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationItem(AdminNavigationItemData item, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _handleNavigationSelect(item.item),
          child: Container(
            decoration:
                isSelected
                    ? BoxDecoration(
                      color: const Color(0xFF34A853),
                      borderRadius: BorderRadius.circular(8),
                    )
                    : null,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SafeAssetImage(
                  assetPath: item.iconPath,
                  width: 22,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.black54,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
