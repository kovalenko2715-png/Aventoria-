import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screens/auth_screen.dart';
import 'screens/main_screen.dart';
import 'services/audio_manager.dart';

const kGoldColor = Color(0xFFFFD700);
const kDarkBackground = Color(0xFF151515);
const kPanelColor = Color(0xFF1E1E1E);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  AudioManager.instance.startMenuMusic();
  runApp(const AventoriaApp());
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
