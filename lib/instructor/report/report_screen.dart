import 'package:flutter/material.dart';
import '../../shared/instructor/instructor_appbar.dart';
import '../../shared/instructor/instructor_sidebar.dart';

class InstructorReportScreen extends StatefulWidget {
  const InstructorReportScreen({Key? key}) : super(key: key);

  @override
  State<InstructorReportScreen> createState() => _InstructorReportScreenState();
}

class _InstructorReportScreenState extends State<InstructorReportScreen> {
  int _sidebarIndex = 6; // Reports

  void _onSidebarSelect(int idx) {
    setState(() => _sidebarIndex = idx);
    if (idx == 0) {
      Navigator.of(context).pushReplacementNamed('/instructor-dashboard');
    } else if (idx == 6) {
      // Already on reports
    }
  }

  final List<Map<String, dynamic>> classes = [
    {
      'name': 'BSIT- 1B',
      'desc': 'Bachelor of Science in Information Technology',
      'students': 25,
      'active': true,
    },
    {
      'name': 'BFPT- 1A',
      'desc': 'Bachelor of Food Processing Technology',
      'students': 25,
      'active': true,
    },
    {
      'name': 'ICT- 1C',
      'desc': 'Information and Communication Technology (ICT)',
      'students': 25,
      'active': true,
    },
    {
      'name': 'IA- 1D',
      'desc': 'Industrial Arts',
      'students': 25,
      'active': true,
    },
    {
      'name': 'ICT- 1C',
      'desc': 'Information and Communication Technology (ICT)Information and Communication Technology (ICT)',
      'students': 25,
      'active': true,
    },
    {
      'name': 'IA- 1D',
      'desc': 'Industrial Arts',
      'students': 25,
      'active': true,
    },
  ];

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
                        const Text('Reports', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32)),
                        const SizedBox(height: 6),
                        const Text('Manage your classes  and track environmental impact through education', style: TextStyle(color: Colors.black38, fontSize: 16)),
                        const SizedBox(height: 32),
                        Expanded(
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                              childAspectRatio: 1.9,
                            ),
                            itemCount: classes.length,
                            itemBuilder: (context, i) {
                              final c = classes[i];
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
                                ),
                                padding: const EdgeInsets.all(28),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28)),
                                    const SizedBox(height: 5),
                                   Text(c['desc'],style: const TextStyle(color: Colors.black54,
                                    fontSize: 15),maxLines: 1,overflow: TextOverflow.ellipsis,),
                                    const SizedBox(height: 15),
                                    Row(
                                      children: [
                                        const Icon(Icons.people_outline, size: 20, color: Colors.black54),
                                        const SizedBox(width: 6),
                                        Text('${c['students']} Students', style: const TextStyle(fontSize: 15)),
                                        const Spacer(),
                                        const Icon(Icons.circle, size: 12, color: Color(0xFF34A853)),
                                        const SizedBox(width: 4),
                                        const Text('Active', style: TextStyle(color: Color(0xFF34A853), fontSize: 13)),
                                      ],
                                    ),
                                    const SizedBox(height: 15),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF34A853),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).pushReplacementNamed('/instructor-class-report');
                                        },
                                        child: const Text('Manage Class', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
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