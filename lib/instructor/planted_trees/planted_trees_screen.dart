import 'package:flutter/material.dart';
import '../../shared/instructor/instructor_appbar.dart';
import '../../shared/instructor/instructor_sidebar.dart';

class InstructorPlantedTreesScreen extends StatefulWidget {
  const InstructorPlantedTreesScreen({Key? key}) : super(key: key);

  @override
  State<InstructorPlantedTreesScreen> createState() => _InstructorPlantedTreesScreenState();
}

class _InstructorPlantedTreesScreenState extends State<InstructorPlantedTreesScreen> {
  int _sidebarIndex = 5; // Planted Trees
  bool _showGoalDialog = false;
  bool _showRegisterDialog = false;
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _treeNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _plantedByController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  int semesterGoal = 100;
  int treesPlanted = 12;
  int recentActivity = 3;
  List<Map<String, String>> registrations = [
    {'date': '7/1/2025', 'name': 'Mango', 'location': 'Campus', 'by': 'BSIT-1A'},
    {'date': '7/1/2025', 'name': 'Mango', 'location': 'Student Center', 'by': 'BFPT-1D'},
    {'date': '7/1/2025', 'name': 'Mango', 'location': 'Library Garden', 'by': 'BSIT-1B'},
    {'date': '7/1/2025', 'name': 'Mango', 'location': 'Field', 'by': 'ICT-1E'},
    {'date': '7/1/2025', 'name': 'Mango', 'location': 'Campus', 'by': 'IA-C'},
    {'date': '7/1/2025', 'name': 'Mango', 'location': 'Side Court', 'by': 'BFPT-D'},
    {'date': '7/1/2025', 'name': 'Mango', 'location': 'USTP', 'by': 'BSIT-1F'},
  ];

  void _onSidebarSelect(int idx) {
    setState(() => _sidebarIndex = idx);
    if (idx == 0) {
      Navigator.of(context).pushReplacementNamed('/instructor-dashboard');
    } else if (idx == 5) {
      // Already on planted trees
    }
  }

  void _showGoal() {
    setState(() => _showGoalDialog = true);
  }

  void _showRegister() {
    setState(() => _showRegisterDialog = true);
  }

  void _closeDialogs() {
    setState(() {
      _showGoalDialog = false;
      _showRegisterDialog = false;
      _goalController.clear();
      _treeNameController.clear();
      _locationController.clear();
      _plantedByController.clear();
      _dateController.clear();
    });
  }

  void _addGoal() {
    setState(() {
      semesterGoal = int.tryParse(_goalController.text) ?? semesterGoal;
      _showGoalDialog = false;
      _goalController.clear();
    });
  }

