import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/widgets/instructor_avatar.dart';
import '../../shared/models/message_model.dart';
import '../../shared/utils/file_type_utils.dart';
import '../../shared/widgets/file_display_widgets.dart';
import '../../shared/services/file_download_service.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import 'message_chat_controller.dart';

/// Student chat screen — shows the real-time conversation between
/// the student and their selected instructor.
///
/// All business logic is delegated to [MessageChatController].
/// This widget is a thin presentation shell per agents.md §3.1.
class MessageChatScreen extends StatelessWidget {
  final Map<String, dynamic>? instructor;

  const MessageChatScreen({super.key, this.instructor});

  @override
  Widget build(BuildContext context) {
    final MessageChatController controller = Get.put(
      MessageChatController(),
      tag: 'chat_${instructor?['id'] ?? 'unknown'}',
    );
    controller.initWithInstructor(instructor);

    return Scaffold(
      appBar: _buildAppBar(context, controller),
      backgroundColor: const Color(0xFFF7F8FA),
      resizeToAvoidBottomInset: true,
      body: controller.hasInstructor
          ? _ChatBody(controller: controller)
          : const Center(child: Text('No instructor selected')),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    MessageChatController controller,
  ) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: controller.hasInstructor
          ? _AppBarTitle(controller: controller, instructor: instructor!)
          : _StaticAppBarTitle(instructor: instructor),
      centerTitle: false,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Private widgets extracted for readability (agents.md §17 — 300 lines)
// ─────────────────────────────────────────────────────────────────────

/// AppBar title with real-time instructor presence from Firestore.
class _AppBarTitle extends StatelessWidget {
  final MessageChatController controller;
  final Map<String, dynamic> instructor;

  const _AppBarTitle({
    required this.controller,
    required this.instructor,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('instructors')
          .doc(instructor['id'] as String)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        final Map<String, dynamic>? data =
            snapshot.hasData && snapshot.data!.exists
                ? snapshot.data!.data() as Map<String, dynamic>?
                : null;

        final bool isOnlineFlag = data?['isOnline'] == true;
        final Object? lastSeen = data?['lastSeen'];

        final bool isActuallyOnline = controller.isInstructorOnline(
          isOnlineFlag: isOnlineFlag,
          lastSeen: lastSeen,
        );

        return Row(
          children: [
            InstructorMessageAvatar(
              profileImage: instructor['profileImageUrl'] ??
                  instructor['profileImage'],
              name: instructor['name'] as String? ?? 'Unknown Instructor',
              isOnline: isActuallyOnline,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instructor['name'] as String? ?? 'Unknown Instructor',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
                _buildPresenceText(
                  controller,
                  isActuallyOnline,
                  lastSeen,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildPresenceText(
    MessageChatController controller,
    bool isActuallyOnline,
    Object? lastSeen,
  ) {
    if (isActuallyOnline) {
      return const Text(
        'Online',
        style: TextStyle(color: Color(0xFF34A853), fontSize: 13),
      );
    }

    final DateTime? lastSeenTime = controller.parseLastSeen(lastSeen);
    if (lastSeenTime != null) {
      return Text(
        controller.formatLastSeen(lastSeenTime),
        style: const TextStyle(color: Colors.grey, fontSize: 13),
      );
    }

    return const Text(
      'Offline',
      style: TextStyle(color: Colors.grey, fontSize: 13),
    );
  }
}

/// Static fallback app bar title when instructor ID is null.
class _StaticAppBarTitle extends StatelessWidget {
  final Map<String, dynamic>? instructor;

  const _StaticAppBarTitle({this.instructor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InstructorMessageAvatar(
          profileImage:
              instructor?['profileImageUrl'] ?? instructor?['profileImage'],
          name: instructor?['name'] as String? ?? 'Unknown Instructor',
          isOnline: instructor?['isOnline'] == true,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              instructor?['name'] as String? ?? 'Unknown Instructor',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 16,
              ),
            ),
            Text(
              instructor?['isOnline'] == true ? 'Online' : 'Offline',
              style: TextStyle(
                color: instructor?['isOnline'] == true
                    ? const Color(0xFF34A853)
                    : Colors.grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The main chat body: message list + input area.
class _ChatBody extends StatelessWidget {
  final MessageChatController controller;

  const _ChatBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MessageModel>>(
      stream: controller.messagesStream,
      builder: (
        BuildContext context,
        AsyncSnapshot<List<MessageModel>> snapshot,
      ) {
        // Mark as read on first load
        if (snapshot.hasData) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.markAsReadIfNeeded();
          });
        }

        // Auto-scroll when new messages arrive
        if (snapshot.hasData && !controller.focusNode.hasFocus) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.scrollToBottom();
          });
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(Color(0xFF34A853)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
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

        final List<MessageModel> messages = snapshot.data ?? [];

        return Column(
          children: [
            Expanded(
              child: messages.isEmpty
                  ? _EmptyState(controller: controller)
                  : _MessageList(
                      controller: controller,
                      messages: messages,
                    ),
            ),
            _ChatInputArea(controller: controller),
          ],
        );
      },
    );
  }
}

/// Empty state shown when there are no messages yet.
class _EmptyState extends StatelessWidget {
  final MessageChatController controller;

  const _EmptyState({required this.controller});

  @override
  Widget build(BuildContext context) {
    final String instructorName =
        controller.instructor.value?['name'] as String? ?? 'your instructor';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
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
            'Start a conversation with $instructorName',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Scrollable message list.
class _MessageList extends StatelessWidget {
  final MessageChatController controller;
  final List<MessageModel> messages;

  const _MessageList({
    required this.controller,
    required this.messages,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: messages.length,
      itemBuilder: (BuildContext context, int i) {
        return _MessageBubble(
          controller: controller,
          message: messages[i],
        );
      },
    );
  }
}

/// A single message bubble with avatar, content, and timestamp.
class _MessageBubble extends StatelessWidget {
  final MessageChatController controller;
  final MessageModel message;

  const _MessageBubble({
    required this.controller,
    required this.message,
  });

  bool get _isMe => message.senderType == 'student';

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: _isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment:
              _isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: _isMe
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!_isMe) ...[
                  _InstructorAvatar(controller: controller),
                  const SizedBox(width: 8),
                ],
                GestureDetector(
                  onLongPress: _isMe && !message.isUnsent
                      ? () => _showDeleteDialog(context)
                      : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: _BubbleContent(
                          controller: controller,
                          message: message,
                          isMe: _isMe,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              controller.formatTime(message.timestamp.toDate()),
              style: TextStyle(
                color: _isMe
                    ? const Color(0xFF34A853)
                    : Colors.black38,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) => ConfirmationDialog(
        title: 'Unsend Message',
        message: 'Are you sure you want to unsend this message?',
        confirmText: 'Unsend',
        cancelText: 'Cancel',
        icon: Icons.undo_outlined,
        iconColor: Colors.orange,
        confirmButtonColor: Colors.orange,
        onConfirm: () async {
          final bool success =
              await controller.unsendMessage(message.id);
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? 'Message unsent successfully'
                      : 'Failed to unsend message',
                ),
                backgroundColor:
                    success ? const Color(0xFF34A853) : Colors.red,
              ),
            );
          }
        },
      ),
    );
  }
}

/// Instructor avatar with real-time online status for message bubbles.
class _InstructorAvatar extends StatelessWidget {
  final MessageChatController controller;

  const _InstructorAvatar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? instructor = controller.instructor.value;
    if (instructor == null || instructor['id'] == null) {
      return InstructorMessageAvatar(
        profileImage: instructor?['profileImageUrl'] ??
            instructor?['profileImage'],
        name: instructor?['name'] as String? ?? 'Unknown Instructor',
        isOnline: false,
        radius: 16,
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('instructors')
          .doc(instructor['id'] as String)
          .snapshots(),
      builder: (
        BuildContext context,
        AsyncSnapshot<DocumentSnapshot> snapshot,
      ) {
        final Map<String, dynamic>? data =
            snapshot.hasData && snapshot.data!.exists
                ? snapshot.data!.data() as Map<String, dynamic>?
                : null;

        final bool isOnlineFlag = data?['isOnline'] == true;
        final Object? lastSeen = data?['lastSeen'];

        final bool isActuallyOnline = controller.isInstructorOnline(
          isOnlineFlag: isOnlineFlag,
          lastSeen: lastSeen,
        );

        return InstructorMessageAvatar(
          profileImage: instructor['profileImageUrl'] ??
              instructor['profileImage'],
          name: instructor['name'] as String? ?? 'Unknown Instructor',
          isOnline: isActuallyOnline,
          radius: 16,
        );
      },
    );
  }
}

/// The styled bubble container with message content.
class _BubbleContent extends StatelessWidget {
  final MessageChatController controller;
  final MessageModel message;
  final bool isMe;

  const _BubbleContent({
    required this.controller,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF34A853) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File attachment (only if not unsent)
          if (message.fileAttachment != null && !message.isUnsent) ...[
            _FileAttachmentDisplay(
              attachment: message.fileAttachment!,
              isMe: isMe,
            ),
            if (message.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message.content,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ],
          ],
          // Text content for text-only or unsent messages
          if (message.fileAttachment == null || message.isUnsent)
            Text(
              message.isUnsent
                  ? (isMe
                      ? 'You unsent a message'
                      : '${controller.getFirstName(controller.instructor.value?['name'] as String? ?? 'Instructor')} unsent a message')
                  : message.content,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
                fontStyle:
                    message.isUnsent ? FontStyle.italic : FontStyle.normal,
              ),
            ),
        ],
      ),
    );
  }
}

