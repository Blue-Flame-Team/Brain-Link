import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:brain_link/model/app_models.dart';
import 'package:brain_link/model/chat_message.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Streams
  Stream<List<Session>> getSessions() {
    return _db
        .collection('sessions')
        .orderBy('startTime', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Session.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<Post>> getPosts() {
    return _db
        .collection('posts')
        .orderBy('timeStamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Post.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<LibraryItem>> getLibraryItems() {
    return _db
        .collection('library')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LibraryItem.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<ChatItem>> getChats() {
    final currentUserId =
        FirebaseAuth.instance.currentUser?.uid ?? 'anonymous_id';

    return _db
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs.map((doc) {
            final data = doc.data();

            final pNames = data['participantNames'] as Map<String, dynamic>?;
            String displayName = data['participantName'] ?? 'مستخدم';
            String otherUserId = '';

            if (pNames != null) {
              final otherNames = pNames.keys.where((k) => k != currentUserId);
              if (otherNames.isNotEmpty) {
                otherUserId = otherNames.first;
                displayName = pNames[otherUserId] ?? displayName;
              }
            }

            var item = ChatItem.fromMap(data, doc.id, otherUserId: otherUserId);
            return item;
          }).toList();

          chats.sort((a, b) => b.time.compareTo(a.time));
          return chats;
        });
  }

  // Insert Methods
  Future<void> addPost(Post post) async {
    await _db.collection('posts').add(post.toMap());
  }

  Future<void> addSession(Session session) async {
    await _db.collection('sessions').add(session.toMap());
  }

  Future<void> addLibraryItem(LibraryItem item) async {
    await _db.collection('library').add(item.toMap());
  }

  // Interactions
  Future<void> toggleLikePost(
    String postId,
    List<String> currentLikes,
    String userId,
  ) async {
    if (currentLikes.contains(userId)) {
      await _db.collection('posts').doc(postId).update({
        'likedBy': FieldValue.arrayRemove([userId]),
        'likesCount': FieldValue.increment(-1),
      });
    } else {
      await _db.collection('posts').doc(postId).update({
        'likedBy': FieldValue.arrayUnion([userId]),
        'likesCount': FieldValue.increment(1),
      });
    }
  }

  Future<void> deletePost(String postId) async {
    await _db.collection('posts').doc(postId).delete();
  }

  Future<void> addNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'reminder',
  }) async {
    await _db.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  Stream<List<Map<String, dynamic>>> getNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => {'id': d.id, ...d.data()}).toList();
          list.sort((a, b) {
            final aTime =
                (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            final bTime =
                (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            return bTime.compareTo(aTime);
          });
          return list;
        });
  }

  Future<void> incrementSessionParticipants(String sessionId) async {
    await _db.collection('sessions').doc(sessionId).update({
      'participantsCount': FieldValue.increment(1),
    });
  }

  Stream<List<ChatMessage>> getComments(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('time', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> addComment(String postId, ChatMessage comment) async {
    await _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .add(comment.toMap());
    await _db.collection('posts').doc(postId).update({
      'commentsCount': FieldValue.increment(1),
    });
  }

  // Chats
  Stream<List<ChatMessage>> getChatMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('time', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> addChatMessage(
    String chatId,
    ChatMessage message,
    String text,
  ) async {
    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toMap());

    // Also remove the current user from typing array since they just sent the message
    await _db.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'time': FieldValue.serverTimestamp(),
      'typing': FieldValue.arrayRemove([message.senderId]),
    });
  }

  Future<void> updateTypingStatus(
    String chatId,
    String userId,
    bool isTyping,
  ) async {
    try {
      if (isTyping) {
        await _db.collection('chats').doc(chatId).update({
          'typing': FieldValue.arrayUnion([userId]),
        });
      } else {
        await _db.collection('chats').doc(chatId).update({
          'typing': FieldValue.arrayRemove([userId]),
        });
      }
    } catch (e) {
      // Ignored for instances where the chat doesn't exist yet
    }
  }

  Future<void> updatePresence(bool isOnline) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await _db.collection('users').doc(userId).set({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Ignored
    }
  }

  Stream<DocumentSnapshot> getUserPresence(String userId) {
    if (userId.isEmpty) {
      return const Stream.empty();
    }
    return _db.collection('users').doc(userId).snapshots();
  }

  Stream<DocumentSnapshot> getChatDocument(String chatId) {
    return _db.collection('chats').doc(chatId).snapshots();
  }

  Future<ChatItem> getOrCreateChat(
    String otherUserId,
    String otherUserName,
  ) async {
    final currentUserId =
        FirebaseAuth.instance.currentUser?.uid ?? 'anonymous_id';
    final currentUserName =
        FirebaseAuth.instance.currentUser?.displayName ?? 'المستخدم';

    final participants = [currentUserId, otherUserId]..sort();
    final chatId = participants.join('_');

    final doc = await _db.collection('chats').doc(chatId).get();
    if (!doc.exists) {
      final newChat = ChatItem(
        id: chatId,
        participantName: otherUserName,
        lastMessage: 'بدأت المحادثة',
        time: DateTime.now(),
        unreadCount: 0,
        isOnline: false,
        isGroup: false,
        hasAttachment: false,
        otherUserId: otherUserId,
      );
      final chatData = newChat.toMap();
      chatData['participants'] = participants;
      chatData['participantNames'] = {
        currentUserId: currentUserName,
        otherUserId: otherUserName,
      };

      await _db.collection('chats').doc(chatId).set(chatData);
      return newChat;
    } else {
      final docData = doc.data()!;

      final pNames = docData['participantNames'] as Map<String, dynamic>?;
      String displayName = docData['participantName'] ?? otherUserName;

      if (pNames != null) {
        displayName =
            pNames[otherUserId] ??
            pNames.values.firstWhere(
              (n) => n != currentUserName,
              orElse: () => displayName,
            );
      }

      var chat = ChatItem.fromMap(docData, doc.id, otherUserId: otherUserId);
      return chat;
    }
  }
}
