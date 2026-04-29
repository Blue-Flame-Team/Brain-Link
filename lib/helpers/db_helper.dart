import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:brain_link/model/user_model.dart';

class DbHelper {
  static Database? _db;
  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await openDatabase(join(await getDatabasesPath(), 'brainlink.db'),
        onCreate: (db, version) => db.execute("CREATE TABLE users(id TEXT, fullName TEXT, email TEXT)"),
        version: 1);
    return _db!;
  }

  static Future<void> saveUser(UserModel user) async {
    final db = await database;
    await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
}