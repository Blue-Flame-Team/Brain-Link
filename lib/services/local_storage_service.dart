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

    // Convert current list to map to remove duplicates by ID easier
    final Map<String, dynamic> postsMap = {};
    for (var str in postsStr) {
      final decoded = jsonDecode(str);
      postsMap[decoded['id']] = decoded;
    }

    final postMap = post.toMap();
    postMap['id'] = post.id;
    // timestamp handling for JSON
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
