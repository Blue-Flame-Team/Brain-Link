# 📄 Doc 02 — Flutter Basics & Widgets

---

## 1. Basic Widgets in Flutter

Flutter يوفر مجموعة من الـ Widgets الأساسية لبناء واجهات مستخدم احترافية.

---

### 1.1 Text Widget

يُستخدم لعرض نص في الشاشة مع التحكم في التنسيق.

```dart
Text(
  'Hello Nour Ahmed! 😍',
  style: TextStyle(
    fontSize: 12,
    color: Colors.blue,
    fontWeight: FontWeight.bold,
  ),
)
```

**الاستخدام في BrainLink:**
- عرض اسم المستخدم في بطاقة البوست: `Text(post.authorName)`
- عرض محتوى المنشور: `Text(post.content)`

---

### 1.2 Row & Column

`Column` → يرتب الـ Widgets رأسياً (من فوق لتحت)  
`Row` → يرتب الـ Widgets أفقياً (من اليمين لليسار)

```dart
Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Icon(Icons.star, color: Colors.green),
    Text('Hello, Nour!'),
    Text('Good morning 🤩'),
    Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.star, color: Colors.green),
        Icon(Icons.favorite, color: Colors.red),
      ],
    ),
  ],
)
```

**الاستخدام في BrainLink:**  
كل بطاقة بوست أو جلسة مبنية من `Column` و `Row` متداخلة.

---

### 1.3 Stack Widget

يتيح وضع الـ Widgets فوق بعضها (Layering).

```dart
Stack(
  children: [
    Container(width: 100, height: 100, color: Colors.blue),
    Positioned(
      top: 20,
      left: 20,
      child: Icon(Icons.star, color: Colors.white, size: 40),
    ),
  ],
)
```

**الاستخدام في BrainLink:**  
في بطاقة الدردشة، صورة المستخدم + نقطة الـ Online Status مبنيتان بـ `Stack` مع `Positioned`.

```dart
Stack(
  children: [
    CircleAvatar(...),
    Positioned(
      bottom: 2, right: 2,
      child: Container(
        width: 14, height: 14,
        decoration: BoxDecoration(
          color: isOnline ? Colors.green : Colors.grey,
          shape: BoxShape.circle,
        ),
      ),
    ),
  ],
)
```

---

### 1.4 Container Widget

صندوق مرن للـ Layout مع دعم الـ Decoration (لون خلفية، حواف، ظل...).

```dart
Container(
  padding: EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.red,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black26)],
  ),
  child: Text('Hello, Nour!', style: TextStyle(color: Colors.white)),
)
```

**الاستخدام في BrainLink:**  
كل بطاقة (بوست، جلسة، دردشة) هي `Container` مع `BoxDecoration` احترافية.

---

## 2. Material Components in Flutter

### 2.1 MaterialApp

نقطة البداية لأي تطبيق Flutter. يوفر:
1. **Navigator** — إدارة التنقل بين الشاشات
2. **Theme** — ألوان وأنماط التطبيق
3. **Directionality** — دعم RTL (عربي)

```dart
void main() {
  runApp(MaterialApp(
    home: MyHomePage(),
  ));
}
```

**في BrainLink:**
```dart
MaterialApp(
  debugShowCheckedModeBanner: false,
  title: 'BrainLink',
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF5E35B1)),
  ),
  initialRoute: AppRoutes.splash,
  onGenerateRoute: RouterGenerator.generateRoute,
)
```

---

### 2.2 Scaffold — الهيكل الأساسي للشاشة

```dart
Scaffold(
  appBar: AppBar(title: Text("Home Page")),
  body: Center(child: Text("Hello, Nour!")),
  floatingActionButton: FloatingActionButton(
    onPressed: () {},
    child: Icon(Icons.add),
  ),
)
```

**المكونات:**
| المكون | الوصف |
|---|---|
| `appBar` | شريط العنوان العلوي |
| `body` | منطقة المحتوى الرئيسي |
| `floatingActionButton` | زر العمل البارز |
| `drawer` | قائمة جانبية |
| `bottomNavigationBar` | شريط التنقل السفلي |

---

### 2.3 AppBar

```dart
AppBar(
  title: Text("My App"),
  leading: Icon(Icons.menu),
  actions: [
    IconButton(icon: Icon(Icons.notifications), onPressed: () {}),
  ],
)
```

---

### 2.4 FloatingActionButton

```dart
FloatingActionButton(
  onPressed: () {
    Navigator.pushNamed(context, '/add-post');
  },
  backgroundColor: Color(0xFF5E35B1),
  child: Icon(Icons.add, color: Colors.white),
)
```

---

### 2.5 Material vs Cupertino

| | Material Design | Cupertino (iOS) |
|---|---|---|
| يُستخدم مع | Android + Cross-platform | iOS فقط |
| AppBar | `AppBar` | `CupertinoNavigationBar` |
| App Root | `MaterialApp` | `CupertinoApp` |