/// Smart file attachment display — renders inline for images/videos,
/// or as a download card for documents.
class _FileAttachmentDisplay extends StatelessWidget {
  final FileAttachment attachment;
  final bool isMe;

  const _FileAttachmentDisplay({
    required this.attachment,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final String fileType = attachment.fileType.toLowerCase();

    if (FileTypeUtils.shouldDisplayInline(fileType)) {
      if (FileTypeUtils.isImageFile(fileType)) {
        return ImageDisplayWidget(
          imageUrl: attachment.fileUrl,
          maxWidth: 250,
          maxHeight: 300,
          onTap: () => _openImageViewer(context),
        );
      } else if (FileTypeUtils.isVideoFile(fileType)) {
        return VideoDisplayWidget(
          videoUrl: attachment.fileUrl,
          maxWidth: 250,
          maxHeight: 200,
          onTap: () => _downloadFile(context),
        );
      }
    }

    return FileAttachmentWidget(
      fileName: attachment.fileName,
      fileUrl: attachment.fileUrl,
      fileType: attachment.fileType,
      fileSize: attachment.fileSize,
      backgroundColor:
          isMe ? Colors.white.withOpacity(0.2) : const Color(0xFFF3F4F6),
      textColor: isMe ? Colors.white : Colors.black87,
      onTap: () => _downloadFile(context),
    );
  }

  void _openImageViewer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ImageViewerScreen(
          imageUrl: attachment.fileUrl,
          fileName: attachment.fileName,
          fileType: attachment.fileType,
        ),
      ),
    );
  }

  void _downloadFile(BuildContext context) {
    FileDownloadService.handleFileAction(
      fileUrl: attachment.fileUrl,
      fileName: attachment.fileName,
      fileType: attachment.fileType,
      context: context,
    );
  }
}

