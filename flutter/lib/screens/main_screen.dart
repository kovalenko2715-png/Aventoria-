import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../services/chat_service.dart';
import '../services/item_drafts.dart';
import '../services/items_catalog.dart';
import '../services/player_repository.dart';
import '../widgets/game_image.dart';
import '../widgets/nickname_dialog.dart';
import 'admin_screen.dart';
import 'arena_screen.dart';
import 'auction_screen.dart';
import 'bosses_screen.dart';
import 'chat_screen.dart';
import 'guild_screen.dart';
import 'inventory_screen.dart';
import 'looks_screen.dart';
import 'mail_screen.dart';
import 'market_screen.dart';
import 'map_screen.dart';
import 'monster_select_screen.dart';
import 'profile_screen.dart';
import 'quests_screen.dart';
import 'settings_screen.dart';
import 'tavern_screen.dart';


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
  int _adminRank = 0;
  String _lastMessage = 'Система: Добро пожаловать в Aventoria!';
  Timer? _clockTimer;
  String _timeString = '';
  StreamSubscription<int>? _adminSub;
  late final AnimationController _runePulse;

  @override
  void initState() {
    super.initState();
    _initPlayer();
    ChatService.instance.startHeartbeat();
    ItemsCatalog.instance.start();
    ItemDrafts.instance.load();
    _adminSub = ChatService.instance.adminRank().listen((r) {
      if (mounted && r != _adminRank) setState(() => _adminRank = r);
    });
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
    _adminSub?.cancel();
    _runePulse.dispose();
    ChatService.instance.stopHeartbeat();
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
    if (user != null) {
      try {
        await _player
            .loadOrCreate(user)
            .timeout(const Duration(seconds: 15));
      } catch (e) {
        _lastMessage =
            'Система: профиль не загрузился, стадия офлайн-режима'
            ' (${e.toString()})';
      }
    }
    if (_player.isLoaded && _player.nicknameMissing && mounted) {
      await showNicknameDialog(context);
    }
    if (mounted && await ChatService.instance.hasPendingNickRequest()) {
      final reason = await ChatService.instance.adminNickRequestMessage();
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF151515),
            title: const Text('Запрос от администрации',
                style: TextStyle(
                    color: kGoldColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            content: Text(
                'Администрация просит сменить ник персонажа.${(reason == null || reason.isEmpty) ? '' : '\n\n$reason'}',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Понятно',
                    style: TextStyle(color: kGoldColor)),
              ),
            ],
          ),
        );
        await showNicknameDialog(context);
        await ChatService.instance.clearNickRequest();
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  void _openModule(String title) {
    Future<void> push(Widget screen) async {
      setState(() => _burgerOpen = false);
      await Navigator.push(
        context,
        PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.black.withOpacity(0.45),
          barrierDismissible: true,
          transitionDuration: const Duration(milliseconds: 160),
          pageBuilder: (_, __, ___) => Material(
            type: MaterialType.transparency,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 78, 14, 62),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: screen,
                ),
              ),
            ),
          ),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.93, end: 1.0).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          ),
        ),
      );
      if (mounted) setState(() {});
    }

    switch (title) {
      case 'battles':
      case 'Боссы и монстры':
        push(const MonsterSelectScreen());
        return;
      case 'Боссы':
        push(const BossesScreen());
        return;
      case 'Гильдия':
        push(const GuildScreen());
        return;
      case 'Арена':
        push(const ArenaScreen());
        return;
      case 'Профиль':
        push(const ProfileScreen());
        return;
      case 'Таверна':
        push(const TavernScreen());
        return;
      case 'Задания':
        push(const QuestsScreen());
        return;
      case 'Карта':
        push(const MapScreen());
        return;
      case 'Лавка':
        push(const MarketScreen());
        return;
      case 'Аукцион':
        push(const AuctionScreen());
        return;
      case 'Инвентарь':
        push(const InventoryScreen());
        return;
      case 'Почта':
        push(const MailScreen());
        return;
      case 'Чат':
        ChatService.instance.markChatRead();
        push(const ChatScreen());
        ChatService.instance.markChatRead();
        return;
      case 'Настройки':
        push(const SettingsScreen());
        return;
      case 'Облики':
        push(const LooksScreen());
        return;
      case 'Админ панель':
        push(const AdminScreen());
        return;
    }
    setState(() {
      _lastMessage = 'Система: $title — закрыто';
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
        GameImage(
          _isDay ? 'images/day1.png' : 'images/day2.png',
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
                  top: 72,
                  bottom: 56,
                  child: _contentArea(),
                ),
                Positioned(
                  left: w * 0.10,
                  right: w * 0.10,
                  bottom: 10,
                  child: _bottomNav(),
                ),
                Positioned(
                  right: 10,
                  bottom: 62,
                  child: StreamBuilder<int>(
                    stream: ChatService.instance.onlineCount(),
                    builder: (context, snap0) {
                      final online = snap0.data ?? 1;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0x99000000),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: kGoldColor.withOpacity(0.2)),
                        ),
                        child: Text('Онлайн: $online',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11)),
                      );
                    },
                  ),
                ),
                if (_burgerOpen &&
                    FirebaseAuth.instance.currentUser != null)
                  _burgerPanel(w, h),
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
      height: 66,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Text('Золото',
                style: TextStyle(
                    color: kGoldColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            GameImage('images/ui/gold_icon.png', width: 28, height: 28),
            Text('$gold',
                style:
                    const TextStyle(color: kGoldColor, fontSize: 16)),
            const SizedBox(width: 14),
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
            GameImage('images/ui/rune_icon.png', width: 26, height: 26),
            const SizedBox(width: 2),
            FadeTransition(
              opacity: curvedPulse,
              child: const Text('Забытые руны',
                  style: TextStyle(
                      color: kRuneBlue, fontSize: 13,
                      fontWeight: FontWeight.w600)),
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
    return const SizedBox.shrink();
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
      child: Row(
        children: [
          nb('≡ Меню', onTap: () => setState(() => _burgerOpen = !_burgerOpen)),
          nb('🏰 Гильдия', onTap: () => _openModule('Гильдия')),
          nb('🍸 Таверна', onTap: () => _openModule('Таверна')),
          nb('💰Лавка', onTap: () => _openModule('Лавка')),
          nb('🍾 Боссы', onTap: () => _openModule('Боссы')),
          nb('🗺️ Карта', onTap: () => _openModule('Карта')),
          StreamBuilder<int>(
            stream: ChatService.instance.unreadCount(),
            builder: (context, snap) {
              final unread = snap.data ?? 0;
              return Expanded(
                child: Center(
                  child: FadeTransition(
                    opacity: unread > 0
                        ? curvedPulse
                        : const AlwaysStoppedAnimation(1.0),
                    child: Text(
                      _lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: unread > 0 ? kGoldColor : Colors.white,
                          fontSize: 11),
                    ),
                  ),
                ),
              );
            },
          ),
          StreamBuilder<int>(
            stream: ChatService.instance.unreadCount(),
            builder: (context, snap) {
              final unread = snap.data ?? 0;
              return Flexible(
                child: FadeTransition(
                  opacity: unread > 0
                      ? curvedPulse
                      : const AlwaysStoppedAnimation(1.0),
                  child: TextButton(
                    onPressed: () => _openModule('Чат'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: const Size(0, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      unread > 0 ? 'Чат ($unread)' : 'Чат',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: kGoldColor, fontSize: 13),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          const SizedBox(width: 2),
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
      ('Инвентарь', moduleAction('Инвентарь')),
      ('Аукцион', moduleAction('Аукцион')),
      ('Задания', moduleAction('Задания')),
      ('Почта', moduleAction('Почта')),
      ('Настройки', moduleAction('Настройки')),
      if (_adminRank > 0) ('👑 Админ панель', moduleAction('Админ панель')),
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
