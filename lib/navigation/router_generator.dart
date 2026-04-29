import 'package:flutter/material.dart';
import 'package:brain_link/screens/core/splash_screen.dart';
import 'package:brain_link/screens/auth/signup_screen.dart';
import 'package:brain_link/screens/auth/login_screen.dart';
import 'package:brain_link/screens/auth/Role_screen.dart';
import 'package:brain_link/screens/core/main_layout.dart';
import 'package:brain_link/screens/forms/add_post_screen.dart';
import 'package:brain_link/screens/forms/add_session_screen.dart';
import 'package:brain_link/screens/forms/add_library_screen.dart';
import 'package:brain_link/screens/home_features/notifications_screen.dart';
import 'AppRoutes.dart';

class RouterGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case AppRoutes.signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());

      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case AppRoutes.roleScreen:
        return MaterialPageRoute(builder: (_) => const RoleScreen());

      case AppRoutes.mainLayout:
        return MaterialPageRoute(builder: (_) => const MainLayout());

      case AppRoutes.addPost:
        return MaterialPageRoute(builder: (_) => const AddPostScreen());

      case AppRoutes.addSession:
        return MaterialPageRoute(builder: (_) => const AddSessionScreen());

      case AppRoutes.addLibrary:
        return MaterialPageRoute(builder: (_) => const AddLibraryScreen());

      case AppRoutes.notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());

      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) {
        return const Scaffold(body: Center(child: Text('Page not found')));
      },
    );
  }
}