/// Chat input area with file preview, text field, and send button.
class _ChatInputArea extends StatelessWidget {
  final MessageChatController controller;

  const _ChatInputArea({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Obx(() => controller.previewFile.value != null
            ? _FilePreview(controller: controller)
            : const SizedBox.shrink()),
        _InputRow(controller: controller),
      ],
    );
  }
}

/// File preview bar shown above the input when a file is attached.
class _FilePreview extends StatelessWidget {
  final MessageChatController controller;

  const _FilePreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    final file = controller.previewFile.value!;
    final bool isImage =
        FileTypeUtils.isImageFile(file.extension ?? '');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          if (isImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: file.bytes != null
                  ? Image.memory(
                      file.bytes!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    )
                  : const SizedBox(
                      width: 80, height: 80, child: Icon(Icons.image)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(file.size / 1024).toStringAsFixed(1)} KB',
                    style: const TextStyle(
                      fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ] else ...[
            Icon(Icons.insert_drive_file, size: 48, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(file.size / 1024).toStringAsFixed(1)} KB • ${file.extension ?? 'file'}',
                    style: const TextStyle(
                      fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: Colors.grey[600],
            onPressed: controller.clearPreview,
            tooltip: 'Remove attachment',
          ),
        ],
      ),
    );
  }
}

/// Text input row with attach button, text field, and send button.
class _InputRow extends StatelessWidget {
  final MessageChatController controller;

  const _InputRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        children: [
          Obx(() => GestureDetector(
                onTap: controller.isUploading.value
                    ? null
                    : () async {
                        try {
                          await controller.pickFile();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to pick file: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                child: Image.asset(
                  'assets/icons/Vector (8).png',
                  width: 22,
                  color: controller.isUploading.value
                      ? Colors.grey
                      : Colors.black45,
                ),
              )),
          const SizedBox(width: 6),
          Expanded(
            child: Obx(() => ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 100),
                  child: TextField(
                    cursorColor: Colors.black54,
                    controller: controller.textController,
                    focusNode: controller.focusNode,
                    enabled: !controller.isUploading.value,
                    textInputAction: TextInputAction.send,
                    keyboardType: TextInputType.text,
                    maxLines: null,
                    minLines: 1,
                    decoration: const InputDecoration(
                      hintText: 'Type a message',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8, vertical: 8),
                    ),
                    onSubmitted: (String value) => _handleSend(context),
                  ),
                )),
          ),
          const SizedBox(width: 6),
          Obx(() => controller.isUploading.value
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
              : ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller.textController,
                  builder: (
                    BuildContext context,
                    TextEditingValue value,
                    Widget? child,
                  ) {
                    final bool hasContent =
                        value.text.trim().isNotEmpty ||
                        controller.previewFile.value != null;
                    return GestureDetector(
                      onTap: () => _handleSend(context),
                      child: Image.asset(
                        'assets/icons/akar-icons_send.png',
                        width: 24,
                        color: hasContent
                            ? const Color(0xFF34A853)
                            : Colors.grey,
                      ),
                    );
                  },
                )),
        ],
      ),
    );
  }

  Future<void> _handleSend(BuildContext context) async {
    final String content = controller.textController.text.trim();
    if (content.isEmpty && controller.previewFile.value == null) return;

    final bool success = await controller.sendMessage(content);

    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message'),
          backgroundColor: Colors.red,
        ),
      );
    } else if (success &&
        controller.previewFile.value == null &&
        context.mounted) {
      // File success snackbar is only shown for file messages
    }
  }
}

// ─────────────────────────────────────────────────────────────────────
// Full-screen image viewer (unchanged from original)
// ─────────────────────────────────────────────────────────────────────

/// Full-screen image viewer for mobile devices.
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
            onPressed: () => FileDownloadService.handleFileAction(
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
            placeholder: (BuildContext context, String url) => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            errorWidget: (BuildContext context, String url, Object error) =>
                const Center(
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
