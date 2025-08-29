import 'package:flutter/material.dart';
import '../../shared/instructor/instructor_appbar.dart';
import '../../shared/instructor/instructor_sidebar.dart';

class InstructorProfileScreen extends StatefulWidget {
  const InstructorProfileScreen({Key? key}) : super(key: key);

  @override
  State<InstructorProfileScreen> createState() => _InstructorProfileScreenState();
}

class _InstructorProfileScreenState extends State<InstructorProfileScreen> {
  int _sidebarIndex = -1; // Profile

  void _onSidebarSelect(int idx) {
    setState(() => _sidebarIndex = idx);
    if (idx == 0) {
      Navigator.of(context).pushReplacementNamed('/instructor-dashboard');
    } else if (idx == -1) {
      // Already on profile
    }
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
                        const Text('Instructor Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32)),
                        const SizedBox(height: 6),
                        const Text('Manage your professional information', style: TextStyle(color: Colors.black38, fontSize: 16)),
                        const SizedBox(height: 32),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const CircleAvatar(
                                    radius: 48,
                                    backgroundImage: AssetImage('assets/images/Photo (4).png'),
                                  ),
                                  const SizedBox(height: 18),
                                  const Text('Mia Castro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                                  const SizedBox(height: 18),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: const [
                                      Icon(Icons.email_outlined, size: 20, color: Colors.black54),
                                      SizedBox(width: 8),
                                      Text('miacastro@university.edu', style: TextStyle(fontSize: 15)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: const [
                                      Icon(Icons.phone_outlined, size: 20, color: Colors.black54),
                                      SizedBox(width: 8),
                                      Text('09357987051', style: TextStyle(fontSize: 15)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: const [
                                      Icon(Icons.calendar_today_outlined, size: 20, color: Colors.black54),
                                      SizedBox(width: 8),
                                      Text('Joined September 2021', style: TextStyle(fontSize: 15)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 32),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    side: const BorderSide(color: Color(0xFFBDBDBD)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                                  ),
                                  onPressed: () {},
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        const Text('About', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: 600, // Set desired max width
                          child: const Text(
                            'Passionate educator with over 10 years of experience in environmental science and sustainability. Dedicated to inspiring students to make positive environmental impacts through education and hands-on learning experiences.',
                            style: TextStyle(fontSize: 16),
                            textAlign: TextAlign.justify, // optional: align text nicely
                          ),
                        )

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