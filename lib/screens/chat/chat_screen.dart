import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:brain_link/services/firestore_service.dart';
import 'package:brain_link/model/app_models.dart';
import 'package:brain_link/model/chat_message.dart';
import 'package:intl/intl.dart' as intl;

class ChatScreen extends StatefulWidget {
  final ChatItem chatInfo;
  const ChatScreen({super.key, required this.chatInfo});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _sendMessage() async {
    if (_msgController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'مستخدم';
    final userId = user?.uid ?? 'anonymous_uid';

    final text = _msgController.text.trim();
    _msgController.clear();

    final message = ChatMessage(
      id: '',
      senderId: userId,
      senderName: userName,
      text: text,
      time: DateTime.now(),
    );

    // Call service to add message to /chats/{id}/messages
    // First, let's make sure this method exists in FirestoreService.
    // Actually, I can write to firestore directly or add a new method to the service.
    // I'll define it here to be safe:
    await _firestoreService.addChatMessage(widget.chatInfo.id, message, text);
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
              child: Icon(
                widget.chatInfo.isGroup ? Icons.group : Icons.person,
                color: deepPurple,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chatInfo.participantName,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.chatInfo.isOnline ? 'نشط الآن' : 'غير متصل',
                  style: TextStyle(
                    color: widget.chatInfo.isOnline
                        ? Colors.green
                        : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
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
                    child: IconButton(
                      icon: const Icon(Icons.attach_file_rounded),
                      color: Colors.grey.shade600,
                      onPressed: () {},
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

