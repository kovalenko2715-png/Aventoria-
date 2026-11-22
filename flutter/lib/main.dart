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

enum _BootStage { boot, error, app }

class _AventoriaAppState extends State<AventoriaApp> {
  _BootStage _stage = _BootStage.boot;
  String _error = '';
  User? _user;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _bootSteps();
    _poll = Timer.periodic(const Duration(seconds: 1), (_) => _syncUser());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _bootSteps() async {
    try {
      await Firebase.initializeApp().timeout(const Duration(seconds: 20));
    } catch (e) {
      if (mounted) {
        setState(() {
          _stage = _BootStage.error;
          _error = 'Firebase: $e';
        });
      }
      return;
    }
    AudioManager.instance.startLoginMusic();
    _syncUser();
  }

  void _syncUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (!mounted) return;
    if (user != _user || _stage != _BootStage.app) {
      setState(() {
        _user = user;
        _stage = _BootStage.app;
      });
    }
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
      home: switch (_stage) {
        _BootStage.boot => const _BootScreen(),
        _BootStage.error => _BootError(error: _error),
        _BootStage.app => _user != null
            ? const MainScreen()
            : const AuthScreen(),
      },
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Image.asset('assets/logo.png', fit: BoxFit.contain),
            ),
          ),
          const Text('Загрузка...',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const Padding(
            padding: EdgeInsets.only(bottom: 40),
            child: CircularProgressIndicator(),
          ),
        ],
      ),
    );
  }
}

class _BootError extends StatelessWidget {
  const _BootError({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Text('ОШИБКА FIREBASE:\n\n$error',
                style: const TextStyle(
                    color: Colors.redAccent, fontSize: 12)),
          ),
        ),
      ),
    );
  }
}

