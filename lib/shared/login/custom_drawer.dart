import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenquest/components/snackbarUtils.dart';
import 'package:greenquest/user/auth/auth_controller.dart';
import '../../../user/materials/materials_list_screen.dart';
import '../../../user/profile/profile_screen.dart';
import '../../../user/home_screen.dart';
import '../../../user/message/message_list_screen.dart';
import '../../../user/leaderboard/leaderboard_screen.dart';

class CustomDrawer extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onSelect;
  CustomDrawer({required this.selectedIndex, required this.onSelect, Key? key})
    : super(key: key);

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  final authController = Get.put(AuthController());
  final drawerItems = const [
    {
      'label': 'Overview',
      'icon': 'assets/icons/material-symbols-light_home-rounded.png',
    },
    {'label': 'Message', 'icon': 'assets/icons/mage_message-fill.png'},
    {
      'label': 'Leaderboard',
      'icon': 'assets/icons/material-symbols-light_leaderboard-rounded.png',
    },
    {'label': 'Materials', 'icon': 'assets/icons/mage_book-fill.png'},
    {'label': 'Profile', 'icon': 'assets/icons/mingcute_user-3-fill.png'},
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Center(
              child: Image.asset('assets/images/image 297.png', height: 150),
            ),
            const SizedBox(height: 24),
            ...List.generate(
              drawerItems.length,
              (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Material(
                  color:
                      widget.selectedIndex == i
                          ? const Color(0xFF34A853)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      widget.onSelect(i);
                      if (i == 0) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                        );
                      }
                      if (i == 1) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MessageListScreen(),
                          ),
                        );
                      }
                      if (i == 2) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LeaderboardScreen(),
                          ),
                        );
                      }
                      if (i == 3) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MaterialsListScreen(),
                          ),
                        );
                      }
                      if (i == 4) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            child: Image.asset(
                              drawerItems[i]['icon']!,
                              width: 24,
                              color:
                                  widget.selectedIndex == i
                                      ? Colors.white
                                      : Colors.grey[400],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            drawerItems[i]['label']!,
                            style: TextStyle(
                              color:
                                  widget.selectedIndex == i
                                      ? Colors.white
                                      : Colors.grey[500],
                              fontWeight:
                                  widget.selectedIndex == i
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.black45),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.black45),
              ),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        backgroundColor: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 32,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Confirm Logout',
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
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed:
                                          () =>
                                              Navigator.of(context).pop(false),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: Color(0xFF34A853),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                      ),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: Color(0xFF34A853),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed:
                                          () => Navigator.of(context).pop(true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF34A853,
                                        ),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                      ),
                                      child: const Text(
                                        'Logout',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                );

                if (confirmed == true) {
                  // Close drawer first
                  Navigator.of(context).pop();

                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (context) => const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF34A853),
                            ),
                          ),
                        ),
                  );

                  try {
                    // Perform logout
                    await authController.logout();

                    // Close loading dialog
                    Navigator.of(context).pop();

                    // Show success message
                    showSuccessSnackBar(
                      context,
                      message: 'Logged out successfully',
                    );

                    // Navigate to login screen
                    Get.offAllNamed('/login_app');
                  } catch (e) {
                    // Close loading dialog
                    Navigator.of(context).pop();

                    // Show error message
                    showErrorSnackBar(
                      context,
                      message: 'Logout failed. Please try again.',
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
