import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../shared/instructor/instructor_appbar.dart';
import '../../shared/instructor/instructor_sidebar.dart';
import '../../shared/instructor/instructor_navigation_constants.dart';
import '../instructor_dashboard_controller.dart';
import 'package:get/get.dart';
import '../../shared/services/message_service.dart';
import '../../shared/models/message_model.dart';
import 'package:file_picker/file_picker.dart';
import '../../shared/services/file_upload_service.dart';
import '../../shared/utils/file_type_utils.dart';
import '../../shared/widgets/file_display_widgets.dart';
import '../../shared/services/file_download_service.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/widgets/skeleton_loading.dart';
import '../../shared/utils/presence_utils.dart';

class InstructorMessageScreen extends StatefulWidget {
  final Map<String, dynamic> student;
  const InstructorMessageScreen({super.key, required this.student});

  @override
  State<InstructorMessageScreen> createState() =>
      _InstructorMessageScreenState();
}

class _InstructorMessageScreenState extends State<InstructorMessageScreen> {
  InstructorNavigationItem _selectedItem = InstructorNavigationItem.messages;
  final InstructorController instructorController = Get.put(
    InstructorController(),
  );
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Preview state for attachments
  PlatformFile? _previewFile;
  bool _isUploading = false;
  bool _hasMarkedAsRead = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _clearPreview() {
    setState(() {
      _previewFile = null;
    });
  }

