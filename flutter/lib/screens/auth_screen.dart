import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../main.dart';
import '../services/audio_manager.dart';

/// Экран входа: новый фон-арт + поля и кнопки из PNG-ассетов (images/ui/).
/// Состояния: gold = обычное, blue = фокус, red = ошибка/нажатие, grey = выключено.
/// Если PNG нет — рисуется похожая рамка кодом (errorBuilder), ничего не падает.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  double _logoOpacity = 0.0;
  String _appVersion = '';

  bool _isLogin = true;
  bool _busy = false;
  bool _showPassword = false;
  bool _emailError = false;
  bool _passwordError = false;
  bool _confirmError = false;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform()
        .then((i) {
          if (mounted) setState(() => _appVersion = i.version);
        })
        .catchError((_) {});
    Future.delayed(Duration.zero, () {
      if (mounted) setState(() => _logoOpacity = 1.0);
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
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

  void _clearFieldErrors() {
    if (_emailError || _passwordError || _confirmError) {
      setState(() {
        _emailError = false;
        _passwordError = false;
        _confirmError = false;
      });
    }
  }

  Future<void> _submitEmail() async {
    final email = _email.text.trim();
    final password = _password.text;
    var bad = false;
    var emailBad = false;
    var passBad = false;
    var confirmBad = false;
    if (email.isEmpty || !email.contains('@')) {
      emailBad = true;
      bad = true;
    }
    if (password.length < 6) {
      passBad = true;
      bad = true;
    }
    if (!_isLogin && password != _confirm.text) {
      confirmBad = true;
      bad = true;
    }
    setState(() {
      _emailError = emailBad;
      _passwordError = passBad;
      _confirmError = confirmBad;
    });
    if (bad) {
      _showError(emailBad
          ? 'Введите корректный email'
          : (password != _confirm.text
              ? 'Пароли не совпадают'
              : 'Пароль минимум 6 символов'));
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

  // ─── UI-ассеты ───

  Widget _uiAsset(String name, Widget fallback, {BoxFit fit = BoxFit.fill}) {
    return Image.asset('assets/images/ui/$name',
        fit: fit, errorBuilder: (_, __, ___) => fallback);
  }

  static const _stateColors = {
    'gold': Color(0xFFC9A227),
    'blue': Color(0xFF3E7BFA),
    'red': Color(0xFFE03A3A),
    'grey': Color(0xFF8A8A8A),
  };

  Widget _frameFallback(String state) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xF20D0D0D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: _stateColors[state] ?? kGoldColor, width: 2),
      ),
    );
  }

  Widget _buttonFallback(String state, String text) {
    final disabled = state == 'grey';
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: state == 'red'
            ? const Color(0xCC7A1414)
            : (disabled ? const Color(0xCC2A2A2A) : const Color(0xCC000000)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: _stateColors[state] ?? kGoldColor, width: 2),
      ),
      child: Text(text,
          style: TextStyle(
              color: disabled ? Colors.white38 : Colors.white,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _linkFallback(String state, String text) {
    final disabled = state == 'grey';
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xCC0D0D0D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: (_stateColors[state] ?? kGoldColor).withOpacity(0.6)),
      ),
      child: Text(text,
          style: TextStyle(
              color: disabled ? Colors.white38 : kGoldColor, fontSize: 12)),
    );
  }

  Widget _frameField({
    required TextEditingController ctl,
    required FocusNode focus,
    required String base,
    required String hint,
    required bool secret,
    required TextInputType type,
    required bool error,
    VoidCallback? onToggleSecret,
  }) {
    return Focus(
      onFocusChange: (_) => setState(() {}),
      child: Builder(builder: (context) {
        final focused = focus.hasFocus;
        final state = error ? 'red' : (focused ? 'blue' : 'gold');
        return SizedBox(
          height: 46,
          child: Stack(
            children: [
              Positioned.fill(
                child: _uiAsset('${base}_$state.png',
                    _frameFallback(error ? 'red' : 'gold')),
              ),
              Positioned(
                left: 44,
                right: secret || error ? 42 : 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: TextField(
                    controller: ctl,
                    focusNode: focus,
                    obscureText: secret && !_showPassword,
                    keyboardType: type,
                    onChanged: (_) => _clearFieldErrors(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                    cursorColor: kGoldColor,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: hint,
                      hintStyle: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          fontWeight: FontWeight.normal),
                    ),
                  ),
                ),
              ),
              if (error)
                const Positioned(
                  right: 10,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Text('❗', style: TextStyle(fontSize: 18)),
                  ),
                ),
              if (secret)
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    onPressed: onToggleSecret,
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.white54,
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _imgButton({
    required String base,
    required String label,
    required VoidCallback? onTap,
    double height = 46,
    Widget? busyChild,
  }) {
    bool pressed = false;
    return StatefulBuilder(builder: (context, setLocal) {
      final state = onTap == null ? 'grey' : (pressed ? 'red' : 'gold');
      return GestureDetector(
        onTapDown: (_) => setLocal(() => pressed = true),
        onTapCancel: () => setLocal(() => pressed = false),
        onTapUp: (_) => setLocal(() => pressed = false),
        onTap: onTap,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: _uiAsset('${base}_$state.png',
                    _buttonFallback(state, label)),
              ),
              if (busyChild != null) busyChild,
            ],
          ),
        ),
      );
    });
  }

  Widget _imgLink(String base, String text, VoidCallback? onTap) {
    bool pressed = false;
    return StatefulBuilder(builder: (context, setLocal) {
      final state = onTap == null ? 'grey' : (pressed ? 'red' : 'gold');
      return GestureDetector(
        onTapDown: (_) => setLocal(() => pressed = true),
        onTapCancel: () => setLocal(() => pressed = false),
        onTapUp: (_) => setLocal(() => pressed = false),
        onTap: onTap,
        child: SizedBox(
          height: 30,
          width: double.infinity,
          child: _uiAsset(
              '${base}_$state.png', _linkFallback(state, text)),
        ),
      );
    });
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
            child: _uiAsset(
              'auth_bg.png',
              Image.asset('assets/logo.png', fit: BoxFit.cover),
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            left: 10,
            bottom: 6,
            child: Text('Aventoria v$_appVersion',
                style: const TextStyle(
                    color: Colors.white38, fontSize: 12)),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 320),
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  decoration: BoxDecoration(
                    color: const Color(0x59000000),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _frameField(
                        ctl: _email,
                        focus: _emailFocus,
                        base: 'email_field',
                        hint: 'Логин (email)',
                        secret: false,
                        type: TextInputType.emailAddress,
                        error: _emailError,
                      ),
                      const SizedBox(height: 8),
                      _frameField(
                        ctl: _password,
                        focus: _passwordFocus,
                        base: 'password_field',
                        hint: 'Пароль',
                        secret: true,
                        type: TextInputType.text,
                        error: _passwordError,
                        onToggleSecret: () => setState(
                            () => _showPassword = !_showPassword),
                      ),
                      if (!_isLogin) ...[
                        const SizedBox(height: 8),
                        _frameField(
                          ctl: _confirm,
                          focus: _confirmFocus,
                          base: 'password_field',
                          hint: 'Повтор пароля',
                          secret: true,
                          type: TextInputType.text,
                          error: _confirmError,
                          onToggleSecret: () => setState(
                              () => _showPassword = !_showPassword),
                        ),
                      ],
                      const SizedBox(height: 10),
                      _imgLink(
                        'register_link',
                        _isLogin
                            ? 'Нет аккаунта? Регистрация'
                            : 'Уже есть аккаунт? Вход',
                        _busy
                            ? null
                            : () {
                                _clearFieldErrors();
                                setState(() => _isLogin = !_isLogin);
                              },
                      ),
                      if (_isLogin) ...[
                        const SizedBox(height: 6),
                        _imgLink('forgot_password', 'Забыли пароль?',
                            _busy ? null : () {}),
                      ],
                      const SizedBox(height: 10),
                      _imgButton(
                        base: 'google_sign_in',
                        label: 'Войти через Google',
                        onTap: _busy ? null : _signInWithGoogle,
                        height: 42,
                      ),
                      const SizedBox(height: 10),
                      _imgButton(
                        base: 'login_button',
                        label: 'Войти',
                        onTap: _busy ? null : _submitEmail,
                        height: 50,
                        busyChild: _busy
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                        Colors.white)))
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
