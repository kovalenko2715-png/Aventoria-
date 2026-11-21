import 'dart:math';

import 'package:flutter/material.dart';

import '../main.dart';
import '../services/player_repository.dart';
import '../widgets/module_window.dart';

class _TopEntry {
  final String name;
  final int level;
  final int pvpWins;
  final int monsters;
  final int gold;
  final bool isBot;
  const _TopEntry(this.name,
      {required this.level,
      required this.pvpWins,
      required this.monsters,
      required this.gold,
      required this.isBot});
}

class HallScreen extends StatefulWidget {
  const HallScreen({super.key});

  @override
  State<HallScreen> createState() => _HallScreenState();
}

class _HallScreenState extends State<HallScreen> {
  static const _botNames = [
    'Альтаир', 'Брут', 'Велес', 'Гром', 'Добрыня',
    'Елисей', 'Ждан', 'Златослав', 'Искра', 'Казимир',
    'Людобор', 'Мирослав', 'Никита', 'Олег', 'Перун',
    'Радомир', 'Святогор', 'Твердислав', 'Умар', 'Фрол',
    'Храбр', 'Цветан', 'Часлав', 'Шурик', 'Юрий',
    'Яромир', 'Богдан', 'Владимир', 'Глеб', 'Денис'
  ];

  String _tab = 'level';
  List<_TopEntry> _shown = const [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  List<_TopEntry> _keyOf(List<_TopEntry> list, String tab) {
    int value(_TopEntry p) {
      switch (tab) {
        case 'level':
          return p.level;
        case 'pvp':
          return p.pvpWins;
        case 'monsters':
          return p.monsters;
        default:
          return p.gold;
      }
    }

    final sorted = List<_TopEntry>.from(list)..sort((a, b) => value(b) - value(a));
    return sorted;
  }

  void _refresh() {
    final player = PlayerRepository.instance;
    final stats = player.data?['stats_pvp'] as Map<String, dynamic>? ?? const {};
    final list = [
      _TopEntry(player.name,
          level: player.level,
          pvpWins: (stats['pvp_wins'] as num?)?.toInt() ?? 0,
          monsters: (stats['monsters'] as num?)?.toInt() ?? 0,
          gold: player.gold,
          isBot: false),
      for (final name in _botNames)
        _TopEntry(name,
            level: Random().nextInt(50) + 1,
            pvpWins: Random().nextInt(100),
            monsters: Random().nextInt(500),
            gold: Random().nextInt(10000),
            isBot: true),
    ];
    setState(() => _shown = _keyOf(list, _tab));
  }

  String _rankPrefix(int index) {
    switch (index) {
      case 0:
        return '🥇 ';
      case 1:
        return '🥈 ';
      case 2:
        return '🥉 ';
      default:
        return '';
    }
  }

  String _formatNumber(int num) {
    if (num >= 1000000) return '${num ~/ 1000000}M';
    if (num >= 1000) return '${num ~/ 1000}K';
    return '$num';
  }

  int _value(_TopEntry p) {
    switch (_tab) {
      case 'level':
        return p.level;
      case 'pvp':
        return p.pvpWins;
      case 'monsters':
        return p.monsters;
      default:
        return p.gold;
    }
  }

  String _valueName() {
    switch (_tab) {
      case 'level':
        return 'очков';
      case 'pvp':
        return 'побед';
      case 'monsters':
        return 'монстров';
      default:
        return 'золота';
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerName = PlayerRepository.instance.name;
    const tabs = [
      ('level', '🏆 УРОВЕНЬ'),
      ('pvp', '⚔️ PVP'),
      ('monsters', '👾 МОНСТРЫ'),
      ('gold', '💰 ЗОЛОТО'),
    ];
    return ModuleWindow(
      title: '🏆 ЗАЛ СЛАВЫ 🏆',
      actions: [
        IconButton(
          onPressed: _refresh,
          tooltip: 'Обновить',
          icon: const Icon(Icons.refresh, color: kGoldColor),
        ),
      ],
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final (id, label) in tabs)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: OutlinedButton(
                      onPressed: () => setState(() {
                        _tab = id;
                        _shown = _keyOf(_shown, id);
                      }),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: _tab == id
                                ? kGoldColor
                                : const Color(0x33FFD700)),
                        backgroundColor: _tab == id
                            ? const Color(0xFF2A2318)
                            : const Color(0xFF221D18),
                        minimumSize: const Size(140, 45),
                      ),
                      child: Text(label,
                          style: TextStyle(
                              color: _tab == id
                                  ? kGoldColor
                                  : const Color(0xFFCCCCCC),
                              fontSize: 13)),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(color: Color(0x4DFFD700)),
          Expanded(
            child: _shown.isEmpty
                ? const Center(
                    child: Text('Нет данных для отображения.\nНажмите ОБНОВИТЬ',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF999999), fontSize: 18)))
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: _shown.length,
                    itemBuilder: (context, i) {
                      final p = _shown[i];
                      final top3 = i < 3;
                      var displayName = p.name;
                      if (p.isBot) {
                        displayName = '🤖 $displayName';
                      } else if (displayName == playerName) {
                        displayName = '⭐ $displayName (Вы)';
                      }
                      final valueStr = _tab == 'gold'
                          ? '${_formatNumber(_value(p))}💰'
                          : '${_value(p)}';
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${_rankPrefix(i)}${i + 1}.',
                                  style: TextStyle(
                                      color: top3
                                          ? kGoldColor
                                          : const Color(0xFFCCCCCC),
                                      fontSize: top3 ? 18 : 15),
                                ),
                                const SizedBox(width: 10),
                                Text(displayName,
                                    style: TextStyle(
                                        color: top3
                                            ? kGoldColor
                                            : const Color(0xFFE5E5E5),
                                        fontSize: top3 ? 18 : 15)),
                                Text(
                                  ' — $valueStr ${_valueName()}',
                                  style: TextStyle(
                                      color: top3
                                          ? const Color(0xFF80FF80)
                                          : const Color(0xFFB3B3B3),
                                      fontSize: top3 ? 18 : 15),
                                ),
                                if (_tab == 'level')
                                  Text(' [Уровень ${p.level}]',
                                      style: const TextStyle(
                                          color: kRuneBlue, fontSize: 15)),
                              ],
                            ),
                          ),
                          if (i == 2 && _shown.length > 3)
                            const Divider(color: Color(0x4DFFD700)),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
