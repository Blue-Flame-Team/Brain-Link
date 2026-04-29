import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'navigation/router_generator.dart';
import 'navigation/AppRoutes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    await initializeDateFormatting('ar', null);
    await initializeDateFormatting('en_US', null);
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BrainLink',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5E35B1)),
        useMaterial3: true,
      ),

      initialRoute: AppRoutes.splash,
      onGenerateRoute: RouterGenerator.generateRoute,
    );
  }
}
