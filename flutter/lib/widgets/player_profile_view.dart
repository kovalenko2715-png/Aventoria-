import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../main.dart';
import '../services/combat_service.dart';
import 'game_image.dart';

/// Просмотр профиля другого игрока из чата: статы, пассивки,
/// уровень, HP/мана, кукла с обликом и надетый шмот — как в бойцовском клубе.
class PlayerProfileView extends StatefulWidget {
  final String uid;
  const PlayerProfileView({super.key, required this.uid});

  @override
  State<PlayerProfileView> createState() => _PlayerProfileViewState();
}

class _PlayerProfileViewState extends State<PlayerProfileView> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
  }

  @override
  void didUpdateWidget(PlayerProfileView old) {
    super.didUpdateWidget(old);
    if (old.uid != widget.uid) {
      _future = FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
    }
  }

  Widget _kv(String label, String value, {Color? valueColor}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
            const SizedBox(width: 4),
            Text(value,
                style: TextStyle(
                    color: valueColor ?? kGoldColor, fontSize: 13)),
          ],
        ),
      );

  Widget _stat(int value, String label) => _kv('$label:', '$value');

  static const _slotOrder = [
    'wings',
    'bracelet',
    'mask',
    'helmet',
    'armor',
    'gloves',
    'weapon',
    'weapon2',
    'pants',
    'boots',
    'cloak',
    'necklace',
    'earring1',
    'earring2',
    'shield',
    'shirt',
    'belt',
    'ring1',
    'ring2',
    'bag',
    'rune',
  ];

  Widget _eqSlot(Map<String, dynamic> equipment, String key) {
    final item = equipment[key];
    final has = item is Map<String, dynamic>;
    final icon = has ? (item['icon']?.toString() ?? '') : '';
    return Container(
      width: 42,
      height: 46,
      decoration: BoxDecoration(
        border: Border.all(
            color: has
                ? kGoldColor
                : kGoldColor.withOpacity(0.4),
            width: has ? 2 : 1.2),
        borderRadius: BorderRadius.circular(8),
        color: const Color(0x33221D18),
      ),
      child: Center(
        child: has && icon.startsWith('http')
            ? GameImage(icon,
                width: 30, height: 30, fit: BoxFit.contain)
            : Text(icon,
                style: TextStyle(
                    fontSize: has ? 18 : 10,
                    color: has ? Colors.white : Colors.white24)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snap.data?.data() ?? const {};
        final stats =
            (data['stats'] as Map<String, dynamic>?) ?? const {};
        final elements =
            (data['elements'] as Map<String, dynamic>?) ?? const {};
        final look = data['look']?.toString() ?? '';
        final equipment =
            (data['equipment'] as Map<String, dynamic>?) ?? const {};
        int s(String k) => (stats[k] as num?)?.toInt() ?? 0;

        final combat =
            CombatService.compute(stats: stats, equipment: equipment);
        final hp = combat.maxHp;
        final mana = combat.maxMana;
        const elementNames = {
          'fire': '🔥 Огонь',
          'water': '💧 Вода',
          'earth': '🌍 Земля',
          'air': '🌪️ Воздух',
          'light': '✨ Свет',
          'dark': '🌑 Тьма',
        };

        Widget section(String t) => Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 2),
              child: Text(t,
                  style: const TextStyle(
                      color: kGoldColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            );

        return Padding(
          padding: const EdgeInsets.all(10),
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 110,
                      height: 150,
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: kGoldColor, width: 2),
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0x33221D18),
                      ),
                      child: look.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: GameImage(look, fit: BoxFit.cover),
                            )
                          : const Center(
                              child: Text('🧍',
                                  style: TextStyle(
                                      fontSize: 36,
                                      color: Colors.white24)),
                            ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                        'Уровень ${(data['level'] as num?)?.toInt() ?? 1}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12)),
                    Text('❤️ $hp/${hp}',
                        style: const TextStyle(
                            color: Color(0xFFFF7070), fontSize: 11)),
                    Text('🧪 $mana/$mana',
                        style: const TextStyle(
                            color: Color(0xFF70A0FF), fontSize: 11)),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      section('ХАРАКТЕРИСТИКИ'),
                      for (final k in playerStatOrder)
                        _stat(
                            s(k), playerStatNames[k] ?? k),
                      section('ПАССИВНЫЕ'),
                      Wrap(spacing: 16, runSpacing: 0, children: [
                        _stat(combat.attack, '⚔️ Атака'),
                        _stat(combat.defense, '🛡️ Защита'),
                        if (combat.dualWield)
                          _stat((combat.attack * 1.2).toInt(),
                              '\u270c\ufe0f \u0410\u0442\u0430\u043a\u0430 \u04451.2'),
                        _stat(
                            combat.maxHp, '❤️ HP'),
                        _stat(
                            combat.maxMana,
                            '🧪 Мана'),
                        _stat(
                            combat.critChance,
                            '🎯 Крит %'),
                        _stat(
                            combat.critDamage,
                            '💥 Крит. урон %'),
                        _stat(
                            combat.evasion,
                            '🌀 Уклонение'),
                        _stat(
                            combat.magicFind,
                            '🔮 Маг. фаинд'),
                      ]),
                      section('СТИХИИ'),
                      Wrap(spacing: 12, runSpacing: 0, children: [
                        for (final e in elements.entries)
                          Text(
                              '${elementNames[e.key] ?? e.key}: ${(e.value as num?)?.toInt() ?? 0}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12))
                      ]),
                      section('ШМОТ'),
                      Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: [
                            for (final k in _slotOrder) _eqSlot(equipment, k)
                          ]),
                      section('ИНФОРМАЦИЯ'),
                      _kv('Ник:',
                          data['name']?.toString() ?? '???'),
                      _kv('Гильдия:',
                          data['guild']?.toString() ?? '—'),
                      _kv('Титул:',
                          data['title']?.toString() ?? '—'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
