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
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertFavorite(Post post) async {
    final db = await database;
    await db.insert('favorites', {
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
    }, conflictAlgorithm: ConflictAlgorithm.replace);
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
        timeStamp: DateTime.fromMillisecondsSinceEpoch(row['timeStamp'] as int),
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
