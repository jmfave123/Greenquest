import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import '../utils/file_type_utils.dart';
import 'notify_service.dart';

class MessageService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Send a text message
  static Future<void> sendMessage({
    required String receiverId,
    required String content,
    String senderType = 'student',
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final message = MessageModel(
        id: '', // Will be set by Firestore
        senderId: user.uid,
        receiverId: receiverId,
        senderType: senderType,
        content: content,
        timestamp: Timestamp.now(),
        isRead: false,
        messageType: 'text',
      );

      await _firestore.collection('messages').add(message.toMap());

      // Send push notification if instructor is sending to student
      if (senderType == 'instructor') {
        _sendPushNotification(
          receiverId: receiverId,
          senderId: user.uid,
          content: content,
          messageType: 'text',
        );
      }
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  /// Send a message with file attachment
  static Future<void> sendMessageWithFile({
    required String receiverId,
    required String content,
    required String fileName,
    required String fileUrl,
    required String fileType,
    required int fileSize,
    String senderType = 'student',
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final fileAttachment = FileAttachment(
        fileName: fileName,
        fileUrl: fileUrl,
        fileType: fileType,
        fileSize: fileSize,
      );

      final message = MessageModel(
        id: '', // Will be set by Firestore
        senderId: user.uid,
        receiverId: receiverId,
        senderType: senderType,
        content:
            content.isEmpty
                ? ''
                : content, // Use empty string instead of 'Sent a file'
        timestamp: Timestamp.now(),
        isRead: false,
        messageType: 'file',
        fileAttachment: fileAttachment,
      );

      await _firestore.collection('messages').add(message.toMap());

      // Send push notification if instructor is sending to student
      if (senderType == 'instructor') {
        _sendPushNotification(
          receiverId: receiverId,
          senderId: user.uid,
          content:
              content.isEmpty
                  ? fileName
                  : content, // Use file name instead of 'Sent a file'
          messageType: 'file',
          fileType: fileType,
        );
      }
    } catch (e) {
      print('Error sending file message: $e');
      rethrow;
    }
  }

  /// Get messages between current user and another user - SIMPLIFIED VERSION
  static Stream<List<MessageModel>> getMessages(String otherUserId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('messages')
        .where('senderId', isEqualTo: user.uid)
        .where('receiverId', isEqualTo: otherUserId)
        .snapshots()
        .map((snapshot) {
          final messages = <MessageModel>[];
          for (var doc in snapshot.docs) {
            messages.add(MessageModel.fromMap(doc.id, doc.data()));
          }
          return messages;
        });
  }

  /// Get bidirectional messages between two users (for both student and instructor)
  static Stream<List<MessageModel>> getBidirectionalMessages(
    String otherUserId,
  ) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    // Get messages where current user is either sender or receiver
    return _firestore.collection('messages').snapshots().asyncMap((
      snapshot,
    ) async {
      final messages = <MessageModel>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final senderId = data['senderId'] as String;
        final receiverId = data['receiverId'] as String;

        // Include message if current user is involved with otherUserId
        if ((senderId == user.uid && receiverId == otherUserId) ||
            (senderId == otherUserId && receiverId == user.uid)) {
          messages.add(MessageModel.fromMap(doc.id, data));
        }
      }

      // Sort by timestamp
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    });
  }

  /// Get all enrolled students for the instructor with their message data
  static Stream<List<Map<String, dynamic>>> getStudentsWithMessages() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    // Combine streams: students collection + messages collection for real-time updates
    // Listen to messages collection to trigger updates when messages are sent/received
    final studentsStream =
        _firestore
            .collection('instructors')
            .doc(user.uid)
            .collection('students')
            .snapshots();

    // Listen to all messages - when any message changes, it will trigger an update
    final messagesStream = _firestore.collection('messages').snapshots();

    // Combine both streams - when either students or messages change, update the list
    // Use asyncExpand to combine streams properly
    return studentsStream.asyncExpand((studentsSnapshot) {
      // Every time students change, also listen to message changes
      return messagesStream.asyncMap((_) async {
        // Re-fetch messages when stream triggers
        final students = <Map<String, dynamic>>[];
        final conversationData = <String, Map<String, dynamic>>{};

        // Get all messages where instructor is involved (bidirectional) - REAL-TIME
        // Get messages sent by instructor to students
        final sentMessagesSnapshot =
            await _firestore
                .collection('messages')
                .where('senderId', isEqualTo: user.uid)
                .where('senderType', isEqualTo: 'instructor')
                .get();

        // Get messages received by instructor from students
        final receivedMessagesSnapshot =
            await _firestore
                .collection('messages')
                .where('receiverId', isEqualTo: user.uid)
                .where('senderType', isEqualTo: 'student')
                .get();

        // Process sent messages (from instructor)
        for (var doc in sentMessagesSnapshot.docs) {
          final data = doc.data();
          final receiverId = data['receiverId'] as String;

          // Store latest message data per conversation
          if (!conversationData.containsKey(receiverId)) {
            conversationData[receiverId] = {
              'lastMessage': _formatMessagePreview(
                data,
                'You', // Use "You" when instructor sends message
                true, // isFromInstructor
              ),
              'timestamp': data['timestamp'],
              'isRead': true, // Messages sent by instructor are always "read"
              'hasMessages': true,
              'senderType': 'instructor',
              'senderName': 'You',
            };
          } else {
            final existing = conversationData[receiverId]!;
            if ((data['timestamp'] as Timestamp).compareTo(
                  existing['timestamp'],
                ) >
                0) {
              conversationData[receiverId] = {
                'lastMessage': _formatMessagePreview(
                  data,
                  'You', // Use "You" when instructor sends message
                  true, // isFromInstructor
                ),
                'timestamp': data['timestamp'],
                'isRead': true,
                'hasMessages': true,
                'senderType': 'instructor',
                'senderName': 'You',
              };
            }
          }
        }

        // Process received messages (from students)
        for (var doc in receivedMessagesSnapshot.docs) {
          final data = doc.data();
          final senderId = data['senderId'] as String;

          // Store latest message data per conversation
          if (!conversationData.containsKey(senderId)) {
            // Get student name for message preview
            String studentName = 'Student';
            try {
              final studentDoc =
                  await _firestore.collection('users').doc(senderId).get();
              if (studentDoc.exists) {
                final studentData = studentDoc.data();
                studentName =
                    studentData?['name'] ??
                    studentData?['fullName'] ??
                    studentData?['studentName'] ??
                    'Student';
              }
            } catch (e) {
              print('Error fetching student name: $e');
            }

            conversationData[senderId] = {
              'lastMessage': _formatMessagePreview(
                data,
                studentName,
                false, // isFromInstructor
              ),
              'timestamp': data['timestamp'],
              'isRead': data['isRead'] ?? false,
              'hasMessages': true,
              'senderType': 'student',
              'senderName': studentName,
            };
          } else {
            final existing = conversationData[senderId]!;
            if ((data['timestamp'] as Timestamp).compareTo(
                  existing['timestamp'],
                ) >
                0) {
              // Get student name for message preview
              String studentName = 'Student';
              try {
                final studentDoc =
                    await _firestore.collection('users').doc(senderId).get();
                if (studentDoc.exists) {
                  final studentData = studentDoc.data();
                  studentName =
                      studentData?['name'] ??
                      studentData?['fullName'] ??
                      studentData?['studentName'] ??
                      'Student';
                }
              } catch (e) {
                print('Error fetching student name: $e');
              }

              conversationData[senderId] = {
                'lastMessage': _formatMessagePreview(
                  data,
                  studentName,
                  false, // isFromInstructor
                ),
                'timestamp': data['timestamp'],
                'isRead': data['isRead'] ?? false,
                'hasMessages': true,
                'senderType': 'student',
                'senderName': studentName,
              };
            }
          }
        }

        // Process all enrolled students
        for (var doc in studentsSnapshot.docs) {
          final studentId = doc.id;
          final studentDocData = doc.data();

          // Get conversation data if student has messages
          final conversationInfo = conversationData[studentId];

          // Fetch profile image from users collection
          String profileImageUrl = '';
          try {
            final userDoc =
                await _firestore.collection('users').doc(studentId).get();
            if (userDoc.exists) {
              final userData = userDoc.data() as Map<String, dynamic>;
              profileImageUrl =
                  userData['profileImage'] ??
                  userData['profileImageUrl'] ??
                  userData['profileUrl'] ??
                  '';
            }
          } catch (e) {
            print('Error fetching profile image for student $studentId: $e');
          }

          // Calculate unread count (only messages from student that are unread)
          int unreadCount = 0;
          if (conversationInfo != null &&
              conversationInfo['senderType'] == 'student') {
            unreadCount = (conversationInfo['isRead'] == false) ? 1 : 0;
          }

          students.add({
            'id': studentId,
            'name': studentDocData['studentName'] ?? 'Unknown Student',
            'email': studentDocData['email'] ?? '',
            'image': profileImageUrl,
            'lastMessage':
                conversationInfo?['lastMessage'] ?? 'No messages yet',
            'timestamp': conversationInfo?['timestamp'] ?? Timestamp.now(),
            'hasMessages': conversationInfo?['hasMessages'] ?? false,
            'online': studentDocData['isOnline'] ?? false,
            'status': studentDocData['isOnline'] == true ? 'Online' : 'Offline',
            'unreadCount': unreadCount,
          });
        }

        // Sort by latest message timestamp (students with messages first)
        students.sort((a, b) {
          final aHasMessages = a['hasMessages'] as bool;
          final bHasMessages = b['hasMessages'] as bool;

          if (aHasMessages && !bHasMessages) return -1;
          if (!aHasMessages && bHasMessages) return 1;

          if (aHasMessages && bHasMessages) {
            return (b['timestamp'] as Timestamp).compareTo(a['timestamp']);
          }

          // If neither has messages, sort by name
          return (a['name'] as String).compareTo(b['name'] as String);
        });

        return students;
      });
    });
  }

  /// Get first name from full name
  static String _getFirstName(String fullName) {
    if (fullName.isEmpty) return 'Student';
    final nameParts = fullName.trim().split(' ');
    return nameParts.first;
  }

  /// Format message preview text based on message type
  /// Returns formatted string like "You: imissyou" or "john sent a photo" or "Message text"
  static String _formatMessagePreview(
    Map<String, dynamic> messageData,
    String senderName,
    bool isFromInstructor,
  ) {
    final messageType = messageData['messageType'] ?? 'text';
    final content = messageData['content']?.toString() ?? '';
    final isUnsent = messageData['isUnsent'] ?? false;

    // Handle unsent messages
    if (isUnsent) {
      if (isFromInstructor) {
        return 'You unsent a message';
      } else {
        // Use first name only for student
        final firstName = _getFirstName(senderName);
        return '$firstName unsent a message';
      }
    }

    // If it's a file attachment
    if (messageType == 'file' && messageData['fileAttachment'] != null) {
      final fileAttachment =
          messageData['fileAttachment'] as Map<String, dynamic>;
      final fileType =
          (fileAttachment['fileType'] ?? '').toString().toLowerCase();

      // Check if it's an image
      if (FileTypeUtils.isImageFile(fileType)) {
        if (isFromInstructor) {
          return 'You sent a photo';
        } else {
          // Use first name only for student
          final firstName = _getFirstName(senderName);
          return '$firstName sent a photo';
        }
      } else {
        if (isFromInstructor) {
          return 'You sent a file';
        } else {
          // Use first name only for student
          final firstName = _getFirstName(senderName);
          return '$firstName sent a file';
        }
      }
    }

    // For text messages - if content is empty and there's a file, show file name
    if (content.isEmpty) {
      // This case should not happen for text messages, but handle gracefully
      return '';
    }

    // For text messages: add "You: " prefix if from instructor, otherwise just show content
    if (isFromInstructor) {
      return 'You: $content';
    } else {
      // Just show the student's message content without name prefix
      return content;
    }
  }

  /// Mark messages as read
  static Future<void> markMessagesAsRead(String senderId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();

      final unreadMessages =
          await _firestore
              .collection('messages')
              .where('senderId', isEqualTo: senderId)
              .where('receiverId', isEqualTo: user.uid)
              .where('isRead', isEqualTo: false)
              .get();

      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  /// Get unread message count for current user
  static Stream<int> getUnreadCount() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('messages')
        .where('receiverId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Get recent conversations for current user
  static Stream<List<Map<String, dynamic>>> getRecentConversations() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('messages')
        .where('senderId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final conversations = <String, Map<String, dynamic>>{};

          // Get messages sent by current user
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final receiverId = data['receiverId'] as String;

            if (!conversations.containsKey(receiverId)) {
              conversations[receiverId] = {
                'receiverId': receiverId,
                'lastMessage': data['content'],
                'timestamp': data['timestamp'],
                'isRead': true, // Messages sent by user are always "read"
              };
            }
          }

          // Get messages received by current user
          final receivedMessages =
              await _firestore
                  .collection('messages')
                  .where('receiverId', isEqualTo: user.uid)
                  .orderBy('timestamp', descending: true)
                  .get();

          for (var doc in receivedMessages.docs) {
            final data = doc.data();
            final senderId = data['senderId'] as String;

            if (!conversations.containsKey(senderId) ||
                conversations[senderId]!['timestamp'].compareTo(
                      data['timestamp'],
                    ) <
                    0) {
              conversations[senderId] = {
                'receiverId': senderId,
                'lastMessage': data['content'],
                'timestamp': data['timestamp'],
                'isRead': data['isRead'],
              };
            }
          }

          return conversations.values.toList()..sort(
            (a, b) => (b['timestamp'] as Timestamp).compareTo(
              a['timestamp'] as Timestamp,
            ),
          );
        });
  }

  /// Delete a message (optional feature)
  static Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).delete();
    } catch (e) {
      print('Error deleting message: $e');
      rethrow;
    }
  }

  /// Unsend a message (replace with "You unsent a message" text)
  static Future<void> unsendMessage(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'content': 'You unsent a message',
        'isUnsent': true,
        'fileAttachment': null, // Remove file attachment when unsent
      });
    } catch (e) {
      print('Error unsending message: $e');
      rethrow;
    }
  }

  /// Send push notification to student when instructor sends a message
  static Future<void> _sendPushNotification({
    required String receiverId,
    required String senderId,
    required String content,
    required String messageType,
    String? fileType,
  }) async {
    try {
      // Get student's Player ID
      final playerId = await OneSignalHelper.getPlayerIdForUser(receiverId);
      if (playerId == null || playerId.isEmpty) {
        print(
          '⚠️ No Player ID found for user $receiverId, skipping push notification',
        );
        return;
      }

      // Get instructor's name
      String instructorName = 'Instructor';
      try {
        final instructorDoc =
            await _firestore.collection('instructors').doc(senderId).get();
        if (instructorDoc.exists) {
          final instructorData = instructorDoc.data();
          instructorName =
              instructorData?['name'] ??
              instructorData?['fullName'] ??
              instructorData?['instructorName'] ??
              'Instructor';
        }
      } catch (e) {
        print('Error fetching instructor name: $e');
      }

      // Format notification content based on message type
      String notificationContent = content;
      if (messageType == 'file') {
        if (fileType != null) {
          final lowerFileType = fileType.toLowerCase();
          if (FileTypeUtils.isImageFile(lowerFileType)) {
            notificationContent = 'Sent a photo';
          } else if (FileTypeUtils.isVideoFile(lowerFileType)) {
            notificationContent = 'Sent a video';
          } else {
            notificationContent = 'Sent a file';
          }
        } else {
          notificationContent = 'Sent a file';
        }
      }

      // Truncate content if too long
      if (notificationContent.length > 100) {
        notificationContent = '${notificationContent.substring(0, 97)}...';
      }

      // Send push notification
      await NotifServices.sendIndividualNotification(
        playerId: playerId,
        heading: 'New message from $instructorName',
        content: notificationContent,
      );

      print('✅ Push notification sent to student $receiverId');
    } catch (e) {
      print('❌ Error sending push notification: $e');
      // Don't throw - message was already sent successfully
    }
  }
}
