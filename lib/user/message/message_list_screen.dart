import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/login/custom_drawer.dart';
import '../../shared/widgets/instructor_avatar.dart';
import '../../shared/models/message_model.dart';
import 'package:greenquest/shared/widgets/skeleton_loading.dart';
import 'package:greenquest/shared/widgets/pull_to_refresh_wrapper.dart';
import 'message_chat_screen.dart';
import 'message_list_controller.dart';

/// Student message list screen — shows the student's selected
/// instructor and the most recent message preview.
///
/// All business logic is delegated to [MessageListController].
/// This widget is a thin presentation shell per agents.md §3.1.
class MessageListScreen extends StatelessWidget {
  const MessageListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Register controller — automatically disposed when route is removed.
    final MessageListController controller = Get.put(MessageListController());

    return Scaffold(
      drawer: CustomDrawer(
        selectedIndex: 1,
        onSelect: (int i) => Navigator.pop(context),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
        leading: Builder(
          builder: (BuildContext ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text(
          'Message',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Obx(() => _buildBody(context, controller)),
      ),
    );
  }

  Widget _buildBody(BuildContext context, MessageListController controller) {
    if (controller.isLoading.value) {
      return const SkeletonMessageCard();
    }

    final Map<String, dynamic>? instructor =
        controller.selectedInstructor.value;

    if (instructor == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No instructor selected',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Please select an instructor first',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: PullToRefreshWrapper(
            onRefresh: () async {
              await controller.loadSelectedInstructor();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => MessageChatScreen(instructor: instructor),
                      ),
                    );
                  },
                  child: ListTile(
                    leading: InstructorProfileAvatar(
                      profileImage:
                          instructor['profileImageUrl'] ??
                          instructor['profileImage'],
                      name: instructor['name'] as String? ?? '',
                      isOnline: instructor['isOnline'] == true,
                    ),
                    title: Text(
                      instructor['name'] as String? ?? 'Unknown Instructor',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: _buildSubtitle(controller, instructor),
                  ),
                ),
                const Divider(height: 1),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitle(
    MessageListController controller,
    Map<String, dynamic> instructor,
  ) {
    final MessageModel? message = controller.lastMessage.value;

    if (message == null) {
      final bool isOnline = instructor['isOnline'] == true;
      return Text(
        isOnline ? 'Online' : 'Offline',
        style: TextStyle(
          color: isOnline ? const Color(0xFF34A853) : Colors.grey,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (message.fileAttachment != null) ...[
              Icon(
                _fileAttachmentIcon(message),
                size: 16,
                color: Colors.black54,
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                message.isUnsent
                    ? controller.formatUnsentPreview(message)
                    : controller.formatMessagePreview(message),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  fontStyle: message.isUnsent
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          message.getDisplayTime(),
          style: const TextStyle(color: Colors.black38, fontSize: 12),
        ),
      ],
    );
  }

  /// Choose the correct icon based on file type.
  IconData _fileAttachmentIcon(MessageModel message) {
    final String fileType =
        message.fileAttachment!.fileType.toLowerCase();
    final bool isMedia =
        fileType.contains('image') || fileType.contains('video');
    return isMedia ? Icons.image : Icons.insert_drive_file;
  }
}
