# 📄 Doc 03 — Dart Basics (final, const, Classes, copyWith)

---

## 1. final vs const

### الفرق الجوهري

| | `final` | `const` |
|---|---|---|
| متى يُحدد؟ | وقت التشغيل (Runtime) | وقت الترجمة (Compile-time) |
| يمكن تغيير القيمة؟ | ❌ | ❌ |
| يمكن تغيير المحتوى (list مثلاً)؟ | ✅ إذا لم يكن الـ list const | ❌ |
| Instance variables؟ | ✅ | ❌ |

---

### final

```dart
final name = 'Nour Ahmed';       // بدون type annotation
final String address = 'Alex';  // مع type annotation

// خطأ: لا يمكن تغيير قيمة final
name = 'Ahmed'; // ❌ Error: a final variable can only be set once
```

**final مع List — القائمة نفسها لا تتغير لكن المحتوى يتغير:**
```dart
final baz = [];
baz.add(1);    // ✅ هذا يعمل — تغيير المحتوى مسموح
print(baz);    // Output: [1]
```

---

### const

```dart
const bar = 1000000;
const double atm = 1.01325 * bar; // ✅ تُحسب وقت الترجمة

// const list — لا يمكن تغيير المحتوى
const list = [];
list.add(1); // ❌ Error: Unsupported operation: add

// var تشير لـ const list
var list2 = const [];
list2.add(1); // ❌ Error: Unsupported operation: add

// final تشير لـ const list
final list3 = const [];
list3.add(1); // ❌ Error: Unsupported operation: add
```

---

### const في الـ Classes

إذا أردت `const` على مستوى الـ class، استخدم `static const`:

```dart
// ❌ خطأ
class MyClass {
  const String name;  // Error: instance variables cannot be const
  MyClass(this.name);
}

// ✅ صحيح
class MyClass {
  final String name;  // استخدم final
  MyClass(this.name);
}

// ✅ static const للقيم الثابتة على مستوى الـ class
class AppColors {
  static const Color deepPurple = Color(0xFF5E35B1);
  static const Color green = Color(0xFF00E676);
}
```

**في BrainLink:**
```dart
// في كل شاشة نستخدم const للألوان
const deepPurple = Color(0xFF5E35B1);
const bgColor = Color(0xFFF8F9FD);
```

---

## 2. Classes في Dart

### تعريف Class أساسي

```dart
class CopyWithExample {
  final String name;
  final String email;
  String address;

  // Constructor مع قيم افتراضية
  CopyWithExample({
    this.name = "Nour Ahmed",
    this.email = "Nour_Ahmed@hotmail.com",
    this.address = "Egypt Alex",
  });

  // Method لتحديث القيمة
  void updateAddress() {
    address = "Egypt Cairo";
    print("Name: $name, Email: $email, Address: $address");
  }

  // copyWith Pattern
  CopyWithExample copyWith({
    String? newName,
    String? newEmail,
    String? newAddress,
  }) {
    return CopyWithExample(
      name: newName ?? name,        // إذا كان null احتفظ بالقديم
      email: newEmail ?? email,
      address: newAddress ?? address,
    );
  }

  @override
  String toString() {
    return "CopyWithExample(Name: $name, Email: $email, Address: $address)";
  }
}
```

#### استخدام copyWith

```dart
final original = CopyWithExample();
print(original); // Name: Nour Ahmed, Email: Nour_Ahmed@hotmail.com, Address: Egypt Alex

// نسخة جديدة مع تغيير Address فقط
final updated = original.copyWith(newAddress: "Egypt Cairo");
print(updated); // Name: Nour Ahmed, Email: Nour_Ahmed@hotmail.com, Address: Egypt Cairo
print(original); // لم يتغير! — Immutability
```

---

### Data Models في BrainLink

كل نموذج بيانات في التطبيق يتبع نفس النمط:

```dart
class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final bool hasCodeSnippet;
  final int likesCount;
  final List<String> likedBy;

  Post({
    required this.id,
    this.authorId = '',
    required this.authorName,
    required this.content,
    required this.hasCodeSnippet,
    required this.likesCount,
    this.likedBy = const [],
  });

  // من Firestore Map إلى Object
  factory Post.fromMap(Map<String, dynamic> data, String id) {
    return Post(
      id: id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      content: data['content'] ?? '',
      hasCodeSnippet: data['hasCodeSnippet'] ?? false,
      likesCount: data['likesCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }

  // من Object إلى Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'content': content,
      'hasCodeSnippet': hasCodeSnippet,
      'likesCount': likesCount,
      'likedBy': likedBy,
    };
  }
}
```

