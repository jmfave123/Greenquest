import 'package:flutter/material.dart';
import 'instructor_navigation_constants.dart';
import '../widgets/safe_asset_image.dart';

// Data class for navigation items
class NavigationItemData {
  final String label;
  final String iconPath;
  final InstructorNavigationItem item;
  final String route;

  const NavigationItemData({
    required this.label,
    required this.iconPath,
    required this.item,
    required this.route,
  });
}

class InstructorSidebar extends StatefulWidget {
  final InstructorNavigationItem selectedItem;
  final Function(InstructorNavigationItem) onItemSelected;

  const InstructorSidebar({
    Key? key,
    required this.selectedItem,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  State<InstructorSidebar> createState() => _InstructorSidebarState();
}

class _InstructorSidebarState extends State<InstructorSidebar> {
  // Navigation items configuration - easy to maintain and modify
  static const List<NavigationItemData> _mainMenuItems = [
    NavigationItemData(
      label: 'Dashboard',
      iconPath:
          'assets/instructor/icons/material-symbols-light_home-outline-rounded.png',
      item: InstructorNavigationItem.dashboard,
      route: '/instructor-dashboard',
    ),
    NavigationItemData(
      label: 'Create',
      iconPath: 'assets/instructor/icons/add.png',
      item: InstructorNavigationItem.create,
      route: '/instructor-create',
    ),
  ];

  static const List<NavigationItemData> _managementItems = [
    NavigationItemData(
      label: 'Class',
      iconPath: 'assets/instructor/icons/mage_users.png',
      item: InstructorNavigationItem.classManagement,
      route: '/instructor-class',
    ),
    NavigationItemData(
      label: 'Messages',
      iconPath: 'assets/instructor/icons/mage_message.png',
      item: InstructorNavigationItem.messages,
      route: '/instructor-message-list',
    ),
    NavigationItemData(
      label: 'Announcements',
      iconPath: 'assets/instructor/icons/fluent_speaker-1-24-regular.png',
      item: InstructorNavigationItem.announcements,
      route: '/instructor-announcement',
    ),
    NavigationItemData(
      label: 'Planted Trees',
      iconPath: 'assets/instructor/icons/lucide_trees.png',
      item: InstructorNavigationItem.plantedTrees,
      route: '/instructor-planted-trees',
    ),
    NavigationItemData(
      label: 'Reports',
      iconPath: 'assets/instructor/icons/fluent_document-20-regular.png',
      item: InstructorNavigationItem.reports,
      route: '/instructor-report',
    ),
  ];

  static const NavigationItemData _profileItem = NavigationItemData(
    label: 'Profile',
    iconPath: 'assets/instructor/icons/mage_user.png',
    item: InstructorNavigationItem.profile,
    route: '/instructor-profile',
  );

  void _handleNavigationSelect(InstructorNavigationItem item) {
    widget.onItemSelected(item);

    // Find the route for the selected item
    String? route;

    // Check main menu items
    for (final menuItem in _mainMenuItems) {
      if (menuItem.item == item) {
        route = menuItem.route;
        break;
      }
    }

    // Check management items
    if (route == null) {
      for (final menuItem in _managementItems) {
        if (menuItem.item == item) {
          route = menuItem.route;
          break;
        }
      }
    }

    // Check profile item
    if (route == null && item == _profileItem.item) {
      route = _profileItem.route;
    }

    // Navigate if route found and not already on that route
    if (route != null && ModalRoute.of(context)?.settings.name != route) {
      Navigator.of(context).pushNamed(route);
    }
  }

  void _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => _buildLogoutDialog(),
    );

    if (shouldLogout == true) {
      // Navigate to login screen
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Widget _buildLogoutDialog() {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
            child: const Icon(
              Icons.logout,
              color: Colors.red,
              size: 30,
            ),
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
            style: TextStyle(
              color: Colors.black54,
              fontSize: 15,
            ),
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
                onPressed: () => Navigator.of(context).pop(true),
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
                onPressed: () => Navigator.of(context).pop(false),
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
  }

  Widget _buildNavigationItem(NavigationItemData item, bool isSelected) {
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
                  Image.asset(
                    'assets/instructor/images/image 331.png',
                    height: 44,
                    errorBuilder:
                        (context, error, stackTrace) => Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF34A853),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.school,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'GreenQuest',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Color(0xFF34A853),
                          ),
                        ),
                        Text(
                          'Instructor Portal',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
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

            // Profile Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildNavigationItem(
                _profileItem,
                widget.selectedItem == _profileItem.item,
              ),
            ),

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
                        Icon(
                          Icons.logout_rounded,
                          size: 22,
                          color: Colors.red.shade600,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.w600,
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
}