  void _showDeleteDialog(BuildContext context, MessageModel message) {
    showDialog(
      context: context,
      builder:
          (context) => ConfirmationDialog(
            title: 'Unsend Message',
            message: 'Are you sure you want to unsend this message?',

            confirmText: 'Unsend',
            cancelText: 'Cancel',
            icon: Icons.undo_outlined,
            iconColor: Colors.orange,
            confirmButtonColor: Colors.orange,
            onConfirm: () async {
              try {
                await MessageService.unsendMessage(message.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Message unsent successfully'),
                      backgroundColor: Color(0xFF22C55E),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to unsend message: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      return '${hour == 0 ? 12 : hour}:${dateTime.minute.toString().padLeft(2, '0')} $period';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      const days = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      return days[dateTime.weekday - 1];
    } else {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[dateTime.month - 1]} ${dateTime.day}';
    }
  }

  String _formatLastSeen(DateTime lastSeenTime) {
    return PresenceUtils.formatLastSeen(lastSeenTime);
  }

  void _sendMessage() async {
    final content = _controller.text.trim();
    final hasContent = content.isNotEmpty;
    final hasAttachment = _previewFile != null;

    if ((!hasContent && !hasAttachment) || widget.student['id'] == null) return;

    if (_isUploading) return; // Prevent double sending

    // Capture ScaffoldMessenger before async operations to avoid context lookup issues
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      setState(() {
        _isUploading = true;
      });

      // If there's an attachment, upload and send with file
      if (hasAttachment && _previewFile != null) {
        final file = _previewFile!;

        if (file.bytes == null) {
          throw Exception('File bytes are null');
        }

        // Upload to Cloudinary
        final fileUploadService = FileUploadService();
        fileUploadService.initialize();

        final response = await fileUploadService.uploadFile(
          file: file,
          folder: 'greenquest/messages',
        );

        if (!mounted) return;

        if (response != null) {
          // Send message with file attachment
          await MessageService.sendMessageWithFile(
            receiverId: widget.student['id'],
            content:
                content, // Send empty string if no content, file name will be shown in UI
            fileName: file.name,
            fileUrl: response.url,
            fileType: file.extension ?? 'unknown',
            fileSize: file.size,
            senderType: 'instructor',
          );

          if (!mounted) return;

          // Clear preview and text
          setState(() {
            _previewFile = null;
          });
          _controller.clear();

          // Use captured scaffoldMessenger instead of context lookup
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('File sent successfully'),
              backgroundColor: Color(0xFF22C55E),
            ),
          );
        } else {
          throw Exception('Upload failed');
        }
      } else {
        // Send text-only message
        await MessageService.sendMessage(
          receiverId: widget.student['id'],
          content: content,
          senderType: 'instructor',
        );

        if (!mounted) return;
        _controller.clear();
      }
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        // Use captured scaffoldMessenger instead of context lookup
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _pickAndSendFile() async {
    try {
      // Pick file - just select, don't upload yet
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true, // This fixes the "bytes are null" issue on mobile
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final extension = (file.extension ?? '').toLowerCase();
      if (!FileUploadService.isAllowedExtension(extension)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This file type is not allowed in chat.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (file.bytes == null) {
        throw Exception('File bytes are null');
      }

      // Store file for preview - don't upload yet
      setState(() {
        _previewFile = file;
      });
    } catch (e) {
      print('Error picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Open image in full-screen viewer
  void _openImageViewer(String imageUrl, String fileName, String fileType) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => _ImageViewerScreen(
              imageUrl: imageUrl,
              fileName: fileName,
              fileType: fileType,
            ),
      ),
    );
  }

  /// Build smart file attachment display based on file type
  Widget _buildFileAttachment(FileAttachment attachment, bool isMe) {
    final fileType = attachment.fileType.toLowerCase();

    // Check if file should be displayed inline (image/video)
    if (FileTypeUtils.shouldDisplayInline(fileType)) {
      if (FileTypeUtils.isImageFile(fileType)) {
        return ImageDisplayWidget(
          imageUrl: attachment.fileUrl,
          maxWidth: 250,
          maxHeight: 300,
          onTap:
              () => _openImageViewer(
                attachment.fileUrl,
                attachment.fileName,
                attachment.fileType,
              ),
        );
      } else if (FileTypeUtils.isVideoFile(fileType)) {
        return VideoDisplayWidget(
          videoUrl: attachment.fileUrl,
          maxWidth: 250,
          maxHeight: 200,
          onTap:
              () => FileDownloadService.handleFileAction(
                fileUrl: attachment.fileUrl,
                fileName: attachment.fileName,
                fileType: attachment.fileType,
                context: context,
              ),
        );
      }
    }

    // For documents and other files, show download widget
    return FileAttachmentWidget(
      fileName: attachment.fileName,
      fileUrl: attachment.fileUrl,
      fileType: attachment.fileType,
      fileSize: attachment.fileSize,
      backgroundColor:
          isMe ? Colors.white.withOpacity(0.2) : const Color(0xFFF3F4F6),
      textColor: isMe ? Colors.white : Colors.black87,
      onTap: () {
        print('📥 Downloading file from message: ${attachment.fileName}');
        print('📥 File URL: ${attachment.fileUrl}');
        print('📥 File Type: ${attachment.fileType}');
        FileDownloadService.handleFileAction(
          fileUrl: attachment.fileUrl,
          fileName: attachment.fileName,
          fileType: attachment.fileType,
          context: context,
        );
      },
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'ST';
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0].toUpperCase()}${words[words.length - 1][0].toUpperCase()}';
    } else if (words.length == 1) {
      return words[0].length >= 2
          ? words[0].substring(0, 2).toUpperCase()
          : words[0][0].toUpperCase();
    }
    return 'ST';
  }

  String _getFirstName(String fullName) {
    if (fullName.isEmpty) return 'Student';
    final nameParts = fullName.trim().split(' ');
    return nameParts.first;
  }

  void _onNavigationSelect(InstructorNavigationItem item) {
    setState(() => _selectedItem = item);
    String route = InstructorNavigationHelper.getRoute(item);
    Get.offAllNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
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
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios_new,
                                size: 22,
                              ),
                              onPressed: () => Get.back(),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Message',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 32,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Manage your classroom communications',
                          style: TextStyle(color: Colors.black38, fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        // Fixed Profile Header (like mobile apps) - stays visible while chatting
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Profile Avatar with Online Indicator
                              widget.student['id'] != null
                                  ? StreamBuilder<DocumentSnapshot>(
                                    stream:
                                        FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(widget.student['id'])
                                            .snapshots(),
                                    builder: (context, snapshot) {
                                      final isOnline =
                                          snapshot.hasData &&
                                          snapshot.data!.exists &&
                                          (snapshot.data!.data()
                                                  as Map<
                                                    String,
                                                    dynamic
                                                  >?)?['isOnline'] ==
                                              true;
                                      dynamic lastSeen;
                                      if (snapshot.hasData &&
                                          snapshot.data!.exists) {
                                        final data =
                                            snapshot.data!.data()
                                                as Map<String, dynamic>?;
                                        lastSeen = data?['lastSeen'];
                                      } else {
                                        lastSeen = null;
                                      }

                                      final isActuallyOnline =
                                          PresenceUtils.isActuallyOnline(
                                            isOnline: isOnline,
                                            lastSeen: lastSeen,
                                          );

                                      return Stack(
                                        children: [
                                          (student['image'] != null &&
                                                  (student['image'] as String)
                                                      .isNotEmpty)
                                              ? CircleAvatar(
                                                radius: 28,
                                                backgroundImage: NetworkImage(
                                                  student['image'],
                                                ),
                                                backgroundColor: const Color(
                                                  0xFF22C55E,
                                                ),
                                              )
                                              : CircleAvatar(
                                                radius: 28,
                                                backgroundColor: const Color(
                                                  0xFF22C55E,
                                                ),
                                                child: Text(
                                                  _getInitials(student['name']),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          // Online Status Indicator
                                          if (isActuallyOnline)
                                            Positioned(
                                              right: 0,
                                              bottom: 0,
                                              child: Container(
                                                width: 14,
                                                height: 14,
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF34A853,
                                                  ),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  )
                                  : Stack(
                                    children: [
                                      (student['image'] != null &&
                                              (student['image'] as String)
                                                  .isNotEmpty)
                                          ? CircleAvatar(
                                            radius: 28,
                                            backgroundImage: NetworkImage(
                                              student['image'],
                                            ),
                                            backgroundColor: const Color(
                                              0xFF22C55E,
                                            ),
                                          )
                                          : CircleAvatar(
                                            radius: 28,
                                            backgroundColor: const Color(
                                              0xFF22C55E,
                                            ),
                                            child: Text(
                                              _getInitials(student['name']),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      // Online Status Indicator
                                      if (student['online'] == true ||
                                          student['isOnline'] == true)
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            width: 14,
                                            height: 14,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF34A853),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                              const SizedBox(width: 16),
                              // Profile Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            student['name'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    widget.student['id'] != null
                                        ? StreamBuilder<DocumentSnapshot>(
                                          stream:
                                              FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(widget.student['id'])
                                                  .snapshots(),
                                          builder: (context, snapshot) {
                                            final isOnline =
                                                snapshot.hasData &&
                                                snapshot.data!.exists &&
                                                (snapshot.data!.data()
                                                        as Map<
                                                          String,
                                                          dynamic
                                                        >?)?['isOnline'] ==
                                                    true;
                                            dynamic lastSeen;
                                            if (snapshot.hasData &&
                                                snapshot.data!.exists) {
                                              final data =
                                                  snapshot.data!.data()
                                                      as Map<String, dynamic>?;
                                              lastSeen = data?['lastSeen'];
                                            } else {
                                              lastSeen = null;
                                            }

                                            final isActuallyOnline =
                                                PresenceUtils.isActuallyOnline(
                                                  isOnline: isOnline,
                                                  lastSeen: lastSeen,
                                                );

                                            return Row(
                                              children: [
                                                // Online Status or Last Seen
                                                if (isActuallyOnline)
                                                  Row(
                                                    children: [
                                                      Container(
                                                        width: 8,
                                                        height: 8,
                                                        decoration:
                                                            const BoxDecoration(
                                                              color: Color(
                                                                0xFF34A853,
                                                              ),
                                                              shape:
                                                                  BoxShape
                                                                      .circle,
                                                            ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      const Text(
                                                        'Online',
                                                        style: TextStyle(
                                                          color: Color(
                                                            0xFF34A853,
                                                          ),
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                else if (lastSeen != null)
                                                  Builder(
                                                    builder: (context) {
                                                      DateTime? lastSeenTime;
                                                      try {
                                                        if (lastSeen
                                                            is Timestamp) {
                                                          lastSeenTime =
                                                              lastSeen.toDate();
                                                        } else if (lastSeen
                                                            is DateTime) {
                                                          lastSeenTime =
                                                              lastSeen;
                                                        }
                                                      } catch (e) {
                                                        lastSeenTime = null;
                                                      }

                                                      if (lastSeenTime !=
                                                          null) {
                                                        return Text(
                                                          _formatLastSeen(
                                                            lastSeenTime,
                                                          ),
                                                          style: const TextStyle(
                                                            color:
                                                                Colors.black54,
                                                            fontSize: 13,
                                                          ),
                                                          maxLines: 1,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        );
                                                      } else {
                                                        return Text(
                                                          student['email'] ??
                                                              'Offline',
                                                          style: const TextStyle(
                                                            color:
                                                                Colors.black54,
                                                            fontSize: 13,
                                                          ),
                                                          maxLines: 1,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        );
                                                      }
                                                    },
                                                  )
                                                else
                                                  Text(
                                                    student['email'] ??
                                                        'Offline',
                                                    style: const TextStyle(
                                                      color: Colors.black54,
                                                      fontSize: 13,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                              ],
                                            );
                                          },
                                        )
                                        : Row(
                                          children: [
                                            // Online Status or Email
                                            if (student['online'] == true ||
                                                student['isOnline'] == true)
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: Color(
                                                            0xFF34A853,
                                                          ),
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  const Text(
                                                    'Online',
                                                    style: TextStyle(
                                                      color: Color(0xFF34A853),
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            else
                                              Text(
                                                student['email'] ?? 'Offline',
                                                style: const TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: 13,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Expanded(
                          child:
                              widget.student['id'] != null
                                  ? StreamBuilder<List<MessageModel>>(
                                    stream:
                                        MessageService.getBidirectionalMessages(
                                          widget.student['id'],
                                        ),
                                    builder: (context, snapshot) {
                                      // Mark messages as read on first load
                                      if (snapshot.hasData &&
                                          !_hasMarkedAsRead) {
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                              MessageService.markMessagesAsRead(
                                                widget.student['id'],
                                              );
                                              _hasMarkedAsRead = true;
                                            });
                                      }

                                      // Auto-scroll to bottom when new messages arrive
                                      if (snapshot.hasData) {
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                              if (_scrollController
                                                  .hasClients) {
                                                _scrollController.animateTo(
                                                  _scrollController
                                                      .position
                                                      .maxScrollExtent,
                                                  duration: const Duration(
                                                    milliseconds: 300,
                                                  ),
                                                  curve: Curves.easeOut,
                                                );
                                              }
                                            });
                                      }

                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 0,
                                            vertical: 18,
                                          ),
                                          child: ListView.builder(
                                            itemCount: 6,
                                            itemBuilder: (context, index) {
                                              // Alternate between sent and received messages
                                              final isMe = index % 2 == 0;
                                              return SkeletonMessageBubble(
                                                isMe: isMe,
                                              );
                                            },
                                          ),
                                        );
                                      }

                                      if (snapshot.hasError) {
                                        return Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.error_outline,
                                                size: 64,
                                                color: Colors.red[400],
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'Error loading messages',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }

                                      final messages = snapshot.data ?? [];

                                      if (messages.isEmpty) {
                                        return const Center(
                                          child: Text(
                                            'No messages yet',
                                            style: TextStyle(
                                              color: Colors.black38,
                                              fontSize: 16,
                                            ),
                                          ),
                                        );
                                      }

                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 0,
                                          vertical: 18,
                                        ),
                                        child: ListView.builder(
                                          controller: _scrollController,
                                          itemCount: messages.length,
                                          itemBuilder: (context, index) {
                                            final msg = messages[index];
                                            final isMe =
                                                msg.senderType == 'instructor';
                                            return Align(
                                              alignment:
                                                  isMe
                                                      ? Alignment.centerRight
                                                      : Alignment.centerLeft,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 6,
                                                    ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      isMe
                                                          ? MainAxisAlignment
                                                              .end
                                                          : MainAxisAlignment
                                                              .start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    // Student avatar (shown on left for student messages)
                                                    if (!isMe) ...[
                                                      CircleAvatar(
                                                        radius: 16,
                                                        backgroundColor:
                                                            const Color(
                                                              0xFF22C55E,
                                                            ),
                                                        backgroundImage:
                                                            (student['image'] !=
                                                                        null &&
                                                                    (student['image']
                                                                            as String)
                                                                        .isNotEmpty)
                                                                ? NetworkImage(
                                                                  student['image'],
                                                                )
                                                                : null,
                                                        child:
                                                            (student['image'] ==
                                                                        null ||
                                                                    (student['image']
                                                                            as String)
                                                                        .isEmpty)
                                                                ? Text(
                                                                  _getInitials(
                                                                    student['name'],
                                                                  ),
                                                                  style: const TextStyle(
                                                                    color:
                                                                        Colors
                                                                            .white,
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                )
                                                                : null,
                                                      ),
                                                      const SizedBox(width: 8),
                                                    ],
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .end,
                                                      children: [
                                                        Column(
                                                          crossAxisAlignment:
                                                              isMe
                                                                  ? CrossAxisAlignment
                                                                      .end
                                                                  : CrossAxisAlignment
                                                                      .start,
                                                          children: [
                                                            Container(
                                                              constraints:
                                                                  const BoxConstraints(
                                                                    maxWidth:
                                                                        420,
                                                                  ),
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        18,
                                                                    vertical:
                                                                        14,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    isMe
                                                                        ? const Color(
                                                                          0xFF22C55E,
                                                                        )
                                                                        : const Color(
                                                                          0xFFF3F4F6,
                                                                        ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                              ),
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  // Display file attachment with smart rendering (only if not unsent)
                                                                  if (msg.fileAttachment !=
                                                                          null &&
                                                                      !msg.isUnsent) ...[
                                                                    _buildFileAttachment(
                                                                      msg.fileAttachment!,
                                                                      isMe,
                                                                    ),
                                                                    // Show text content if present (no "Sent a file" text - file name is in the widget)
                                                                    if (msg
                                                                        .content
                                                                        .isNotEmpty) ...[
                                                                      const SizedBox(
                                                                        height:
                                                                            8,
                                                                      ),
                                                                      Text(
                                                                        msg.content,
                                                                        style: TextStyle(
                                                                          color:
                                                                              isMe
                                                                                  ? Colors.white
                                                                                  : Colors.black87,
                                                                          fontSize:
                                                                              15,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ],
                                                                  // Display text content for text-only messages or unsent messages
                                                                  if (msg.fileAttachment ==
                                                                          null ||
                                                                      msg.isUnsent)
                                                                    Text(
                                                                      msg.isUnsent
                                                                          ? (isMe
                                                                              ? 'You unsent a message'
                                                                              : '${_getFirstName(student['name'] ?? 'Student')} unsent a message')
                                                                          : msg
                                                                              .content,
                                                                      style: TextStyle(
                                                                        color:
                                                                            isMe
                                                                                ? Colors.white
                                                                                : Colors.black87,
                                                                        fontSize:
                                                                            15,
                                                                        fontStyle:
                                                                            msg.isUnsent
                                                                                ? FontStyle.italic
                                                                                : FontStyle.normal,
                                                                      ),
                                                                    ),
                                                                ],
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 4,
                                                            ),
                                                            Text(
                                                              _formatTime(
                                                                msg.timestamp
                                                                    .toDate(),
                                                              ),
                                                              style: TextStyle(
                                                                color:
                                                                    isMe
                                                                        ? const Color(
                                                                          0xFF22C55E,
                                                                        )
                                                                        : Colors
                                                                            .black38,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        // Three-dot menu for own messages (not already unsent)
                                                        if (isMe &&
                                                            !msg.isUnsent) ...[
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          PopupMenuButton<
                                                            String
                                                          >(
                                                            icon: Icon(
                                                              Icons.more_vert,
                                                              size: 18,
                                                              color:
                                                                  Colors
                                                                      .grey[600],
                                                            ),
                                                            padding:
                                                                EdgeInsets.zero,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8,
                                                                  ),
                                                            ),
                                                            itemBuilder:
                                                                (context) => [
                                                                  PopupMenuItem(
                                                                    value:
                                                                        'delete',
                                                                    child: Row(
                                                                      children: [
                                                                        Icon(
                                                                          Icons
                                                                              .undo_outlined,
                                                                          size:
                                                                              20,
                                                                          color:
                                                                              Colors.orange[400],
                                                                        ),
                                                                        const SizedBox(
                                                                          width:
                                                                              8,
                                                                        ),
                                                                        const Text(
                                                                          'Unsend',
                                                                          style: TextStyle(
                                                                            fontSize:
                                                                                14,
                                                                            fontWeight:
                                                                                FontWeight.w500,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                            onSelected: (
                                                              value,
                                                            ) async {
                                                              if (value ==
                                                                  'delete') {
                                                                _showDeleteDialog(
                                                                  context,
                                                                  msg,
                                                                );
                                                              }
                                                            },
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  )
                                  : const Center(
                                    child: Text('No student selected'),
                                  ),
                        ),
                        // Show preview if file is selected
                        if (_previewFile != null) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Preview for images
                                if (FileTypeUtils.isImageFile(
                                  _previewFile!.extension ?? '',
                                )) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child:
                                        _previewFile!.bytes != null
                                            ? Image.memory(
                                              _previewFile!.bytes!,
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            )
                                            : const SizedBox(
                                              width: 80,
                                              height: 80,
                                              child: Icon(Icons.image),
                                            ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _previewFile!.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${(_previewFile!.size / 1024).toStringAsFixed(1)} KB',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ]
                                // Preview for other files
                                else ...[
                                  Icon(
                                    Icons.insert_drive_file,
                                    size: 48,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _previewFile!.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${(_previewFile!.size / 1024).toStringAsFixed(1)} KB • ${_previewFile!.extension ?? 'file'}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                // Remove button
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  color: Colors.grey[600],
                                  onPressed: _clearPreview,
                                  tooltip: 'Remove attachment',
                                ),
                              ],
                            ),
                          ),
                        ],
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  enabled: !_isUploading,
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.only(left: 10),
                                    hintText: 'Type your message...',
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(
                                      color: Color(0xFFBDBDBD),
                                      fontSize: 15,
                                    ),
                                  ),
                                  style: const TextStyle(fontSize: 15),
                                  cursorColor: Colors.black54,
                                  onSubmitted: (_) => _sendMessage(),
                                ),
                              ),
                              IconButton(
                                icon: Image.asset(
                                  'assets/icons/Vector (8).png',
                                  width: 22,
                                  color: const Color(0xFFBDBDBD),
                                ),
                                onPressed:
                                    _isUploading ? null : _pickAndSendFile,
                                tooltip: 'Attach file',
                              ),
                              _isUploading
                                  ? const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFF22C55E),
                                            ),
                                      ),
                                    ),
                                  )
                                  : IconButton(
                                    icon: Image.asset(
                                      'assets/icons/akar-icons_send.png',
                                      width: 22,
                                      color: const Color(0xFF22C55E),
                                    ),
                                    onPressed:
                                        (_controller.text.trim().isNotEmpty ||
                                                _previewFile != null)
                                            ? _sendMessage
                                            : null,
                                  ),
                            ],
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
}

/// Full-screen image viewer for mobile devices
class _ImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String fileName;
  final String fileType;

  const _ImageViewerScreen({
    required this.imageUrl,
    required this.fileName,
    required this.fileType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          fileName,
          style: const TextStyle(color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed:
                () => FileDownloadService.handleFileAction(
                  fileUrl: imageUrl,
                  fileName: fileName,
                  fileType: fileType,
                  context: context,
                ),
            tooltip: 'Download image',
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder:
                (context, url) => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
            errorWidget:
                (context, url, error) => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, color: Colors.white, size: 64),
                      SizedBox(height: 16),
                      Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
          ),
        ),
      ),
    );
  }
}
