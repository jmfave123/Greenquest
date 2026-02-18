import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenquest/user/select/select_controller.dart';
import 'package:greenquest/shared/widgets/search_bar_widget.dart';
import 'package:greenquest/shared/widgets/instructor_selection_footer.dart';

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
              SearchBarWidget(
                controller: searchController,
                searchQuery: selectController.searchQuery,
                hintText: 'Search instructors...',
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

              // Selection footer with continue button
              InstructorSelectionFooter(
                selectedInstructorId: selectController.selectedInstructorId,
                selectedInstructorName: selectController.selectedInstructorName,
                studentName: selectController.studentName,
                onContinue: () => Get.toNamed('/select-course'),
                isWeb: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
