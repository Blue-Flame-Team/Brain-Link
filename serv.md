# أكواد قواعد البيانات وخدمات التخزين المرتبطة بالتطبيق

بناءً على طلبك، قمت بتلخيص وجمع الأكواد المسؤولة عن التخزين المحلي، وقواعد بيانات [Firestore](file:///e:/mobile/brain_link/lib/services/firestore_service.dart#8-342)، وقواعد بيانات `Realtime Database`. تم تقسيمها ليسهل عليك مراجعتها.

<br>

<details>
<summary><b>1. التخزين المحلي وقاعدة بيانات SQLite ([db_helper.dart](file:///e:/mobile/brain_link/lib/helpers/db_helper.dart))</b></summary>

هذا الملف يستخدم `sqflite` لإنشاء قاعدة بيانات محلية، وحفظ بيانات المستخدم الأساسية وقائمة المفضلات لكي تعمل بكفاءة أثناء غياب الاتصال بالإنترنت (Offline Mode).

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:brain_link/model/user_model.dart';
import 'package:brain_link/model/app_models.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._internal();
  static Database? _db;

  DbHelper._internal();

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'brainlink.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute(
          "CREATE TABLE users(id TEXT, fullName TEXT, email TEXT)",
        );
        await db.execute('''
          CREATE TABLE favorites (
            id TEXT PRIMARY KEY,
            authorId TEXT,
            authorName TEXT,
            authorRole TEXT,
            timeStamp INTEGER,
            content TEXT,
            hasCodeSnippet INTEGER,
            snippetCode TEXT,
            likesCount INTEGER,
            commentsCount INTEGER,
            likedBy TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS favorites (
              id TEXT PRIMARY KEY,
              authorId TEXT,
              authorName TEXT,
              authorRole TEXT,
              timeStamp INTEGER,
              content TEXT,
              hasCodeSnippet INTEGER,
              snippetCode TEXT,
              likesCount INTEGER,
              commentsCount INTEGER,
              likedBy TEXT
            )
          ''');
        }
      },
    );
  }

  static Future<void> saveUser(UserModel user) async {
    final db = await database;
    await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertFavorite(Post post) async {
    final db = await database;
    await db.insert(
      'favorites',
      {
        'id': post.id,
        'authorId': post.authorId,
        'authorName': post.authorName,
        'authorRole': post.authorRole,
        'timeStamp': post.timeStamp.millisecondsSinceEpoch,
        'content': post.content,
        'hasCodeSnippet': post.hasCodeSnippet ? 1 : 0,
        'snippetCode': post.snippetCode,
        'likesCount': post.likesCount,
        'commentsCount': post.commentsCount,
        'likedBy': post.likedBy.join(','),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteFavorite(String postId) async {
    final db = await database;
    await db.delete('favorites', where: 'id = ?', whereArgs: [postId]);
  }

  Future<bool> isFavorite(String postId) async {
    final db = await database;
    final result = await db.query(
      'favorites',
      where: 'id = ?',
      whereArgs: [postId],
    );
    return result.isNotEmpty;
  }

  Future<List<Post>> getFavorites() async {
    final db = await database;
    final rows = await db.query('favorites');
    return rows.map((row) {
      final likedByRaw = row['likedBy'] as String;
      return Post(
        id: row['id'] as String,
        authorId: row['authorId'] as String,
        authorName: row['authorName'] as String,
        authorRole: row['authorRole'] as String,
        timeStamp: DateTime.fromMillisecondsSinceEpoch(
          row['timeStamp'] as int,
        ),
        content: row['content'] as String,
        hasCodeSnippet: (row['hasCodeSnippet'] as int) == 1,
        snippetCode: row['snippetCode'] as String,
        likesCount: row['likesCount'] as int,
        commentsCount: row['commentsCount'] as int,
        likedBy: likedByRaw.isEmpty ? [] : likedByRaw.split(','),
      );
    }).toList();
  }
}
```
</details>

<br>

<details>
<summary><b>2. التخزين المحلي للملفات عبر SharedPreferences ([local_storage_service.dart](file:///e:/mobile/brain_link/lib/services/local_storage_service.dart))</b></summary>

يُستخدم هذا الملف لتخزين وعمل 'Cache' لتفاصيل المنشورات، الجلسات، ورسائل الدردشة داخل الذاكرة المحلية للجهاز `SharedPreferences` للتسريع وتقليل التنزيلات.

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brain_link/model/app_models.dart';
import 'package:brain_link/model/chat_message.dart';

class LocalStorageService {
  static const String _postsKey = 'saved_posts';
  static const String _sessionsKey = 'saved_sessions';
  static const String _libraryKey = 'saved_library';
  static const String _chatsPrefix = 'chat_messages_';

  // Posts
  static Future<void> savePost(Post post) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> postsStr = prefs.getStringList(_postsKey) ?? [];

    final Map<String, dynamic> postsMap = {};
    for (var str in postsStr) {
      final decoded = jsonDecode(str);
      postsMap[decoded['id']] = decoded;
    }

    final postMap = post.toMap();
    postMap['id'] = post.id;
    postMap['timeStamp'] = post.timeStamp.toIso8601String();

    postsMap[post.id] = postMap;

    final List<String> updatedList = postsMap.values
        .map((v) => jsonEncode(v))
        .toList();
    await prefs.setStringList(_postsKey, updatedList);
  }

  // Sessions
  static Future<void> saveSession(Session session) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> sessionsStr = prefs.getStringList(_sessionsKey) ?? [];

    final Map<String, dynamic> sessionsMap = {};
    for (var str in sessionsStr) {
      final decoded = jsonDecode(str);
      sessionsMap[decoded['id']] = decoded;
    }

    final sessionMap = session.toMap();
    sessionMap['id'] = session.id;
    sessionMap['startTime'] = session.startTime.toIso8601String();

    sessionsMap[session.id] = sessionMap;

    final List<String> updatedList = sessionsMap.values
        .map((v) => jsonEncode(v))
        .toList();
    await prefs.setStringList(_sessionsKey, updatedList);
  }

  // Library Items
  static Future<void> saveLibraryItem(LibraryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> libraryStr = prefs.getStringList(_libraryKey) ?? [];

    final Map<String, dynamic> libraryMap = {};
    for (var str in libraryStr) {
      final decoded = jsonDecode(str);
      libraryMap[decoded['id']] = decoded;
    }

    final itemMap = item.toMap();
    itemMap['id'] = item.id;

    libraryMap[item.id] = itemMap;

    final List<String> updatedList = libraryMap.values
        .map((v) => jsonEncode(v))
        .toList();
    await prefs.setStringList(_libraryKey, updatedList);
  }

  // Chat Messages
  static Future<void> saveChatMessage(
    String chatId,
    ChatMessage message,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_chatsPrefix$chatId';
    final List<String> messagesStr = prefs.getStringList(key) ?? [];

    final Map<String, dynamic> messagesMap = {};
    for (var str in messagesStr) {
      final decoded = jsonDecode(str);
      messagesMap[decoded['id']] = decoded;
    }

    final messageMap = message.toMap();
    messageMap['id'] = message.id;
    messageMap['time'] = message.time.toIso8601String();

    messagesMap[message.id] = messageMap;

    final List<String> updatedList = messagesMap.values
        .map((v) => jsonEncode(v))
        .toList();
    await prefs.setStringList(key, updatedList);
  }
}
```
</details>

<br>

<details>
<summary><b>3. التخزين السحابي وقواعد البيانات (Firestore Service)</b></summary>

ملف [firestore_service.dart](file:///e:/mobile/brain_link/lib/services/firestore_service.dart) هو الوسيط الرئيسي للتطبيق الخاص بسحب الجلسات، المنشورات، الإشعارات وعمليات الإعجاب المباشرة من خوادم `Firebase Firestore`. 

```dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:brain_link/model/app_models.dart';
import 'package:brain_link/model/chat_message.dart';
import 'package:brain_link/services/local_storage_service.dart';

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
    await LocalStorageService.savePost(post);
  }

  Future<void> addSession(Session session) async {
    await _db.collection('sessions').add(session.toMap());
    await LocalStorageService.saveSession(session);
  }

  Future<void> addLibraryItem(LibraryItem item) async {
    await _db.collection('library').add(item.toMap());
    await LocalStorageService.saveLibraryItem(item);
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

  Future<void> addFavoriteNotification({
    required String authorId,
    required String postId,
    required String favoritedByUserName,
  }) async {
    if (authorId.isEmpty) return;
    try {
      await _db.collection('notifications').add({
        'userId': authorId,
        'title': '⭐ مفضلة جديدة',
        'body': '$favoritedByUserName أضاف بوستك إلى المفضلات',
        'type': 'favorite',
        'postId': postId,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      debugPrint("Error adding favorite notification: $e");
    }
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
    String text, {
    bool hasAttachment = false,
  }) async {
    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toMap());

    await LocalStorageService.saveChatMessage(chatId, message);

    await _db.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'hasAttachment': hasAttachment,
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
```
</details>

<br>

<details>
<summary><b>4. قاعدة البيانات الحية للملفات (Realtime Database Service)</b></summary>

ملف [file_handler.dart](file:///e:/mobile/brain_link/lib/helpers/file_handler.dart) يستخدم لقراءة البيانات المحفوظة كنصوص طويلة (Base64) بداخل `Firebase Realtime Database` وتحويلها لملفات حقيقية (PDF مثلاً) قابلة للفتح، وذلك تفادياً لاستخدام الحجم الكبير لـ `Firebase Storage`.

```dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';

class FileHandler {
  static Future<void> openFile(
    String fileUrl, {
    String? defaultFileName,
  }) async {
    // التقاط مسار Realtime Database
    if (fileUrl.startsWith('rtdb://')) {
      try {
        final path = fileUrl.replaceAll('rtdb://', '');
        // قراءة الملف من قاعدة البيانات اللحظية
        final snapshot = await FirebaseDatabase.instance.ref(path).get();
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          final base64Str = data['data'] as String;
          final fileName = data['name'] as String? ?? defaultFileName ?? 'file';

          // تحويل سلسلة Base64 إلى بيانات (Bytes)
          final bytes = base64Decode(base64Str);

          // حفظ الملف مؤقتاً في الجهاز وتشغيله أو عرضه
          if (kIsWeb) {
            final uri = Uri.dataFromBytes(bytes).toString();
            await launchUrl(Uri.parse(uri));
          } else {
            final tempDir = await getTemporaryDirectory();
            final file = await File(
              '${tempDir.path}/$fileName',
            ).writeAsBytes(bytes);
            await OpenFilex.open(file.path);
          }
        }
      } catch (e) {
        debugPrint('Error opening rtdb file: $e');
      }
    } else {
      await launchUrl(Uri.parse(fileUrl));
    }
  }
}
```
</details>
