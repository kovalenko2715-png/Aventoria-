import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screens/auth_screen.dart';
import 'screens/main_screen.dart';
import 'services/audio_manager.dart';

const kGoldColor = Color(0xFFFFD700);
const kRuneBlue = Color(0xFF80CCFF);
const kDarkBackground = Color(0xFF151515);
const kPanelColor = Color(0xFF1E1E1E);

void _errorScreen(Object error, Object? stack) {
  runApp(Directionality(
    textDirection: TextDirection.ltr,
    child: Material(
      color: const Color(0xFF151515),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Text(
              'ОШИБКА ЗАПУСКА:\n\n$error\n\n$stack',
              style: const TextStyle(color: Colors.redAccent, fontSize: 11),
            ),
          ),
        ),
      ),
    ),
  ));
}

Future<void> main() async {
  return runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          color: const Color(0xFF151515),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Text(
                  details.exceptionAsString(),
                  style:
                      const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),
            ),
          ),
        ),
      );
    };
    try {
      await Firebase.initializeApp();
    } catch (e) {
      _errorScreen('Firebase.initializeApp: $e', StackTrace.current);
      return;
    }
    AudioManager.instance.startLoginMusic();
    runApp(const AventoriaApp());
  }, _errorScreen);
}

class AventoriaApp extends StatelessWidget {
  const AventoriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aventoria',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kDarkBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kGoldColor,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kPanelColor,
          foregroundColor: Colors.white,
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.hasData ? const MainScreen() : const AuthScreen();
        },
      ),
    );
  }
}
