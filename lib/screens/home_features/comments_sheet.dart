import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:brain_link/services/firestore_service.dart';
import 'package:brain_link/model/chat_message.dart';
import 'package:brain_link/model/app_models.dart';
import 'package:intl/intl.dart' as intl;

class CommentsSheet extends StatefulWidget {
  final Post post;
  const CommentsSheet({super.key, required this.post});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _commentController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  void _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'مستخدم';
    final userId = user?.uid ?? 'anonymous_id';

    final comment = ChatMessage(
      id: '',
      senderId: userId,
      senderName: userName,
      text: _commentController.text.trim(),
      time: DateTime.now(),
    );

    _commentController.clear();
    await _firestoreService.addComment(widget.post.id, comment);
  }

  @override
  Widget build(BuildContext context) {
    const deepPurple = Color(0xFF5E35B1);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'التعليقات',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${widget.post.commentsCount} تعليق',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _firestoreService.getComments(widget.post.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text("لا توجد تعليقات بعد، كن أول من يعلق!"),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final comment = snapshot.data![index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            backgroundColor: deepPurple,
                            radius: 18,
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        comment.senderName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        intl.DateFormat(
                                          'hh:mm a',
                                          'ar',
                                        ).format(comment.time),
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    comment.text,
                                    style: const TextStyle(
                                      height: 1.4,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 10,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'اكتب تعليقك هنا...',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: const BoxDecoration(
                    color: deepPurple,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _submitComment,
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
