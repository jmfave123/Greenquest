import 'package:flutter/material.dart';

class AnnouncementDetailScreen extends StatelessWidget {
  const AnnouncementDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final announcements = [
      {
        'type': 'quiz',
        'title': 'Quiz Tomorrow',
        'desc': 'Study Material 1-8 about the Sustainable Development',
        'date': '7/16/2025',
      },
      {
        'type': 'urgent',
        'title': 'Clean up drive',
        'desc': 'To all NSTP students: There will be a General Orientation on:\n\nJuly 20, 2025 (Saturday)\n9:00 AM – 12:00 NN\nUniversity Covered Court\n\nAttendance is mandatory. Bring your ID, pen, and notebook. Important guidelines and project details will be discussed. Be on time. See you there!',
        'date': '7/8/2025',
      },
      {
        'type': 'event',
        'title': 'Tree Planting',
        'desc': 'To all NSTP students: There will be a Tree Planting Event on:\n\nJuly 20, 2025 (Monday)\n9:00 AM – 5:00 PM\nUniversity Covered Court\n\nAttendance is mandatory. Bring your ID, and extra shirt. Important guidelines and project details will be discussed. Be on time. See you there!',
        'date': '7/8/2025',
      },
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Color(0xFF34A853), width: 2),
              ),
              child: ClipOval(
                child: Image.asset('assets/images/image 297.png', height: 32, width: 32, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 10),
            const Text('GreeQuest', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: false,
      ),
      backgroundColor: const Color(0xFFF7F8FA),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: announcements.length,
        itemBuilder: (context, i) {
          final a = announcements[i];
          Color? accent;
          Widget? leading;
          Widget? trailing;
          if (a['type'] == 'quiz') {
            accent = const Color(0xFF34A853);
            leading = const Icon(Icons.emoji_events, color: Colors.white);
          } else if (a['type'] == 'urgent') {
            accent = const Color(0xFFFFE5E5);
            leading = const Icon(Icons.warning_amber_rounded, color: Colors.redAccent);
            trailing = Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Urgent', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            );
          } else {
            accent = const Color(0xFFE3F0FF);
            leading = const Icon(Icons.nature, color: Color(0xFF2886D7));
          }
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: leading,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(a['title']!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: accent == const Color(0xFF34A853) ? accent : Colors.black)),
                              if (trailing != null) ...[
                                const SizedBox(width: 8),
                                trailing,
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(a['desc']!, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(a['date']!, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 