**لماذا `fromMap` و `toMap`؟**
- Firestore يخزن البيانات كـ `Map<String, dynamic>`
- `fromMap` → تحويل من الـ Map لـ Object Dart
- `toMap` → تحويل من الـ Object لـ Map للحفظ في Firestore

---

## 3. Null Safety في Dart

```dart
String name = 'Nour';    // لا يقبل null
String? email = null;    // يقبل null (nullable)

// التعامل مع null
String displayName = email ?? 'مجهول';  // إذا null، استخدم 'مجهول'
int length = email?.length ?? 0;        // إذا null، الطول = 0

// التأكد أنه ليس null
if (email != null) {
  print(email.length); // آمن الآن
}
```

---

# 📄 Doc 04 — sqflite Local Database

---

## ما هو SQLite و sqflite؟

- **SQLite**: قاعدة بيانات علائقية (Relational DB) تعمل محلياً على الجهاز
- **sqflite**: حزمة Flutter تتيح استخدام SQLite

**لماذا نستخدمه؟**
- حفظ المفضلة والإعدادات محلياً
- الوصول للبيانات بدون اتصال إنترنت (Offline support)

---

## 1. إضافة الحزمة

```yaml
# pubspec.yaml
dependencies:
  sqflite: ^2.3.0
  path_provider: ^2.1.2
  path: ^1.8.3
```

---

## 2. تعريف النموذج (Model)

```dart
class NewsItem {
  final int? id;
  final String title;
  final String description;

  NewsItem({this.id, required this.title, required this.description});

  // تحويل لـ Map للحفظ في قاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
    };
  }

  // بناء Object من Map
  factory NewsItem.fromMap(Map<String, dynamic> map) {
    return NewsItem(
      id: map['id'],
      title: map['title'],
      description: map['description'],
    );
  }
}
```

---

## 3. إعداد قاعدة البيانات

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  // Singleton — قاعدة بيانات واحدة للتطبيق كله
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // المسار المحلي للجهاز
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'favorites.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // إنشاء الجدول
        await db.execute('''
          CREATE TABLE favorites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT NOT NULL
          )
        ''');
      },
    );
  }
```

---

## 4. عمليات CRUD

### C — Create (الإضافة)

```dart
Future<void> insertNews(NewsItem item) async {
  final db = await database;
  await db.insert(
    'favorites',
    item.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}
```

### R — Read (القراءة)

```dart
Future<List<NewsItem>> getAllFavorites() async {
  final db = await database;
  final maps = await db.query('favorites');
  return maps.map((map) => NewsItem.fromMap(map)).toList();
}
```

### U — Update (التعديل)

```dart
Future<void> updateNews(NewsItem item) async {
  final db = await database;
  await db.update(
    'favorites',
    item.toMap(),
    where: 'id = ?',
    whereArgs: [item.id],
  );
}
```

### D — Delete (الحذف)

```dart
Future<void> deleteNews(int id) async {
  final db = await database;
  await db.delete(
    'favorites',
    where: 'id = ?',
    whereArgs: [id],
  );
}
```

---

## 5. الاستخدام في الواجهة

```dart
class FavoritesScreen extends StatefulWidget { ... }

class _FavoritesScreenState extends State<FavoritesScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<NewsItem> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final items = await _dbHelper.getAllFavorites();
    setState(() => _favorites = items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final item = _favorites[index];
          return ListTile(
            title: Text(item.title),
            subtitle: Text(item.description),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () async {
                await _dbHelper.deleteNews(item.id!);
                _loadFavorites(); // تحديث الواجهة
              },
            ),
          );
        },
      ),
    );
  }
}
```

---

## SQLite vs Firestore — متى نستخدم كل واحد؟

| | sqflite (SQLite) | Firestore |
|---|---|---|
| الموقع | على الجهاز محلياً | على السحابة |
| يحتاج اتصال؟ | ❌ | ✅ |
| يُشارَك بين المستخدمين؟ | ❌ | ✅ |
| مثال الاستخدام | الإعدادات، المفضلة | البوستات، الجلسات، الدردشات |

**في BrainLink:**
- نستخدم `shared_preferences` لحفظ حالة تسجيل الدخول محلياً
- نستخدم Firestore لكل البيانات المشتركة بين المستخدمين
