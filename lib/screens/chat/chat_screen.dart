import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:brain_link/services/firestore_service.dart';
import 'package:brain_link/model/app_models.dart';
import 'package:brain_link/model/chat_message.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart' as intl;
import 'package:brain_link/helpers/file_handler.dart';

class ChatScreen extends StatefulWidget {
  final ChatItem chatInfo;
  const ChatScreen({super.key, required this.chatInfo});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isTyping = false;
  bool _isUploadingFile = false;

  @override
  void initState() {
    super.initState();
    _msgController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _msgController.removeListener(_onTextChanged);
    if (_isTyping) {
      _updateTypingStatus(false);
    }
    _msgController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _msgController.text.trim();
    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      _updateTypingStatus(true);
    } else if (text.isEmpty && _isTyping) {
      _isTyping = false;
      _updateTypingStatus(false);
    }
  }

  void _updateTypingStatus(bool typing) {
    if (widget.chatInfo.id.isEmpty) return;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUserId.isNotEmpty) {
      _firestoreService.updateTypingStatus(
        widget.chatInfo.id,
        currentUserId,
        typing,
      );
    }
  }

  Future<void> _pickAndSendFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.any,
      withData: true, // Supports web
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final fileName = file.name;

    setState(() => _isUploadingFile = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userName = user?.displayName ?? 'مستخدم';
      final userId = user?.uid ?? 'anonymous_uid';

      final ext = file.name.split('.').last;
      final safeFileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
      String dbKey = safeFileName.replaceAll('.', '_');

      // Convert to Base64
      Uint8List bytesToUpload;
      if (kIsWeb || file.path == null) {
        bytesToUpload = file.bytes!;
      } else {
        bytesToUpload = await File(file.path!).readAsBytes();
      }
      String base64String = base64Encode(bytesToUpload);

      final dbRef = FirebaseDatabase.instance
          .ref('chat_attachments')
          .child(dbKey);
      await dbRef.set({'data': base64String, 'name': fileName});

      final fileUrl = 'rtdb://chat_attachments/$dbKey';

      final message = ChatMessage(
        id: '',
        senderId: userId,
        senderName: userName,
        text: '',
        time: DateTime.now(),
        fileUrl: fileUrl,
        fileName: fileName,
      );

      await _firestoreService.addChatMessage(
        widget.chatInfo.id,
        message,
        'مرفق 📎',
        hasAttachment: true,
      );
    } catch (e) {
      debugPrint("File upload error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("حدث خطأ أثناء رفع الملف: $e")));
      }
    } finally {
      if (mounted) setState(() => _isUploadingFile = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_msgController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'مستخدم';
    final userId = user?.uid ?? 'anonymous_uid';

    final text = _msgController.text.trim();
    _msgController
        .clear(); // This will trigger _onTextChanged and set _isTyping to false

    final message = ChatMessage(
      id: '',
      senderId: userId,
      senderName: userName,
      text: text,
      time: DateTime.now(),
    );

    await _firestoreService.addChatMessage(
      widget.chatInfo.id,
      message,
      text,
      hasAttachment: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const deepPurple = Color(0xFF5E35B1);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: deepPurple),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: deepPurple.withValues(alpha: 0.1),
              child: Text(
                widget.chatInfo.participantName.isNotEmpty
                    ? widget.chatInfo.participantName[0].toUpperCase()
                    : '؟',
                style: const TextStyle(
                  color: deepPurple,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chatInfo.participantName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  StreamBuilder<DocumentSnapshot>(
                    stream: _firestoreService.getUserPresence(
                      widget.chatInfo.otherUserId,
                    ),
                    builder: (context, userSnap) {
                      bool isOnline = widget.chatInfo.isOnline;
                      if (userSnap.hasData && userSnap.data!.exists) {
                        final data =
                            userSnap.data!.data() as Map<String, dynamic>?;
                        if (data != null && data.containsKey('isOnline')) {
                          isOnline = data['isOnline'] == true;
                        }
                      }

                      return StreamBuilder<DocumentSnapshot>(
                        stream: _firestoreService.getChatDocument(
                          widget.chatInfo.id,
                        ),
                        builder: (context, chatSnap) {
                          bool isOtherUserTyping = false;
                          if (chatSnap.hasData && chatSnap.data!.exists) {
                            final chatData =
                                chatSnap.data!.data() as Map<String, dynamic>?;
                            List<dynamic> typingUsers = [];
                            if (chatData != null &&
                                chatData.containsKey('typing')) {
                              typingUsers = chatData['typing'] ?? [];
                            }
                            isOtherUserTyping = typingUsers.contains(
                              widget.chatInfo.otherUserId,
                            );
                          }

                          if (isOtherUserTyping && !widget.chatInfo.isGroup) {
                            return const Text(
                              'يكتب الآن...',
                              style: TextStyle(
                                color: deepPurple,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                fontStyle: FontStyle.italic,
                              ),
                            );
                          }

                          return Text(
                            isOnline ? 'نشط الآن' : 'غير متصل',
                            style: TextStyle(
                              color: isOnline ? Colors.green : Colors.grey,
                              fontSize: 12,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _firestoreService.getChatMessages(widget.chatInfo.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'ابدأ المحادثة مع ${widget.chatInfo.participantName}',
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe =
                        msg.senderId ==
                        (FirebaseAuth.instance.currentUser?.uid ??
                            'anonymous_uid');

                    return Align(
                      alignment: isMe
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? deepPurple : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isMe
                                ? Radius.zero
                                : const Radius.circular(16),
                            bottomRight: isMe
                                ? const Radius.circular(16)
                                : Radius.zero,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (!isMe && widget.chatInfo.isGroup)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  msg.senderName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: deepPurple.withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                            if (msg.fileUrl != null && msg.fileUrl!.isNotEmpty)
                              GestureDetector(
                                onTap: () => FileHandler.openFile(
                                  msg.fileUrl!,
                                  defaultFileName: msg.fileName,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  margin: const EdgeInsets.only(bottom: 6),
                                  decoration: BoxDecoration(
                                    color: (isMe ? Colors.white : deepPurple)
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.attachment_rounded,
                                        size: 20,
                                        color: isMe ? Colors.white : deepPurple,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          msg.fileName ?? 'المرفق',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: isMe
                                                ? Colors.white
                                                : deepPurple,
                                            fontWeight: FontWeight.bold,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (msg.text.isNotEmpty)
                              Text(
                                msg.text,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87,
                                  fontSize: 15,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              intl.DateFormat(
                                'hh:mm a',
                                'en_US',
                              ).format(msg.time),
                              style: TextStyle(
                                color: isMe
                                    ? Colors.white70
                                    : Colors.grey.shade500,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: _isUploadingFile
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.attach_file_rounded),
                            color: Colors.grey.shade600,
                            onPressed: _pickAndSendFile,
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالتك...',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: deepPurple,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded),
                      color: Colors.white,
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
