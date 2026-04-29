import 'package:cloud_firestore/cloud_firestore.dart';

class Session {
  final String id;
  final String title;
  final String hostName;
  final DateTime startTime;
  final bool isLive;
  final List<String> tags;
  final int participantsCount;
  final String meetingUrl;

  Session({
    required this.id,
    required this.title,
    required this.hostName,
    required this.startTime,
    required this.isLive,
    required this.tags,
    required this.participantsCount,
    this.meetingUrl = 'https://meet.google.com/xyz',
  });

  factory Session.fromMap(Map<String, dynamic> data, String id) {
    return Session(
      id: id,
      title: data['title'] ?? '',
      hostName: data['hostName'] ?? '',
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isLive: data['isLive'] ?? false,
      tags: List<String>.from(data['tags'] ?? []),
      participantsCount: data['participantsCount'] ?? 0,
      meetingUrl: data['meetingUrl'] ?? 'https://meet.google.com/xyz',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'hostName': hostName,
      'startTime': startTime,
      'isLive': isLive,
      'tags': tags,
      'participantsCount': participantsCount,
      'meetingUrl': meetingUrl,
    };
  }
}

class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String authorRole;
  final DateTime timeStamp;
  final String content;
  final bool hasCodeSnippet;
  final String snippetCode;
  final int likesCount;
  final int commentsCount;
  final List<String> likedBy;

  Post({
    required this.id,
    this.authorId = '',
    required this.authorName,
    required this.authorRole,
    required this.timeStamp,
    required this.content,
    required this.hasCodeSnippet,
    this.snippetCode = '',
    required this.likesCount,
    required this.commentsCount,
    this.likedBy = const [],
  });

  factory Post.fromMap(Map<String, dynamic> data, String id) {
    return Post(
      id: id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorRole: data['authorRole'] ?? '',
      timeStamp: (data['timeStamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      content: data['content'] ?? '',
      hasCodeSnippet: data['hasCodeSnippet'] ?? false,
      snippetCode: data['snippetCode'] ?? '',
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole,
      'timeStamp': timeStamp,
      'content': content,
      'hasCodeSnippet': hasCodeSnippet,
      'snippetCode': snippetCode,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'likedBy': likedBy,
    };
  }
}

class LibraryItem {
  final String id;
  final String title;
  final String type;
  final String size;
  final String rating;
  final String views;
  final String fileUrl;
  final String category;

  LibraryItem({
    required this.id,
    required this.title,
    required this.type,
    required this.size,
    required this.rating,
    required this.views,
    this.fileUrl = '',
    this.category = 'عام',
  });

  factory LibraryItem.fromMap(Map<String, dynamic> data, String id) {
    return LibraryItem(
      id: id,
      title: data['title'] ?? '',
      type: data['type'] ?? '',
      size: data['size'] ?? '',
      rating: data['rating'] ?? '',
      views: data['views'] ?? '',
      fileUrl: data['fileUrl'] ?? '',
      category: data['category'] ?? 'عام',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'type': type,
      'size': size,
      'rating': rating,
      'views': views,
      'fileUrl': fileUrl,
      'category': category,
    };
  }
}

class ChatItem {
  final String id;
  final String participantName;
  final String lastMessage;
  final DateTime time;
  final int unreadCount;
  final bool isOnline;
  final bool isGroup;
  final bool hasAttachment;
  final String otherUserId;
  final List<String> typingUsers;

  ChatItem({
    required this.id,
    required this.participantName,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.isOnline,
    required this.isGroup,
    required this.hasAttachment,
    this.otherUserId = '',
    this.typingUsers = const [],
  });

  factory ChatItem.fromMap(
    Map<String, dynamic> data,
    String id, {
    String otherUserId = '',
  }) {
    return ChatItem(
      id: id,
      participantName: data['participantName'] ?? '',
      lastMessage: data['lastMessage'] ?? '',
      time: (data['time'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: data['unreadCount'] ?? 0,
      isOnline: data['isOnline'] ?? false,
      isGroup: data['isGroup'] ?? false,
      hasAttachment: data['hasAttachment'] ?? false,
      otherUserId: otherUserId,
      typingUsers: List<String>.from(data['typing'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participantName': participantName,
      'lastMessage': lastMessage,
      'time': time,
      'unreadCount': unreadCount,
      'isOnline': isOnline,
      'isGroup': isGroup,
      'hasAttachment': hasAttachment,
      'typing': typingUsers,
    };
  }
}
