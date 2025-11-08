import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenquest/user/select/select_controller.dart';

class SelectInstructorScreen extends StatefulWidget {
  const SelectInstructorScreen({super.key});

  @override
  State<SelectInstructorScreen> createState() => _SelectInstructorScreenState();
}

class _SelectInstructorScreenState extends State<SelectInstructorScreen> {
  final selectController = Get.put(SelectController());
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  void selectInstructor(String instructorId, String instructorName) async {
    // Dismiss keyboard and clear search when selecting instructor
    searchFocusNode.unfocus();
    searchController.clear();
    selectController.searchQuery.value = '';
    await selectController.selectInstructor(instructorId, instructorName);
    // Navigation is now handled by the Continue button
  }

  bool isInstructorSelected(String instructorId) {
    return selectController.selectedInstructorId.value == instructorId;
  }

  /// Get instructor profile image from various possible fields
  ImageProvider? _getInstructorProfileImage(Map<String, dynamic> instructor) {
    // Try different possible field names for profile image
    String? imageUrl =
        instructor['profileImageUrl'] ??
        instructor['profileImage'] ??
        instructor['img'];

    if (imageUrl != null && imageUrl.isNotEmpty) {
      // Check if it's a base64 encoded image
      if (imageUrl.startsWith('data:image/') || imageUrl.startsWith('/9j/')) {
        try {
          return MemoryImage(base64Decode(imageUrl));
        } catch (e) {
          print('Error decoding base64 image: $e');
        }
      }
      // Check if it's a network URL
      else if (imageUrl.startsWith('http://') ||
          imageUrl.startsWith('https://')) {
        return NetworkImage(imageUrl);
      }
      // Check if it's a Cloudinary URL (common in this app)
      else if (imageUrl.contains('cloudinary.com') ||
          imageUrl.contains('res.cloudinary.com')) {
        return NetworkImage(imageUrl);
      }
    }

    // Return null if no valid image found (will use initials instead)
    return null;
  }

  /// Get initials from instructor name (e.g., "Jovel Lapornina" -> "JL")
  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      // Single name - take first 2 characters
      return parts[0]
          .substring(0, parts[0].length > 2 ? 2 : parts[0].length)
          .toUpperCase();
    } else {
      // Multiple names - take first letter of first and last name
      final first = parts[0].isNotEmpty ? parts[0][0] : '';
      final last =
          parts[parts.length - 1].isNotEmpty ? parts[parts.length - 1][0] : '';
      return (first + last).toUpperCase();
    }
  }

  /// Get color for avatar based on instructor name
  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF43A047),
      const Color(0xFF2196F3),
      const Color(0xFF9C27B0),
      const Color(0xFFF57C00),
      const Color(0xFFE91E63),
      const Color(0xFF00BCD4),
      const Color(0xFF795548),
      const Color(0xFF607D8B),
    ];

    // Use name hash to consistently assign color
    int hash = name.hashCode;
    return colors[hash.abs() % colors.length];
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside search field
          searchFocusNode.unfocus();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              const Text(
                'NSTP Instructors',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select your instructor',
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Obx(
                  () => TextField(
                    controller: searchController,
                    focusNode: searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Search instructors...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.black38,
                      ),
                      suffixIcon:
                          selectController.searchQuery.value.isNotEmpty
                              ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.black38,
                                ),
                                onPressed: () {
                                  searchController.clear();
                                  selectController.searchQuery.value = '';
                                },
                              )
                              : null,
                      border: InputBorder.none,
                      hintStyle: const TextStyle(color: Colors.black38),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onChanged: (value) {
                      selectController.searchQuery.value = value;
                    },
                  ),
                ),
              ),
              Obx(() {
                RxList instructors = selectController.filteredInstructors;
                if (selectController.isLoading.value) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading instructors...'),
                      ],
                    ),
                  );
                }
                if (instructors.isEmpty) {
                  final hasSearchQuery =
                      selectController.searchQuery.value.isNotEmpty;
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          hasSearchQuery
                              ? Icons.search_off
                              : Icons.error_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          hasSearchQuery
                              ? 'No instructors found matching "${selectController.searchQuery.value}"'
                              : 'No instructors found',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hasSearchQuery
                              ? 'Try a different search term'
                              : 'Please try again later',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85, // Adjusted to prevent overflow
                  padding: EdgeInsets.zero,
                  children: List.generate(instructors.length, (index) {
                    final instructor = instructors[index];
                    final instructorName = instructor['name'] ?? '';
                    final instructorUid = instructor['uid'] ?? '';

                    // Skip instructors without valid names or UIDs
                    if (instructorName.isEmpty || instructorUid.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final isSelected = isInstructorSelected(instructorUid);
                    final hasClasses = instructor['hasClasses'] ?? false;

                    return GestureDetector(
                      onTap:
                          hasClasses
                              ? () => selectInstructor(
                                instructorUid,
                                instructorName,
                              )
                              : () {
                                // Show tooltip or snackbar when trying to select instructor without classes
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'This instructor does not have any classes yet',
                                    ),
                                    duration: Duration(seconds: 2),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              },
                      child: Opacity(
                        opacity: hasClasses ? 1.0 : 0.5,
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? const Color(0xFFE8F5E8)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? const Color(0xFF43A047)
                                      : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  // Check if instructor has profile image
                                  _getInstructorProfileImage(instructor) != null
                                      ? CircleAvatar(
                                        radius: 24,
                                        backgroundImage:
                                            _getInstructorProfileImage(
                                              instructor,
                                            ),
                                      )
                                      : CircleAvatar(
                                        radius: 24,
                                        backgroundColor: _getAvatarColor(
                                          instructorName,
                                        ),
                                        child: Text(
                                          _getInitials(instructorName),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  if (!hasClasses)
                                    Positioned(
                                      right: -2,
                                      bottom: -2,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.orange,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.info_outline,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Flexible(
                                child: Text(
                                  instructorName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    color:
                                        isSelected
                                            ? const Color(0xFF43A047)
                                            : hasClasses
                                            ? Colors.black
                                            : Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!hasClasses)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    'No classes',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                );
              }),

              // Show instructor info if selected
              Obx(() {
                if (selectController.selectedInstructorId.value.isNotEmpty) {
                  return Container(
                    margin: const EdgeInsets.only(top: 20, bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person,
                          color: Color(0xFF34A853),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selected: ${selectController.selectedInstructorName.value}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                selectController.studentName.value.isNotEmpty
                                    ? 'Student: ${selectController.studentName.value}'
                                    : 'Tap to continue to course selection',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFF34A853),
                          size: 16,
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: Obx(
                    () => ElevatedButton(
                      onPressed:
                          selectController.selectedInstructorId.value.isNotEmpty
                              ? () => Get.toNamed('/select-course')
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            selectController
                                    .selectedInstructorId
                                    .value
                                    .isNotEmpty
                                ? const Color(0xFF43A047)
                                : Colors.grey,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text('Continue'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
