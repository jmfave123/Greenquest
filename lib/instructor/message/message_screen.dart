import 'package:flutter/material.dart';
import '../../shared/instructor/instructor_appbar.dart';
import '../../shared/instructor/instructor_sidebar.dart';
import '../../shared/instructor/instructor_navigation_constants.dart';
import 'package:get/get.dart';

class InstructorMessageScreen extends StatefulWidget {
  final Map<String, dynamic> student;
  const InstructorMessageScreen({Key? key, required this.student})
    : super(key: key);

  @override
  State<InstructorMessageScreen> createState() =>
      _InstructorMessageScreenState();
}

class _InstructorMessageScreenState extends State<InstructorMessageScreen> {
  InstructorNavigationItem _selectedItem = InstructorNavigationItem.messages;
  final List<Map<String, dynamic>> messages = [
    {
      'from': 'student',
      'text':
          'Hi Ms. Thompson, I have a question about the homework assignment.',
      'time': '10:30 AM',
    },
    {
      'from': 'instructor',
      'text': 'Of course! What specifically are you having trouble with?',
      'time': '10:32 AM',
    },
    {
      'from': 'student',
      'text':
          'I\'m stuck on problem 15. I don\'t understand how to solve for x when there are two variables.',
      'time': '10:36 AM',
    },
    {
      'from': 'instructor',
      'text':
          'Great question! When you have two variables, you need to use substitution or elimination method. Let me walk you through it step by step.',
      'time': '10:37 AM',
    },
  ];
  final TextEditingController _controller = TextEditingController();

  void _onNavigationSelect(InstructorNavigationItem item) {
    setState(() => _selectedItem = item);
    String route = InstructorNavigationHelper.getRoute(item);
    Get.offAllNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
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
                const InstructorAppBar(instructorName: 'Mia Castro'),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios_new,
                                size: 22,
                              ),
                              onPressed: () => Get.back(),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Message',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 32,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Manage your classroom communications',
                          style: TextStyle(color: Colors.black38, fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: AssetImage(student['image']),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        student['status'],
                                        style: TextStyle(
                                          color:
                                              student['online']
                                                  ? const Color(0xFF22C55E)
                                                  : Colors.black38,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (student['online'])
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 6,
                                          ),
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
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: 18,
                            ),
                            child: ListView(
                              children: [
                                ...messages.map((msg) {
                                  final isMe = msg['from'] == 'instructor';
                                  return Align(
                                    alignment:
                                        isMe
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            isMe
                                                ? CrossAxisAlignment.end
                                                : CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            constraints: const BoxConstraints(
                                              maxWidth: 420,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 18,
                                              vertical: 14,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  isMe
                                                      ? const Color(0xFF22C55E)
                                                      : const Color(0xFFF3F4F6),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              msg['text'],
                                              style: TextStyle(
                                                color:
                                                    isMe
                                                        ? Colors.white
                                                        : Colors.black87,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            msg['time'],
                                            style: TextStyle(
                                              color:
                                                  isMe
                                                      ? const Color(0xFF22C55E)
                                                      : Colors.black38,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.only(left: 10),
                                    hintText: 'Type your message...',
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(
                                      color: Color(0xFFBDBDBD),
                                      fontSize: 15,
                                    ),
                                  ),
                                  style: const TextStyle(fontSize: 15),
                                  cursorColor: Colors.black54,
                                ),
                              ),
                              IconButton(
                                icon: Image.asset(
                                  'assets/icons/Vector (8).png',
                                  width: 22,
                                  color: Color(0xFFBDBDBD),
                                ),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: Image.asset(
                                  'assets/icons/akar-icons_send.png',
                                  width: 22,
                                  color: const Color(0xFF22C55E),
                                ),
                                onPressed: () {},
                              ),
                            ],
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
