# 📄 Doc 01 — Project Overview & Firebase Architecture

---

## 🧠 ما هو BrainLink؟

**BrainLink** هو تطبيق Flutter للهاتف المحمول مخصص لمجتمع المبرمجين وطلاب علوم الحاسب. يمكّن المستخدمين من:

- 📝 نشر منشورات تقنية تحتوي على أكواد برمجية
- 📅 إنشاء جلسات دراسة جماعية والانضمام إليها
- 📚 مشاركة ملفات PDF والمراجع في مكتبة مشتركة
- 💬 التواصل عبر دردشة فردية ومجموعات
- 🔔 استقبال الإشعارات عند التسجيل لجلسة

---

## 🏗️ هيكل المشروع (Architecture)

```
main.dart                → نقطة البداية (Entry Point)
    ↓
MainLayout               → شريط التنقل السفلي (Bottom Navigation)
    ↓
[HomeTab] [SessionsTab] [LibraryTab] [ChatTab] [ProfileTab]
    ↓
FirestoreService         → طبقة البيانات المركزية (Service Layer)
    ↓
Firebase Firestore / Storage / Auth
```

### سبب هذا الهيكل
| المبدأ | التطبيق |
|---|---|
| **Separation of Concerns** | البيانات في `FirestoreService`، الـ UI في الشاشات |
| **Single Source of Truth** | صفحة واحدة للـ Routes (`AppRoutes.dart`) |
| **Reactive UI** | `StreamBuilder` يتحدث الواجهة تلقائياً عند تغير البيانات |

---

## 🔥 Firebase — الشرح التفصيلي الكامل

### ما هو Firebase؟

Firebase هو **منصة Backend كـ خدمة (BaaS)** من Google. تتيح للمطور بناء تطبيقات كاملة بدون كتابة كود خادم (Server-side code).

في BrainLink استخدمنا 3 خدمات أساسية:

---

### 1️⃣ Firebase Authentication (المصادقة)

#### ما الذي يقوم به؟
يتولى تسجيل الدخول وإنشاء الحسابات وحمايتها.

#### كيف يعمل في التطبيق؟

```dart
// التسجيل
await FirebaseAuth.instance.createUserWithEmailAndPassword(
  email: email,
  password: password,
);

// تسجيل الدخول
await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: email,
  password: password,
);

// معرفة المستخدم الحالي
final user = FirebaseAuth.instance.currentUser;
print(user?.uid);   // المعرف الفريد للمستخدم
print(user?.email); // البريد الإلكتروني
```

#### الاستمرارية (Persistence)
Firebase يحفظ جلسة المستخدم تلقائياً. لذلك نتحقق في `SplashScreen` إذا كان المستخدم مسجلاً دخوله مسبقاً وننقله مباشرة للشاشة الرئيسية.

```dart
final user = FirebaseAuth.instance.currentUser;
if (user != null) {
  Navigator.pushReplacementNamed(context, AppRoutes.mainLayout);
} else {
  Navigator.pushReplacementNamed(context, AppRoutes.login);
}
```

#### إعادة تعيين كلمة المرور
```dart
await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
// Firebase يرسل رابط إعادة التعيين تلقائياً للبريد
```

---

### 2️⃣ Cloud Firestore (قاعدة البيانات)

#### ما هو Firestore؟
قاعدة بيانات **NoSQL** تعمل في الوقت الفعلي (Real-time). البيانات مخزنة كـ **Collections** (مجموعات) تحتوي على **Documents** (مستندات).

#### هيكل قاعدة البيانات في BrainLink

