import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/web_chat_controller.dart';
import '../../config/web_theme.dart';
import '../../config/web_routes.dart';
import '../../utils/web_responsive_utils.dart';
import '../../widgets/layout/web_app_bar.dart';
import '../../widgets/layout/web_sidebar.dart';
import '../../../shared/models/message_model.dart';
import '../../../shared/services/file_download_service.dart';
import '../../../shared/services/file_upload_service.dart';
import '../../../shared/widgets/skeleton_loading.dart';

class WebMessageListScreen extends StatefulWidget {
  const WebMessageListScreen({super.key});

  @override
  State<WebMessageListScreen> createState() => _WebMessageListScreenState();
}

class _WebMessageListScreenState extends State<WebMessageListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late WebChatController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(WebChatController());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = WebResponsiveUtils.isDesktop(context);

    // Auto scroll when new messages arrive
    ever(controller.messages, (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    });

    return Scaffold(
      key: _scaffoldKey,
      appBar: WebAppBar(
        title: 'Messages',
        onMenuPressed:
            isDesktop ? null : () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer:
          !isDesktop
              ? Drawer(child: WebSidebar(currentRoute: WebRoutes.messages))
              : null,
      body: Row(
        children: [
          if (isDesktop) const WebSidebar(currentRoute: WebRoutes.messages),
          Expanded(
            child: Container(
              color: WebTheme.backgroundLight,
              child: _buildMainContent(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return _buildSkeletonLoading();
      }

      if (controller.selectedInstructor.value == null) {
        return _buildNoInstructorSelected();
      }

      return Row(
        children: [
          // Desktop: Show instructor info on the left, mobile: Hide
          if (WebResponsiveUtils.isDesktop(context)) _buildInstructorSidebar(),

          // Chat View
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: WebTheme.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildChatHeader(),
                  const Divider(height: 1),
                  Expanded(child: _buildMessageList()),
                  const Divider(height: 1),
                  _buildMessageInput(),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildInstructorSidebar() {
    final instructor = controller.selectedInstructor.value!;
    return Container(
      width: 300,
      margin: const EdgeInsets.fromLTRB(24, 24, 0, 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WebTheme.borderLight),
      ),
      child: Column(
        children: [
          _buildInstructorAvatar(instructor, 100),
          const SizedBox(height: 20),
          Text(
            instructor['name'] ?? 'Instructor',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          _buildOnlineStatus(instructor['isOnline'] ?? false),
          const Divider(height: 48),
          _buildInfoItem(
            Icons.email_outlined,
            'Email',
            instructor['email'] ?? 'N/A',
          ),
          const SizedBox(height: 16),
          _buildInfoItem(
            Icons.phone_outlined,
            'Phone',
            instructor['phone'] ?? 'N/A',
          ),
          const Spacer(),
          const Text(
            'Keep your conversations respectful and educational.',
            style: TextStyle(color: WebTheme.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorAvatar(Map<String, dynamic> instructor, double size) {
    final imageUrl =
        instructor['profileImageUrl'] ?? instructor['profileImage'];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: WebTheme.primaryGreen.withOpacity(0.2),
          width: 3,
        ),
      ),
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: WebTheme.primaryGreen.withOpacity(0.1),
        backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
        child:
            imageUrl == null
                ? Text(
                  (instructor['name'] ?? '?')[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.bold,
                    color: WebTheme.primaryGreen,
                  ),
                )
                : null,
      ),
    );
  }

  Widget _buildOnlineStatus(bool isOnline) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOnline ? Colors.green : Colors.grey,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isOnline ? 'Online' : 'Offline',
          style: TextStyle(
            color: isOnline ? Colors.green : WebTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: WebTheme.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: WebTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatHeader() {
    final instructor = controller.selectedInstructor.value!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          if (!WebResponsiveUtils.isDesktop(context)) ...[
            _buildInstructorAvatar(instructor, 40),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instructor['name'] ?? 'Chat',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                if (!WebResponsiveUtils.isDesktop(context))
                  _buildOnlineStatus(instructor['isOnline'] ?? false),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: WebTheme.textSecondary),
            onPressed: () {
              // Show details dialog for mobile
              if (!WebResponsiveUtils.isDesktop(context)) {
                _showInstructorDetailsDialog(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return Obx(() {
      final messages = controller.messages;

      if (messages.isEmpty) {
        return _buildEmptyChat();
      }

      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(24),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          final isMe = message.senderType == 'student';
          final showDate =
              index == 0 ||
              !_isSameDay(
                messages[index - 1].timestamp.toDate(),
                message.timestamp.toDate(),
              );

          return Column(
            children: [
              if (showDate) _buildDateHeader(message.timestamp.toDate()),
              _buildMessageBubble(message, isMe),
            ],
          );
        },
      );
    });
  }

  Widget _buildDateHeader(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: WebTheme.backgroundLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        DateFormat('MMMM dd, yyyy').format(date),
        style: const TextStyle(
          fontSize: 12,
          color: WebTheme.textSecondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.6,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? WebTheme.primaryGreen : WebTheme.backgroundLight,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 0),
                  bottomRight: Radius.circular(isMe ? 0 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.messageType == 'file' &&
                      message.fileAttachment != null)
                    _buildFileMessage(message.fileAttachment!, isMe),
                  if (message.content.isNotEmpty)
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isMe ? Colors.white : WebTheme.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('hh:mm a').format(message.timestamp.toDate()),
              style: const TextStyle(
                fontSize: 10,
                color: WebTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileMessage(FileAttachment attachment, bool isMe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insert_drive_file,
            color: isMe ? Colors.white : WebTheme.primaryGreen,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              attachment.fileName,
              style: TextStyle(
                color: isMe ? Colors.white : WebTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed:
                () => FileDownloadService.handleFileAction(
                  fileUrl: attachment.fileUrl,
                  fileName: attachment.fileName,
                  fileType: attachment.fileType,
                  context: context,
                ),
            icon: const Icon(Icons.open_in_new, size: 16),
            color: isMe ? Colors.white : WebTheme.primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file, color: WebTheme.textSecondary),
            onPressed: _handleFileUpload,
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: WebTheme.backgroundLight,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (val) => _handleSendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return Obx(
      () => Container(
        decoration: const BoxDecoration(
          color: WebTheme.primaryGreen,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon:
              controller.isSending.value
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                  : const Icon(Icons.send, color: Colors.white, size: 20),
          onPressed: controller.isSending.value ? null : _handleSendMessage,
        ),
      ),
    );
  }

  void _handleSendMessage() {
    final text = _messageController.text;
    if (text.trim().isNotEmpty) {
      controller.sendMessage(text);
      _messageController.clear();
    }
  }

  Widget _buildNoInstructorSelected() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.message_outlined,
            size: 80,
            color: WebTheme.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          const Text(
            'Keep in touch with your instructors',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Select an instructor to start a conversation.'),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 60,
            color: WebTheme.textSecondary.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            'No messages yet',
            style: TextStyle(color: WebTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Send a message to start the journey!',
            style: TextStyle(color: WebTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _showInstructorDetailsDialog(BuildContext context) {
    final instructor = controller.selectedInstructor.value!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInstructorAvatar(instructor, 80),
                const SizedBox(height: 16),
                Text(
                  instructor['name'] ?? 'Instructor',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                _buildOnlineStatus(instructor['isOnline'] ?? false),
                const Divider(height: 48),
                _buildInfoItem(
                  Icons.email_outlined,
                  'Email',
                  instructor['email'] ?? 'N/A',
                ),
                const SizedBox(height: 16),
                _buildInfoItem(
                  Icons.phone_outlined,
                  'Phone',
                  instructor['phone'] ?? 'N/A',
                ),
              ],
            ),
          ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<void> _handleFileUpload() async {
    try {
      // Pick a file
      final files = await FileUploadService().pickFiles(allowMultiple: false);

      if (files == null || files.isEmpty) {
        return;
      }

      final file = files.first;

      // Show uploading indicator
      Get.dialog(
        const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: WebTheme.primaryGreen),
                  SizedBox(height: 16),
                  Text('Uploading file...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Upload the file
      final response = await FileUploadService().uploadFile(
        file: file,
        folder: 'messages',
      );

      // Close the uploading dialog
      Get.back();

      if (response != null) {
        // Send the file message
        await controller.sendFile(
          file.name,
          response.secureUrl,
          file.extension ?? 'unknown',
          file.size,
        );

        Get.snackbar(
          'Success',
          'File sent successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: WebTheme.primaryGreen,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      // Close any open dialogs
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      Get.snackbar(
        'Error',
        'Failed to upload file: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Widget _buildSkeletonLoading() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SkeletonText(width: 200, height: 24),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: 5,
                itemBuilder:
                    (context, index) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: SkeletonMessageCard(),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
