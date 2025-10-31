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
import 'package:url_launcher/url_launcher.dart';

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
  List<MessageModel> messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMessages() {
    if (widget.student['id'] == null) return;

    MessageService.getBidirectionalMessages(widget.student['id']).listen((
      messageList,
    ) {
      if (mounted) {
        setState(() {
          messages = messageList;
        });

        // Auto-scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
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

  void _sendMessage() async {
    final content = _controller.text.trim();
    if (content.isEmpty || widget.student['id'] == null) return;

    try {
      await MessageService.sendMessage(
        receiverId: widget.student['id'],
        content: content,
        senderType: 'instructor',
      );

      _controller.clear();
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickAndSendFile() async {
    try {
      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true, // This fixes the "bytes are null" issue on mobile
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) {
        throw Exception('File bytes are null');
      }

      // Show uploading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploading file...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Upload to Cloudinary
      final fileUploadService = FileUploadService();
      fileUploadService.initialize();

      final response = await fileUploadService.uploadFile(
        file: file,
        folder: 'greenquest/messages',
      );

      if (response != null) {
        // Send message with file attachment
        await MessageService.sendMessageWithFile(
          receiverId: widget.student['id'],
          content: _controller.text.trim(),
          fileName: file.name,
          fileUrl: response.url,
          fileType: file.extension ?? 'unknown',
          fileSize: file.size,
          senderType: 'instructor',
        );

        _controller.clear();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File sent successfully'),
              backgroundColor: Color(0xFF22C55E),
            ),
          );
        }
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      print('Error sending file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openFile(String fileUrl) async {
    try {
      final uri = Uri.parse(fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not open file');
      }
    } catch (e) {
      print('Error opening file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Open image in full-screen viewer
  void _openImageViewer(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ImageViewerScreen(imageUrl: imageUrl),
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
          onTap: () => _openImageViewer(attachment.fileUrl),
        );
      } else if (FileTypeUtils.isVideoFile(fileType)) {
        return VideoDisplayWidget(
          videoUrl: attachment.fileUrl,
          maxWidth: 250,
          maxHeight: 200,
          onTap: () => _openFile(attachment.fileUrl),
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              (student['image'] != null &&
                                      (student['image'] as String).isNotEmpty)
                                  ? CircleAvatar(
                                    radius: 24,
                                    backgroundImage: NetworkImage(
                                      student['image'],
                                    ),
                                    backgroundColor: const Color(0xFF22C55E),
                                  )
                                  : CircleAvatar(
                                    radius: 24,
                                    backgroundColor: const Color(0xFF22C55E),
                                    child: Text(
                                      _getInitials(student['name']),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                  Text(
                                    student['email'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: 18,
                            ),
                            child:
                                messages.isEmpty
                                    ? const Center(
                                      child: Text(
                                        'No messages yet',
                                        style: TextStyle(
                                          color: Colors.black38,
                                          fontSize: 16,
                                        ),
                                      ),
                                    )
                                    : ListView.builder(
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
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 6,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  isMe
                                                      ? CrossAxisAlignment.end
                                                      : CrossAxisAlignment
                                                          .start,
                                              children: [
                                                Container(
                                                  constraints:
                                                      const BoxConstraints(
                                                        maxWidth: 420,
                                                      ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 18,
                                                        vertical: 14,
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
                                                      // Display file attachment with smart rendering
                                                      if (msg.fileAttachment !=
                                                          null) ...[
                                                        _buildFileAttachment(
                                                          msg.fileAttachment!,
                                                          isMe,
                                                        ),
                                                        if (msg.content !=
                                                                'Sent a file' &&
                                                            msg
                                                                .content
                                                                .isNotEmpty)
                                                          const SizedBox(
                                                            height: 8,
                                                          ),
                                                      ],
                                                      // Display text content
                                                      if (msg.content !=
                                                              'Sent a file' ||
                                                          msg.fileAttachment ==
                                                              null)
                                                        Text(
                                                          msg.content,
                                                          style: TextStyle(
                                                            color:
                                                                isMe
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black87,
                                                            fontSize: 15,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _formatTime(
                                                    msg.timestamp.toDate(),
                                                  ),
                                                  style: TextStyle(
                                                    color:
                                                        isMe
                                                            ? const Color(
                                                              0xFF22C55E,
                                                            )
                                                            : Colors.black38,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                          ),
                        ),
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
                                onPressed: _pickAndSendFile,
                                tooltip: 'Attach file',
                              ),
                              IconButton(
                                icon: Image.asset(
                                  'assets/icons/akar-icons_send.png',
                                  width: 22,
                                  color: const Color(0xFF22C55E),
                                ),
                                onPressed: _sendMessage,
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

  const _ImageViewerScreen({required this.imageUrl});

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
        title: const Text('Image', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed:
                () => FileDownloadService.handleFileAction(
                  fileUrl: imageUrl,
                  fileName:
                      'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
                  fileType: 'jpg',
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
