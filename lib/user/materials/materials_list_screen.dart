import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'materials_list_screen_controller.dart';
import 'materials_detail_screen.dart';
import 'package:greenquest/shared/widgets/skeleton_loading.dart';
import 'package:greenquest/shared/login/custom_drawer.dart';
import 'package:greenquest/shared/widgets/pull_to_refresh_wrapper.dart';

class MaterialsListScreen extends StatefulWidget {
  const MaterialsListScreen({super.key});

  @override
  State<MaterialsListScreen> createState() => _MaterialsListScreenState();
}

class _MaterialsListScreenState extends State<MaterialsListScreen> {
  MaterialsListScreenController? controller;
  int selectedDrawerIndex = 4;

  @override
  void initState() {
    super.initState();
    controller = Get.put(MaterialsListScreenController());
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
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Learning Materials',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: PullToRefreshWrapper(
        onRefresh: () async {
          await controller?.refreshMaterials();
        },
        wrapContent: false,
        child: Obx(() {
          if (controller?.isLoading.value ?? true) {
            return _buildSkeletonLoading();
          }

          if (controller?.errorMessage.value.isNotEmpty ?? false) {
            return _buildErrorState(controller!.errorMessage.value);
          }

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: controller!.getMaterialsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildSkeletonLoading();
              }

              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              }

              final materials = snapshot.data ?? [];

              if (materials.isEmpty) {
                return _buildEmptyState();
              }

              return _buildMaterialsGrid(materials, context);
            },
          );
        }),
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 600;
        final isTablet = screenWidth >= 600 && screenWidth < 1200;
        final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20.0 : (isTablet ? 24.0 : 32.0),
              vertical: isMobile ? 20.0 : (isTablet ? 24.0 : 32.0),
            ),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: isMobile ? 12.0 : 16.0,
                mainAxisSpacing: isMobile ? 20.0 : (isTablet ? 24.0 : 32.0),
                childAspectRatio: 2.2,
              ),
              itemCount: 6,
              itemBuilder: (context, i) => const SkeletonGridItem(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: $error',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
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
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMaterialsGrid(
    List<Map<String, dynamic>> materials,
    BuildContext context,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 600;
        final isTablet = screenWidth >= 600 && screenWidth < 1200;

        final gridPadding = isMobile ? 20.0 : (isTablet ? 24.0 : 32.0);
        final cardPadding = isMobile ? 16.0 : 20.0;
        final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);
        final childAspectRatio = isMobile ? 2.2 : (isTablet ? 2.4 : 2.6);

        final titleFontSize = isMobile ? 16.0 : (isTablet ? 18.0 : 20.0);
        final descriptionFontSize = isMobile ? 13.0 : (isTablet ? 14.0 : 15.0);
        final iconSize = isMobile ? 14.0 : (isTablet ? 16.0 : 18.0);

        return GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: gridPadding,
            vertical: gridPadding,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: isMobile ? 12.0 : 16.0,
            mainAxisSpacing: gridPadding,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: materials.length,
          itemBuilder: (context, i) {
            final material = materials[i];

            return GestureDetector(
              onTap: () {
                if (material.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MaterialsDetailScreen(material: material),
                    ),
                  );
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF34A853).withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF34A853).withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFF34A853),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (material['title'] ?? 'No Title').toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: titleFontSize,
                                    color: Colors.black,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        (material['description'] ?? 'No description')
                            .toString(),
                        style: TextStyle(
                          fontSize: descriptionFontSize,
                          color: Colors.grey[700],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34A853).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: const Color(0xFF34A853),
                              size: iconSize,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                (material['createdAt'] ?? 'Unknown Date')
                                    .toString(),
                                style: TextStyle(
                                  color: const Color(0xFF34A853),
                                  fontSize: descriptionFontSize - 1,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.person_outline,
                              color: Colors.black54,
                              size: iconSize,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                (material['instructorName'] ??
                                        'Unknown Instructor')
                                    .toString(),
                                style: TextStyle(
                                  fontSize: descriptionFontSize - 1,
                                  color: Colors.black54,
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
        );
      },
    );
  }
}
