import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../main.dart';
import '../services/audio_manager.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  double _logoOpacity = 0.0;

  bool _isLogin = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      if (mounted) setState(() => _logoOpacity = 1.0);
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Ошибка входа',
                style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(message,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK', style: TextStyle(color: kGoldColor))),
        ],
      ),
    );
  }

  Future<void> _game() async {
    await AudioManager.instance.switchToGameMusic();
  }

  Future<void> _submitEmail() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || !email.contains('@')) {
      _showError('Введите корректный email');
      return;
    }
    if (password.length < 6) {
      _showError('Пароль минимум 6 символов');
      return;
    }
    if (!_isLogin && password != _confirm.text) {
      _showError('Пароли не совпадают');
      return;
    }
    setState(() => _busy = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
      await _game();
    } on FirebaseAuthException catch (e) {
      _showError(_authMessage(e.code));
    } catch (e) {
      _showError('Ошибка соединения: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _busy = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      await _game();
    } on FirebaseAuthException catch (e) {
      _showError(_authMessage(e.code));
    } catch (e) {
      _showError('Вход через Google: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _authMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Некорректный email';
      case 'user-not-found':
        return 'Аккаунт не найден';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Неверный email или пароль';
      case 'email-already-in-use':
        return 'Логин уже занят';
      case 'weak-password':
        return 'Слабый пароль — минимум 6 символов';
      case 'user-disabled':
        return 'Аккаунт заблокирован';
      case 'too-many-requests':
        return 'Слишком много попыток, подождите';
      case 'network-request-failed':
        return 'Нет соединения с интернетом';
      default:
        return 'Ошибка: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedOpacity(
            opacity: _logoOpacity,
            duration: const Duration(seconds: 2),
            curve: Curves.easeIn,
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.cover,
            ),
          ),
          LayoutBuilder(
            builder: (context, c) {
              return Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 380),
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    decoration: BoxDecoration(
                      color: const Color(0xE60C0A08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: kGoldColor.withOpacity(0.5)),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _field(_email, 'Логин (email)',
                        Icons.mail_outline, false,
                        TextInputType.emailAddress),
                    const SizedBox(height: 10),
                    _field(_password,
                        _isLogin ? 'Пароль' : 'Придумайте пароль',
                        Icons.lock_outline, true, TextInputType.text),
                    if (!_isLogin) ...[
                      const SizedBox(height: 10),
                      _field(
                          _confirm,
                          'Повтор пароля',
                          Icons.lock_outline,
                          true,
                          TextInputType.text),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: _busy ? null : _submitEmail,
                        style: OutlinedButton.styleFrom(
                          backgroundColor:
                              const Color(0xCC000000),
                          side: const BorderSide(
                              color: kGoldColor),
                        ),
                        child: _busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2))
                            : Text(
                                _isLogin
                                    ? 'ВОЙТИ'
                                    : 'ЗАРЕГИСТРИРОВАТЬСЯ',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() => _isLogin = !_isLogin),
                      child: Text(
                        _isLogin
                            ? 'Нет аккаунта? Регистрация'
                            : 'Уже есть аккаунт? Вход',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13),
                      ),
                    ),
                    const Divider(
                        color: Colors.white24,
                        height: 16),
                    SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _signInWithGoogle,
                        style: OutlinedButton.styleFrom(
                          backgroundColor:
                              const Color(0xCC000000),
                          side: const BorderSide(
                              color: Colors.white24),
                        ),
                        icon: const Text('G',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        label: const Text('Войти через Google',
                            style: TextStyle(
                                color: Colors.white)),
                      ),
                    ),
                  ],
                    ),
                  ),
                ),
              ),
            );
            },
          ),
        ],
      ),
    );
  }

  Widget _field(
      TextEditingController ctl, String hint, IconData icon,
      bool secret, TextInputType type) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: ctl,
        obscureText: secret,
        keyboardType: type,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: Colors.white54, fontSize: 13),
          filled: true,
          fillColor: const Color(0xB3000000),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 0),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: kGoldColor),
          ),
          prefixIcon: Icon(icon, size: 18, color: Colors.white38),
        ),
      ),
    );
  }
}
