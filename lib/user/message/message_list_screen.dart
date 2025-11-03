import 'dart:async';
import 'package:flutter/material.dart';
import '../../shared/login/custom_drawer.dart';
import '../../shared/services/instructor_service.dart';
import '../../shared/services/message_service.dart';
import '../../shared/widgets/instructor_avatar.dart';
import 'message_chat_screen.dart';
import 'package:greenquest/shared/widgets/skeleton_loading.dart';
import '../../shared/models/message_model.dart';

class MessageListScreen extends StatefulWidget {
  const MessageListScreen({super.key});

  @override
  State<MessageListScreen> createState() => _MessageListScreenState();
}

class _MessageListScreenState extends State<MessageListScreen> {
  int selectedDrawerIndex = 1;
  Map<String, dynamic>? selectedInstructor;
  bool isLoading = true;
  MessageModel? lastMessage;
  StreamSubscription<List<MessageModel>>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _loadSelectedInstructor();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSelectedInstructor() async {
    try {
      final instructor = await InstructorService.getSelectedInstructor();
      setState(() {
        selectedInstructor = instructor;
        isLoading = false;
      });

      // Load last message if instructor is available
      if (instructor != null && instructor['id'] != null) {
        _loadLastMessage(instructor['id']);
      }
    } catch (e) {
      print('Error loading selected instructor: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _loadLastMessage(String instructorId) {
    // Cancel previous subscription
    _messageSubscription?.cancel();

    // Subscribe to bidirectional messages and get the last one
    _messageSubscription = MessageService.getBidirectionalMessages(
      instructorId,
    ).listen((messages) {
      if (messages.isNotEmpty && mounted) {
        // Get the last message (messages are sorted by timestamp ascending)
        setState(() {
          lastMessage = messages.last;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomDrawer(
        selectedIndex: selectedDrawerIndex,
        onSelect: (i) {
          setState(() => selectedDrawerIndex = i);
          Navigator.pop(context);
        },
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.black),
                onPressed: () => Scaffold.of(context).openDrawer(),
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
      body: SafeArea(child: _buildContent()),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const SkeletonMessageCard();
    }

    if (selectedInstructor == null) {
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
        ListTile(
          leading: InstructorProfileAvatar(
            profileImage:
                selectedInstructor!['profileImageUrl'] ??
                selectedInstructor!['profileImage'],
            name: selectedInstructor!['name'],
            isOnline: selectedInstructor!['isOnline'] ?? false,
          ),
          title: Text(
            selectedInstructor!['name'] ?? 'Unknown Instructor',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle:
              lastMessage != null
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Show icon for attachments
                          if (lastMessage!.fileAttachment != null) ...[
                            Icon(
                              lastMessage!.fileAttachment!.fileType
                                          .toLowerCase()
                                          .contains('image') ||
                                      lastMessage!.fileAttachment!.fileType
                                          .toLowerCase()
                                          .contains('video')
                                  ? Icons.image
                                  : Icons.insert_drive_file,
                              size: 16,
                              color: Colors.black54,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              lastMessage!.fileAttachment != null
                                  ? lastMessage!.fileAttachment!.fileName
                                  : lastMessage!.content,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lastMessage!.getDisplayTime(),
                        style: const TextStyle(
                          color: Colors.black38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )
                  : Text(
                    selectedInstructor!['isOnline'] == true
                        ? 'Online'
                        : 'Offline',
                    style: TextStyle(
                      color:
                          selectedInstructor!['isOnline'] == true
                              ? const Color(0xFF34A853)
                              : Colors.grey,
                    ),
                  ),
          trailing: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => MessageChatScreen(instructor: selectedInstructor!),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF34A853),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              elevation: 0,
            ),
            child: const Text('Chat'),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
