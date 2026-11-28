import 'dart:math';

import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../main.dart';
import '../services/battle_engine.dart';
import '../services/player_repository.dart';
import '../screens/battle_screen.dart';
import '../widgets/game_image.dart';
import '../widgets/module_window.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  /// Цвета меток — 1:1 как в оригинале map.gd.
  static const Map<String, Color> markerColors = {
    'tower': Color(0xFF994CCC),
    'forest': Color(0xFF33B34D),
    'city': Color(0xFFFFD700),
    'volcano': Color(0xFFFF6600),
    'mountains': Color(0xFF6699FF),
    'mansion': Color(0xFFCC4D80),
    'crypt': Color(0xFF808080),
    'ruins': Color(0xFFCCB34D),
    'castle': Color(0xFFFF3333),
  };

  MobDef? _mobById(String? mobId) {
    if (mobId == null) return null;
    for (final mob in MobDatabase.mobs) {
      if (mob.id == mobId) return mob;
    }
    // Из оригинала приходят golem/ghost — мапим на ближайших по духу мобов.
    const fallback = {'golem': 'troll', 'ghost': 'skeleton'};
    final mapped = fallback[mobId];
    if (mapped == null) return null;
    for (final mob in MobDatabase.mobs) {
      if (mob.id == mapped) return mob;
    }
    return null;
  }

  /// В бой с локации — как в оригинале: случайный враг из списка.
  void _fightLocation(BuildContext context, List<dynamic> enemies) {
    if (enemies.isEmpty) return;
    final enemy =
        enemies[Random().nextInt(enemies.length)] as Map<String, dynamic>;
    final mob = _mobById(enemy['mob_id']?.toString());
    if (mob == null) return;
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => BattleScreen(mob: mob)));
  }

  void _openLocation(
      BuildContext context, String locId, Map<String, dynamic> loc) {
    final color = markerColors[locId] ?? kGoldColor;
    final enemies =
        (loc['enemies'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
    final playerLvl = PlayerRepository.instance.level;
    var minLevel = 999, maxLevel = 0;
    for (final e in enemies) {
      final l = (e['level'] as num?)?.toInt() ?? 1;
      if (l < minLevel) minLevel = l;
      if (l > maxLevel) maxLevel = l;
    }
    final tooDangerous = playerLvl < minLevel;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF191009),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: color.withOpacity(0.8), width: 3),
        ),
        child: Container(
          width: 420,
          constraints: const BoxConstraints(maxHeight: 430),
          padding: const EdgeInsets.all(14),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(loc['icon']?.toString() ?? '📍',
                    style: const TextStyle(fontSize: 40)),
                Text(loc['name']?.toString() ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: color,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const Divider(
                    color: Color(0x80CCAA44), height: 14),
                Text(loc['desc']?.toString() ?? '',
                    softWrap: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Color(0xFFF2E6CC), fontSize: 13)),
                if (enemies.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          '📊 Уровень врагов: $minLevel - $maxLevel',
                          style: TextStyle(
                              color: tooDangerous
                                  ? const Color(0xFFFF4D4D)
                                  : const Color(0xFF80FF80),
                              fontSize: 13)),
                      if (tooDangerous)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Text('⚠️ ОПАСНО!',
                              style: TextStyle(
                                  color: Color(0xFFFF4D4D),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('⚔️ ВРАГИ',
                      style: TextStyle(
                          color: kGoldColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  for (final enemy in enemies)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              final mob = _mobById(
                                  enemy['mob_id']?.toString());
                              if (mob != null) {
                                Navigator.pop(ctx);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            BattleScreen(mob: mob)));
                              }
                            },
                            child: Text(
                                '${enemy['icon'] ?? ''} ${enemy['name'] ?? ''} (Ур.${enemy['level']}) — ${enemy['damage'] ?? ''} урона',
                                style: const TextStyle(
                                    color: Color(0xFFFFB34D),
                                    fontSize: 13,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Color(0x66FFB34D))),
                          ),
                          Text('  🎁 ${enemy['drops'] ?? ''}',
                              style: const TextStyle(
                                  color: Color(0xFF80E680), fontSize: 12)),
                        ],
                      ),
                    ),
                ],
                if ((loc['quests'] as List<dynamic>? ?? const [])
                    .isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('📋 ЗАДАНИЯ',
                      style: TextStyle(
                          color: kGoldColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  for (final q in loc['quests'] as List<dynamic>)
                    Text('📌 $q',
                        style: const TextStyle(
                            color: Color(0xFFF2F2F2), fontSize: 13)),
                ],
                if (loc['rumor'] != null) ...[
                  const SizedBox(height: 8),
                  const Text('💬 СЛУХ',
                      style: TextStyle(
                          color: kGoldColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  Text('🔮 ${loc['rumor']}',
                      softWrap: true,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFFB3CCFF), fontSize: 13)),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: tooDangerous
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              _fightLocation(context, enemies);
                            },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFFB71C1C)),
                      ),
                      child: Text(
                          tooDangerous
                              ? '⚔️ НУЖЕН УР. $minLevel'
                              : '⚔️ В БОЙ',
                          style: TextStyle(
                              color: tooDangerous
                                  ? const Color(0xFFCC6666)
                                  : const Color(0xFFFF6B6B),
                              fontSize: 13)),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white38),
                      ),
                      child: const Text('❌ ЗАКРЫТЬ',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final mapHeight = mq.size.height - 120;
    return ModuleWindow(
      title: '🗺️ Карта Эвории',
      child: InteractiveViewer(
        maxScale: 3,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: mapHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GameImage('images/map.png',
                        fit: BoxFit.contain),
                  ),
                  // Метки как в оригинале: цветной круг 30px с первой буквой
                  // названия локации, белый текст, золотая обводка.
                  for (final e in mapLocations.entries)
                    Positioned(
                      left: ((e.value as Map<String, dynamic>)['x'] as num)
                              .toDouble() *
                          constraints.maxWidth -
                          17,
                      top: ((e.value as Map<String, dynamic>)['y'] as num)
                              .toDouble() *
                          mapHeight -
                          17,
                      child: GestureDetector(
                        onTap: () => _openLocation(
                            context, e.key, e.value as Map<String, dynamic>),
                        child: Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: markerColors[e.key] ??
                                const Color(0xFFFF3333),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.8),
                                width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Text(
                              ((e.value
                                          as Map<String,
                                              dynamic>)['name'] as String?)
                                      ?.isNotEmpty == true
                                  ? (e.value as Map<String,
                                          dynamic>)['name'][0]
                                      as String
                                  : '?',
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
