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
    runApp(const AventoriaApp());
  }, _errorScreen);
}

class AventoriaApp extends StatefulWidget {
  const AventoriaApp({super.key});

  @override
  State<AventoriaApp> createState() => _AventoriaAppState();
}

class _AventoriaAppState extends State<AventoriaApp> {
  late final Future<void> _boot;

  @override
  void initState() {
    super.initState();
    _boot = Firebase.initializeApp().timeout(const Duration(seconds: 20));
    _boot.then((_) => AudioManager.instance.startLoginMusic());
  }

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
      home: FutureBuilder<void>(
        future: _boot,
        builder: (context, bootSnap) {
          if (bootSnap.connectionState != ConnectionState.done) {
            return Scaffold(
              body: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: Image.asset('assets/logo.png',
                          fit: BoxFit.contain),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: CircularProgressIndicator(),
                  ),
                ],
              ),
            );
          }
          if (bootSnap.hasError) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Text(
                      'ОШИБКА FIREBASE:\n\n${bootSnap.error}',
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
                ),
              ),
            );
          }
          return StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return snapshot.hasData
                  ? const MainScreen()
                  : const AuthScreen();
            },
          );
        },
      ),
    );
  }
}

