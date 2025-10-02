import 'package:flutter/material.dart';
import 'package:greenquest/instructor/planted_trees/planted_trees_screen_controller.dart';
import '../../shared/instructor/instructor_appbar.dart';
import '../../shared/instructor/instructor_sidebar.dart';
import '../../shared/instructor/instructor_navigation_constants.dart';
import 'package:get/get.dart';
import '../instructor_dashboard_controller.dart';

class InstructorPlantedTreesScreen extends StatefulWidget {
  const InstructorPlantedTreesScreen({super.key});

  @override
  State<InstructorPlantedTreesScreen> createState() =>
      _InstructorPlantedTreesScreenState();
}

class _InstructorPlantedTreesScreenState
    extends State<InstructorPlantedTreesScreen> {
  final TreeController treeController = Get.put(TreeController());
  final InstructorController instructorController = Get.put(
    InstructorController(),
  );

  InstructorNavigationItem _selectedItem =
      InstructorNavigationItem.plantedTrees;
  bool _showRegisterDialog = false;
  final TextEditingController _treeNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _plantedByController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');


  void _handleNavigationSelect(InstructorNavigationItem item) {
    setState(() => _selectedItem = item);
    String route = InstructorNavigationHelper.getRoute(item);
    Navigator.of(context).pushReplacementNamed(route);
  }

  void _showRegister() {
    setState(() => _showRegisterDialog = true);
  }

  void _closeDialogs() {
    setState(() {
      _showRegisterDialog = false;
      _treeNameController.clear();
      _locationController.clear();
      _plantedByController.clear();
      _dateController.clear();
      _quantityController.clear();
      _quantityController.text = '1';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          InstructorSidebar(
            selectedItem: _selectedItem,
            onItemSelected: _handleNavigationSelect,
          ),
          Expanded(
            child: Stack(
              children: [
                Column(
                  children: [
                    Obx(
                      () => InstructorAppBar(
                        instructorName:
                            instructorController.instructorName.value,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 30,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Environmental Impact',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 32,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Semester Tree Planting Initiative - Academic Year 2025',
                                  style: TextStyle(
                                    color: Colors.black38,
                                    fontSize: 16,
                                  ),
                                ),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF34A853,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 22,
                                          vertical: 16,
                                        ),
                                      ),
                                      onPressed: _showRegister,
                                      icon: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                      ),
                                      label: const Text(
                                        'Register Tree',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Obx(
                                  () => _StatCard(
                                    image:
                                        'assets/instructor/images/image 378.png',
                                    label: 'Trees Planted this Semester',
                                    value:
                                        treeController.totalTrees.value.toString(),
                                    borderColor: const Color(0xFF2563EB),
                                    iconBg: const Color(0xFFE8F0FE),
                                    sublabel: 'Total trees registered',
                                  ),
                                ),

                                const SizedBox(width: 18),
                                Obx(
                                  () => _StatCard(
                                    image:
                                        'assets/instructor/images/image 377.png',
                                    label: 'Recent Activity',
                                    value: treeController.recentActivity.value.toString(),
                                    borderColor: const Color(0xFFF59E42),
                                    iconBg: const Color(0xFFFFF7E6),
                                    sublabel: 'Trees added this week',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.fromLTRB(32, 24, 0, 0),
                                    child: Text(
                                      'Recent Tree Registrations',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  Container(
                                    constraints: const BoxConstraints(
                                      maxHeight: 270,
                                    ),
                                    child: Obx(() {
                                      final registrations =
                                          treeController.registrations;

                                      return Scrollbar(
                                        thumbVisibility: true,
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: registrations.length + 1,
                                          itemBuilder: (context, i) {
                                            if (i == 0) {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 24,
                                                      vertical: 0,
                                                    ),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 14,
                                                      ),
                                                  child: Row(
                                                    children: const [
                                                      Expanded(
                                                        flex: 1,
                                                        child: Text(
                                                          'Date',
                                                          style: TextStyle(
                                                            color:
                                                                Colors.black54,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 2,
                                                        child: Text(
                                                          'Tree Name',
                                                          style: TextStyle(
                                                            color:
                                                                Colors.black54,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 3,
                                                        child: Text(
                                                          'Location',
                                                          style: TextStyle(
                                                            color:
                                                                Colors.black54,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 2,
                                                        child: Text(
                                                          'Planted by',
                                                          style: TextStyle(
                                                            color:
                                                                Colors.black54,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 1,
                                                        child: Text(
                                                          'Qty',
                                                          style: TextStyle(
                                                            color:
                                                                Colors.black54,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 1,
                                                        child: Text(
                                                          'Actions',
                                                          style: TextStyle(
                                                            color:
                                                                Colors.black54,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }

                                            final r = registrations[i - 1];
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                    vertical: 0,
                                                  ),
                                              child: Container(
                                                decoration: const BoxDecoration(
                                                  border: Border(
                                                    bottom: BorderSide(
                                                      color: Color(0xFFE5E7EB),
                                                      width: 1,
                                                    ),
                                                  ),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 18,
                                                    ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      flex: 1,
                                                      child: Text(
                                                        r['date'] ?? '',
                                                        style: const TextStyle(
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 2,
                                                      child: Text(
                                                        r['name'] ?? '',
                                                        style: const TextStyle(
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 3,
                                                      child: Text(
                                                        r['location'] ?? '',
                                                        style: const TextStyle(
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 2,
                                                      child: Text(
                                                        r['by'] ?? '',
                                                        style: const TextStyle(
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                    ),
                                                      Expanded(
                                                        flex: 1,
                                                        child: Text(
                                                          r['quantity'].toString(),
                                                          style: const TextStyle(
                                                            fontSize: 15,
                                                          ),
                                                          textAlign: TextAlign.start,
                                                        ),
                                                      ),

                                                    Expanded(flex: 1, child: Row(
                                                      children: [
                                                         // Action buttons
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        color: Colors.blue,
                                                      ),
                                                      onPressed: () {
                                                        showEditDialog(
                                                          context,
                                                          r,
                                                        );
                                                      },
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red,
                                                      ),
                                                      onPressed: () async {
                                                        final shouldDelete = await showDialog<
                                                          bool
                                                        >(
                                                          context: context,
                                                          builder:
                                                              (
                                                                context,
                                                              ) => AlertDialog(
                                                                title: const Text(
                                                                  'Delete Confirmation',
                                                                ),
                                                                content: const Text(
                                                                  'Are you sure you want to delete this tree?',
                                                                ),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed:
                                                                        () => Navigator.of(
                                                                          context,
                                                                        ).pop(
                                                                          false,
                                                                        ),
                                                                    child: const Text(
                                                                      'Cancel',
                                                                    ),
                                                                  ),
                                                                  ElevatedButton(
                                                                    onPressed:
                                                                        () => Navigator.of(
                                                                          context,
                                                                        ).pop(
                                                                          true,
                                                                        ),
                                                                    child: const Text(
                                                                      'Delete',
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                        );
                                                        if (shouldDelete ==
                                                            true) {
                                                          treeController
                                                              .deleteTree(
                                                                r['id'],
                                                              );
                                                        }
                                                      },
                                                    ),
                                                    
                                                      ],
                                                    ),

                                                   ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    }),
                                  ),

                                  const SizedBox(height: 19),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_showRegisterDialog)
                  _RegisterTreeDialog(
                    treeNameController: _treeNameController,
                    locationController: _locationController,
                    plantedByController: _plantedByController,
                    dateController: _dateController,
                    quantityController: _quantityController,
                    onCancel: _closeDialogs,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void showEditDialog(BuildContext context, Map<String, dynamic> r) {
  final TreeController editDialogTreeController = Get.find<TreeController>();
  final nameController = TextEditingController(text: r['name']);
  final locationController = TextEditingController(text: r['location']);
  final byController = TextEditingController(text: r['by']);
  final quantityController = TextEditingController(text: r['quantity'].toString());

  showDialog(
    context: context,
    builder: (context) => _EditTreeDialog(
      treeNameController: nameController,
      locationController: locationController,
      plantedByController: byController,
      quantityController: quantityController,
      onCancel: () => Navigator.pop(context),
      onSave: () {
        final quantity = int.tryParse(quantityController.text) ?? 1;
        editDialogTreeController.editTree(r['id'], {
          "treeName": nameController.text,
          "location": locationController.text,
          "plantedBy": byController.text,
          "quantity": quantity,
        });
        Navigator.pop(context);
      },
    ),
  );
}

class _StatCard extends StatelessWidget {
  final String image;
  final String label;
  final String value;
  final Color borderColor;
  final Color iconBg;
  final String sublabel;
  const _StatCard({
    required this.image,
    required this.label,
    required this.value,
    required this.borderColor,
    required this.iconBg,
    required this.sublabel,
  });

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
            top: BorderSide(color: borderColor),
            right: BorderSide(color: borderColor),
            bottom: BorderSide(color: borderColor),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(image, height: 80),
            const SizedBox(width: 20),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sublabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
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
  final TextEditingController quantityController;
  final VoidCallback onCancel;

  const _RegisterTreeDialog({
    required this.treeNameController,
    required this.locationController,
    required this.plantedByController,
    required this.dateController,
    required this.quantityController,
    required this.onCancel,
  });

  @override
  State<_RegisterTreeDialog> createState() => _RegisterTreeDialogState();
}

class _RegisterTreeDialogState extends State<_RegisterTreeDialog> {
  final TreeController treeController = Get.find<TreeController>();

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
              primary: const Color(0xFF34A853), // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black, // body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF34A853), // button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      widget.dateController.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      setState(() {});
    }
  }

  Future<void> _handleAddTree() async {
    final treeName = widget.treeNameController.text.trim();
    final location = widget.locationController.text.trim();
    final plantedBy = widget.plantedByController.text.trim();
    final date = widget.dateController.text.trim();
    final quantityText = widget.quantityController.text.trim();
    
    final quantity = int.tryParse(quantityText) ?? 1;

    if (treeName.isEmpty ||
        location.isEmpty ||
        plantedBy.isEmpty ||
        date.isEmpty) {
      Get.snackbar("Error", "All fields are required.");
      return;
    }

    if (quantity < 1) {
      Get.snackbar("Error", "Quantity must be at least 1.");
      return;
    }

    await treeController.addTree(
      treeName: treeName,
      location: location,
      plantedBy: plantedBy,
      plantDate: date,
      quantity: quantity,
    );

    // Clear fields but KEEP the dialog open
    widget.treeNameController.clear();
    widget.locationController.clear();
    widget.plantedByController.clear();
    widget.dateController.clear();
    widget.quantityController.clear();
    widget.quantityController.text = '1';

    // Optionally show confirmation without closing
    Get.snackbar("Success", "Tree added successfully!");
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
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add New Tree',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onCancel,
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // --- Tree Name ---
              const Text(
                'Tree Name',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: widget.treeNameController,
                decoration: _inputDecoration("e.g., Mango Tree"),
              ),

              const SizedBox(height: 18),

              // --- Location ---
              const Text(
                'Location',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: widget.locationController,
                decoration: _inputDecoration("e.g., School Garden, Front Yard"),
              ),

              const SizedBox(height: 18),

              // --- Planted By ---
              const Text(
                'Planted By',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: widget.plantedByController,
                decoration: _inputDecoration("e.g., BSIT-1A"),
              ),

              const SizedBox(height: 18),

              // --- Quantity ---
              const Text(
                'Quantity',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: widget.quantityController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration("e.g., 5").copyWith(
                 
                ),
              ),

              const SizedBox(height: 18),

              // --- Plant Date ---
              const Text(
                'Plant Date',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextField(
                    controller: widget.dateController,
                    decoration: _inputDecoration("dd/mm/yyyy").copyWith(
                      prefixIcon: const Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: Color(0xFF34A853),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // --- ACTION BUTTONS ---
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Color(0xFF34A853)),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _handleAddTree,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF34A853),
                    ),
                    child: const Text(
                      'Add Tree',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF34A853), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class _EditTreeDialog extends StatelessWidget {
  final TextEditingController treeNameController;
  final TextEditingController locationController;
  final TextEditingController plantedByController;
  final TextEditingController quantityController;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _EditTreeDialog({
    required this.treeNameController,
    required this.locationController,
    required this.plantedByController,
    required this.quantityController,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Tree',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onCancel,
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // --- Tree Name ---
              const Text(
                'Tree Name',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: treeNameController,
                decoration: _inputDecoration("e.g., Mango Tree"),
              ),

              const SizedBox(height: 18),

              // --- Location ---
              const Text(
                'Location',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: locationController,
                decoration: _inputDecoration("e.g., School Garden, Front Yard"),
              ),

              const SizedBox(height: 18),

              // --- Planted By ---
              const Text(
                'Planted By',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: plantedByController,
                decoration: _inputDecoration("e.g., BSIT-1A"),
              ),

              const SizedBox(height: 18),

              // --- Quantity ---
              const Text(
                'Quantity',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration("e.g., 5").copyWith(
                 
                ),
              ),

              const SizedBox(height: 24),

              // --- ACTION BUTTONS ---
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Color(0xFF34A853)),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF34A853),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF34A853), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