  void _addTree() {
    setState(() {
      registrations.insert(0, {
        'date': _dateController.text,
        'name': _treeNameController.text,
        'location': _locationController.text,
        'by': _plantedByController.text,
      });
      treesPlanted++;
      _showRegisterDialog = false;
      _treeNameController.clear();
      _locationController.clear();
      _plantedByController.clear();
      _dateController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    double progress = treesPlanted / semesterGoal;
    return Scaffold(
      backgroundColor:  Colors.white,
      body: Row(
        children: [
          InstructorSidebar(selectedIndex: _sidebarIndex, onItemSelected: _onSidebarSelect),
          Expanded(
            child: Stack(
              children: [
                Column(
                  children: [
                    const InstructorAppBar(instructorName: 'Mia Castro'),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Environmental Impact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Semester Tree Planting Initiative - Academic Year 2025', style: TextStyle(color: Colors.black38, fontSize: 16)),
                                 Row(
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF34A853),
                                    side: const BorderSide(color: Color(0xFF34A853)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                                  ),
                                  onPressed: _showGoal,
                                  icon: const Icon(Icons.flag, color: Color(0xFF34A853)),
                                  label: const Text('Goal', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF34A853),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                                  ),
                                  onPressed: _showRegister,
                                  icon: const Icon(Icons.add, color: Colors.white),
                                  label: const Text('Register Tree', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                _StatCard(
                                  image: 'assets/instructor/images/image 378.png',
                                  label: 'Tree Planted this Semester',
                                  value: '$treesPlanted',
                                  borderColor: const Color(0xFF2563EB),
                                  iconBg: const Color(0xFFE8F0FE),
                                  sublabel: 'Total tress registered',
                                ),
                                const SizedBox(width: 18),
                                _StatCard(
                                  image: 'assets/instructor/images/image 379.png',
                                  label: 'Goal Progress',
                                  value: '${(progress * 100).toStringAsFixed(0)}%',
                                  borderColor: const Color(0xFF34A853),
                                  iconBg: const Color(0xFFE6F7EC),
                                  sublabel: '$semesterGoal Tree semester goal',
                                ),
                                const SizedBox(width: 18),
                                _StatCard(
                                  image: 'assets/instructor/images/image 377.png',
                                  label: 'Recent Activity',
                                  value: '$recentActivity',
                                  borderColor: const Color(0xFFF59E42),
                                  iconBg: const Color(0xFFFFF7E6),
                                  sublabel: 'Tress added this week',
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.fromLTRB(32, 24, 0, 0),
                                    child: Text('Recent Tree Registrations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  ),
                                  const SizedBox(height: 15),
                                  Container(
                                    constraints: const BoxConstraints(maxHeight: 300),
                                    child: Scrollbar(
                                      thumbVisibility: true,
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: registrations.length + 1,
                                        itemBuilder: (context, i) {
                                          if (i == 0) {
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 14),
                                                child: Row(
                                                  children: const [
                                                    Expanded(flex: 2, child: Text('Date', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold))),
                                                    Expanded(flex: 3, child: Text('Tree Name', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold))),
                                                    Expanded(flex: 4, child: Text('Location', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold))),
                                                    Expanded(flex: 3, child: Text('Planted by', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold))),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }
                                          final r = registrations[i - 1];
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
                                              ),
                                              padding: const EdgeInsets.symmetric(vertical: 18),
                                              child: Row(
                                                children: [
                                                  Expanded(flex: 2, child: Text(r['date']!, style: const TextStyle(fontSize: 15))),
                                                  Expanded(flex: 3, child: Text(r['name']!, style: const TextStyle(fontSize: 15))),
                                                  Expanded(flex: 4, child: Text(r['location']!, style: const TextStyle(fontSize: 15))),
                                                  Expanded(flex: 3, child: Text(r['by']!, style: const TextStyle(fontSize: 15))),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_showGoalDialog)
                  _GoalDialog(
                    controller: _goalController,
                    onCancel: _closeDialogs,
                    onAdd: _addGoal,
                  ),
                if (_showRegisterDialog)
                  _RegisterTreeDialog(
                    treeNameController: _treeNameController,
                    locationController: _locationController,
                    plantedByController: _plantedByController,
                    dateController: _dateController,
                    onCancel: _closeDialogs,
                    onAdd: _addTree,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String image;
  final String label;
  final String value;
  final Color borderColor;
  final Color iconBg;
  final String sublabel;
  const _StatCard({required this.image, required this.label, required this.value, required this.borderColor, required this.iconBg, required this.sublabel});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: borderColor, width: 5),
            top:  BorderSide(color: borderColor),
            right:  BorderSide(color: borderColor),
            bottom:  BorderSide(color: borderColor),
          ),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(image,  height: 80),
            const SizedBox(width: 20),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: Colors.black)),
                const SizedBox(height: 2),
                Text(sublabel, style: const TextStyle(fontWeight: FontWeight.bold,color: Colors.black54, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalDialog extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onCancel;
  final VoidCallback onAdd;
  const _GoalDialog({required this.controller, required this.onCancel, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, 8))],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Goal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onCancel,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text('Number of tress to plant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                cursorColor: Colors.black54,
                decoration: InputDecoration(
                  hintText: 'e.g., 50',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF34A853), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Color(0xFF34A853)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: onCancel,
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF34A853),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: onAdd,
                    child: const Text('Add Tree', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegisterTreeDialog extends StatefulWidget {
  final TextEditingController treeNameController;
  final TextEditingController locationController;
  final TextEditingController plantedByController;
  final TextEditingController dateController;
  final VoidCallback onCancel;
  final VoidCallback onAdd;
  const _RegisterTreeDialog({required this.treeNameController, required this.locationController, required this.plantedByController, required this.dateController, required this.onCancel, required this.onAdd});

  @override
  State<_RegisterTreeDialog> createState() => _RegisterTreeDialogState();
}

class _RegisterTreeDialogState extends State<_RegisterTreeDialog> {
  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF34A853), // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black, // body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF34A853), // button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      widget.dateController.text = "${picked.month}/${picked.day}/${picked.year}";
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, 8))],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add New Tree', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onCancel,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text('Tree Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              TextField(
                controller: widget.treeNameController,
                cursorColor: Colors.black54,
                decoration: InputDecoration(
                  hintText: 'e.g., Mango Tree',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF34A853), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 18),
              const Text('Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              TextField(
                controller: widget.locationController,
                cursorColor: Colors.black54,
                decoration: InputDecoration(
                  hintText: 'e.g., School Garden, Front Yard',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF34A853), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 18),
              const Text('Planted by:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              TextField(
                controller: widget.plantedByController,
                cursorColor: Colors.black54,
                decoration: InputDecoration(
                  hintText: 'e.g., BSIT-1A',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF34A853), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 18),
              const Text('Plant Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextField(
                    controller: widget.dateController,
                    cursorColor: Colors.black54,
                    decoration: InputDecoration(
                      hintText: 'dd/mm/yyyy',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF34A853), width: 2),
                      ),
                      prefixIcon: const Icon(Icons.calendar_today, size: 20, color: Color(0xFF34A853)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Color(0xFF34A853)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: widget.onCancel,
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF34A853),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: widget.onAdd,
                    child: const Text('Add Tree', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 