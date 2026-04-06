import 'dart:async';
import 'package:get/get.dart';
import '../../shared/services/instructor_service.dart';
import '../../shared/services/message_repository.dart';
import '../../shared/models/message_model.dart';
import '../../core/utils/app_logger.dart';

/// Controller for the student message list screen.
///
/// Handles loading the selected instructor and subscribing
/// to the real-time last-message stream for that conversation.
///
/// Follows agents.md §2.1 (Single Responsibility),
/// §3.1 (UI never contains business logic),
/// §9 (State management via GetX observables).
class MessageListController extends GetxController {
  final _logger = AppLogger('MessageListController');

  /// Injected repository for message queries.
  MessageRepository get _repo => Get.find<MessageRepository>();

  // ── Observable State ──────────────────────────────────────────────
  final Rx<Map<String, dynamic>?> selectedInstructor =
      Rx<Map<String, dynamic>?>(null);
  final Rx<MessageModel?> lastMessage = Rx<MessageModel?>(null);
  final RxBool isLoading = true.obs;

  // ── Stream Management ─────────────────────────────────────────────
  StreamSubscription<List<MessageModel>>? _messageSubscription;

  // ── Lifecycle ─────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    loadSelectedInstructor();
  }

  @override
  void onClose() {
    _messageSubscription?.cancel();
    super.onClose();
  }

  // ── Public Methods ────────────────────────────────────────────────

  /// Load the student's selected instructor and begin listening
  /// for real-time message updates.
  Future<void> loadSelectedInstructor() async {
    try {
      isLoading.value = true;

      final Map<String, dynamic>? instructor =
          await InstructorService.getSelectedInstructor();

      selectedInstructor.value = instructor;

      if (instructor != null && instructor['id'] != null) {
        _subscribeToLastMessage(instructor['id'] as String);
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to load selected instructor',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Extract first name from a full name for display.
  String getFirstName(String fullName) {
    if (fullName.isEmpty) return 'Instructor';
    return fullName.trim().split(' ').first;
  }

  /// Format the last message into a preview string for the list tile.
  String formatMessagePreview(MessageModel message) {
    final bool isMe = message.senderType == 'student';

    if (message.fileAttachment != null) {
      final String fileType =
          message.fileAttachment!.fileType.toLowerCase();
      final bool isMedia =
          fileType.contains('image') || fileType.contains('video');
      return isMe
          ? (isMedia ? 'You sent a photo' : 'You sent a file')
          : (isMedia ? 'Sent a photo' : 'Sent a file');
    }

    return isMe ? 'You: ${message.content}' : message.content;
  }

  /// Build the unsent message display text.
  String formatUnsentPreview(MessageModel message) {
    if (message.senderType == 'student') {
      return 'You unsent a message';
    }
    final String instructorName =
        selectedInstructor.value?['name'] as String? ?? 'Instructor';
    return '${getFirstName(instructorName)} unsent a message';
  }

  // ── Private Helpers ───────────────────────────────────────────────

  /// Subscribe to bidirectional messages and track the most recent one.
  void _subscribeToLastMessage(String instructorId) {
    _messageSubscription?.cancel();

    _messageSubscription = _repo.getBidirectionalMessages(
      instructorId,
    ).listen(
      (List<MessageModel> messages) {
        if (messages.isNotEmpty) {
          lastMessage.value = messages.last;
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        _logger.error(
          'Error in message stream',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  }
}
