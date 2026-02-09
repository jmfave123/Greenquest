import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../user/select/select_controller.dart';
import '../../config/web_theme.dart';
import '../../config/web_routes.dart';
import '../../utils/web_responsive_utils.dart';
import '../../widgets/layout/web_app_bar.dart';

class WebSelectInstructorScreen extends StatefulWidget {
  const WebSelectInstructorScreen({super.key});

  @override
  State<WebSelectInstructorScreen> createState() =>
      _WebSelectInstructorScreenState();
}

class _WebSelectInstructorScreenState extends State<WebSelectInstructorScreen> {
  final controller = Get.put(SelectController());
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  ImageProvider? _getProfileImage(Map<String, dynamic> instructor) {
    String? url = instructor['profileImageUrl'];
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('data:image/') || url.startsWith('/9j/')) {
      try {
        return MemoryImage(base64Decode(url));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(url);
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = WebResponsiveUtils.isMobile(context);
    final isDesktop = WebResponsiveUtils.isDesktop(context);

    return Scaffold(
      backgroundColor: WebTheme.backgroundLight,
      appBar: WebAppBar(
        title: 'Select Your Instructor',
        showNotifications: false,
        showProfileDropdown: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              _buildHeader(isMobile),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value)
                    return const Center(child: CircularProgressIndicator());
                  final instructors = controller.filteredInstructors;
                  if (instructors.isEmpty) return _buildEmptyState();
                  return _buildGrid(instructors, isMobile, isDesktop);
                }),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      child: Column(
        children: [
          Text('NSTP Instructors', style: WebTheme.headingMedium),
          const SizedBox(height: 8),
          Text(
            'Choose the instructor assigned to your section',
            style: WebTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _searchController,
            onChanged: (v) => controller.searchQuery.value = v,
            decoration: InputDecoration(
              hintText: 'Search by name...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  controller.searchQuery.value = '';
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List instructors, bool isMobile, bool isDesktop) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:
            isDesktop
                ? 4
                : isMobile
                ? 2
                : 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 0.85,
      ),
      itemCount: instructors.length,
      itemBuilder: (context, index) {
        final instructor = instructors[index];
        return _buildInstructorCard(instructor);
      },
    );
  }

  Widget _buildInstructorCard(Map<String, dynamic> inst) {
    final name = inst['name'] ?? '';
    final id = inst['uid'] ?? '';
    final hasClasses = inst['hasClasses'] ?? false;

    return Obx(() {
      final isSelected = controller.selectedInstructorId.value == id;
      return MouseRegion(
        cursor:
            hasClasses ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap:
              hasClasses ? () => controller.selectInstructor(id, name) : null,
          child: Opacity(
            opacity: hasClasses ? 1.0 : 0.6,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? WebTheme.primaryGreen.withOpacity(0.05)
                        : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isSelected ? WebTheme.primaryGreen : WebTheme.borderLight,
                  width: 2,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: WebTheme.primaryGreen.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundImage: _getProfileImage(inst),
                    backgroundColor: _getAvatarColor(name),
                    child:
                        _getProfileImage(inst) == null
                            ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                            : null,
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      style: WebTheme.bodyLarge.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!hasClasses)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'No active classes',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: WebTheme.textHint),
          const SizedBox(height: 16),
          Text('No instructors found', style: WebTheme.headingSmall),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: WebTheme.borderLight)),
      ),
      child: Obx(() {
        final hasSelection = controller.selectedInstructorId.value.isNotEmpty;
        return Row(
          children: [
            if (hasSelection)
              Expanded(
                child: Text(
                  'Selected: ${controller.selectedInstructorName.value}',
                  style: WebTheme.bodyLarge.copyWith(
                    color: WebTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const Spacer(),
            ElevatedButton(
              onPressed:
                  hasSelection
                      ? () => Get.toNamed(WebRoutes.selectCourse)
                      : null,
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              child: const Text('Continue'),
            ),
          ],
        );
      }),
    );
  }
}
