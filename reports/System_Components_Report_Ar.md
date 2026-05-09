# 📝 تقرير تفصيلي لمكونات النظام الأساسية وتأكيد عملها

بناءً على طلبك، هذا التقرير يفصل مكان تواجد الأقسام المحورية (UI, Navigation, Low, Firebase Auth, Realtime Database, Local Database) في هيكل مشروع `BrainLink`، مع إرفاق نماذج الأكواد وشرح لكيفية التأكد من أنها تعمل بكفاءة.

---

## 1. واجهة المستخدم (UI)
**أين تقع؟**
كل ما يخص واجهات المستخدم موجود داخل مجلد `lib/screens/` بجميع تفريعاته (مثل `tabs/` و `forms/` و `auth/` و `home_features/`).

**ما هو الكود الخاص بها؟ (عينة من واجهة الرئيسية `home_tab.dart`):**
الواجهات مبنية كـ `StatefulWidget` أو `StatelessWidget` وتستخدم مكونات الـ `Material3`:
```dart
Widget _buildPostCard(BuildContext context, Post post) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.grey.shade100),
      boxShadow: [
        BoxShadow(color: deepPurple.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8)),
      ],
    ),
    // ... تصميم الواجهات الداخلي من نصوص وأزرار
  );
}
```

**كيف تتأكد أنها تعمل؟**
1. **صرياً:** شغل التطبيق على محاكي (Emulator) أو هاتف حقيقي وتأكد من أن الألوان متناسقة ولا يوجد تجاوز للحدود (Overflow) في الشاشات الصغيرة.
2. **برمجياً:** قُم بتمرير داتا ثابتة (Dummy Data) بدلاً من الفايربيس للـ Streams للتأكد من أن الأشكال تترتب افقياً وعمودياً بأسلوب صحيح بدون شاشات بيضاء فارغة.

---

## 2. إدارة التنقلات (Navigation)
**أين تقع؟**
تتركز إدارة المسارات في التطبيق بداخل مجلد `lib/navigation/` (تحديداً في ملفي `AppRoutes.dart` و `router_generator.dart`).

**ما هو الكود الخاص بها؟**
ملف `AppRoutes.dart` يعرف المسارات:
```dart
class AppRoutes {
  static const String login = '/login';
  static const String mainLayout = '/main';
}
```
ملف `router_generator.dart` يوجه التطبيق:
```dart
class RouterGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.mainLayout:
        return MaterialPageRoute(builder: (_) => const MainLayout());
      default:
        return MaterialPageRoute(builder: (_) => Scaffold(body: Center(child: Text('Page not found'))));
    }
  }
}
```

**كيف تتأكد أنها تعمل؟**
1. قم بالضغط على جميع مسارات الإنتقال داخل التطبيق (كالضغط على زر للإنتقال للمكتبة). 
2. إذا ظهرت واجهة تقول `Page not found`، هذا معناه أن المسار غير معرف بشكل صحيح في الـ `switch statement`. يجب أن ينتقل النظام للشاشة بانسيابية في كل مرة يُستدعى فيها الأمر `Navigator.pushNamed`.

---

## 3. طبقة المنطق والأكواد السفلية (Low - Models & Logic)
*ملاحظة: الـ Low-level layers هي الطبقات التي تعالج البنية التحتية من نماذج بيانات ودوال مساعدة لا يراها المستخدم مباشرة.*
**أين تقع؟**
في مجلدي `lib/model/` (للهياكل) و `lib/helpers/` (لبناء المعالجات المنطقية).

**ما هو الكود الخاص بها؟ (عينة من `app_models.dart`)**
تحويل الداتا السحابية العائمة لكائنات حقيقية:
```dart
class User_Model {
  String id;
  String email;
  factory User_Model.fromMap(Map<String, dynamic> data, String docId) {
    return User_Model(
      id: docId,
      email: data['email'] ?? '', // التعامل الآمن مع الأخطاء
    );
  }
}
```

