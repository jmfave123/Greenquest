import 'package:flutter/material.dart';
import '../../shared/instructor/instructor_appbar.dart';
import '../../shared/instructor/instructor_sidebar.dart';

class InstructorAnnouncementScreen extends StatefulWidget {
  const InstructorAnnouncementScreen({Key? key}) : super(key: key);

  @override
  State<InstructorAnnouncementScreen> createState() => _InstructorAnnouncementScreenState();
}

class _InstructorAnnouncementScreenState extends State<InstructorAnnouncementScreen> {
  int _sidebarIndex = 4; // Announcements
  bool _showCreate = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _pinToTop = false;
  bool _urgent = false;

  List<Map<String, dynamic>> announcements = [
    {
      'title': 'Quiz Tomorrow',
      'content': 'Study Material 1-8 about the Sustainable Development',
      'date': '7/16/2025',
      'views': 22,
      'pinned': true,
      'urgent': false,
    },
    {
      'title': 'Clean up drive',
      'content': 'To all NSTP students: There will be a General Orientation on:\n📅 July 20, 2025 (Saturday)\n🕒 9:00 AM – 12:00 NN\n📍 University Covered Court Attendance is mandatory. Bring your ID, pen, and notebook. Important guidelines and project details will be discussed. Be on time. See you there!',
      'date': '7/16/2025',
      'views': 10,
      'pinned': false,
      'urgent': true,
    },
    {
      'title': 'Tree Planting',
      'content': 'To all NSTP students: There will be a Tree Planting  Event:\n📅 August 10, 2025 (Monday)\n🕒 9:00 AM – 5:00 PM\n📍 University Covered Court Attendance is mandatory. Bring your ID, extra shirt. Important guidelines and project details will be discussed. Be on time. See you there!',
      'date': '7/16/2025',
      'views': 0,
      'pinned': false,
      'urgent': false,
    },
  ];

  void _onSidebarSelect(int idx) {
    setState(() => _sidebarIndex = idx);
    if (idx == 0) {
      Navigator.of(context).pushReplacementNamed('/instructor-dashboard');
    } else if (idx == 3) {
      Navigator.of(context).pushReplacementNamed('/instructor-message-list');
    } else if (idx == 4) {
      // Already on announcements
    }
  }

  void _showCreateAnnouncement() {
    setState(() => _showCreate = true);
  }

  void _cancelCreate() {
    setState(() => _showCreate = false);
    _titleController.clear();
    _contentController.clear();
    _pinToTop = false;
    _urgent = false;
  }

  void _postAnnouncement() {
    setState(() {
      announcements.insert(0, {
        'title': _titleController.text,
        'content': _contentController.text,
        'date': '7/16/2025',
        'views': 0,
        'pinned': _pinToTop,
        'urgent': _urgent,
      });
      _showCreate = false;
      _titleController.clear();
      _contentController.clear();
      _pinToTop = false;
      _urgent = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  Colors.white,
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
                        Row(
                          children: [
                            const Text('Announcements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32)),
                            const Spacer(),
                            if (!_showCreate)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF22C55E),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                                ),
                                onPressed: _showCreateAnnouncement,
                                icon: const Icon(Icons.add, color: Colors.white),
                                label: const Text('New Announcement', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text('Share important updates with your students', style: TextStyle(color: Colors.black38, fontSize: 16)),
                        const SizedBox(height: 24),
                        if (_showCreate)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFB),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Create  New Announcement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                                const SizedBox(height: 18),
                                const Text('Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _titleController,
                                  cursorColor: Colors.black54,
                                  decoration: InputDecoration(
                                    hintText: 'Enter announcement title...',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFF34A853), width: 2),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                const Text('Content', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _contentController,
                                  maxLines: 4,
                                  cursorColor: Colors.black54,
                                  decoration: InputDecoration(
                                    hintText: 'Write your announcement here...',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFF34A853), width: 2),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    Switch(
                                      value: _pinToTop,
                                      onChanged: (v) => setState(() => _pinToTop = v),
                                      activeColor: const Color(0xFF34A853),
                                    ),
                                    const Text('Pin to top', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(width: 24),
                                    Switch(
                                      value: _urgent,
                                      onChanged: (v) => setState(() => _urgent = v),
                                      activeColor: Colors.red,
                                    ),
                                    const Text('Mark as urgent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF34A853),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                      ),
                                      onPressed: _postAnnouncement,
                                      child: const Text('Post Announcement', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 18),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.black,
                                        side: const BorderSide(color: Color(0xFF34A853)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                      ),
                                      onPressed: _cancelCreate,
                                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: ListView.separated(
                            itemCount: announcements.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 18),
                            itemBuilder: (context, i) {
                              final a = announcements[i];
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: a['pinned'] ? const Color(0xFFF8FAFB) : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (a['pinned'])
                                          const Icon(Icons.push_pin, color: Color(0xFF22C55E), size: 22),
                                        Text(a['title'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: a['pinned'] ? const Color(0xFF22C55E) : Colors.black)),
                                        if (a['urgent'])
                                          Container(
                                            margin: const EdgeInsets.only(left: 10),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFE5E5),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text('Urgent', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(a['content'], style: const TextStyle(fontSize: 15)),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Text(a['date'], style: const TextStyle(color: Colors.black38, fontSize: 14)),
                                        const SizedBox(width: 18),
                                        const Icon(Icons.visibility, size: 18, color: Colors.black26),
                                        const SizedBox(width: 4),
                                        Text('${a['views']} views', style: const TextStyle(color: Colors.black38, fontSize: 14)),
                                      ],
                                    ),
                                  ],
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