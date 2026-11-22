import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../main.dart';
import 'game_image.dart';

/// Просмотр профиля другого игрока из чата: статы, пассивки,
/// уровень, HP/мана и кукла с обликом — как в бойцовском клубе.
class PlayerProfileView extends StatelessWidget {
  final String uid;
  const PlayerProfileView({super.key, required this.uid});

  int _passive(Map<String, dynamic> stats, String key) {
    int s(String k) => (stats[k] as num?)?.toInt() ?? 0;
    return switch (key) {
      'attack' => 100 + s('strength') * 2,
      'defense' => 50 + s('endurance'),
      'max_hp' => 200 + s('endurance') * 5,
      'max_mana' => 100 + s('wisdom') * 3,
      'crit_chance' => (5 + s('agility') * 0.5).toInt(),
      'crit_damage' => 150 + s('intuition'),
      'evasion' => (5 + s('agility') * 0.5).toInt(),
      'magic_find' => (5 + s('intuition') * 0.3).toInt(),
      _ => 0,
    };
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
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
        int s(String k) => (stats[k] as num?)?.toInt() ?? 0;

        final hp = _passive(stats, 'max_hp');
        final mana = _passive(stats, 'max_mana');
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
                        _stat(_passive(stats, 'attack'), '⚔️ Атака'),
                        _stat(_passive(stats, 'defense'), '🛡️ Защита'),
                        _stat(
                            _passive(stats, 'max_hp'), '❤️ HP'),
                        _stat(
                            _passive(stats, 'max_mana'),
                            '🧪 Мана'),
                        _stat(
                            _passive(stats, 'crit_chance'),
                            '🎯 Крит %'),
                        _stat(
                            _passive(stats, 'crit_damage'),
                            '💥 Крит. урон %'),
                        _stat(
                            _passive(stats, 'evasion'),
                            '🌀 Уклонение'),
                        _stat(
                            _passive(stats, 'magic_find'),
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
