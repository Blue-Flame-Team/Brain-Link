<div align="center">

<img src="assets/animation/animation.json" alt="BrainLink Logo" width="120" height="120"/>

# 🧠 BrainLink

**منصة تعليمية تفاعلية للمبرمجين وطلاب علوم الحاسب**  
*An interactive educational community platform for developers & CS students*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-FFCA28?style=for-the-badge&logo=firebase)](https://firebase.google.com)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-blueviolet?style=for-the-badge)](https://flutter.dev)

---

</div>

## 🚀 Overview

**BrainLink** is a full-featured Flutter mobile application that brings together a community of developers and computer science students. It combines real-time chat, collaborative study sessions, a shared knowledge library, and community posts — all backed by **Firebase** and built with a clean, modern UI.

> Built as a graduation/course project demonstrating production-level Flutter development with Firebase integration.

---

## ✨ Features

| Feature | Description |
|---|---|
| 🔐 **Authentication** | Email/password sign-up & login with **Firebase Auth**, persistent sessions |
| 👤 **User Profiles** | Real name, role (Teacher/Student), level, rating, profile photo upload |
| 📝 **Community Posts** | Create posts with code snippets, like, comment, delete your own posts |
| 📅 **Study Sessions** | Create and join live/upcoming sessions, set reminders (+1 attendee) |
| 📚 **Knowledge Library** | Upload and download PDFs/files by category via Firebase Storage |
| 💬 **Real-time Chat** | 1-on-1 and group chat with online presence & typing indicators |
| 🔔 **Notifications** | Live notification feed stored in Firestore (session reminders, etc.) |
| 🔍 **Search & Filter** | Filter library by category, filter chats by groups vs. messages |

---

## 🏗️ Architecture

```
brain_link/
├── lib/
│   ├── main.dart                    # App entry point + Firebase init
│   ├── navigation/
│   │   ├── AppRoutes.dart           # Named route constants
│   │   └── router_generator.dart   # Route generation (generateRoute)
│   ├── model/
│   │   └── app_models.dart         # Data models: Post, Session, LibraryItem, ChatItem
│   ├── services/
│   │   └── firestore_service.dart  # All Firestore CRUD + Streams
│   └── screens/
│       ├── auth/                   # Login, Signup, Role selection
│       ├── core/                   # SplashScreen, MainLayout (BottomNav)
│       ├── tabs/                   # HomeTab, SessionsTab, LibraryTab, ChatTab, ProfileTab
│       ├── chat/                   # ChatScreen, UsersListScreen, CreateGroupScreen
│       ├── forms/                  # AddPostScreen, AddSessionScreen, AddLibraryScreen
│       ├── home_features/          # CommentsSheet, NotificationsScreen
│       └── library_features/      # LibraryCategoryScreen
```

---

## 📱 Screens

| Home | Sessions | Library |
|---|---|---|
| Community posts with code blocks | Live & upcoming study sessions | Categorized file browser |

| Chat | Profile | Notifications |
|---|---|---|
| 1-on-1 & group chats with presence | User profile with photo upload | Real-time notification feed |

---

## 🔥 Firebase Services Used

| Service | Usage |
|---|---|
| **Firebase Auth** | User registration, login, password reset |
| **Cloud Firestore** | Posts, Sessions, Chats, Messages, Notifications, Users |
| **Firebase Storage** | Profile photos, Library file uploads |

### Firestore Collections

```
📦 Firestore
├── users/          {name, role, level, rating, photoUrl, isOnline}
├── posts/          {authorId, authorName, content, snippetCode, likesCount, likedBy}
├── sessions/       {title, hostName, startTime, isLive, tags, participantsCount}
├── chats/          {participants, participantNames, lastMessage, isGroup}
│   └── messages/   {text, senderId, time}
├── library/        {title, type, size, fileUrl, category}
└── notifications/  {userId, title, body, type, createdAt, isRead}
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **UI Framework** | Flutter 3.x (Material Design) |
| **Language** | Dart 3.x |
| **Backend / BaaS** | Firebase (Auth + Firestore + Storage) |
| **State Management** | `StreamBuilder` (reactive UI) |
| **Local Storage** | `shared_preferences`, `sqflite` |
| **Navigation** | Named Routes (`AppRoutes` + `RouterGenerator`) |
| **Media** | `image_picker`, `file_picker` |
| **File Launch** | `url_launcher` |
| **Sharing** | `share_plus` |

---

## ⚙️ Getting Started

### Prerequisites
- Flutter SDK ≥ 3.0
- A Firebase project with Android app registered
- `google-services.json` placed in `android/app/`

### Setup

```bash
# 1. Clone the repo
git clone https://github.com/yourusername/brain_link.git
cd brain_link

# 2. Install dependencies
flutter pub get

# 3. Run the app
flutter run
```

### Firebase Rules (Firestore)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    match /posts/{postId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow delete: if request.auth.uid == resource.data.authorId;
    }
    match /notifications/{notifId} {
      allow read, write: if request.auth != null;
    }
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## 📐 Key Design Patterns

### 1. Reactive UI with StreamBuilder
All data is fetched as **real-time streams** from Firestore. The UI automatically rebuilds when data changes — no manual refresh needed.

```dart
StreamBuilder<List<Post>>(
  stream: FirestoreService().getPosts(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    return ListView(children: snapshot.data!.map(_buildPostCard).toList());
  },
)
```

### 2. Named Routing Pattern
All routes are defined in `AppRoutes` and resolved in `RouterGenerator`, keeping navigation logic centralized.

```dart
// Navigate anywhere with one line:
Navigator.pushNamed(context, AppRoutes.notifications);
```

### 3. Service Layer
All Firestore interactions go through `FirestoreService`, keeping screens clean and testable.

---

## 👥 Team / Developer

| Name | Role |
|---|---|
| **[Your Name]** | Flutter Developer |

---

## 📄 License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.
