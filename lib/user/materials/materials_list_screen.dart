import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/login/custom_drawer.dart';
import 'materials_detail_screen.dart';
import 'materials_list_screen_controller.dart';

class MaterialsListScreen extends StatefulWidget {
  const MaterialsListScreen({Key? key}) : super(key: key);

  @override
  State<MaterialsListScreen> createState() => _MaterialsListScreenState();
}

class _MaterialsListScreenState extends State<MaterialsListScreen> {
  int selectedDrawerIndex = 3;
  MaterialsListScreenController? controller;

  @override
  void initState() {
    super.initState();
    // Initialize controller with proper error handling
    try {
      controller = Get.put(MaterialsListScreenController(), permanent: false);
    } catch (e) {
      print('Error initializing controller: $e');
      // Fallback: try to find existing controller
      try {
        controller = Get.find<MaterialsListScreenController>();
      } catch (e2) {
        print('Error finding existing controller: $e2');
        controller = null;
      }
    }
  }

  @override
  void dispose() {
    try {
      if (controller != null) {
        Get.delete<MaterialsListScreenController>();
      }
    } catch (e) {
      print('Error disposing controller: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomDrawer(
        selectedIndex: selectedDrawerIndex,
        onSelect: (i) {
          setState(() => selectedDrawerIndex = i);
          Navigator.pop(context);
        },
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.black),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        title:
            controller == null
                ? const Text(
                  'Materials',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                )
                : Obx(
                  () => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        controller!.currentInstructorUid.value.isNotEmpty
                            ? 'Materials'
                            : 'All Materials',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (controller!.currentInstructorUid.value.isNotEmpty &&
                          controller!.currentInstructorName.value.isNotEmpty)
                        Text(
                          'by ${controller!.currentInstructorName.value}',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: Colors.black),
            onPressed: () {
              if (controller != null) {
                if (controller!.currentInstructorUid.value.isNotEmpty) {
                  // Switch to all materials
                  controller!.currentInstructorUid.value = '';
                  controller!.currentInstructorName.value = '';
                  controller!.loadMaterials();
                } else {
                  // Switch to selected instructor materials
                  controller!.loadCurrentInstructorMaterials();
                }
              }
            },
            tooltip:
                'Toggle between Selected Instructor Materials and All Materials',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              if (controller != null) {
                controller!.refreshMaterials();
              }
            },
            tooltip: 'Refresh Materials',
          ),
          // IconButton(
          //   icon: const Icon(Icons.bug_report, color: Colors.black),
          //   onPressed: () {
          //     if (controller != null) {
          //       _showDebugInfo();
          //     }
          //   },
          //   tooltip: 'Debug Info',
          // ),
        ],
      ),
      backgroundColor: Colors.white,
      body:
          controller == null
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF34A853),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Initializing...',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              )
              : Obx(() {
                if (controller!.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF34A853),
                      ),
                    ),
                  );
                }

                if (controller!.materials.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.library_books_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          controller!.currentInstructorUid.value.isNotEmpty
                              ? 'No materials uploaded yet'
                              : 'No materials available',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          controller!.currentInstructorUid.value.isNotEmpty
                              ? 'This instructor has not uploaded any materials yet'
                              : 'Materials will appear here when instructors upload them',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isTablet = constraints.maxWidth > 600;
                    final crossAxisCount = isTablet ? 3 : 2;
                    final childAspectRatio = isTablet ? 0.8 : 0.75;
                    final gridPadding = isTablet ? 32.0 : 16.0;
                    return Column(
                      children: [
                        Expanded(
                          child: GridView.builder(
                            padding: EdgeInsets.all(gridPadding),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: gridPadding,
                                  mainAxisSpacing: gridPadding,
                                  childAspectRatio: childAspectRatio,
                                ),
                            itemCount: controller!.materials.length,
                            itemBuilder: (context, i) {
                              final material = controller!.materials[i];

                              // Validate material data before navigation
                              if (material.isEmpty) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Invalid Material',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                );
                              }

                              return GestureDetector(
                                onTap: () {
                                  // Double-check material is valid before navigation
                                  if (material.isNotEmpty) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => MaterialsDetailScreen(
                                              material: material,
                                            ),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(18),
                                          topRight: Radius.circular(18),
                                        ),
                                        child: _getMaterialImage(
                                          material['topic'],
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(
                                          isTablet ? 18 : 12,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              material['title'],
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: isTablet ? 17 : 15,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: isTablet ? 8 : 6),
                                            Text(
                                              material['topic'],
                                              style: TextStyle(
                                                fontSize: isTablet ? 13 : 11,
                                                color: Colors.black54,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(
                                              height: isTablet ? 14 : 10,
                                            ),
                                            const Divider(
                                              height: 1,
                                              thickness: 1,
                                              color: Color(0xFFE0E0E0),
                                            ),
                                            SizedBox(
                                              height: isTablet ? 14 : 10,
                                            ),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.circle,
                                                  color: Color(0xFF34A853),
                                                  size: 12,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  material['createdAt'] ??
                                                      'Unknown Date',
                                                  style: TextStyle(
                                                    color: Color(0xFF34A853),
                                                    fontSize:
                                                        isTablet ? 10 : 10,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: isTablet ? 8 : 6),
                                            Text(
                                              'By: ${material['instructorName']}',
                                              style: TextStyle(
                                                fontSize: isTablet ? 12 : 10,
                                                color: Colors.black54,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
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
                        ),
                      ],
                    );
                  },
                );
              }),
    );
  }

  /// Show debug information
  void _showDebugInfo() {
    if (controller == null) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Debug Information'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Current Instructor UID: ${controller!.currentInstructorUid.value}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current Instructor Name: ${controller!.currentInstructorName.value}',
                  ),
                  const SizedBox(height: 8),
                  Text('Materials Count: ${controller!.materials.length}'),
                  const SizedBox(height: 8),
                  Text('Is Loading: ${controller!.isLoading.value}'),
                  const SizedBox(height: 8),
                  Text('Error Message: ${controller!.errorMessage.value}'),
                  const SizedBox(height: 16),
                  const Text(
                    'Materials:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...controller!.materials
                      .take(5)
                      .map(
                        (material) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• ${material['title']} - ${material['topic']}',
                          ),
                        ),
                      ),
                  if (controller!.materials.length > 5)
                    Text('... and ${controller!.materials.length - 5} more'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  controller!.loadCurrentInstructorMaterials();
                },
                child: const Text('Reload'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Test with the specific instructor from the image
                  controller!.testLoadMaterialsForInstructor(
                    '6df36lEI0GPbSRCLSHDyZPQMFrn2',
                  );
                },
                child: const Text('Test Load'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // List all instructors for debugging
                  controller!.listAllInstructors();
                },
                child: const Text('List Instructors'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Load materials for the specific instructor from Firestore image
                  controller!.loadMaterialsForInstructorByUid(
                    '6df36lEI0GPbSRCLSHDyZPQMFrn2',
                  );
                },
                child: const Text('Load Test Materials'),
              ),
            ],
          ),
    );
  }

  /// Get appropriate image based on material topic
  Widget _getMaterialImage(String topic) {
    // Default images based on topic
    String imagePath;
    double imageHeight = 120.0;

    if (topic.toLowerCase().contains('climate') ||
        topic.toLowerCase().contains('environment') ||
        topic.toLowerCase().contains('change')) {
      imagePath = 'assets/images/image 328.png';
    } else if (topic.toLowerCase().contains('deforestation') ||
        topic.toLowerCase().contains('forest') ||
        topic.toLowerCase().contains('understanding')) {
      imagePath = 'assets/images/engineering-supplies-blueprint 2.png';
    } else if (topic.toLowerCase().contains('renewable') ||
        topic.toLowerCase().contains('energy')) {
      imagePath = 'assets/images/image 328.png';
    } else {
      // Default to climate change image for better visual appeal
      imagePath = 'assets/images/image 328.png';
    }

    return Image.asset(
      imagePath,
      height: imageHeight,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: imageHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF34A853).withOpacity(0.8),
                const Color(0xFF34A853).withOpacity(0.4),
              ],
            ),
          ),
          child: const Icon(Icons.library_books, size: 40, color: Colors.white),
        );
      },
    );
  }
}