```
📦 Firestore
│
├── 👤 users/
│   └── {userId}/
│       ├── name: "Mohammed Ali"
│       ├── role: "Student"
│       ├── level: "مبتدئ"
│       ├── rating: 4.5
│       ├── photoUrl: "https://storage..."
│       └── isOnline: true
│
├── 📝 posts/
│   └── {postId}/
│       ├── authorId: "uid123"
│       ├── authorName: "Mohammed Ali"
│       ├── content: "شرح الـ StreamBuilder..."
│       ├── hasCodeSnippet: true
│       ├── snippetCode: "StreamBuilder<...>"
│       ├── likesCount: 12
│       └── likedBy: ["uid123", "uid456"]
│
├── 📅 sessions/
│   └── {sessionId}/
│       ├── title: "Flutter State Management"
│       ├── hostName: "Ahmed"
│       ├── startTime: Timestamp
│       ├── isLive: false
│       ├── participantsCount: 3
│       ├── tags: ["Flutter", "Dart"]
│       └── meetingUrl: "https://meet.google.com/..."
│
├── 💬 chats/
│   └── {chatId}/
│       ├── participants: ["uid1", "uid2"]
│       ├── participantNames: {"uid1": "Ali", "uid2": "Sara"}
│       ├── lastMessage: "مرحباً!"
│       ├── isGroup: false
│       └── messages/ (subcollection)
│           └── {msgId}/
│               ├── text: "مرحباً!"
│               ├── senderId: "uid1"
│               └── time: Timestamp
│
├── 📚 library/
│   └── {itemId}/
│       ├── title: "Flutter Cookbook"
│       ├── type: "PDF"
│       ├── size: "2.3 MB"
│       ├── fileUrl: "https://storage..."
│       └── category: "برمجة"
│
└── 🔔 notifications/
    └── {notifId}/
        ├── userId: "uid123"
        ├── title: "تذكير بجلسة قادمة"
        ├── body: "سيتم تذكيرك بـ Flutter Session"
        ├── type: "reminder"
        ├── createdAt: Timestamp
        └── isRead: false
```

#### كيف نقرأ البيانات؟

**Stream (الوقت الفعلي)** — يُستخدم مع `StreamBuilder`:
```dart
// تُرجع Stream تتحدث تلقائياً عند كل تغيير
Stream<List<Post>> getPosts() {
  return _db
      .collection('posts')
      .orderBy('timeStamp', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => Post.fromMap(doc.data(), doc.id)).toList());
}
```

**Future (مرة واحدة)** — يُستخدم مع `await`:
```dart
// نقرأ بيانات المستخدم مرة عند نشر بوست
final doc = await FirebaseFirestore.instance
    .collection('users')
    .doc(user.uid)
    .get();
final name = doc.data()?['name'] ?? 'مستخدم';
```

#### كيف نكتب البيانات؟

```dart
// إضافة مستند جديد (Firestore يولد ID تلقائياً)
await _db.collection('posts').add(post.toMap());

// تعديل حقل معين فقط
await _db.collection('posts').doc(postId).update({
  'likesCount': FieldValue.increment(1),
  'likedBy': FieldValue.arrayUnion([userId]),
});

// حذف مستند
await _db.collection('posts').doc(postId).delete();
```

---

### 3️⃣ Firebase Storage (التخزين السحابي)

#### ما الذي يقوم به؟
رفع وتنزيل الملفات (صور، PDFs، إلخ).

#### في التطبيق — رفع صورة البروفايل

```dart
// 1. اختيار صورة من الجهاز
final picker = ImagePicker();
final picked = await picker.pickImage(source: ImageSource.gallery);

// 2. رفع الصورة على Firebase Storage
final ref = FirebaseStorage.instance
    .ref()
    .child('profile_photos/${user.uid}.jpg');
await ref.putFile(File(picked.path));

// 3. الحصول على رابط الصورة
final url = await ref.getDownloadURL();

// 4. حفظ الرابط في Firestore
await FirebaseFirestore.instance
    .collection('users')
    .doc(user.uid)
    .update({'photoUrl': url});
```

---

### الفرق بين الخدمات الثلاث

| الخاصية | Firebase Auth | Firestore | Storage |
|---|---|---|---|
| يخزن | بيانات الحسابات | بيانات التطبيق | ملفات وصور |
| تحديث لحظي | ❌ | ✅ | ❌ |
| يُستخدم مع | تسجيل الدخول | CRUD عمليات | رفع ملفات |

---

## ⚡ Presence System (نظام الحضور اللحظي)

نعرف إذا كان المستخدم أونلاين أو لا بتحديث Firestore عند فتح/إغلاق التطبيق:

```dart
// في main.dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    FirestoreService().updatePresence(true);   // أونلاين
  } else if (state == AppLifecycleState.paused) {
    FirestoreService().updatePresence(false);  // أوفلاين
  }
}
```

في قائمة الدردشة، يُعرض مؤشر أخضر/رمادي بناءً على حقل `isOnline` في مستند المستخدم.

---

## 🔄 دورة حياة البيانات (Data Flow)

```
المستخدم يضغط "نشر"
    ↓
AddPostScreen._submit()
    ↓
يجلب اسم المستخدم من Firestore (users/{uid})
    ↓
يبني Post object مع authorId
    ↓
FirestoreService.addPost(post)
    ↓
يضيف المستند لـ posts/ collection
    ↓
HomeTab StreamBuilder يلتقط التغيير تلقائياً
    ↓
يعيد بناء الـ UI بالبوست الجديد ✓
```
