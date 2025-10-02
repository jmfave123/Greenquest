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

  void selectInstructor(String instructorId, String instructorName) async {
    await selectController.selectInstructor(instructorId, instructorName);
    // Automatically navigate to course screen after selection
    Get.toNamed('/select-course');
  }

  bool isInstructorSelected(String instructorId) {
    return selectController.selectedInstructorId.value == instructorId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
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
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.search, color: Colors.black38),
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.black38),
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
                enabled: false,
              ),
            ),
            Obx(() {
              RxList instructors = selectController.instructors;
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
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No instructors found'),
                      SizedBox(height: 8),
                      Text(
                        'Please try again later',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.75,
                children: List.generate(instructors.length, (index) {
                  final instructor = instructors[index];
                  final isSelected = isInstructorSelected(
                    instructor['uid'] ?? '',
                  );

                  return GestureDetector(
                    onTap:
                        () => selectInstructor(
                          instructor['uid'] ?? '',
                          instructor['name'] ?? '',
                        ),
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
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage:
                                instructor['img'] != null
                                    ? MemoryImage(
                                      base64Decode(instructor['img']),
                                    )
                                    : AssetImage(
                                      'assets/images/image_311-removebg-preview.png',
                                    ),
                          ),
                          const SizedBox(height: 6),
                          Flexible(
                            child: Text(
                              instructor['name'] ?? '',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                color:
                                    isSelected
                                        ? const Color(0xFF43A047)
                                        : Colors.black,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      selectController.selectedInstructorId.value.isNotEmpty
                          ? () => Get.toNamed('/select-course')
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        selectController.selectedInstructorId.value.isNotEmpty
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
          ],
        ),
      ),
    );
  }
}
