import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String senderType; // 'student' or 'instructor'
  final String content;
  final Timestamp timestamp;
  final bool isRead;
  final String messageType; // 'text', 'image', 'file'
  final FileAttachment? fileAttachment;
  final bool isUnsent;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.senderType,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.messageType = 'text',
    this.fileAttachment,
    this.isUnsent = false,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'senderType': senderType,
      'content': content,
      'timestamp': timestamp,
      'isRead': isRead,
      'messageType': messageType,
      'fileAttachment': fileAttachment?.toMap(),
      'isUnsent': isUnsent,
    };
  }

  // Create from Firestore document
  factory MessageModel.fromMap(String id, Map<String, dynamic> data) {
    return MessageModel(
      id: id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      senderType: data['senderType'] ?? 'student',
      content: data['content'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      isRead: data['isRead'] ?? false,
      messageType: data['messageType'] ?? 'text',
      fileAttachment:
          data['fileAttachment'] != null
              ? FileAttachment.fromMap(data['fileAttachment'])
              : null,
      isUnsent: data['isUnsent'] ?? false,
    );
  }

  // Helper method to check if message is from current user
  bool isFromUser(String userId) {
    return senderId == userId;
  }

  // Helper method to get display time
  String getDisplayTime() {
    final now = DateTime.now();
    final messageTime = timestamp.toDate();
    final difference = now.difference(messageTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${messageTime.day}/${messageTime.month}';
    }
  }
}

class FileAttachment {
  final String fileName;
  final String fileUrl;
  final String fileType;
  final int fileSize;

  FileAttachment({
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
  });

  Map<String, dynamic> toMap() {
    return {
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileSize': fileSize,
    };
  }

  factory FileAttachment.fromMap(Map<String, dynamic> data) {
    return FileAttachment(
      fileName: data['fileName'] ?? '',
      fileUrl: data['fileUrl'] ?? '',
      fileType: data['fileType'] ?? '',
      fileSize: data['fileSize'] ?? 0,
    );
  }
}
