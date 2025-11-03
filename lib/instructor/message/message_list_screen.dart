import 'package:flutter/material.dart';
import '../../shared/instructor/instructor_appbar.dart';
import '../../shared/instructor/instructor_sidebar.dart';
import '../../shared/instructor/instructor_navigation_constants.dart';
import '../instructor_dashboard_controller.dart';
import 'message_screen.dart';
import 'package:get/get.dart';
import '../../shared/services/message_service.dart';

class InstructorMessageListScreen extends StatefulWidget {
  const InstructorMessageListScreen({super.key});

  @override
  State<InstructorMessageListScreen> createState() =>
      _InstructorMessageListScreenState();
}

class _InstructorMessageListScreenState
    extends State<InstructorMessageListScreen> {
  InstructorNavigationItem _selectedItem = InstructorNavigationItem.messages;
  final InstructorController instructorController = Get.put(
    InstructorController(),
  );
  String _search = '';

  void _onNavigationSelect(InstructorNavigationItem item) {
    setState(() => _selectedItem = item);
    String route = InstructorNavigationHelper.getRoute(item);
    Navigator.of(context).pushNamed(route);
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'ST';
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0].toUpperCase()}${words[words.length - 1][0].toUpperCase()}';
    } else if (words.length == 1) {
      return words[0].length >= 2
          ? words[0].substring(0, 2).toUpperCase()
          : words[0][0].toUpperCase();
    }
    return 'ST';
  }

  Widget _buildStudentItem(Map<String, dynamic> student) {
    final hasImage =
        student['image'] != null && (student['image'] as String).isNotEmpty;

    return InkWell(
      onTap: () {
        // Mark messages as read when clicking on student
        MessageService.markMessagesAsRead(student['id']);
        Get.to(() => InstructorMessageScreen(student: student));
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 200),
        child: Row(
          children: [
            hasImage
                ? CircleAvatar(
                  radius: 26,
                  backgroundImage: NetworkImage(student['image']),
                  backgroundColor: const Color(0xFF22C55E),
                )
                : CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFF22C55E),
                  child: Text(
                    _getInitials(student['name']),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    student['lastMessage'] ?? '',
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if ((student['unreadCount'] ?? 0) > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3D00),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${student['unreadCount']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          InstructorSidebar(
            selectedItem: _selectedItem,
            onItemSelected: _onNavigationSelect,
          ),
          Expanded(
            child: Column(
              children: [
                Obx(
                  () => InstructorAppBar(
                    instructorName: instructorController.instructorName.value,
                    instructorRole: 'Instructor',
                    profileImageUrl: instructorController.profileImageUrl.value,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Message',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Manage your classroom communications',
                          style: TextStyle(color: Colors.black38, fontSize: 16),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'STUDENTS',
                          style: TextStyle(
                            color: Colors.black38,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1,
                          ),
                        ),
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
                              Image.asset(
                                'assets/icons/akar-icons_search.png',
                                width: 20,
                                color: const Color(0xFFBDBDBD),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(
                                    hintText: 'Search students',
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(
                                      color: Color(0xFFBDBDBD),
                                      fontSize: 15,
                                    ),
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
                          child: StreamBuilder<List<Map<String, dynamic>>>(
                            stream: MessageService.getStudentsWithMessages(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF22C55E),
                                  ),
                                );
                              }

                              if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    'Error loading messages',
                                    style: TextStyle(
                                      color: Colors.red.shade400,
                                    ),
                                  ),
                                );
                              }

                              final students = snapshot.data ?? [];
                              final filtered =
                                  students
                                      .where(
                                        (s) => s['name'].toLowerCase().contains(
                                          _search.toLowerCase(),
                                        ),
                                      )
                                      .toList();

                              if (filtered.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.message_outlined,
                                        size: 64,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _search.isEmpty
                                            ? 'No messages yet'
                                            : 'No matching students',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _search.isEmpty
                                            ? 'Messages from your students will appear here'
                                            : 'Try a different search term',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder:
                                    (_, __) => const SizedBox(height: 18),
                                itemBuilder: (context, i) {
                                  final s = filtered[i];
                                  return _buildStudentItem(s);
                                },
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
