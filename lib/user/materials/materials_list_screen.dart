import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'materials_list_screen_controller.dart';
import 'materials_detail_screen.dart';

class MaterialsListScreen extends StatefulWidget {
  const MaterialsListScreen({super.key});

  @override
  State<MaterialsListScreen> createState() => _MaterialsListScreenState();
}

class _MaterialsListScreenState extends State<MaterialsListScreen> {
  MaterialsListScreenController? controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(MaterialsListScreenController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Materials',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF34A853),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              controller?.loadCurrentInstructorMaterials();
            },
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
          ),
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
                        if (controller!.userSectionCode.value.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF34A853).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Filtered for section: ${controller!.userSectionCode.value}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF34A853),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;
                    final isMobile = screenWidth < 600;
                    final isTablet = screenWidth >= 600 && screenWidth < 1200;

                    // Modern responsive configuration
                    final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);
                    final childAspectRatio =
                        2.2; // Much wider ratio to reduce height
                    final gridPadding =
                        isMobile ? 20.0 : (isTablet ? 24.0 : 32.0);
                    final cardPadding =
                        isMobile ? 6.0 : (isTablet ? 8.0 : 10.0);
                    final titleFontSize =
                        isMobile ? 16.0 : (isTablet ? 18.0 : 20.0);
                    final descriptionFontSize =
                        isMobile ? 12.0 : (isTablet ? 14.0 : 16.0);
                    final iconSize = isMobile ? 14.0 : (isTablet ? 16.0 : 18.0);

                    return SafeArea(
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: GridView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: gridPadding,
                            vertical: gridPadding,
                          ),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: isMobile ? 12.0 : 16.0,
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
                                  child: Text('Invalid Material'),
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
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF34A853,
                                    ).withOpacity(0.1),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF34A853,
                                      ).withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(cardPadding),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Header with title and status
                                      Row(
                                        children: [
                                          Container(
                                            width: 4,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF34A853),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              (material['title'] ?? 'No Title')
                                                  .toString(),
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: titleFontSize,
                                                color: Colors.black87,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),

                                      // Description
                                      Text(
                                        (material['description'] ??
                                                'No description')
                                            .toString(),
                                        style: TextStyle(
                                          fontSize: descriptionFontSize,
                                          color: Colors.black54,
                                          height: 1.2,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                      const Spacer(),

                                      // Footer with date and instructor
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF34A853,
                                          ).withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.access_time,
                                              color: const Color(0xFF34A853),
                                              size: iconSize - 2,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                (material['createdAt'] ??
                                                        'Unknown Date')
                                                    .toString(),
                                                style: TextStyle(
                                                  color: const Color(
                                                    0xFF34A853,
                                                  ),
                                                  fontSize:
                                                      descriptionFontSize - 1,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              Icons.person_outline,
                                              color: Colors.black54,
                                              size: iconSize - 2,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                (material['instructorName'] ??
                                                        'Unknown Instructor')
                                                    .toString(),
                                                style: TextStyle(
                                                  fontSize:
                                                      descriptionFontSize - 1,
                                                  color: Colors.black54,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              }),
    );
  }
}
