import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/services/message_service.dart';
import '../../../shared/services/instructor_service.dart';
import '../../../shared/models/message_model.dart';

class WebChatController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable variables
  var isLoading = true.obs;
  var selectedInstructor = Rxn<Map<String, dynamic>>();
  var messages = <MessageModel>[].obs;
  var isSending = false.obs;

  StreamSubscription? _messageSubscription;
  StreamSubscription? _instructorSubscription;

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  @override
  void onClose() {
    _messageSubscription?.cancel();
    _instructorSubscription?.cancel();
    super.onClose();
  }

  Future<void> loadInitialData() async {
    try {
      isLoading.value = true;
      final instructor = await InstructorService.getSelectedInstructor();
      if (instructor != null) {
        selectInstructor(instructor);
      }
    } catch (e) {
      print('Error loading initial chat data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void selectInstructor(Map<String, dynamic> instructor) {
    selectedInstructor.value = instructor;
    _subscribeToMessages(instructor['id']);
    _subscribeToInstructorStatus(instructor['id']);
  }

  void _subscribeToMessages(String instructorId) {
    _messageSubscription?.cancel();
    _messageSubscription = MessageService.getBidirectionalMessages(
      instructorId,
    ).listen((newMessages) {
      messages.value = newMessages;
      // Mark messages as read when they arrive and we're looking at them
      MessageService.markMessagesAsRead(instructorId);
    }, onError: (e) => print('Error in message subscription: $e'));
  }

  void _subscribeToInstructorStatus(String instructorId) {
    _instructorSubscription?.cancel();
    _instructorSubscription = FirebaseFirestore.instance
        .collection('instructors')
        .doc(instructorId)
        .snapshots()
        .listen((doc) {
          if (doc.exists && selectedInstructor.value != null) {
            final data = doc.data() as Map<String, dynamic>;
            selectedInstructor.value = {
              ...selectedInstructor.value!,
              'isOnline': data['isOnline'] ?? false,
              'lastSeen': data['lastSeen'],
            };
          }
        });
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || selectedInstructor.value == null) return;

    try {
      isSending.value = true;
      await MessageService.sendMessage(
        receiverId: selectedInstructor.value!['id'],
        content: text.trim(),
        senderType: 'student',
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send message: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSending.value = false;
    }
  }

  Future<void> sendFile(String name, String url, String type, int size) async {
    if (selectedInstructor.value == null) return;

    try {
      await MessageService.sendMessageWithFile(
        receiverId: selectedInstructor.value!['id'],
        content: '',
        fileName: name,
        fileUrl: url,
        fileType: type,
        fileSize: size,
        senderType: 'student',
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send file: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
