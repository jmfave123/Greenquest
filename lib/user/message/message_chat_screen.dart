import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../shared/widgets/instructor_avatar.dart';
import '../../shared/services/message_service.dart';
import '../../shared/models/message_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../../shared/services/file_upload_service.dart';
import '../../shared/utils/file_type_utils.dart';
import '../../shared/widgets/file_display_widgets.dart';
import '../../shared/services/file_download_service.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class MessageChatScreen extends StatefulWidget {
  final Map<String, dynamic>? instructor;

  const MessageChatScreen({super.key, this.instructor});

  @override
  State<MessageChatScreen> createState() => _MessageChatScreenState();
}

class _MessageChatScreenState extends State<MessageChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<MessageModel> messages = [];
  bool isLoading = true;
  Map<String, dynamic>? currentUserProfile;

  // Preview state for attachments
  PlatformFile? _previewFile;
  bool _isUploading = false;

  Map<String, dynamic>? get instructor => widget.instructor;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadCurrentUserProfile();
    // Add listener to update UI when text changes (for send button color)
    _controller.addListener(() {
      setState(() {
        // Trigger rebuild when text changes to update send button color
      });
    });
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
            warningMessage:
                'This message will be replaced with "You unsent a message".',
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
                      backgroundColor: Color(0xFF34A853),
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

  void _loadMessages() {
    if (instructor == null) return;

    MessageService.getBidirectionalMessages(instructor!['id']).listen((
      messageList,
    ) {
      if (mounted) {
        setState(() {
          messages = messageList;
          isLoading = false;
        });

        // Mark messages as read
        MessageService.markMessagesAsRead(instructor!['id']);

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

  void _loadCurrentUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          currentUserProfile = {
            'id': user.uid,
            'name':
                userData['fullName'] ??
                'Student', // Use fullName like in profile
            'email': userData['email'] ?? user.email ?? '',
            'profileImage': userData['profileImage'], // Use profileImage field
          };
        });
      }
    } catch (e) {
      print('Error loading current user profile: $e');
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'S'; // Default to 'S' for Student

    final words = name.trim().split(' ');
    if (words.length >= 2) {
      // Get first letter of first name and first letter of last name
      return '${words[0][0].toUpperCase()}${words[words.length - 1][0].toUpperCase()}';
    } else if (words.length == 1) {
      // If only one name, use first two letters
      return words[0].length >= 2
          ? words[0].substring(0, 2).toUpperCase()
          : words[0][0].toUpperCase();
    }
    return 'S';
  }

  String _getFirstName(String fullName) {
    if (fullName.isEmpty) return 'Instructor';
    final nameParts = fullName.trim().split(' ');
    return nameParts.first;
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

  void _sendMessage(String content) async {
    final hasContent = content.trim().isNotEmpty;
    final hasAttachment = _previewFile != null;

    if ((!hasContent && !hasAttachment) || instructor == null) return;

    if (_isUploading) return; // Prevent double sending

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

        if (response != null) {
          // Send message with file attachment
          await MessageService.sendMessageWithFile(
            receiverId: instructor!['id'],
            content: content.trim().isEmpty ? 'Sent a file' : content.trim(),
            fileName: file.name,
            fileUrl: response.url,
            fileType: file.extension ?? 'unknown',
            fileSize: file.size,
            senderType: 'student',
          );

          // Clear preview and text
          setState(() {
            _previewFile = null;
          });
          _controller.clear();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File sent successfully'),
                backgroundColor: Color(0xFF34A853),
              ),
            );
          }
        } else {
          throw Exception('Upload failed');
        }
      } else {
        // Send text-only message
        await MessageService.sendMessage(
          receiverId: instructor!['id'],
          content: content.trim(),
          senderType: 'student',
        );

        _controller.clear();
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            InstructorMessageAvatar(
              profileImage:
                  instructor?['profileImageUrl'] ?? instructor?['profileImage'],
              name: instructor?['name'] ?? 'Unknown Instructor',
              isOnline: instructor?['isOnline'] ?? false,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instructor?['name'] ?? 'Unknown Instructor',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
                Text(
                  instructor?['isOnline'] == true ? 'Online' : 'Offline',
                  style: TextStyle(
                    color:
                        instructor?['isOnline'] == true
                            ? const Color(0xFF34A853)
                            : Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: false,
      ),
      backgroundColor: const Color(0xFFF7F8FA),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          Expanded(
            child:
                isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF34A853),
                        ),
                      ),
                    )
                    : messages.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start a conversation with ${instructor?['name'] ?? 'your instructor'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, i) {
                        final message = messages[i];
                        final isMe = message.senderType == 'student';
                        return Align(
                          alignment:
                              isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              crossAxisAlignment:
                                  isMe
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      isMe
                                          ? MainAxisAlignment.end
                                          : MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (!isMe)
                                      InstructorMessageAvatar(
                                        profileImage:
                                            instructor?['profileImageUrl'] ??
                                            instructor?['profileImage'],
                                        name:
                                            instructor?['name'] ??
                                            'Unknown Instructor',
                                        isOnline:
                                            instructor?['isOnline'] ?? false,
                                        radius: 16,
                                      ),
                                    if (!isMe) const SizedBox(width: 8),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Flexible(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  isMe
                                                      ? const Color(0xFF34A853)
                                                      : Colors.white,
                                              borderRadius: BorderRadius.only(
                                                topLeft: const Radius.circular(
                                                  16,
                                                ),
                                                topRight: const Radius.circular(
                                                  16,
                                                ),
                                                bottomLeft: Radius.circular(
                                                  isMe ? 16 : 4,
                                                ),
                                                bottomRight: Radius.circular(
                                                  isMe ? 4 : 16,
                                                ),
                                              ),
                                              boxShadow: [
                                                if (!isMe)
                                                  const BoxShadow(
                                                    color: Colors.black12,
                                                    blurRadius: 2,
                                                    offset: Offset(0, 1),
                                                  ),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Display file attachment with smart rendering (only if not unsent)
                                                if (message.fileAttachment !=
                                                        null &&
                                                    !message.isUnsent) ...[
                                                  _buildFileAttachment(
                                                    message.fileAttachment!,
                                                    isMe,
                                                  ),
                                                  if (message.content !=
                                                          'Sent a file' &&
                                                      message
                                                          .content
                                                          .isNotEmpty)
                                                    const SizedBox(height: 8),
                                                ],
                                                // Display text content (or unsent message)
                                                if (message.content !=
                                                        'Sent a file' ||
                                                    message.content.isNotEmpty)
                                                  Text(
                                                    message.isUnsent
                                                        ? (isMe
                                                            ? 'You unsent a message'
                                                            : '${_getFirstName(instructor?['name'] ?? 'Instructor')} unsent a message')
                                                        : message.content,
                                                    style: TextStyle(
                                                      color:
                                                          isMe
                                                              ? Colors.white
                                                              : Colors.black87,
                                                      fontSize: 15,
                                                      fontStyle:
                                                          message.isUnsent
                                                              ? FontStyle.italic
                                                              : FontStyle
                                                                  .normal,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Three-dot menu for own messages (not already unsent)
                                        if (isMe && !message.isUnsent) ...[
                                          const SizedBox(width: 4),
                                          PopupMenuButton<String>(
                                            icon: Icon(
                                              Icons.more_vert,
                                              size: 18,
                                              color: Colors.grey[600],
                                            ),
                                            padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            itemBuilder:
                                                (context) => [
                                                  PopupMenuItem(
                                                    value: 'delete',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.undo_outlined,
                                                          size: 20,
                                                          color:
                                                              Colors
                                                                  .orange[400],
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        const Text(
                                                          'Unsend',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                            onSelected: (value) async {
                                              if (value == 'delete') {
                                                _showDeleteDialog(
                                                  context,
                                                  message,
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (isMe) const SizedBox(width: 8),
                                    if (isMe)
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: const Color(
                                          0xFF34A853,
                                        ),
                                        backgroundImage:
                                            currentUserProfile?['profileImage'] !=
                                                        null &&
                                                    currentUserProfile!['profileImage']
                                                        .toString()
                                                        .isNotEmpty
                                                ? NetworkImage(
                                                  currentUserProfile!['profileImage'],
                                                )
                                                : null,
                                        child:
                                            currentUserProfile?['profileImage'] ==
                                                        null ||
                                                    currentUserProfile!['profileImage']
                                                        .toString()
                                                        .isEmpty
                                                ? Text(
                                                  _getInitials(
                                                    currentUserProfile?['name'] ??
                                                        'Student',
                                                  ),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                )
                                                : null,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTime(message.timestamp.toDate()),
                                  style: TextStyle(
                                    color:
                                        isMe
                                            ? const Color(0xFF34A853)
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
          Column(
            children: [
              // Show preview if file is selected
              if (_previewFile != null) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 8),
              ],
              Container(
                color: Colors.white,
                padding: EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 8,
                  bottom: MediaQuery.of(context).padding.bottom + 8,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _isUploading ? null : _pickAndSendFile,
                      child: Image.asset(
                        'assets/icons/Vector (8).png',
                        width: 22,
                        color: _isUploading ? Colors.grey : Colors.black45,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 100, // Limit max height for multiline
                        ),
                        child: TextField(
                          cursorColor: Colors.black54,
                          controller: _controller,
                          enabled: !_isUploading,
                          textInputAction: TextInputAction.send,
                          keyboardType: TextInputType.text,
                          maxLines: null,
                          minLines: 1,
                          decoration: const InputDecoration(
                            hintText: 'Type a message',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          onSubmitted: (value) {
                            // Send message when user presses send/enter on keyboard
                            if (value.trim().isNotEmpty ||
                                _previewFile != null) {
                              _sendMessage(value.trim());
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _isUploading
                        ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF34A853),
                              ),
                            ),
                          ),
                        )
                        : GestureDetector(
                          onTap: () {
                            // Always allow tapping - check inside if we should send
                            final content = _controller.text.trim();
                            if (content.isNotEmpty || _previewFile != null) {
                              _sendMessage(content);
                            }
                          },
                          child: Image.asset(
                            'assets/icons/akar-icons_send.png',
                            width: 24,
                            color:
                                (_controller.text.trim().isNotEmpty ||
                                        _previewFile != null)
                                    ? const Color(0xFF34A853)
                                    : Colors.grey,
                          ),
                        ),
                  ],
                ),
              ),
            ],
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