BrainLink يستخدم **Material Design** لأنه Cross-platform.

---

## 3. StatelessWidget vs StatefulWidget

### 3.1 StatelessWidget

Widget **ثابت** لا يغير حالته بعد بنائه. يُعاد بناؤه فقط عند تغيير البيانات الممررة له.

```dart
class WelcomeText extends StatelessWidget {
  final String name;
  const WelcomeText({required this.name});

  @override
  Widget build(BuildContext context) {
    return Text('مرحباً $name!');
  }
}
```

**متى نستخدمه؟**  
للعناصر الثابتة مثل: بطاقات، نصوص، أيقونات.

---

### 3.2 StatefulWidget

Widget **ديناميكي** يحتوي على `State` يمكن تغييره باستخدام `setState()`.

```dart
class CounterWidget extends StatefulWidget {
  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('العدد: $_count'),
        ElevatedButton(
          onPressed: () {
            setState(() {   // ← هنا يتم تحديث الـ UI
              _count++;
            });
          },
          child: Text('زيادة'),
        ),
      ],
    );
  }
}
```

**`setState()`** يخبر Flutter أن البيانات تغيرت وأن يعيد بناء الـ Widget.

**في BrainLink:**
- `ChatTab` هو `StatefulWidget` لأنه يحتوي على `_showGroups` (true/false)
- `SessionsTab` هو `StatefulWidget` لأنه يحتوي على `_remindedSessions` و `_selectedTab`

---

## 4. TextField — حقول الإدخال

### إنشاء وتنسيق

```dart
TextField(
  decoration: InputDecoration(
    border: OutlineInputBorder(),
    hintText: 'أدخل بحثك هنا...',
    prefixIcon: Icon(Icons.search),
  ),
)
```

### استرجاع القيمة باستخدام TextEditingController

```dart
class MyForm extends StatefulWidget { ... }

class _MyFormState extends State<MyForm> {
  // 1. إنشاء الـ Controller
  final myController = TextEditingController();

  // 2. تنظيفه عند الانتهاء (مهم!)
  @override
  void dispose() {
    myController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 3. ربطه بالـ TextField
        TextField(controller: myController),
        
        ElevatedButton(
          onPressed: () {
            // 4. قراءة القيمة
            print(myController.text);
          },
          child: Text('إرسال'),
        ),
      ],
    );
  }
}
```

**في BrainLink:**  
في `AddPostScreen`، نستخدم `_contentController` و `_codeController` لقراءة محتوى البوست والكود عند النشر.

---

## 5. Navigation — التنقل بين الشاشات

### 5.1 ما هو Navigator؟

Navigator يعمل كـ **Stack** (مكدس):
- `push` → يضيف شاشة جديدة في الأعلى
- `pop` → يزيل الشاشة الحالية ويعود للسابقة

```
[HomeScreen]  →push→  [HomeScreen, AddPostScreen]
              ←pop←   [HomeScreen]
```

### 5.2 الانتقال الأساسي

```dart
// الانتقال لشاشة جديدة
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => SecondScreen()),
);

// العودة للشاشة السابقة
Navigator.pop(context);
```

### 5.3 Named Routes (الطريقة الاحترافية)

**الخطوة 1: تعريف الأسماء**
```dart
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String mainLayout = '/main';
  static const String addPost = '/add-post';
  static const String notifications = '/notifications';
}
```

**الخطوة 2: RouterGenerator**
```dart
class RouterGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.mainLayout:
        return MaterialPageRoute(builder: (_) => MainLayout());
      case AppRoutes.addPost:
        return MaterialPageRoute(builder: (_) => AddPostScreen());
      case AppRoutes.notifications:
        return MaterialPageRoute(builder: (_) => NotificationsScreen());
      default:
        return MaterialPageRoute(builder: (_) => Scaffold(
          body: Center(child: Text('Page not found')),
        ));
    }
  }
}
```

**الخطوة 3: ربطه بـ MaterialApp**
```dart
MaterialApp(
  initialRoute: AppRoutes.splash,
  onGenerateRoute: RouterGenerator.generateRoute,
)
```

**الخطوة 4: الاستخدام في أي مكان**
```dart
Navigator.pushNamed(context, AppRoutes.notifications);
Navigator.pushReplacementNamed(context, AppRoutes.mainLayout);
```

### 5.4 إرسال بيانات بين الشاشات

```dart
// إرسال
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PersonScreen(person: myPerson),
  ),
);

// الاستقبال في الشاشة الأخرى
class PersonScreen extends StatelessWidget {
  final Person person;
  const PersonScreen({required this.person});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(person.name)),
      body: Text('${person.name} - ${person.email}'),
    );
  }
}
```

**في BrainLink:**  
عند الضغط على محادثة في `ChatTab` يتم إرسال `ChatItem` إلى `ChatScreen`:
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => ChatScreen(chatInfo: item)),
);
```
