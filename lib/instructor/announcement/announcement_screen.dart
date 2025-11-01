import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import '../../shared/instructor/instructor_appbar.dart';
import '../../shared/instructor/instructor_sidebar.dart';
import '../../shared/instructor/instructor_navigation_constants.dart';
import 'announcement_screen_controller.dart';
import '../instructor_dashboard_controller.dart';

class InstructorAnnouncementScreen extends StatelessWidget {
  const InstructorAnnouncementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AnnouncementScreenController());
    final instructorController = Get.put(InstructorController());
    InstructorNavigationItem selectedItem =
        InstructorNavigationItem.announcements;

    void handleNavigationSelect(InstructorNavigationItem item) {
      selectedItem = item;
      String route = InstructorNavigationHelper.getRoute(item);
      Navigator.of(context).pushReplacementNamed(route);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          InstructorSidebar(
            selectedItem: selectedItem,
            onItemSelected: handleNavigationSelect,
          ),
          Expanded(
            child: Column(
              children: [
                Obx(
                  () => InstructorAppBar(
                    instructorName: instructorController.instructorName.value,
                    instructorRole: 'Instructor',
                    profileImageUrl: instructorController.profileImageUrl.value,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Announcements',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 32,
                              ),
                            ),
                            const Spacer(),
                            Obx(() {
                              if (!controller.showCreate.value) {
                                return ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF22C55E),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 22,
                                      vertical: 16,
                                    ),
                                  ),
                                  onPressed: controller.showCreateAnnouncement,
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'New Announcement',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            }),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Share important updates with your students',
                          style: TextStyle(color: Colors.black38, fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        // Add notification test widget for development
                        // const NotificationTestWidget(),
                        const SizedBox(height: 24),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Obx(() {
                                  if (controller.showCreate.value) {
                                    return Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: 24),
                                      padding: const EdgeInsets.all(32),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFB),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: const Color(0xFFE5E7EB),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Obx(
                                            () => Text(
                                              controller.isEditMode.value
                                                  ? 'Edit Announcement'
                                                  : 'Create New Announcement',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 22,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 18),
                                          const Text(
                                            'Title',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextField(
                                            controller:
                                                controller.titleController,
                                            cursorColor: Colors.black54,
                                            decoration: InputDecoration(
                                              hintText:
                                                  'Enter announcement title...',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFF34A853),
                                                  width: 2,
                                                ),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 14,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(height: 15),
                                          const Text(
                                            'Content',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextField(
                                            controller:
                                                controller.contentController,
                                            maxLines: 4,
                                            cursorColor: Colors.black54,
                                            decoration: InputDecoration(
                                              hintText:
                                                  'Write your announcement here...',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFF34A853),
                                                  width: 2,
                                                ),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 14,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(height: 15),
                                          // Section selection
                                          const Text(
                                            'Target Sections',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Obx(() {
                                            if (controller
                                                .isLoadingSections
                                                .value) {
                                              return Container(
                                                padding: const EdgeInsets.all(
                                                  16,
                                                ),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: Colors.grey[300]!,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Color(
                                                          0xFF34A853,
                                                        ),
                                                      ),
                                                ),
                                              );
                                            }

                                            return Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFF34A853,
                                                  ),
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: ExpansionTile(
                                                title: Obx(
                                                  () => Text(
                                                    controller
                                                        .getSelectedSectionsText(),
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                                trailing: const Icon(
                                                  Icons.arrow_drop_down,
                                                  color: Color(0xFF34A853),
                                                ),
                                                backgroundColor:
                                                    Colors.transparent,
                                                collapsedBackgroundColor:
                                                    Colors.transparent,
                                                children:
                                                    controller
                                                            .availableSections
                                                            .isEmpty
                                                        ? [
                                                          const Padding(
                                                            padding:
                                                                EdgeInsets.all(
                                                                  16,
                                                                ),
                                                            child: Text(
                                                              'No sections available',
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                            ),
                                                          ),
                                                        ]
                                                        : controller.availableSections.map((
                                                          section,
                                                        ) {
                                                          return Obx(() {
                                                            final isSelected =
                                                                controller
                                                                    .selectedClasses[section] ??
                                                                false;
                                                            return CheckboxListTile(
                                                              title: Text(
                                                                section,
                                                              ),
                                                              value: isSelected,
                                                              onChanged: (
                                                                value,
                                                              ) {
                                                                controller
                                                                    .toggleSectionSelection(
                                                                      section,
                                                                    );
                                                              },
                                                              activeColor:
                                                                  const Color(
                                                                    0xFF34A853,
                                                                  ),
                                                              controlAffinity:
                                                                  ListTileControlAffinity
                                                                      .leading,
                                                              contentPadding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        16,
                                                                    vertical: 4,
                                                                  ),
                                                            );
                                                          });
                                                        }).toList(),
                                              ),
                                            );
                                          }),
                                          const SizedBox(height: 15),
                                          // Image upload section
                                          const Text(
                                            'Image (Optional)',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Obx(() {
                                            final previewUrl =
                                                controller.previewImageUrl;
                                            if (previewUrl != null &&
                                                previewUrl.isNotEmpty) {
                                              // Show selected/existing image preview
                                              return Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.grey[300]!,
                                                  ),
                                                ),
                                                child: Stack(
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      child: Center(
                                                        child:
                                                            previewUrl
                                                                    .startsWith(
                                                                      'data:',
                                                                    )
                                                                ? Image.memory(
                                                                  base64Decode(
                                                                    previewUrl
                                                                        .split(
                                                                          ',',
                                                                        )[1],
                                                                  ),
                                                                  height: 250,
                                                                  fit:
                                                                      BoxFit
                                                                          .contain,
                                                                )
                                                                : Image.network(
                                                                  previewUrl,
                                                                  height: 250,
                                                                  fit:
                                                                      BoxFit
                                                                          .contain,
                                                                  errorBuilder: (
                                                                    context,
                                                                    error,
                                                                    stackTrace,
                                                                  ) {
                                                                    return Container(
                                                                      height:
                                                                          250,
                                                                      color:
                                                                          Colors
                                                                              .grey[200],
                                                                      child: const Center(
                                                                        child: Icon(
                                                                          Icons
                                                                              .broken_image,
                                                                          size:
                                                                              48,
                                                                        ),
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      top: 8,
                                                      right: 8,
                                                      child: IconButton(
                                                        icon: const Icon(
                                                          Icons.close,
                                                          color: Colors.white,
                                                        ),
                                                        style:
                                                            IconButton.styleFrom(
                                                              backgroundColor:
                                                                  Colors
                                                                      .black54,
                                                            ),
                                                        onPressed:
                                                            controller
                                                                .removeImage,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            } else {
                                              // Show upload button
                                              return OutlinedButton.icon(
                                                onPressed: controller.pickImage,
                                                icon: const Icon(
                                                  Icons.image_outlined,
                                                ),
                                                label: const Text(
                                                  'Select Image',
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: const Color(
                                                    0xFF34A853,
                                                  ),
                                                  side: const BorderSide(
                                                    color: Color(0xFF34A853),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 12,
                                                      ),
                                                ),
                                              );
                                            }
                                          }),
                                          const SizedBox(height: 15),
                                          Row(
                                            children: [
                                              Obx(
                                                () => Switch(
                                                  value:
                                                      controller.pinToTop.value,
                                                  onChanged:
                                                      (v) =>
                                                          controller
                                                              .pinToTop
                                                              .value = v,
                                                  activeThumbColor: const Color(
                                                    0xFF34A853,
                                                  ),
                                                ),
                                              ),
                                              const Text(
                                                'Pin to top',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(width: 20),
                                              Obx(
                                                () => Switch(
                                                  value:
                                                      controller.urgent.value,
                                                  onChanged:
                                                      (v) =>
                                                          controller
                                                              .urgent
                                                              .value = v,
                                                  activeThumbColor: Colors.red,
                                                ),
                                              ),
                                              const Text(
                                                'Mark as urgent',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Obx(
                                                () => ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFF34A853),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 32,
                                                          vertical: 16,
                                                        ),
                                                  ),
                                                  onPressed:
                                                      controller.isLoading.value
                                                          ? null
                                                          : controller
                                                              .postAnnouncement,
                                                  child:
                                                      controller.isLoading.value
                                                          ? const SizedBox(
                                                            width: 20,
                                                            height: 15,
                                                            child:
                                                                CircularProgressIndicator(
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                  strokeWidth:
                                                                      2,
                                                                ),
                                                          )
                                                          : Obx(
                                                            () => Text(
                                                              controller
                                                                      .isEditMode
                                                                      .value
                                                                  ? 'Update Announcement'
                                                                  : 'Post Announcement',
                                                              style: const TextStyle(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                ),
                                              ),
                                              const SizedBox(width: 7),
                                              OutlinedButton(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.black,
                                                  side: const BorderSide(
                                                    color: Color(0xFF34A853),
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 8,
                                                      ),
                                                ),
                                                onPressed:
                                                    controller.cancelCreate,
                                                child: const Text(
                                                  'Cancel',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }),
                                // Hide announcements when edit/create form is visible
                                Obx(() {
                                  // Don't show announcements when form is visible
                                  if (controller.showCreate.value) {
                                    return const SizedBox.shrink();
                                  }

                                  if (controller.isLoading.value &&
                                      controller.announcements.isEmpty) {
                                    return const SizedBox(
                                      height: 200,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF34A853),
                                        ),
                                      ),
                                    );
                                  }

                                  if (controller.announcements.isEmpty) {
                                    return const SizedBox(
                                      height: 200,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.announcement_outlined,
                                              size: 64,
                                              color: Colors.grey,
                                            ),
                                            SizedBox(height: 13),
                                            Text(
                                              'No announcements yet',
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.grey,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Create your first announcement to get started',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  return ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: controller.announcements.length,
                                    separatorBuilder:
                                        (_, __) => const SizedBox(height: 18),
                                    itemBuilder: (context, i) {
                                      final a = controller.announcements[i];
                                      return Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color:
                                              a['pinned']
                                                  ? const Color(0xFFF8FAFB)
                                                  : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFE5E7EB),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                if (a['pinned'])
                                                  const Icon(
                                                    Icons.push_pin,
                                                    color: Color(0xFF22C55E),
                                                    size: 22,
                                                  ),
                                                Expanded(
                                                  child: Text(
                                                    a['title'],
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18,
                                                      color:
                                                          a['pinned']
                                                              ? const Color(
                                                                0xFF22C55E,
                                                              )
                                                              : Colors.black,
                                                    ),
                                                  ),
                                                ),
                                                if (a['urgent'])
                                                  Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                          left: 10,
                                                        ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFFFE5E5,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: const Text(
                                                      'Urgent',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              a['content'],
                                              style: const TextStyle(
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              children: [
                                                Text(
                                                  a['date'],
                                                  style: const TextStyle(
                                                    color: Colors.black38,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const Spacer(),
                                                IconButton(
                                                  onPressed:
                                                      () => controller
                                                          .showEditAnnouncement(
                                                            a,
                                                          ),
                                                  icon: const Icon(
                                                    Icons.edit_outlined,
                                                    color: Color(0xFF34A853),
                                                  ),
                                                  tooltip: 'Edit announcement',
                                                ),
                                                IconButton(
                                                  onPressed:
                                                      () =>
                                                          controller.togglePin(
                                                            a['id'],
                                                            a['pinned'],
                                                          ),
                                                  icon: Icon(
                                                    a['pinned']
                                                        ? Icons.push_pin
                                                        : Icons
                                                            .push_pin_outlined,
                                                    color:
                                                        a['pinned']
                                                            ? const Color(
                                                              0xFF22C55E,
                                                            )
                                                            : Colors.grey,
                                                  ),
                                                  tooltip:
                                                      a['pinned']
                                                          ? 'Unpin'
                                                          : 'Pin to top',
                                                ),
                                                IconButton(
                                                  onPressed:
                                                      () => _showDeleteDialog(
                                                        context,
                                                        controller,
                                                        a['id'],
                                                        a['title'],
                                                      ),
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.red,
                                                  ),
                                                  tooltip:
                                                      'Delete announcement',
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                }),
                              ],
                            ),
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

  void _showDeleteDialog(
    BuildContext context,
    AnnouncementScreenController controller,
    String id,
    String title,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Announcement'),
          content: Text('Are you sure you want to delete "$title"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                controller.deleteAnnouncement(id);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
