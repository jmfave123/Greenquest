import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/file_type_utils.dart';
import 'notify_service.dart';
import '../../core/utils/app_logger.dart';

/// Service responsible for sending push notifications
/// when messages are sent between users.
///
/// Extracted from [MessageService] to satisfy agents.md §2.1 S
/// (Single Responsibility: notification is not CRUD).
class MessageNotificationService {
  static final _logger = AppLogger('MessageNotificationService');
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send a push notification to the receiver when a message is sent.
  ///
  /// This is called by [MessageService] after a message is persisted.
  /// It is intentionally fire-and-forget — a failed notification
  /// should NOT prevent the message from being sent.
  static Future<void> notifyReceiver({
    required String receiverId,
    required String senderId,
    required String content,
    required String messageType,
    required String senderType,
    String? fileType,
  }) async {
    // Only send push notifications from instructor → student
    if (senderType != 'instructor') return;

    try {
      final String? playerId =
          await OneSignalHelper.getPlayerIdForUser(receiverId);
      if (playerId == null || playerId.isEmpty) {
        _logger.debug(
          'No Player ID for user $receiverId — skipping notification',
        );
        return;
      }

      final String instructorName =
          await _resolveInstructorName(senderId);
      final String notificationContent =
          _formatNotificationContent(content, messageType, fileType);

      await NotifServices.sendIndividualNotification(
        playerId: playerId,
        heading: 'New message from $instructorName',
        content: notificationContent,
      );

      _logger.info('Push notification sent to $receiverId');
    } catch (e, stackTrace) {
      // Intentionally non-throwing — the message was already sent.
      _logger.error(
        'Failed to send push notification',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ── Private Helpers ───────────────────────────────────────────────

  /// Resolve the instructor's display name from Firestore.
  static Future<String> _resolveInstructorName(String instructorId) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await _firestore
          .collection('instructors')
          .doc(instructorId)
          .get();

      if (doc.exists) {
        final Map<String, dynamic>? data = doc.data();
        return data?['name'] as String? ??
            data?['fullName'] as String? ??
            data?['instructorName'] as String? ??
            'Instructor';
      }
    } catch (e) {
      _logger.warning('Could not resolve instructor name: $e');
    }
    return 'Instructor';
  }

  /// Format the notification body based on message type.
  static String _formatNotificationContent(
    String content,
    String messageType,
    String? fileType,
  ) {
    if (messageType == 'file' && fileType != null) {
      final String lowerFileType = fileType.toLowerCase();
      if (FileTypeUtils.isImageFile(lowerFileType)) return 'Sent a photo';
      if (FileTypeUtils.isVideoFile(lowerFileType)) return 'Sent a video';
      return 'Sent a file';
    }

    if (messageType == 'file') return 'Sent a file';

    // Truncate long text messages
    if (content.length > 100) {
      return '${content.substring(0, 97)}...';
    }
    return content;
  }
}
