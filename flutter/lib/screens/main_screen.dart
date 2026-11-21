import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../main.dart';
import '../services/player_repository.dart';
import 'monster_select_screen.dart';

const kRuneBlue = Color(0xFF80CCFF);

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  final PlayerRepository _player = PlayerRepository.instance;
  bool _loading = true;
  bool _burgerOpen = false;
  String _lastMessage = 'Система: Добро пожаловать в Aventoria!';
  Timer? _clockTimer;
  String _timeString = '';
  late final AnimationController _runePulse;

  @override
  void initState() {
    super.initState();
    _initPlayer();
    _runePulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(_updateClock);
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _runePulse.dispose();
    super.dispose();
  }

  void _updateClock() {
    final now = DateTime.now();
    _timeString =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  bool get _isDay => DateTime.now().hour >= 6 && DateTime.now().hour < 18;

  Future<void> _initPlayer() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) await _player.loadOrCreate(user);
    if (mounted) setState(() => _loading = false);
  }

  void _openModule(String title, {bool isBattles = false}) {
    if (isBattles) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MonsterSelectScreen()),
      );
      return;
    }
    setState(() {
      _lastMessage = 'Система: $title — модуль переносится на следующем этапе';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _gameLayout(),
    );
  }

  Widget _gameLayout() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          _isDay ? 'assets/images/day1.png' : 'assets/images/day2.png',
          fit: BoxFit.cover,
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            final w = constraints.maxWidth;
            return Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _topBar(),
                ),
                Positioned(
                  left: w * 0.05,
                  right: w * 0.05,
                  top: 76,
                  bottom: 116,
                  child: _contentArea(),
                ),
                Positioned(
                  left: w * 0.10,
                  right: w * 0.10,
                  bottom: 8,
                  child: _bottomNav(),
                ),
                if (_burgerOpen) _burgerPanel(w, h),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _topBar() {
    final gold = _player.gold;
    final rune = _player.rune;
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    final name = _player.isLoaded && _player.name != 'Герой'
        ? _player.name
        : (email.contains('@') ? email.split('@').first : 'Игрок');
    return Container(
      color: const Color(0xB31A1A1A),
      height: 64,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Image.asset('assets/images/ui/gold_icon.png',
                width: 28, height: 28),
            const SizedBox(width: 4),
            const Text('Золото',
                style: TextStyle(
                    color: kGoldColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            Text('$gold',
                style:
                    const TextStyle(color: kGoldColor, fontSize: 16)),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 90),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(name,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 15)),
              ),
            ),
            const Expanded(
              child: Center(
                child: Text('AVENTORIA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: kGoldColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2)),
              ),
            ),
            Text(_timeString,
                style: const TextStyle(color: Colors.white, fontSize: 15)),
            const SizedBox(width: 10),
            Text('$rune',
                style: const TextStyle(color: kRuneBlue, fontSize: 16)),
            const SizedBox(width: 2),
            FadeTransition(
              opacity: curvedPulse,
              child: Image.asset('assets/images/ui/rune_icon.png',
                  width: 26, height: 26),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  late final Animation<double> curvedPulse = CurvedAnimation(
    parent: _runePulse,
    curve: Curves.easeInOut,
  );

  Widget _contentArea() {
    const modules = [
      ('Профиль', Icons.person, Colors.teal, ''),
      ('Таверна', Icons.local_bar, Colors.deepOrange, ''),
      ('Гильдия', Icons.shield, kGoldColor, ''),
      ('Задания', Icons.assignment, Colors.green, ''),
      ('Карта', Icons.map, Colors.blue, ''),
      ('Боссы и монстры', Icons.bolt, Colors.red, 'battles'),
      ('Лавка', Icons.storefront, Colors.purple, ''),
      ('Аукцион', Icons.gavel, Colors.indigo, ''),
      ('Рюкзак', Icons.backpack, Colors.brown, ''),
      ('Почта', Icons.mail, Colors.cyan, ''),
      ('Арена', Icons.sports_mma, Colors.pink, ''),
      ('Кузница', Icons.handyman, Colors.amber, ''),
    ];
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: modules.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final (title, icon, color, id) = modules[i];
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xCC1E1E1E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kGoldColor.withOpacity(0.35)),
          ),
          child: ListTile(
            leading: Icon(icon, color: color, size: 28),
            title: Text(title,
                style: const TextStyle(
                    color: Colors.white, fontSize: 16)),
            trailing: const Icon(Icons.chevron_right,
                color: Colors.white38),
            onTap: () => _openModule(title, isBattles: id == 'battles'),
          ),
        );
      },
    );
  }

  Widget _bottomNav() {
    Widget nb(String label, {VoidCallback? onTap}) {
      return Flexible(
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: const Size(0, 40),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xB31A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kGoldColor.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              nb('≡ Меню', onTap: () => setState(() => _burgerOpen = !_burgerOpen)),
              nb('Гильдия', onTap: () => _openModule('Гильдия')),
              nb('Таверна', onTap: () => _openModule('Таверна')),
              nb('💰Лавка', onTap: () => _openModule('Лавка')),
              nb('Боссы', onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MonsterSelectScreen()),
                  )),
              nb('🗺️ Карта', onTap: () => _openModule('Карта')),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  _lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11),
                ),
              ),
              nb('Чат', onTap: () => _openModule('Чат')),
              const Text('Онлайн 1',
                  style: TextStyle(
                      color: kGoldColor, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _burgerPanel(double w, double h) {
    Future<void> Function() moduleAction(String title) => () async {
          setState(() => _burgerOpen = false);
          _openModule(title);
        };
    final items = <(String, Future<void> Function())>[
      ('Профиль', moduleAction('Профиль')),
      ('Кузница', moduleAction('Кузница')),
      ('Рюкзак', moduleAction('Рюкзак')),
      ('Аукцион', moduleAction('Аукцион')),
      ('Задания', moduleAction('Задания')),
      ('Почта', moduleAction('Почта')),
      ('Настройки', moduleAction('Настройки')),
      ('← Выход', () async {
        PlayerRepository.instance.applyData(null);
        await FirebaseAuth.instance.signOut();
        await GoogleSignIn().signOut();
      }),
    ];
    return GestureDetector(
      onTap: () => setState(() => _burgerOpen = false),
      child: Stack(
        children: [
          Positioned(
            left: w * 0.10,
            top: h * 0.30,
            width: w * 0.30 + 40,
            height: h * 0.25 + 120,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xE61A1A1A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: kGoldColor.withOpacity(0.4)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (label, action) in items)
                      SizedBox(
                        height: 26,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            padding:
                                const EdgeInsets.only(left: 8),
                          ),
                          onPressed: action,
                          child: Text(label,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
