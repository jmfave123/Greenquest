import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/web_theme.dart';
import '../../config/web_breakpoints.dart';
import '../../config/web_routes.dart';

/// Web sidebar navigation for desktop layout
/// Displays navigation menu items with icons and labels

class WebSidebar extends StatefulWidget {
  final String currentRoute;

  const WebSidebar({super.key, required this.currentRoute});

  @override
  State<WebSidebar> createState() => _WebSidebarState();
}

class _WebSidebarState extends State<WebSidebar> {
  bool isCollapsed = false;

  final List<SidebarItem> menuItems = [
    SidebarItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
      route: WebRoutes.home,
    ),
    SidebarItem(
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment,
      label: 'Activities',
      route: WebRoutes.activities,
    ),
    SidebarItem(
      icon: Icons.task_outlined,
      activeIcon: Icons.task,
      label: 'Assignments',
      route: WebRoutes.assignments,
    ),
    SidebarItem(
      icon: Icons.quiz_outlined,
      activeIcon: Icons.quiz,
      label: 'Quizzes',
      route: WebRoutes.quizzes,
    ),
    SidebarItem(
      icon: Icons.leaderboard_outlined,
      activeIcon: Icons.leaderboard,
      label: 'Leaderboard',
      route: WebRoutes.leaderboard,
    ),
    SidebarItem(
      icon: Icons.book_outlined,
      activeIcon: Icons.book,
      label: 'Materials',
      route: WebRoutes.materials,
    ),
    SidebarItem(
      icon: Icons.message_outlined,
      activeIcon: Icons.message,
      label: 'Messages',
      route: WebRoutes.messages,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width:
          isCollapsed
              ? WebBreakpoints.sidebarCollapsedWidth
              : WebBreakpoints.sidebarWidth,
      decoration: const BoxDecoration(
        color: WebTheme.backgroundWhite,
        border: Border(
          right: BorderSide(color: WebTheme.borderLight, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Collapse button
          _buildCollapseButton(),

          const SizedBox(height: 16),

          // Menu items - scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children:
                    menuItems.map((item) => _buildMenuItem(item)).toList(),
              ),
            ),
          ),

          // Profile section at bottom
          _buildProfileSection(),
        ],
      ),
    );
  }

  Widget _buildCollapseButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: IconButton(
        icon: Icon(
          isCollapsed ? Icons.chevron_right : Icons.chevron_left,
          color: WebTheme.textSecondary,
        ),
        onPressed: () {
          setState(() {
            isCollapsed = !isCollapsed;
          });
        },
        tooltip: isCollapsed ? 'Expand sidebar' : 'Collapse sidebar',
      ),
    );
  }

  Widget _buildMenuItem(SidebarItem item) {
    final isActive = widget.currentRoute == item.route;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (item.route.isNotEmpty) {
              Get.toNamed(item.route);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? WebTheme.hoverGreen : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  color:
                      isActive ? WebTheme.primaryGreen : WebTheme.textSecondary,
                  size: 24,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        color:
                            isActive
                                ? WebTheme.primaryGreen
                                : WebTheme.textPrimary,
                        fontSize: 15,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: WebTheme.borderLight, width: 1)),
      ),
      child: InkWell(
        onTap: () {
          Get.toNamed(WebRoutes.profile);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: WebTheme.primaryGreen,
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Student',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: WebTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'View Profile',
                        style: TextStyle(
                          fontSize: 11,
                          color: WebTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Sidebar menu item model
class SidebarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  SidebarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}
