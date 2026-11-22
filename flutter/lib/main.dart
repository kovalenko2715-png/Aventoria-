import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show SystemNavigator;

import 'screens/auth_screen.dart';
import 'screens/main_screen.dart';
import 'services/audio_manager.dart';
import 'services/resource_service.dart';
import 'services/update_service.dart';
import 'widgets/godot_viewport.dart';

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

enum _BootStage { boot, resources, error, app }

class _AventoriaAppState extends State<AventoriaApp> {
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  _BootStage _stage = _BootStage.boot;
  String _error = '';
  String _bootLabel = 'Firebase...';
  int _bootSeconds = 0;
  User? _user;
  Timer? _poll;
  Timer? _bootTimer;

  @override
  void initState() {
    super.initState();
    _bootTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _stage == _BootStage.boot) {
        setState(() => _bootSeconds++);
      }
    });
    _bootSteps();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _bootTimer?.cancel();
    super.dispose();
  }

  Future<void> _bootSteps() async {
    _setLabel('Проверка движка...');
    await Future<void>.delayed(const Duration(seconds: 1));
    try {
      _setLabel('Firebase...');
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
    await Future.delayed(const Duration(milliseconds: 100));
    _setLabel('Ресурсы...');
    final info = await PackageInfo.fromPlatform();
    await ResourceService.instance.loadLocal();
    if (!ResourceService.instance.isVersion(info.version)) {
      if (!mounted) return;
      setState(() => _stage = _BootStage.resources);
      await _handleResources(info);
      return;
    }
    await _enterGame();
  }

  Future<void> _enterGame() async {
    _setLabel('Запуск...');
    AudioManager.instance.startLoginMusic();
    if (mounted) {
      setState(() {
        _stage = _BootStage.app;
      });
    }
    _poll = Timer.periodic(const Duration(seconds: 1), (_) => _syncUser());
    _syncUser();
    _bootTimer?.cancel();
    _checkUpdates();
  }

  Future<void> _handleResources(PackageInfo info) async {
    final ctx = _navKey.currentContext;
    if (ctx == null) {
      await _enterGame();
      return;
    }
    var sizeMb = 0;
    var checked = false;
    while (!checked) {
      try {
        await ResourceService.instance.checkRemote();
        sizeMb = (ResourceService.instance.latestSize / (1024 * 1024)).round();
        checked = true;
      } catch (e) {
        final retry = await showDialog<bool>(
          context: ctx,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF151515),
            title: const Text('Нет связи с сервером',
                style: TextStyle(color: Colors.white, fontSize: 17)),
            content: const Text(
              'Не удалось проверить файлы игры на GitHub.\nПроверь интернет и повтори.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Выход',
                    style: TextStyle(color: Colors.white54)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Повторить',
                    style: TextStyle(
                        color: kGoldColor, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        if (retry != true) {
          await SystemNavigator.pop();
          exit(0);
        }
      }
    }
    final yes = await showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text('Файлы игры не загружены',
            style: TextStyle(color: Colors.white, fontSize: 17)),
        content: Text(
          'Клиент скачает файлы игры с GitHub:\nМузыка и графика — $sizeMb МБ.\n\nСкачать сейчас?',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Нет, выйти',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Скачать',
                style: TextStyle(
                    color: kGoldColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) {
      await SystemNavigator.pop();
      exit(0);
    }
    await _downloadResources(info);
  }

  Future<void> _downloadResources(PackageInfo info) async {
    var received = 0, total = 0, bps = 0;
    StateSetter? dlgSet;
    final ctx = _navKey.currentContext;
    if (ctx == null) return;
    showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx2, setDlg) {
          dlgSet = setDlg;
          return AlertDialog(
            backgroundColor: const Color(0xFF151515),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            title: const Text('Загрузка файлов игры',
                style: TextStyle(color: Colors.white, fontSize: 17)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: total > 0 ? received / total : null,
                  color: kGoldColor,
                  backgroundColor: Colors.white12,
                ),
                const SizedBox(height: 10),
                Text(
                  total > 0
                      ? '${_modSize(received)} / ${_modSize(total)} МБ '
                          '(${(received / (total == 0 ? 1 : total) * 100).toStringAsFixed(0)}%)'
                          '${bps > 0 ? '  ${_modSpeed(bps)}' : ''}'
                      : 'Загрузка...',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          );
        });
      },
    );
    var ok = false;
    while (!ok) {
      try {
        await ResourceService.instance.download(info.version, (r, t, b) {
          received = r;
          total = t;
          bps = b;
          if (dlgSet != null) dlgSet!(() {});
        });
        ok = true;
      } catch (e) {
        final retryCtx = _navKey.currentContext;
        if (retryCtx == null) return;
        final retry = await showDialog<bool>(
          context: retryCtx,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF151515),
            title: const Text('Ошибка загрузки',
                style: TextStyle(color: Colors.redAccent, fontSize: 16)),
            content: Text('$e',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Выход',
                      style: TextStyle(color: Colors.white54))),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Повторить',
                      style: TextStyle(color: kGoldColor))),
            ],
          ),
        );
        if (retry != true) {
          await SystemNavigator.pop();
          exit(0);
        }
      }
    }
    final doneCtx = _navKey.currentContext;
    if (doneCtx != null && Navigator.of(doneCtx, rootNavigator: true).canPop()) {
      Navigator.of(doneCtx, rootNavigator: true).pop();
    }
    await _enterGame();
  }

  String _modSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    return mb.toStringAsFixed(1);
  }

  String _modSpeed(int bps) {
    if (bps <= 0) return '';
    final mbps = bps / (1024 * 1024);
    if (mbps >= 1) return '~${mbps.toStringAsFixed(1)} МБ/с';
    return '~${(bps / 1024).toStringAsFixed(0)} КБ/с';
  }

  Future<void> _checkUpdates() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    try {
      final ctx = _navKey.currentContext;
      if (ctx == null || !mounted) return;
      final info = await PackageInfo.fromPlatform();
      await UpdateService.instance.checkForUpdate(info.version);
      if (!mounted || !UpdateService.instance.hasUpdate) return;
      final tag = UpdateService.instance.latestTag;
      final sizeMb = _modSize(UpdateService.instance.apkSize);
      if (!mounted) return;
      var liveCtx = _navKey.currentContext;
      if (liveCtx == null) return;
      final install = await showDialog<bool>(
        context: liveCtx,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF151515),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          title: Row(
            children: [
              const Icon(Icons.system_update,
                  color: kGoldColor, size: 22),
              const SizedBox(width: 8),
              Text('Обновление $tag',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 17)),
            ],
          ),
          content: Text(
            'Доступна новая версия игры.\nВес: $sizeMb МБ.\n\nДальше скачаем с GitHub и установим поверх — ресурсы сохранятся.',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Позже',
                  style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Обновить',
                  style: TextStyle(
                      color: kGoldColor,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      if (install == true && mounted) _downloadUpdate();
    } catch (_) {}
  }

  Future<void> _downloadUpdate() async {
    var received = 0, total = 0, bps = 0;
    StateSetter? dlgSet;
    final upd = UpdateService.instance;
    var liveCtx = _navKey.currentContext;
    if (liveCtx == null) return;
    showDialog<void>(
      context: liveCtx,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx2, setDlg) {
          dlgSet = setDlg;
          return AlertDialog(
            backgroundColor: const Color(0xFF151515),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            title: Text(upd.latestTag,
                style: const TextStyle(
                    color: Colors.white, fontSize: 17)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: total > 0 ? received / total : null,
                  color: kGoldColor,
                  backgroundColor: Colors.white12,
                ),
                const SizedBox(height: 10),
                Text(
                  total > 0
                      ? '${_modSize(received)} / ${_modSize(total)} МБ '
                          '(${(received / (total == 0 ? 1 : total) * 100).toStringAsFixed(0)}%)'
                          '${bps > 0 ? '  ${_modSpeed(bps)}' : ''}'
                      : 'Загрузка...',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          );
        });
      },
    );
    try {
      final dir = await getTemporaryDirectory();
      final file = await upd.downloadApk((r, t, b) {
        received = r;
        total = t;
        bps = b;
        if (dlgSet != null) dlgSet!(() {});
      }, savePath: '${dir.path}/');
      final doneCtx = _navKey.currentContext;
      if (doneCtx != null) Navigator.of(doneCtx, rootNavigator: true).pop();
      await upd.install(file);
    } catch (e) {
      final errCtx = _navKey.currentContext;
      if (errCtx != null &&
          Navigator.of(errCtx, rootNavigator: true).canPop()) {
        Navigator.of(errCtx, rootNavigator: true).pop();
      }
      final failCtx = _navKey.currentContext;
      if (failCtx != null) {
        showDialog<void>(
          context: failCtx,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF151515),
            title: const Text('Ошибка обновления',
                style: TextStyle(color: Colors.redAccent, fontSize: 16)),
            content: Text('$e',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK',
                      style: TextStyle(color: kGoldColor))),
            ],
          ),
        );
      }
    }
  }

  void _setLabel(String label) {
    if (mounted) setState(() => _bootLabel = label);
  }

  void _syncUser() {
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {
      return;
    }
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
      navigatorKey: _navKey,
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
      builder: (context, child) => GodotViewport(child: child!),
      home: switch (_stage) {
        _BootStage.boot =>
            _BootScreen(label: _bootLabel, seconds: _bootSeconds),
        _BootStage.resources => const _ResourceGate(),
        _BootStage.error => _BootError(error: _error),
        _BootStage.app => _user != null
            ? const MainScreen()
            : const AuthScreen(),
      },
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen({required this.label, required this.seconds});

  final String label;
  final int seconds;

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
          Text('Загрузка: $label ($seconds с)',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const Padding(
            padding: EdgeInsets.only(bottom: 40),
            child: CircularProgressIndicator(),
          ),
        ],
      ),
    );
  }
}

class _ResourceGate extends StatelessWidget {
  const _ResourceGate();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/logo.png', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.45)),
          Center(
            child: Text('Загрузка файлов игры...',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    backgroundColor: Colors.black54)),
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

