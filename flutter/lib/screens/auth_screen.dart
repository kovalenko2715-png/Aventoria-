import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../main.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _isRegister = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
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
    if (_isRegister && password != _confirm.text) {
      _showError('Пароли не совпадают');
      return;
    }
    setState(() => _busy = true);
    try {
      if (_isRegister) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(_authMessage(e.code));
    } catch (_) {
      _showError('Ошибка соединения. Попробуйте позже');
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
    } on FirebaseAuthException catch (e) {
      _showError(_authMessage(e.code));
    } catch (_) {
      _showError('Вход через Google не удался');
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset('assets/images/day1.png', height: 160),
                const SizedBox(height: 12),
                const Text(
                  'AVENTORIA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: kGoldColor,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Почта',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: _isRegister ? 'Придумайте пароль' : 'Пароль',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ),
                if (_isRegister) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirm,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Повторите пароль',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _submitEmail,
                  child: _busy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isRegister ? 'Зарегистрироваться' : 'Войти'),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _isRegister = !_isRegister),
                  child: Text(_isRegister
                      ? 'Уже есть аккаунт? Войти'
                      : 'Нет аккаунта? Зарегистрироваться'),
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('или'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _signInWithGoogle,
                  icon: const Icon(Icons.login, size: 24),
                  label: const Text('Войти через Google'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
