import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/instructor/instructor_appbar.dart';
import '../../shared/instructor/instructor_sidebar.dart';
import '../../shared/instructor/instructor_navigation_constants.dart';
import '../../shared/widgets/skeleton_loading.dart';
import '../../shared/widgets/edit_profile_dialog.dart';
import 'profile_screen_controller.dart';

class InstructorProfileScreen extends StatefulWidget {
  const InstructorProfileScreen({super.key});

  @override
  State<InstructorProfileScreen> createState() =>
      _InstructorProfileScreenState();
}

class _InstructorProfileScreenState extends State<InstructorProfileScreen> {
  InstructorNavigationItem _selectedItem = InstructorNavigationItem.profile;
  InstructorController? _controller;

  void _onNavigationSelect(InstructorNavigationItem item) {
    setState(() => _selectedItem = item);
  }

  void _showEditDialog(BuildContext context) {
    if (_controller == null) return;
    _controller!.startEditing();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return EditProfileDialog(controller: _controller!);
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    try {
      // Try to find existing controller first
      _controller = Get.find<InstructorController>();
    } catch (e) {
      // If not found, create a new one
      _controller = Get.put(InstructorController());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          InstructorSidebar(
            selectedItem: _selectedItem,
            onItemSelected: _onNavigationSelect,
          ),
          Expanded(
            child: Column(
              children: [
                Obx(
                  () => InstructorAppBar(
                    instructorName:
                        _controller?.name.value.isEmpty ?? true
                            ? 'Loading...'
                            : _controller!.name.value,
                    instructorRole: 'Instructor',
                    profileImageUrl: _controller?.profileImageUrl.value,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal:
                            MediaQuery.of(context).size.width < 1200 ? 24 : 48,
                        vertical: 32,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Instructor Profile',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 32,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Manage your professional information',
                            style: TextStyle(
                              color: Colors.black38,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Obx(() {
                            if (_controller == null) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: SkeletonInstructorProfile(),
                              );
                            }

                            if (_controller!.isLoading.value) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: SkeletonInstructorProfile(),
                              );
                            }

                            if (_controller!.hasError.value) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      size: 64,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Error loading profile',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _controller!.errorMessage.value,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed:
                                          () => _controller!.refreshData(),
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return LayoutBuilder(
                              builder: (context, constraints) {
                                final isSmallScreen =
                                    constraints.maxWidth < 800;
                                return Flex(
                                  direction:
                                      isSmallScreen
                                          ? Axis.vertical
                                          : Axis.horizontal,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Flexible(
                                      flex: isSmallScreen ? 0 : 1,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          GestureDetector(
                                            onTap:
                                                () =>
                                                    _controller!
                                                        .showProfileImageOptions(),
                                            child: Obx(() {
                                              // Get initials from name
                                              String getInitials(String name) {
                                                if (name.isEmpty) return '';
                                                final parts = name.trim().split(
                                                  ' ',
                                                );
                                                if (parts.length == 1) {
                                                  return parts[0]
                                                      .substring(0, 1)
                                                      .toUpperCase();
                                                }
                                                return (parts.first.substring(
                                                          0,
                                                          1,
                                                        ) +
                                                        parts.last.substring(
                                                          0,
                                                          1,
                                                        ))
                                                    .toUpperCase();
                                              }

                                              final initials = getInitials(
                                                _controller!.name.value,
                                              );
                                              final hasImage =
                                                  _controller!
                                                      .profileImageUrl
                                                      .value
                                                      .isNotEmpty;

                                              return Stack(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 48,
                                                    backgroundColor:
                                                        hasImage
                                                            ? Colors.transparent
                                                            : Colors
                                                                .blue
                                                                .shade700,
                                                    backgroundImage:
                                                        hasImage
                                                            ? NetworkImage(
                                                              _controller!
                                                                  .profileImageUrl
                                                                  .value,
                                                            )
                                                            : null,
                                                    child:
                                                        !hasImage
                                                            ? Text(
                                                              initials,
                                                              style: const TextStyle(
                                                                fontSize: 36,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    Colors
                                                                        .white,
                                                              ),
                                                            )
                                                            : null,
                                                  ),
                                                  if (_controller!
                                                      .isUploadingImage
                                                      .value)
                                                    Positioned.fill(
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                              color:
                                                                  Colors
                                                                      .black54,
                                                              shape:
                                                                  BoxShape
                                                                      .circle,
                                                            ),
                                                        child: const Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                strokeWidth: 2,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  Positioned(
                                                    bottom: 0,
                                                    right: 0,
                                                    child: Container(
                                                      decoration:
                                                          const BoxDecoration(
                                                            color: Colors.blue,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                      padding:
                                                          const EdgeInsets.all(
                                                            4,
                                                          ),
                                                      child: const Icon(
                                                        Icons.camera_alt,
                                                        color: Colors.white,
                                                        size: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }),
                                          ),
                                          const SizedBox(height: 18),
                                          Text(
                                            _controller!.name.value,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 22,
                                            ),
                                          ),
                                          const SizedBox(height: 18),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              const Icon(
                                                Icons.email_outlined,
                                                size: 20,
                                                color: Colors.black54,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                _controller!.email.value,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              const Icon(
                                                Icons.phone_outlined,
                                                size: 20,
                                                color: Colors.black54,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                _controller!.phone.value,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!isSmallScreen)
                                      const SizedBox(width: 32),
                                    if (isSmallScreen)
                                      const SizedBox(height: 20),
                                    Flexible(
                                      flex: 0,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: Colors.black,
                                              side: const BorderSide(
                                                color: Color(0xFFBDBDBD),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 22,
                                                    vertical: 16,
                                                  ),
                                            ),
                                            onPressed:
                                                () => _showEditDialog(context),
                                            icon: const Icon(
                                              Icons.edit,
                                              size: 18,
                                            ),
                                            label: const Text(
                                              'Edit Profile',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          }),
                          const SizedBox(height: 40),
                          Obx(() {
                            if (_controller?.about.value.isEmpty ?? true) {
                              return const SizedBox.shrink();
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'About',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 600,
                                  ),
                                  child: Text(
                                    _controller!.about.value,
                                    style: const TextStyle(fontSize: 16),
                                    textAlign: TextAlign.justify,
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
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
}
