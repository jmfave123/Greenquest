import 'package:flutter/material.dart';
import '../../shared/instructor/instructor_appbar.dart';
import '../../shared/instructor/instructor_sidebar.dart';
import 'message_screen.dart';
import 'package:get/get.dart';

class InstructorMessageListScreen extends StatefulWidget {
  const InstructorMessageListScreen({Key? key}) : super(key: key);

  @override
  State<InstructorMessageListScreen> createState() => _InstructorMessageListScreenState();
}

class _InstructorMessageListScreenState extends State<InstructorMessageListScreen> {
  int _sidebarIndex = 3; // Messages
  final List<Map<String, dynamic>> students = [
    {
      'name': 'Mary Ann',
      'status': 'Online',
      'image': 'assets/images/Photo (4).png',
      'unread': 1,
      'online': true,
    },
    {
      'name': 'Jane Ame',
      'status': 'Offline',
      'image': 'assets/images/Photo (1).png',
      'unread': 0,
      'online': false,
    },
    {
      'name': 'Princess',
      'status': 'Online',
      'image': 'assets/images/Photo (2).png',
      'unread': 4,
      'online': true,
    },
    {
      'name': 'Sophia',
      'status': 'Online',
      'image': 'assets/images/Photo.png',
      'unread': 3,
      'online': true,
    },
    {
      'name': 'Rose Anne',
      'status': 'Online',
      'image': 'assets/images/Photo (3).png',
      'unread': 0,
      'online': true,
    },
    {
      'name': 'Bryan David',
      'status': 'Offline',
      'image': 'assets/images/image 319.png',
      'unread': 2,
      'online': false,
    },
    {
      'name': 'Janna Mae',
      'status': 'Offline',
      'image': 'assets/images/image 321.png',
      'unread': 0,
      'online': false,
    },
  ];
  String _search = '';

  void _onSidebarSelect(int idx) {
    setState(() => _sidebarIndex = idx);
    if (idx == 0) {
      Get.offAllNamed('/instructor-dashboard');
    } else if (idx == 3) {
      // Already on messages
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = students.where((s) => s['name'].toLowerCase().contains(_search.toLowerCase())).toList();
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          InstructorSidebar(selectedIndex: _sidebarIndex, onItemSelected: _onSidebarSelect),
          Expanded(
            child: Column(
              children: [
                const InstructorAppBar(instructorName: 'Mia Castro'),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Message', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32)),
                        const SizedBox(height: 6),
                        const Text('Manage your classroom communications', style: TextStyle(color: Colors.black38, fontSize: 16)),
                        const SizedBox(height: 32),
                        const Text('STUDENTS', style: TextStyle(color: Colors.black38, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
                        const SizedBox(height: 10),
                        Container(
                          width: 340,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              Image.asset('assets/icons/akar-icons_search.png', width: 20, color: const Color(0xFFBDBDBD)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(
                                    hintText: 'Search students',
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(color: Color(0xFFBDBDBD), fontSize: 15),
                                  ),
                                  style: const TextStyle(fontSize: 15),
                                  cursorColor: Colors.black54,
                                  onChanged: (v) => setState(() => _search = v),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 18),
                            itemBuilder: (context, i) {
                              final s = filtered[i];
                              return InkWell(
                                onTap: () {
                                  Get.to(() => InstructorMessageScreen(student: s));
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 200),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 26,
                                        backgroundImage: AssetImage(s['image']),
                                      ),
                                      const SizedBox(width: 16),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                          Row(
                                            children: [
                                              Text(s['status'], style: TextStyle(color: s['online'] ? const Color(0xFF22C55E) : Colors.black38, fontSize: 13)),
                                              if (s['online'])
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 6),
                                                  child: Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: const BoxDecoration(
                                                      color: Color(0xFF22C55E),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      if (s['unread'] > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF3D00),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text('${s['unread']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 