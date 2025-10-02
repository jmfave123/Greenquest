import 'package:flutter/material.dart';
import '../shared/admin/admin_sidebar.dart';
import '../shared/admin/admin_navigation_constants.dart';
import '../shared/widgets/safe_asset_image.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  AdminNavigationItem _selectedItem = AdminNavigationItem.dashboard;
  
  void _handleNavigationSelect(AdminNavigationItem item) {
    setState(() {
      _selectedItem = item;
    });
    String route = AdminNavigationHelper.getRoute(item);
    Navigator.of(context).pushNamed(route);
  }

  // Dummy data
  final instructors = [
    {
      'name': 'Mia Castro',
      'email': 'miacastro@university.edu',
      'department': 'NSTP Department',
      'sections': [
        {
          'name': 'National Service Training Program 1 - BSIT',
          'code': 'NSTP-1 BSIT',
          'schedule': 'MWF 7:00-8:00 AM',
          'program': 'BSIT',
          'active': 29,
          'inactive': 1,
          'students': [
            {'name': 'Bryant Carlos', 'email': 'bryantcarlos@gmail.com', 'status': 'active'},
            {'name': 'Clarence Angelo Yu', 'email': 'clarenceangelyu@gmail.com', 'status': 'inactive'},
            {'name': 'Kristene Melody Aves', 'email': 'kristeneaves@gmail.com', 'status': 'active'},
             {'name': 'Bryant Carlos', 'email': 'bryantcarlos@gmail.com', 'status': 'active'},
            {'name': 'Clarence Angelo Yu', 'email': 'clarenceangelyu@gmail.com', 'status': 'inactive'},
            {'name': 'Kristene Melody Aves', 'email': 'kristeneaves@gmail.com', 'status': 'active'},
             {'name': 'Bryant Carlos', 'email': 'bryantcarlos@gmail.com', 'status': 'active'},
            {'name': 'Clarence Angelo Yu', 'email': 'clarenceangelyu@gmail.com', 'status': 'inactive'},
            {'name': 'Kristene Melody Aves', 'email': 'kristeneaves@gmail.com', 'status': 'active'},
          ],
        },
        {
          'name': 'National Service Training Program 1 - BSIT',
          'code': 'NSTP-1 BSIT',
          'schedule': 'MWF 7:00-8:00 AM',
          'program': 'BSIT',
          'active': 30,
          'inactive': 0,
          'students': [
            {'name': 'Bryant Carlos', 'email': 'bryantcarlos@gmail.com', 'status': 'active'},
            {'name': 'Kristene Melody Aves', 'email': 'kristeneaves@gmail.com', 'status': 'active'},
          ],
        },
      ],
      'totalSections': 3,
      'totalStudents': 40,
    },
    {
      'name': 'Trisha Mae',
      'email': 'mariacastro@university.edu',
      'department': 'NSTP Department',
      'sections': [
        {
          'name': 'NSTP 2 - BPT',
          'code': 'NSTP-2 BPT',
          'schedule': 'TTh 8:00-9:00 AM',
          'program': 'BPT',
          'active': 25,
          'inactive': 2,
          'students': [
            {'name': 'Student A', 'email': 'studenta@gmail.com', 'status': 'active'},
            {'name': 'Student B', 'email': 'studentb@gmail.com', 'status': 'inactive'},
          ],
        },
      ],
      'totalSections': 1,
      'totalStudents': 27,
    },
    {
      'name': 'Arnold Yu',
      'email': 'mariacastro@university.edu',
      'department': 'NSTP Department',
      'sections': [
        {
          'name': 'NSTP 3 - HE',
          'code': 'NSTP-3 HE',
          'schedule': 'Sat 10:00-12:00',
          'program': 'HE',
          'active': 20,
          'inactive': 0,
          'students': [
            {'name': 'Student C', 'email': 'studentc@gmail.com', 'status': 'active'},
          ],
        },
      ],
      'totalSections': 1,
      'totalStudents': 20,
    },
  ];

  int expandedInstructor = -1;
  int expandedSection = -1;
  String searchQuery = '';
  String selectedProgram = 'All Programs';
  final programs = ['All Programs', 'BSIT', 'BPT', 'HE', 'IA', 'ICT'];

  List<Map<String, dynamic>> get filteredInstructors {
    List<Map<String, dynamic>> filtered = instructors;
    if (selectedProgram != 'All Programs') {
      filtered = filtered.where((inst) {
        final sections = inst['sections'] as List?;
        if (sections == null) return false;
        return sections.any((section) => (section as Map)['program'] == selectedProgram);
      }).toList();
    }
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((inst) {
        final name = (inst['name'] as String).toLowerCase();
        final email = (inst['email'] as String).toLowerCase();
        final matchesInstructor = name.contains(searchQuery.toLowerCase()) || email.contains(searchQuery.toLowerCase());
        final matchesStudent = (inst['sections'] as List?)?.any((section) =>
          (section['students'] as List?)?.any((student) =>
            (student['name'] as String).toLowerCase().contains(searchQuery.toLowerCase()) ||
            (student['email'] as String).toLowerCase().contains(searchQuery.toLowerCase())
          ) ?? false
        ) ?? false;
        return matchesInstructor || matchesStudent;
      }).toList();
    }
    return filtered;
  }

  int get totalInstructors => filteredInstructors.length;
  int get totalSections => filteredInstructors.fold(0, (sum, inst) => sum + ((inst['sections'] as List?)?.length ?? 0));
  int get totalStudents => filteredInstructors.fold(0, (sum, inst) {
    final sections = inst['sections'] as List?;
    if (sections == null) return sum;
    final studentsCount = sections.fold<int>(0, (s, sec) {
      final students = (sec as Map)['students'] as List?;
      return s + (students?.length ?? 0);
    });
    return sum + studentsCount;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Row(
        children: [
          // Sidebar
          AdminSidebar(
            selectedItem: _selectedItem,
            onItemSelected: _handleNavigationSelect,
          ),
          // Main content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: const Color(0xFF34A853),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SafeAssetImage(
                      assetPath: 'assets/admin_icons/fluent_hat-graduation-12-regular.png',
                      width: 40,
                      height: 40,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Admin Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32)),
                          SizedBox(height: 4),
                          Text('National Service Training Program - Manage instructors, sections, and students', style: TextStyle(color: Colors.white, fontSize: 15)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Summary Cards
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _summaryCard('Total Instructors', totalInstructors.toString(), 'NSTP instructors', 'assets/admin_icons/lucide_users-round.png'),
                  _summaryCard('Total Sections', totalSections.toString(), 'NSTP program sections', 'assets/admin_icons/lucide_users-round (1).png'),
                  _summaryCard('Total Students', totalStudents.toString(), 'Enrolled in NSTP program', 'assets/admin_icons/lucide_users-round (2).png', highlight: true),
                ],
              ),
              const SizedBox(height: 24),
              // Search and Filter
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                child: Row(
                  children: [
                    Container(
                      height: 48,
                                      width: MediaQuery.of(context).size.width * 0.35,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          Image.asset('assets/admin_icons/akar-icons_search.png', width: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'Search Name',
                                border: InputBorder.none,
                              ),
                              cursorColor: Colors.black54,
                              style: const TextStyle(color: Color(0xFF222B45)),
                              onChanged: (v) => setState(() => searchQuery = v),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Replace the FilterChip row with a custom Row for program chips:
                    Row(
                      children: [
                        ...programs.map((p) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () => setState(() => selectedProgram = p),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: selectedProgram == p ? const Color(0xFF34A853) : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (selectedProgram == p)
                                    Icon(Icons.check, size: 18, color: Colors.white),
                                  if (selectedProgram == p) const SizedBox(width: 6),
                                  Text(
                                    p,
                                    style: TextStyle(
                                      color: selectedProgram == p ? Colors.white : const Color(0xFF222B45),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text('Instructors', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 12),
              // Instructor List
              ...List.generate(filteredInstructors.length, (i) {
                final instructor = filteredInstructors[i];
                final isExpanded = expandedInstructor == i;
                return Container(
                  margin: const EdgeInsets.only(bottom: 18),
                 decoration: BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(14),
  boxShadow: [
    BoxShadow(color: Color(0xFFBDBDBD),
      blurRadius: 2, // more blur for smoothness
      spreadRadius: 2,
      offset: const Offset(0, 2), // more vertical lift
    ),
  ],
),

                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color.fromARGB(255, 228, 245, 229),
                          radius: 35,
                          child: Image.asset('assets/admin_icons/ri_user-line.png', width: 25),
                        ),
                        title: Text(instructor['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(instructor['email'] as String, style: const TextStyle(fontSize: 13)),
                            Text(instructor['department'] as String, style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 13, color: Colors.black)),
                          ],
                        ),
                        trailing: SizedBox(
                          width: 150,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Column(crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset('assets/admin_icons/lucide_users-round (3).png', width: 18),
                                      const SizedBox(width: 10),
                                      Text('${instructor['totalSections']} sections', style: const TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset('assets/admin_icons/lucide_users-round (4).png', width: 18),
                                      const SizedBox(width: 10),
                                      Text('${instructor['totalStudents']} students', style: const TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(width: 10,),
                              Image.asset(
                                isExpanded
                                  ? 'assets/admin_icons/gridicons_dropdown (2).png'
                                  : 'assets/admin_icons/gridicons_dropdown.png',
                                width: 22,
                              ),
                            ],
                          ),
                        ),
                        onTap: () => setState(() => expandedInstructor = isExpanded ? -1 : i),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      ),
                      if (isExpanded && instructor['sections'] != null && (instructor['sections'] as List).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(color: Colors.black26,),
                              const SizedBox(height: 10),
                              const Text('Sections', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 8),
                              ...List.generate((instructor['sections'] as List).length, (j) {
                                final section = (instructor['sections'] as List)[j];
                                final isSectionExpanded = expandedSection == j;
                                return GestureDetector(
                                   onTap: () => setState(() => expandedSection = isSectionExpanded ? -1 : j),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border(top: BorderSide(color: const Color(0xFF34A853).withOpacity(0.2)), 
                                      bottom: BorderSide(color: const Color(0xFF34A853).withOpacity(0.2),),
                                      right:  BorderSide(color: const Color(0xFF34A853).withOpacity(0.2),),
                                      left:  BorderSide(color: const Color(0xFF34A853).withOpacity(0.2), width: 7),
                                    ),),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          color: const Color.fromARGB(255, 228, 245, 229),
                          ),
                          child: Image.asset('assets/admin_icons/ri_user-line.png', height: 20,),
                        ),
                                            const SizedBox(width: 20),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(section['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 10),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius: BorderRadius.circular(15),
                                                          border: Border.all(color: Color(0xFFBDBDBD)),
                                                        ),
                                                        child: Text(section['code'], style: const TextStyle(fontSize: 12, color: Colors.black)),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Image.asset('assets/admin_icons/iconamoon_clock-thin.png', width: 16),
                                                      const SizedBox(width: 2),
                                                      Text(section['schedule'], style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF34A853).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text('${section['active']} active', style: const TextStyle(color: Color(0xFF34A853), fontWeight: FontWeight.bold, fontSize: 13)),
                                                ),
                                                Text('${section['inactive']} inactive', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                              ],
                                            ),
                                             const SizedBox(width: 10),
                                                    Image.asset(
                                                       isSectionExpanded
                                                         ? 'assets/admin_icons/gridicons_dropdown (2).png'
                                                         : 'assets/admin_icons/gridicons_dropdown.png',
                                                       width: 22,
                                                     ),
                                                    
                                                   
                                          ],
                                        ),
                                        if (isSectionExpanded && section['students'] != null && section['students'].isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                              const Divider(color: Colors.black26,),
                              const SizedBox(height: 10),
                                                const Text('Students', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                                const SizedBox(height: 6),
                                               SizedBox(
                                                 height: 220,
                                                 child: LayoutBuilder(
                                                   builder: (context, constraints) {
                                                     return ListView.builder(
                                                       itemCount: section['students'].length,
                                                       shrinkWrap: true,
                                                       physics: const ClampingScrollPhysics(),
                                                       itemBuilder: (context, k) {
                                                         final student = section['students'][k];
                                                         return Container(
                                                           margin: const EdgeInsets.only(bottom: 6),
                                                           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                           decoration: BoxDecoration(
                                                             color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border(top: BorderSide(color: Color(0xFFBDBDBD).withOpacity(.3),width: 3), 
                                      bottom: BorderSide(color: Color(0xFFBDBDBD).withOpacity(.3),width: 3),
                                      right:  BorderSide(color: Color(0xFFBDBDBD).withOpacity(.3),),
                                      left:  BorderSide(color: Color(0xFFBDBDBD).withOpacity(.3), ),
                                    ),
                                                           ),
                                                           child: Row(
                                                             children: [
                                                               if (student['status'] == 'active')
                                                                 Container(
                                                                  height: 50,
                                                                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                                 decoration: BoxDecoration(
                                                                  shape: BoxShape.circle,
                                                                   color:const Color(0xFF34A853).withOpacity(0.1),
                                                                 ),
                                                                  child: Image.asset('assets/admin_icons/solar_user-check-broken.png', width: 18))
                                                               else
                                                                 Container(
                                                                  
                                                                  height: 50,
                                                                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                                 decoration: BoxDecoration(
                                                                  shape: BoxShape.circle,
                                                                   color:const Color(0xFF34A853).withOpacity(0.1),
                                                                 ),
                                                                  child: Image.asset('assets/admin_icons/solar_user-cross-broken.png', width: 18)),
                                                               const SizedBox(width: 10),
                                                               Column(
                                                                 crossAxisAlignment: CrossAxisAlignment.start,
                                                                 children: [
                                                                   Text(student['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                                                                   Text(student['email'], style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                                                 ],
                                                               ),
                                                               const SizedBox(width: 20),
                                                               Container(
                                                                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                                                         decoration: BoxDecoration(
                                                                           color: Colors.white,
                                                                           border: Border.all(color: Color(0xFFBDBDBD)),
                                                                           borderRadius: BorderRadius.circular(20),
                                                                         ),
                                                                         child: Text(
                                                                           section['program'],
                                                                           style: const TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold),
                                                                         ),
                                                                       ),
                                                               const Spacer(),
                                                               Container(
                                                                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
                                                                 decoration: BoxDecoration(
                                                                   color: student['status'] == 'active' ?  const Color(0xFF34A853)  : const Color(0xFFBDBDBD).withOpacity(.2),
                                                                   borderRadius: BorderRadius.circular(15),
                                                                 ),
                                                                 child: Text(student['status'], style: TextStyle(color: student['status'] == 'active' ? Colors.white: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                                                               ),
                                                              
                                                             ],
                                                           ),
                                                         );
                                                       },
                                                     );
                                                   },
                                                 ),
                                               ),
                                              ],
                                            ),
                                          ),
                                       
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, String value, String subtitle, String iconPath, {bool highlight = false}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                Image.asset(iconPath, width: 26, color: highlight ? const Color(0xFF34A853) : null),
              ],
            ),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color:  const Color(0xFF34A853) )),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
} 