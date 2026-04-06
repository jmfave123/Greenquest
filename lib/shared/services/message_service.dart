import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/message_model.dart';
import '../utils/file_type_utils.dart';
import 'message_repository.dart';
import 'message_notification_service.dart';
import '../../core/utils/app_logger.dart';

/// Facade over [MessageRepository] and [MessageNotificationService].
///
/// Preserves the existing static API so that instructor screens
/// and the web chat controller continue working without changes.
///
/// New code should inject [MessageRepository] directly instead
/// of calling these static methods.
///
/// Following agents.md §8 safe refactor flow:
/// Add (MessageRepository) → Migrate (student controllers) →
/// Verify → Remove (these static delegates, eventually).
class MessageService {
  static final _logger = AppLogger('MessageService');
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Access the registered [MessageRepository] instance.
  /// Falls back to direct Firestore if the repository is not yet registered
  /// (e.g. during early app startup).
  static MessageRepository? get _repo {
    try {
      return Get.find<MessageRepository>();
    } catch (_) {
      return null;
    }
  }

  // ── Send ──────────────────────────────────────────────────────────

  /// Send a text message.
  static Future<void> sendMessage({
    required String receiverId,
    required String content,
    String senderType = 'student',
  }) async {
    try {
      final MessageRepository? repo = _repo;
      if (repo != null) {
        await repo.sendMessage(
          receiverId: receiverId,
          content: content,
          senderType: senderType,
        );
      } else {
        // Fallback: direct Firestore write (for backward compatibility)
        await _sendMessageDirect(
          receiverId: receiverId,
          content: content,
          senderType: senderType,
        );
      }

      // Fire-and-forget notification
      MessageNotificationService.notifyReceiver(
        receiverId: receiverId,
        senderId: _auth.currentUser?.uid ?? '',
        content: content,
        messageType: 'text',
        senderType: senderType,
      );
    } catch (e) {
      _logger.error('Error sending message: $e');
      rethrow;
    }
  }

  /// Send a message with file attachment.
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
      final MessageRepository? repo = _repo;
      if (repo != null) {
        await repo.sendMessageWithFile(
          receiverId: receiverId,
          content: content,
          fileName: fileName,
          fileUrl: fileUrl,
          fileType: fileType,
          fileSize: fileSize,
          senderType: senderType,
        );
      } else {
        await _sendMessageWithFileDirect(
          receiverId: receiverId,
          content: content,
          fileName: fileName,
          fileUrl: fileUrl,
          fileType: fileType,
          fileSize: fileSize,
          senderType: senderType,
        );
      }

