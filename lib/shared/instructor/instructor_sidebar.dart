import 'package:flutter/material.dart';

class InstructorSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  const InstructorSidebar({Key? key, required this.selectedIndex, required this.onItemSelected}) : super(key: key);

  @override
  State<InstructorSidebar> createState() => _InstructorSidebarState();
}

class _InstructorSidebarState extends State<InstructorSidebar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }

  void _handleSelect(int idx) {
    setState(() => _selectedIndex = idx);
    widget.onItemSelected(idx);
    // Navigation for dashboard, messages, announcements, and planted trees
    if (idx == 0) {
      Navigator.of(context).pushReplacementNamed('/instructor-dashboard');
    } else if (idx == 1) {
      Navigator.of(context).pushReplacementNamed('/instructor-create');
    } else if (idx == 2) {
      Navigator.of(context).pushReplacementNamed('/instructor-class');
    } else if (idx == 3) {
      Navigator.of(context).pushReplacementNamed('/instructor-message-list');
    } else if (idx == 4) {
      if (ModalRoute.of(context)?.settings.name != '/instructor-announcement') {
        Navigator.of(context).pushReplacementNamed('/instructor-announcement');
      }
    } else if (idx == 5) {
      if (ModalRoute.of(context)?.settings.name != '/instructor-planted-trees') {
        Navigator.of(context).pushReplacementNamed('/instructor-planted-trees');
      }
    } else if (idx == 6) {
      if (ModalRoute.of(context)?.settings.name != '/instructor-report') {
        Navigator.of(context).pushReplacementNamed('/instructor-report');
      }
    } else if (idx == -1) {
      if (ModalRoute.of(context)?.settings.name != '/instructor-profile') {
        Navigator.of(context).pushReplacementNamed('/instructor-profile');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'label': 'Dashboard',
        'icon': 'assets/instructor/icons/material-symbols-light_home-outline-rounded.png',
      },
      {
        'label': 'Create',
        'icon': 'assets/instructor/icons/add.png',
      },
    ];
    final management = [
      {
        'label': 'Class',
        'icon': 'assets/instructor/icons/mage_users.png',
      },
      {
        'label': 'Messages',
        'icon': 'assets/instructor/icons/mage_message.png',
      },
      {
        'label': 'Announcements',
        'icon': 'assets/instructor/icons/fluent_speaker-1-24-regular.png',
      },
      {
        'label': 'Planted Trees',
        'icon': 'assets/instructor/icons/lucide_trees.png',
      },
      {
        'label': 'Reports',
        'icon': 'assets/instructor/icons/fluent_document-20-regular.png',
      },
    ];
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Row(
              children: [
                Image.asset('assets/instructor/images/image 331.png', height: 44),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('GreenQuest', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    Text('Instructor Portal', style: TextStyle(color: Colors.black54, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text('MAIN MENU', style: TextStyle(color: Colors.black38, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
          ),
          const SizedBox(height: 10),
          ...List.generate(items.length, (i) {
            final selected = _selectedIndex == i;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _handleSelect(i),
                child: Container(
                  decoration: selected
                      ? BoxDecoration(
                          color: const Color(0xFF34A853),
                          borderRadius: BorderRadius.circular(8),
                        )
                      : null,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Row(
                    children: [
                      Image.asset(items[i]['icon']!, width: 22, color: selected ? Colors.white : Colors.black),
                      const SizedBox(width: 12),
                      Text(
                        items[i]['label']!,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 18),
          const Divider(indent: 24, endIndent: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text('MANAGEMENT', style: TextStyle(color: Colors.black38, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
          ),
          ...List.generate(management.length, (i) {
            final idx = i + items.length;
            final selected = _selectedIndex == idx;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _handleSelect(idx),
                child: Container(
                  decoration: selected
                      ? BoxDecoration(
                          color: const Color(0xFF34A853),
                          borderRadius: BorderRadius.circular(8),
                        )
                      : null,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Row(
                    children: [
                      Image.asset(management[i]['icon']!, width: 22, color: selected ? Colors.white : Colors.black),
                      const SizedBox(width: 12),
                      Text(
                        management[i]['label']!,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _handleSelect(-1),
              child: Container(
                decoration: _selectedIndex == -1
                    ? BoxDecoration(
                        color: const Color(0xFF34A853),
                        borderRadius: BorderRadius.circular(8),
                      )
                    : null,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Row(
                  children: [
                    Image.asset('assets/instructor/icons/mage_user.png', width: 22, color: _selectedIndex == -1 ? Colors.white : Colors.black),
                    const SizedBox(width: 12),
                    Text('Profile', style: TextStyle(color: _selectedIndex == -1 ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () async {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('Logout Confirmation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
                        const SizedBox(height: 10),
                        const Text(
                          'Are you sure you want to do logout?',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54, fontSize: 15),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF34A853),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                              ),
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 16),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black54,
                                side: const BorderSide(color: Color(0xFF34A853)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                              ),
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
                if (shouldLogout == true) {
                  _handleSelect(-2);
                }
              },
              child: Row(
                children: [
                  Image.asset('assets/instructor/icons/ic_twotone-logout.png', width: 22, color: Colors.red),
                  const SizedBox(width: 12),
                  const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}
