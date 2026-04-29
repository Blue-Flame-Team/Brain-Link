import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:brain_link/services/firestore_service.dart';
import 'package:brain_link/model/app_models.dart';
import 'package:intl/intl.dart' as intl;
import 'package:brain_link/screens/chat/chat_screen.dart';
import 'package:brain_link/screens/chat/users_list_screen.dart';

class ChatTab extends StatefulWidget {
  final VoidCallback? onProfileTapped;
  const ChatTab({super.key, this.onProfileTapped});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  @override
  Widget build(BuildContext context) {
    const deepPurple = Color(0xFF5E35B1);
    const bgColor = Color(0xFFF8F9FD);
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomHeader(context),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 55,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: deepPurple.withValues(alpha: 0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'البحث في الدردشات...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: deepPurple,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // CHATS STREAM BUILDER
            Expanded(
              child: StreamBuilder<List<ChatItem>>(
                stream: firestoreService.getChats(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("لا توجد رسائل حالياً"));
                  }

                  final filteredChats = snapshot.data!
                      .where((c) => !c.isGroup)
                      .toList();

                  if (filteredChats.isEmpty) {
                    return const Center(child: Text("لا توجد رسائل حالياً"));
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredChats.length,
                    itemBuilder: (context, index) {
                      final isLast = index == filteredChats.length - 1;
                      return Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 80.0 : 0),
                        child: _buildChatItem(context, filteredChats[index]),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'chat_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UsersListScreen()),
          );
        },
        backgroundColor: deepPurple,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 26),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  Widget _buildCustomHeader(BuildContext context) {
    const deepPurple = Color(0xFF5E35B1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: deepPurple.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: deepPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: deepPurple,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "BrainLink",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: deepPurple,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade100,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.black87,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/notifications');
                  },
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onProfileTapped,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: deepPurple.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: const CircleAvatar(
                    backgroundColor: deepPurple,
                    radius: 18,
                    child: Icon(Icons.person, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, ChatItem item) {
    const deepPurple = Color(0xFF5E35B1);
    final hasUnread = item.unreadCount > 0;

    final dateFormat = intl.DateFormat('hh:mm a', 'en_US');
    String timeStr = dateFormat.format(item.time);
    if (DateTime.now().difference(item.time).inDays >= 1) {
      timeStr = intl.DateFormat('E', 'ar').format(item.time);
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen(chatInfo: item)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: deepPurple.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: item.isGroup
                      ? deepPurple.withValues(alpha: 0.15)
                      : deepPurple.withValues(alpha: 0.05),
                  child: Text(
                    item.participantName.isNotEmpty
                        ? item.participantName[0].toUpperCase()
                        : '؟',
                    style: const TextStyle(
                      color: deepPurple,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: item.isGroup || item.otherUserId.isEmpty
                      ? const SizedBox.shrink()
                      : StreamBuilder<DocumentSnapshot>(
                          stream: FirestoreService().getUserPresence(
                            item.otherUserId,
                          ),
                          builder: (context, snapshot) {
                            bool isOnline = item.isOnline;
                            if (snapshot.hasData && snapshot.data!.exists) {
                              final data =
                                  snapshot.data!.data()
                                      as Map<String, dynamic>?;
                              if (data != null &&
                                  data.containsKey('isOnline')) {
                                isOnline = data['isOnline'] == true;
                              }
                            }

                            return Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: isOnline
                                    ? const Color(0xFF00E676)
                                    : Colors.grey.shade400,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2.5,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.participantName,
                        style: TextStyle(
                          fontWeight: hasUnread
                              ? FontWeight.w900
                              : FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: hasUnread ? deepPurple : Colors.grey.shade500,
                          fontSize: 12,
                          fontWeight: hasUnread
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (item.hasAttachment) ...[
                        Icon(
                          Icons.image_rounded,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          item.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: hasUnread
                                ? Colors.black87
                                : Colors.grey.shade600,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: deepPurple,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