      // Fire-and-forget notification
      MessageNotificationService.notifyReceiver(
        receiverId: receiverId,
        senderId: _auth.currentUser?.uid ?? '',
        content: content.isEmpty ? fileName : content,
        messageType: 'file',
        senderType: senderType,
        fileType: fileType,
      );
    } catch (e) {
      _logger.error('Error sending file message: $e');
      rethrow;
    }
  }

  // ── Queries ───────────────────────────────────────────────────────

  /// Get bidirectional messages between current user and [otherUserId].
  static Stream<List<MessageModel>> getBidirectionalMessages(
    String otherUserId,
  ) {
    final MessageRepository? repo = _repo;
    if (repo != null) {
      return repo.getBidirectionalMessages(otherUserId);
    }
    // Fallback: direct Firestore query
    return _getBidirectionalMessagesDirect(otherUserId);
  }

  /// Get unread message count for current user.
  static Stream<int> getUnreadCount() {
    final MessageRepository? repo = _repo;
    if (repo != null) return repo.getUnreadCount();
    return _getUnreadCountDirect();
  }

  // ── Commands ──────────────────────────────────────────────────────

  /// Mark messages from [senderId] as read.
  static Future<void> markMessagesAsRead(String senderId) async {
    final MessageRepository? repo = _repo;
    if (repo != null) {
      await repo.markMessagesAsRead(senderId);
    } else {
      await _markMessagesAsReadDirect(senderId);
    }
  }

  /// Unsend (soft-delete) a message.
  static Future<void> unsendMessage(String messageId) async {
    final MessageRepository? repo = _repo;
    if (repo != null) {
      await repo.unsendMessage(messageId);
    } else {
      await _unsendMessageDirect(messageId);
    }
  }

  /// Permanently delete a message.
  static Future<void> deleteMessage(String messageId) async {
    final MessageRepository? repo = _repo;
    if (repo != null) {
      await repo.deleteMessage(messageId);
    } else {
      await _firestore.collection('messages').doc(messageId).delete();
    }
  }

  // ── Instructor-Specific (kept here until instructor refactoring) ──

  /// Get all enrolled students for the instructor with their message data.
  /// This complex orchestration method stays in MessageService for now
  /// because it's only used by the instructor message list screen.
  static Stream<List<Map<String, dynamic>>> getStudentsWithMessages() {
    final User? user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    final Stream<QuerySnapshot<Map<String, dynamic>>> studentsStream =
        _firestore
            .collection('instructors')
            .doc(user.uid)
            .collection('students')
            .snapshots();

    final Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream =
        _firestore.collection('messages').snapshots();

    return studentsStream.asyncExpand(
      (QuerySnapshot<Map<String, dynamic>> studentsSnapshot) {
        return messagesStream.asyncMap((_) async {
          return _buildStudentListWithMessages(
            user.uid,
            studentsSnapshot,
          );
        });
      },
    );
  }

  // ── Direct Firestore Fallbacks ────────────────────────────────────
  // These are used only when the MessageRepository has not been
  // registered yet (pre-DI initialization). They mirror the legacy
  // behavior exactly.

  static Future<void> _sendMessageDirect({
    required String receiverId,
    required String content,
    String senderType = 'student',
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final MessageModel message = MessageModel(
      id: '',
      senderId: user.uid,
      receiverId: receiverId,
      senderType: senderType,
      content: content,
      timestamp: Timestamp.now(),
      isRead: false,
      messageType: 'text',
    );

    await _firestore.collection('messages').add(message.toMap());
  }

  static Future<void> _sendMessageWithFileDirect({
    required String receiverId,
    required String content,
    required String fileName,
    required String fileUrl,
    required String fileType,
    required int fileSize,
    String senderType = 'student',
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final FileAttachment fileAttachment = FileAttachment(
      fileName: fileName,
      fileUrl: fileUrl,
      fileType: fileType,
      fileSize: fileSize,
    );

    final MessageModel message = MessageModel(
      id: '',
      senderId: user.uid,
      receiverId: receiverId,
      senderType: senderType,
      content: content.isEmpty ? '' : content,
      timestamp: Timestamp.now(),
      isRead: false,
      messageType: 'file',
      fileAttachment: fileAttachment,
    );

    await _firestore.collection('messages').add(message.toMap());
  }

  static Stream<List<MessageModel>> _getBidirectionalMessagesDirect(
    String otherUserId,
  ) {
    final User? user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore.collection('messages').snapshots().asyncMap(
      (QuerySnapshot<Map<String, dynamic>> snapshot) async {
        final List<MessageModel> messages = <MessageModel>[];

        for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
            in snapshot.docs) {
          final Map<String, dynamic> data = doc.data();
          final String senderId = data['senderId'] as String? ?? '';
          final String receiverId = data['receiverId'] as String? ?? '';

          if ((senderId == user.uid && receiverId == otherUserId) ||
              (senderId == otherUserId && receiverId == user.uid)) {
            messages.add(MessageModel.fromMap(doc.id, data));
          }
        }

        messages.sort(
          (MessageModel a, MessageModel b) =>
              a.timestamp.compareTo(b.timestamp),
        );
        return messages;
      },
    );
  }

  static Stream<int> _getUnreadCountDirect() {
    final User? user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('messages')
        .where('receiverId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) =>
            snapshot.docs.length);
  }

  static Future<void> _markMessagesAsReadDirect(String senderId) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      final WriteBatch batch = _firestore.batch();

      final QuerySnapshot<Map<String, dynamic>> unreadMessages =
          await _firestore
              .collection('messages')
              .where('senderId', isEqualTo: senderId)
              .where('receiverId', isEqualTo: user.uid)
              .where('isRead', isEqualTo: false)
              .get();

      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      _logger.error('Error marking messages as read: $e');
    }
  }

  static Future<void> _unsendMessageDirect(String messageId) async {
    await _firestore.collection('messages').doc(messageId).update({
      'content': 'You unsent a message',
      'isUnsent': true,
      'fileAttachment': null,
    });
  }

  // ── Student List Builder (instructor-only) ────────────────────────

  static Future<List<Map<String, dynamic>>> _buildStudentListWithMessages(
    String instructorId,
    QuerySnapshot<Map<String, dynamic>> studentsSnapshot,
  ) async {
    final List<Map<String, dynamic>> students = <Map<String, dynamic>>[];
    final Map<String, Map<String, dynamic>> conversationData =
        <String, Map<String, dynamic>>{};

    // Get messages sent by instructor
    final QuerySnapshot<Map<String, dynamic>> sentSnapshot = await _firestore
        .collection('messages')
        .where('senderId', isEqualTo: instructorId)
        .where('senderType', isEqualTo: 'instructor')
        .get();

    // Get messages received by instructor
    final QuerySnapshot<Map<String, dynamic>> receivedSnapshot =
        await _firestore
            .collection('messages')
            .where('receiverId', isEqualTo: instructorId)
            .where('senderType', isEqualTo: 'student')
            .get();

    // Process sent messages
    for (final doc in sentSnapshot.docs) {
      final Map<String, dynamic> data = doc.data();
      final String receiverId = data['receiverId'] as String;
      _updateConversationData(
        conversationData, receiverId, data, true, instructorId,
      );
    }

    // Process received messages
    for (final doc in receivedSnapshot.docs) {
      final Map<String, dynamic> data = doc.data();
      final String senderId = data['senderId'] as String;
      await _updateConversationDataFromStudent(
        conversationData, senderId, data, instructorId,
      );
    }

    // Build student list
    for (final doc in studentsSnapshot.docs) {
      final String studentId = doc.id;
      final Map<String, dynamic> studentDocData = doc.data();
      final Map<String, dynamic>? conversationInfo =
          conversationData[studentId];

      String profileImageUrl = '';
      try {
        final DocumentSnapshot<Map<String, dynamic>> userDoc =
            await _firestore.collection('users').doc(studentId).get();
        if (userDoc.exists) {
          final Map<String, dynamic> userData = userDoc.data()!;
          profileImageUrl = userData['profileImage'] as String? ??
              userData['profileImageUrl'] as String? ??
              userData['profileUrl'] as String? ??
              '';
        }
      } catch (e) {
        _logger.error('Error fetching profile for student $studentId');
      }

      int unreadCount = 0;
      if (conversationInfo != null &&
          conversationInfo['senderType'] == 'student') {
        unreadCount = (conversationInfo['isRead'] == false) ? 1 : 0;
      }

      students.add({
        'id': studentId,
        'name': studentDocData['studentName'] as String? ?? 'Unknown Student',
        'email': studentDocData['email'] as String? ?? '',
        'image': profileImageUrl,
        'lastMessage':
            conversationInfo?['lastMessage'] as String? ?? 'No messages yet',
        'timestamp': conversationInfo?['timestamp'] ?? Timestamp.now(),
        'hasMessages': conversationInfo?['hasMessages'] ?? false,
        'online': studentDocData['isOnline'] ?? false,
        'status':
            studentDocData['isOnline'] == true ? 'Online' : 'Offline',
        'unreadCount': unreadCount,
      });
    }

    // Sort: students with messages first, then by timestamp
    students.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      final bool aHas = a['hasMessages'] as bool;
      final bool bHas = b['hasMessages'] as bool;
      if (aHas && !bHas) return -1;
      if (!aHas && bHas) return 1;
      if (aHas && bHas) {
        return (b['timestamp'] as Timestamp)
            .compareTo(a['timestamp'] as Timestamp);
      }
      return (a['name'] as String).compareTo(b['name'] as String);
    });

    return students;
  }

  static void _updateConversationData(
    Map<String, Map<String, dynamic>> conversationData,
    String otherUserId,
    Map<String, dynamic> data,
    bool isFromInstructor,
    String instructorId,
  ) {
    final String preview = _formatMessagePreview(
      data, 'You', isFromInstructor,
    );
    final Timestamp timestamp = data['timestamp'] as Timestamp;

    if (!conversationData.containsKey(otherUserId) ||
        timestamp.compareTo(
              conversationData[otherUserId]!['timestamp'] as Timestamp,
            ) >
            0) {
      conversationData[otherUserId] = {
        'lastMessage': preview,
        'timestamp': timestamp,
        'isRead': isFromInstructor ? true : (data['isRead'] ?? false),
        'hasMessages': true,
        'senderType': isFromInstructor ? 'instructor' : 'student',
        'senderName': isFromInstructor ? 'You' : 'Student',
      };
    }
  }

  static Future<void> _updateConversationDataFromStudent(
    Map<String, Map<String, dynamic>> conversationData,
    String senderId,
    Map<String, dynamic> data,
    String instructorId,
  ) async {
    String studentName = 'Student';
    try {
      final DocumentSnapshot<Map<String, dynamic>> studentDoc =
          await _firestore.collection('users').doc(senderId).get();
      if (studentDoc.exists) {
        final Map<String, dynamic>? studentData = studentDoc.data();
        studentName = studentData?['name'] as String? ??
            studentData?['fullName'] as String? ??
            studentData?['studentName'] as String? ??
            'Student';
      }
    } catch (e) {
      _logger.error('Error fetching student name: $e');
    }

    final String preview = _formatMessagePreview(data, studentName, false);
    final Timestamp timestamp = data['timestamp'] as Timestamp;

    if (!conversationData.containsKey(senderId) ||
        timestamp.compareTo(
              conversationData[senderId]!['timestamp'] as Timestamp,
            ) >
            0) {
      conversationData[senderId] = {
        'lastMessage': preview,
        'timestamp': timestamp,
        'isRead': data['isRead'] ?? false,
        'hasMessages': true,
        'senderType': 'student',
        'senderName': studentName,
      };
    }
  }

  // ── Formatting Helpers ────────────────────────────────────────────

  static String _getFirstName(String fullName) {
    if (fullName.isEmpty) return 'Student';
    return fullName.trim().split(' ').first;
  }

  static String _formatMessagePreview(
    Map<String, dynamic> messageData,
    String senderName,
    bool isFromInstructor,
  ) {
    final String messageType =
        messageData['messageType'] as String? ?? 'text';
    final String content =
        messageData['content']?.toString() ?? '';
    final bool isUnsent = messageData['isUnsent'] == true;

    if (isUnsent) {
      if (isFromInstructor) return 'You unsent a message';
      return '${_getFirstName(senderName)} unsent a message';
    }

    if (messageType == 'file' && messageData['fileAttachment'] != null) {
      final Map<String, dynamic> fileAttachment =
          messageData['fileAttachment'] as Map<String, dynamic>;
      final String fileType =
          (fileAttachment['fileType'] ?? '').toString().toLowerCase();

      if (FileTypeUtils.isImageFile(fileType)) {
        return isFromInstructor
            ? 'You sent a photo'
            : '${_getFirstName(senderName)} sent a photo';
      }
      return isFromInstructor
          ? 'You sent a file'
          : '${_getFirstName(senderName)} sent a file';
    }

    if (content.isEmpty) return '';

    return isFromInstructor ? 'You: $content' : content;
  }
}
