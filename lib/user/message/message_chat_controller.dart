import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import '../../shared/services/message_repository.dart';
import '../../shared/services/file_upload_service.dart';
import '../../shared/models/message_model.dart';
import '../../shared/utils/presence_utils.dart';
import '../../core/utils/app_logger.dart';

/// Controller for the student message chat screen.
///
/// Handles all business logic for the chat feature:
/// - Loading the current user's profile
/// - Sending text and file messages
/// - File picking and upload orchestration
/// - Instructor presence/online status
///
/// Follows agents.md §2.1 (Single Responsibility),
/// §3.1 (UI never contains business logic),
/// §9 (State management via GetX observables).
class MessageChatController extends GetxController {
  final _logger = AppLogger('MessageChatController');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Injected repository — prefer this over static MessageService calls.
  MessageRepository get _repo => Get.find<MessageRepository>();

  // ── Observable State ──────────────────────────────────────────────
  final Rx<Map<String, dynamic>?> instructor = Rx<Map<String, dynamic>?>(null);
  final Rx<Map<String, dynamic>?> currentUserProfile =
      Rx<Map<String, dynamic>?>(null);
  final Rx<PlatformFile?> previewFile = Rx<PlatformFile?>(null);
  final RxBool isUploading = false.obs;
  final RxBool hasMarkedAsRead = false.obs;

  // ── Text & Scroll Controllers (owned by this controller) ──────────
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode focusNode = FocusNode();

  // ── Computed Getters ──────────────────────────────────────────────
  String? get instructorId =>
      instructor.value != null ? instructor.value!['id'] as String? : null;

  bool get hasInstructor => instructor.value != null && instructorId != null;

  /// Stream of bidirectional messages between current user and instructor.
  Stream<List<MessageModel>> get messagesStream {
    if (!hasInstructor) return Stream.value([]);
    return _repo.getBidirectionalMessages(instructorId!);
  }

  // ── Lifecycle ─────────────────────────────────────────────────────

  /// Initialize with instructor data passed from the list screen.
  void initWithInstructor(Map<String, dynamic>? instructorData) {
    // Force initialization to happen outside the build() cycle if called from a StatelessWidget.
    Future.microtask(() {
      if (instructor.value == null ||
          instructor.value!['id'] != instructorData?['id']) {
        instructor.value = instructorData;
        _loadCurrentUserProfile();
      }
    });
  }

  @override
  void onClose() {
    textController.dispose();
    scrollController.dispose();
    focusNode.dispose();
    super.onClose();
  }

  // ── Public Methods ────────────────────────────────────────────────

  /// Mark messages from instructor as read (called once on first load).
  void markAsReadIfNeeded() {
    if (!hasMarkedAsRead.value && hasInstructor) {
      _repo.markMessagesAsRead(instructorId!);
      hasMarkedAsRead.value = true;
    }
  }

  /// Scroll to the bottom of the message list.
  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Pick a file for preview (does NOT upload yet).
  Future<void> pickFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final PlatformFile file = result.files.first;
      final extension = (file.extension ?? '').toLowerCase();
      if (!FileUploadService.isAllowedExtension(extension)) {
        Get.snackbar(
          'File Not Supported',
          'This file type is not allowed in chat.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      if (file.bytes == null) {
        throw Exception('File bytes are null — file may be too large');
      }

      previewFile.value = file;
    } catch (e, stackTrace) {
      _logger.error('Failed to pick file', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Remove the currently previewed file attachment.
  void clearPreview() {
    previewFile.value = null;
  }

  /// Send a message (text-only, file-only, or text + file).
  ///
  /// Returns `true` on success, `false` on failure.
  /// The UI should show a snackbar based on the result.
  Future<bool> sendMessage(String content) async {
    final bool hasContent = content.trim().isNotEmpty;
    final bool hasAttachment = previewFile.value != null;

    if ((!hasContent && !hasAttachment) || !hasInstructor) return false;
    if (isUploading.value) return false;

    try {
      isUploading.value = true;

      if (hasAttachment && previewFile.value != null) {
        await _sendFileMessage(content.trim(), previewFile.value!);
      } else {
        await _repo.sendMessage(
          receiverId: instructorId!,
          content: content.trim(),
          senderType: 'student',
        );
      }

      // Clear state on success
      previewFile.value = null;
      textController.clear();
      return true;
    } catch (e, stackTrace) {
      _logger.error('Failed to send message', error: e, stackTrace: stackTrace);
      return false;
    } finally {
      isUploading.value = false;
    }
  }

  /// Unsend (soft-delete) a message.
  Future<bool> unsendMessage(String messageId) async {
    try {
      await _repo.unsendMessage(messageId);
      return true;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to unsend message',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  // ── Instructor Presence Helpers ───────────────────────────────────

  /// Determine if instructor is actually online using presence utilities.
  bool isInstructorOnline({
    required bool isOnlineFlag,
    required Object? lastSeen,
  }) {
    return PresenceUtils.isActuallyOnline(
      isOnline: isOnlineFlag,
      lastSeen: lastSeen,
    );
  }

  /// Parse lastSeen from Firestore into a DateTime, safely.
  DateTime? parseLastSeen(Object? lastSeen) {
    if (lastSeen == null) return null;
    try {
      if (lastSeen is Timestamp) return lastSeen.toDate();
      if (lastSeen is DateTime) return lastSeen;
    } catch (e) {
      _logger.warning('Could not parse lastSeen value: $lastSeen');
    }
    return null;
  }

  // ── Display Formatting ────────────────────────────────────────────

  /// Extract first name from a full name string.
  String getFirstName(String fullName) {
    if (fullName.isEmpty) return 'Instructor';
    return fullName.trim().split(' ').first;
  }

  /// Format a DateTime into a human-readable chat timestamp.
  String formatTime(DateTime dateTime) {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      final int hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
      final String period = dateTime.hour >= 12 ? 'PM' : 'AM';
      return '${hour == 0 ? 12 : hour}:${dateTime.minute.toString().padLeft(2, '0')} $period';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      const List<String> days = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      return days[dateTime.weekday - 1];
    } else {
      const List<String> months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[dateTime.month - 1]} ${dateTime.day}';
    }
  }

  /// Format last seen time for display.
  String formatLastSeen(DateTime lastSeenTime) {
    return PresenceUtils.formatLastSeen(lastSeenTime);
  }

  // ── Private Helpers ───────────────────────────────────────────────

  /// Load the current user's profile from Firestore.
  Future<void> _loadCurrentUserProfile() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      final DocumentSnapshot<Map<String, dynamic>> userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final Map<String, dynamic> userData = userDoc.data()!;
        currentUserProfile.value = {
          'id': user.uid,
          'name': userData['fullName'] ?? 'Student',
          'email': userData['email'] ?? user.email ?? '',
          'profileImage': userData['profileImage'],
        };
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to load current user profile',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Upload a file attachment and send as a file message.
  Future<void> _sendFileMessage(String content, PlatformFile file) async {
    if (file.bytes == null) {
      throw Exception('File bytes are null');
    }

    final FileUploadService fileUploadService = FileUploadService();
    fileUploadService.initialize();

    final response = await fileUploadService.uploadFile(
      file: file,
      folder: 'greenquest/messages',
    );

    if (response == null) {
      throw Exception('File upload returned null — upload failed');
    }

    await _repo.sendMessageWithFile(
      receiverId: instructorId!,
      content: content,
      fileName: file.name,
      fileUrl: response.url,
      fileType: file.extension ?? 'unknown',
      fileSize: file.size,
      senderType: 'student',
    );
  }
}
