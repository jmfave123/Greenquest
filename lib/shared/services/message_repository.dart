import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/message_model.dart';
import '../../core/utils/app_logger.dart';

/// Repository for message CRUD operations against Firestore.
///
/// Registered as a [GetxService] so it lives for the app's lifetime
/// and can be injected into controllers via [Get.find].
///
/// Follows agents.md §2.1 D (Dependency Inversion) and
/// §11 (Repository returns domain entities, not raw JSON).
class MessageRepository extends GetxService {
  final _logger = AppLogger('MessageRepository');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Queries ───────────────────────────────────────────────────────

  /// Stream of bidirectional messages between the current user
  /// and [otherUserId], sorted by timestamp ascending.
  ///
  /// Uses full-collection snapshot for backward compatibility with
  /// existing documents that lack the `participants` array.
  /// New messages will include `participants` for future optimization.
  Stream<List<MessageModel>> getBidirectionalMessages(String otherUserId) {
    final User? user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore.collection('messages').snapshots().map((
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) {
      final List<MessageModel> messages = <MessageModel>[];

      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        final Map<String, dynamic> data = doc.data();
        final String senderId = data['senderId'] as String? ?? '';
        final String receiverId = data['receiverId'] as String? ?? '';

        // Only include messages between the current user and otherUserId
        final bool isRelevant =
            (senderId == user.uid && receiverId == otherUserId) ||
            (senderId == otherUserId && receiverId == user.uid);

        if (isRelevant) {
          messages.add(MessageModel.fromMap(doc.id, data));
        }
      }

      messages.sort(
        (MessageModel a, MessageModel b) => a.timestamp.compareTo(b.timestamp),
      );
      return messages;
    });
  }

  /// Stream of unread message count for the current user.
  Stream<int> getUnreadCount() {
    final User? user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('messages')
        .where('receiverId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) =>
              snapshot.docs.length,
        );
  }

  // ── Commands ──────────────────────────────────────────────────────

  /// Send a text-only message.
  Future<void> sendMessage({
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

    final Map<String, dynamic> data = message.toMap();
    // Add participants array for efficient querying
    data['participants'] = [user.uid, receiverId];

    await _firestore.collection('messages').add(data);
    _logger.info('Text message sent to $receiverId');
  }

  /// Send a message with a file attachment.
  Future<void> sendMessageWithFile({
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

    final Map<String, dynamic> data = message.toMap();
    data['participants'] = [user.uid, receiverId];

    await _firestore.collection('messages').add(data);
    _logger.info('File message sent to $receiverId: $fileName');
  }

  /// Mark all unread messages from [senderId] as read.
  Future<void> markMessagesAsRead(String senderId) async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    try {
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
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to mark messages as read',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Soft-delete a message (marks it as "unsent").
  Future<void> unsendMessage(String messageId) async {
    await _firestore.collection('messages').doc(messageId).update({
      'content': 'You unsent a message',
      'isUnsent': true,
      'fileAttachment': null,
    });
    _logger.info('Message unsent: $messageId');
  }

  /// Permanently delete a message document.
  Future<void> deleteMessage(String messageId) async {
    await _firestore.collection('messages').doc(messageId).delete();
    _logger.info('Message deleted: $messageId');
  }
}