**كيف تتأكد أنها تعمل؟**
ضع نقط إيقاف (Breakpoints) أو تعليمات طباعة `debugPrint` بداخل الأستدعاء. لو حدث خطأ بأسماء المتغيرات (مثلاً كتبت "Email" بدلاً من "email") سيظهر لك `Missing Key`، يجب أن تتحول الداتا لـ objects دون حدوث الـ Null Exception.

---

## 4. مصادقة فايربيس (Firebase Auth)
**أين تقع؟**
مكانها البرمجي موجود في `lib/services/auth_service.dart`.

**ما هو الكود الخاص بها؟**
```dart
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential?> signUp(String email, String password, String name) async {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await userCredential.user!.updateDisplayName(name);
      return userCredential;
  }
}
```

**كيف تتأكد أنها تعمل؟**
1. قم بتشغيل التطبيق وأنشئ حساباً جديداً. 
2. افتح متصفحك وسجل الدخول للوحة تحكم **Firebase Console**.
3. توجه للتبويب **Authentication**، وستتأكد أنها تعمل فوراً بمجرد رؤية إيميل اليوزر الجديد وتاريخ التسجيل ظاهرين في القائمة بشكل سليم.

---

## 5. قواعد البيانات الحية (Firestore / Realtime Database)
**أين تقع؟**
معظم عمليات السحب والدفع والتحديث تجري في `lib/services/firestore_service.dart`. أما بالنسبة لخدمة RTDB (الرابط الذي يبدأ بـ `rtdb://`) فتعالج بملف `lib/helpers/file_handler.dart`.

**ما هو الكود الخاص بها؟ (عينة لجلب البوستات بـ Firestore Stream):**
```dart
Stream<List<Post>> getPosts() {
  return _db.collection('posts')
      .orderBy('timeStamp', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => Post.fromMap(doc.data(), doc.id)).toList());
}
```

**كيف تتأكد أنها تعمل؟**
1. **العمل المستمر (Realtime):** افتح التطبيق على الجوال في شاشة الـ Posts، ثم افتح Firebase Console وأضف بوست يدويًا في Firestore أو امسح بوست موجود. التطبيق يجب أن يزيل البوست فوراً أو يعرضه الجديد بمجرد التغيير بدون إعادة تنشيط الواجهة!.
2. بالنسبة للملفات الـ RTDB، يجب النقر على ملف بالشات، والتأكد أن دالة הـ `base64Decode` نجحت في قراءة وفتح الملف على هاتفك بدون فشل. 

---

## 6. قواعد البيانات المحلية (Local Database & Caching)
**أين تقع؟**
تستخدم للاحتفاظ بالداتا حين لا يوجد نت. تقع أساساً في:
1. `lib/helpers/db_helper.dart` (لقاعدة بيانات الجوال الدائمة SQLite - لحفظ اليوزر والمفضلات).
2. `lib/services/local_storage_service.dart` (للحفظ المؤقت Cache عبر Shared Preferences).

**ما هو الكود الخاص بها؟ (مثال لاسترجاع المفضلة بـ SQLite):**
```dart
Future<List<Post>> getFavorites() async {
  final db = await database;
  final rows = await db.query('favorites');
  return rows.map((row) {
    return Post(
      id: row['id'] as String,
      content: row['content'] as String,
      //...باقي البيانات المرجوعة للتطبيق
    );
  }).toList();
}
```

**كيف تتأكد أنها تعمل؟ (اختبار الفصل)**
1. قم بفتح التطبيق واعمل إعجاب وإضافة لـ "المفضلة" لبعض المنشورات، وحمّل المكتبة.
2. **افصل النت تماماً من هاتفك** واقفل التطبيق (Kill App).
3. افتح التطبيق مجدداً (بدون إنترنت).
4. إذا فتحت التطبيق ورأيت واجهة "المفضلة" ما زالت مليئة بالمنشورات المحفوظة ورسائل الشات القديمة ظاهرة بدلاً من واجهة بيضاء، فهذا يعني أن Local Database والشيرد بريفرنسز يعملان بكفاءة أسطورية ويقومان بإرجاع الذاكرة المخبأة.
