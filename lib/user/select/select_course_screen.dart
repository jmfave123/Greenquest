import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenquest/user/select/select_controller.dart';

class SelectCourseScreen extends StatefulWidget {
  const SelectCourseScreen({super.key});

  @override
  State<SelectCourseScreen> createState() => _SelectCourseScreenState();
}

class _SelectCourseScreenState extends State<SelectCourseScreen> {
  final controller = Get.put(SelectController());

  bool showSubCourses = false;
  String? selectedSubCourse;
  bool showSectionDropdown = false;
  String? selectedSection;

  // final courses = [
  //   {
  //     'name': 'Bachelor of Science in Information Technology',
  //     'img': 'assets/images/image 331.png',
  //   },
  //   {
  //     'name': 'Bachelor of Science in Food Processing and Technology',
  //     'img': 'assets/images/image 337.png',
  //   },
  //   {
  //     'name': 'Bachelor of Technology and Livelihood Education',
  //     'img': 'assets/images/image 349.png',
  //   },
  // ];
  final subCourses = [
    'Home Economics (HE)',
    'Information and Communication Technology (ICT)',
    'Industrial Arts (IA)',
  ];
  final sections = ['ICT- A', 'ICT- B', 'ICT- C', 'ICT- D', 'ICT- E', 'ICT- F'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Obx(() {
            final courses = controller.courses;
            if (controller.isLoading.value) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading courses...'),
                  ],
                ),
              );
            }
            if (courses.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No courses found'),
                    SizedBox(height: 8),
                    Text(
                      'Please try again later',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                const Text(
                  'Course and Sections',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select your course and section',
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                // First two courses
                ...courses
                    .take(2)
                    .map(
                      (course) => GestureDetector(
                        onTap: () {},
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: ListTile(
                            leading:
                                course['img'] != null
                                    ? Image.memory(
                                      base64Decode(course['img']),
                                      width: 44,
                                      height: 44,
                                    )
                                    : Image.asset(
                                      'assets/images/image 331.png',
                                      width: 44,
                                      height: 44,
                                    ),
                            title: Text(
                              course['name']!,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                // BTLED course with expandable sub-courses
                GestureDetector(
                  onTap: () {
                    setState(() {
                      showSubCourses = !showSubCourses;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        children: [
                          ListTile(
                            leading:
                                courses[2]['img'] != null
                                    ? Image.memory(
                                      base64Decode(courses[2]['img']),
                                      width: 44,
                                      height: 44,
                                    )
                                    : Image.asset(
                                      'assets/images/image 349.png',
                                      width: 44,
                                      height: 44,
                                    ),
                            title: const Text(
                              'Bachelor of Technology and Livelihood Education',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: Icon(
                              showSubCourses
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 28,
                            ),
                          ),
                          if (showSubCourses)
                            ...subCourses.map(
                              (sub) => GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedSubCourse = sub;
                                    showSubCourses = false;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 0,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        selectedSubCourse == sub
                                            ? const Color(0xFFF2F6FB)
                                            : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFE0E0E0),
                                    ),
                                  ),
                                  child: ListTile(
                                    leading:
                                        courses[2]['img'] != null
                                            ? Image.memory(
                                              base64Decode(courses[2]['img']),
                                              width: 44,
                                              height: 44,
                                            )
                                            : Image.asset(
                                              'assets/images/image 349.png',
                                              width: 44,
                                              height: 44,
                                            ),
                                    title: Text(
                                      sub,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    selected: selectedSubCourse == sub,
                                    selectedTileColor: const Color(0xFFF2F6FB),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Section dropdown styled as a container
                GestureDetector(
                  onTap:
                      selectedSubCourse == null
                          ? null
                          : () {
                            setState(() {
                              showSectionDropdown = !showSectionDropdown;
                            });
                          },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16, top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: ListTile(
                      title: Text(
                        selectedSection ?? 'Section',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color:
                              selectedSection == null
                                  ? Colors.black54
                                  : Colors.black,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                if (showSectionDropdown && selectedSubCourse != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Column(
                      children:
                          sections
                              .map(
                                (s) => GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedSection = s;
                                      showSectionDropdown = false;
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color:
                                          selectedSection == s
                                              ? const Color(0xFFF2F6FB)
                                              : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        s,
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                      selected: selectedSection == s,
                                      selectedTileColor: const Color(
                                        0xFFF2F6FB,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          selectedSubCourse != null && selectedSection != null
                              ? () {
                                Get.toNamed('/home');
                              }
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF43A047),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
