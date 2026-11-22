import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../main.dart';
import '../services/player_repository.dart';
import '../widgets/module_window.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _buffStatusLine(Map<String, dynamic>? buffs, String key, String prefix) {
    final buff = buffs?[key] as Map<String, dynamic>?;
    if (buff == null) return '';
    final name = buff['name'] ?? buff['type'] ?? '';
    final expires = (buff['expires_at'] as num?)?.toInt() ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final remaining = expires - now;
    if (remaining <= 0) return '';
    final m = remaining ~/ 60;
    final s = remaining % 60;
    return '$name ($m:${s.toString().padLeft(2, '0')})';
  }

  @override
  Widget build(BuildContext context) {
    final player = PlayerRepository.instance;
    final data = player.data ?? const {};
    final stats = player.statsMap;
    final pvp = (data['stats_pvp'] as Map<String, dynamic>?) ?? const {};
    final elements = (data['elements'] as Map<String, dynamic>?) ?? const {};
    final buffs = (data['tavern_buffs'] as Map<String, dynamic>?) ?? const {};

    int stat(String k) => (stats[k] as num?)?.toInt() ?? 0;

    var attackMult = 1.0;
    var defenseMult = 1.0;
    var hpBonus = 0, critBonus = 0, evasionBonus = 0;
    final foodBuff = buffs['active_food_buff'] as Map<String, dynamic>?;
    final songBuff = buffs['active_song_buff'] as Map<String, dynamic>?;
    int remaining(Map<String, dynamic>? b) {
      final ex = (b?['expires_at'] as num?)?.toInt() ?? 0;
      return ex - DateTime.now().millisecondsSinceEpoch ~/ 1000;
    }

    if (foodBuff != null && remaining(foodBuff) > 0) {
      switch ((foodBuff['type'] ?? '').toString()) {
        case 'strength':
          attackMult += 0;
          break;
        case 'max_hp':
          hpBonus += (foodBuff['value'] as num?)?.toInt() ?? 0;
        case 'defense':
          defenseMult += ((foodBuff['value'] as num?) ?? 0) / 100.0;
        case 'attack':
          attackMult += ((foodBuff['value'] as num?) ?? 0) / 100.0;
      }
    }
    if (songBuff != null && remaining(songBuff) > 0) {
      switch ((songBuff['type'] ?? '').toString()) {
        case 'attack':
        case 'berserk':
          attackMult += ((songBuff['value'] as num?) ?? 0) / 100.0;
        case 'defense':
          defenseMult += ((songBuff['value'] as num?) ?? 0) / 100.0;
        case 'crit_chance':
          critBonus += (songBuff['value'] as num?)?.toInt() ?? 0;
        case 'evasion':
          evasionBonus += (songBuff['value'] as num?)?.toInt() ?? 0;
      }
    }

    int finalAttack = ((100 + stat('strength') * 2) * attackMult).toInt() +
        (foodBuff != null &&
                remaining(foodBuff) > 0 &&
                (foodBuff['type'] ?? '') == 'strength'
            ? (foodBuff['value'] as num?)?.toInt() ?? 0
            : 0);
    int finalDefense = ((50 + stat('endurance')) * defenseMult).toInt();
    int finalHp = 200 + stat('endurance') * 5 + hpBonus;
    int finalMana = 100 + stat('wisdom') * 3;
    int critChance = (5 + stat('agility') * 0.5).toInt() + critBonus;
    int critDamage = 150 + stat('intuition');
    int evasion = (5 + stat('agility') * 0.5).toInt() + evasionBonus;
    int magicFind = (5 + stat('intuition') * 0.3).toInt();

    String nick = player.name != 'Герой' ? player.name : '—';

    Widget sectionTitle(String t) => Text(t,
        style: const TextStyle(
            color: kGoldColor, fontSize: 15, fontWeight: FontWeight.bold));

    Widget kv(String label, String value, {TextStyle? style}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
              const SizedBox(width: 4),
              Text(value, style: style ?? const TextStyle(color: kGoldColor, fontSize: 13)),
            ],
          ),
        );

    return ModuleWindow(
      title: 'ПРОФИЛЬ ИГРОКА',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                kv('🎰 Уровень:', '${player.level}'),
                const SizedBox(width: 14),
                kv('❤️ HP:', '$finalHp/$finalHp'),
                const SizedBox(width: 14),
                kv('🧪 Мана:', '$finalMana/$finalMana'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      sectionTitle('ХАРАКТЕРИСТИКИ'),
                      const SizedBox(height: 4),
                      kv('⭐ Свободные очки:',
                          '${(data['stat_points'] as num?)?.toInt() ?? 0}'),
                      for (final k in playerStatOrder)
                        _StatPlusRow(
                          label: playerStatNames[k]!,
                          value: stat(k),
                          statKey: k,
                          canSpend:
                              ((data['stat_points'] as num?)?.toInt() ?? 0) > 0,
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      sectionTitle('ПАССИВНЫЕ'),
                      const SizedBox(height: 4),
                      kv('⚔️ Атака:', '$finalAttack'),
                      kv('🛡️ Защита:', '$finalDefense'),
                      kv('❤️ HP:', '$finalHp/$finalHp'),
                      kv('🧪 Мана:', '$finalMana/$finalMana'),
                      kv('🎯 Шанс крита:', '$critChance%'),
                      kv('💥 Крит.урон:', '$critDamage%'),
                      kv('🌀 Уклонение:', '$evasion%'),
                      kv('✨ Маг.файнд:', '$magicFind%'),
                      const SizedBox(height: 10),
                      sectionTitle('СТИХИИ'),
                      const SizedBox(height: 4),
                      kv('🔥 Огонь:',
                          '${(elements['fire'] as num?)?.toInt() ?? 0}'),
                      kv('💧 Вода:',
                          '${(elements['water'] as num?)?.toInt() ?? 0}'),
                      kv('🌍 Земля:',
                          '${(elements['earth'] as num?)?.toInt() ?? 0}'),
                      kv('🌬️ Воздух:',
                          '${(elements['air'] as num?)?.toInt() ?? 0}'),
                      kv('☀️ Свет:',
                          '${(elements['light'] as num?)?.toInt() ?? 0}'),
                      kv('🌙 Тьма:',
                          '${(elements['dark'] as num?)?.toInt() ?? 0}'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      sectionTitle('ИНФОРМАЦИЯ'),
                      const SizedBox(height: 4),
                      kv('Nickname:', nick),
                      kv('Пол:', '—'),
                      kv('Стихия:',
                          itemField(data, 'element', fallback: '—')),
                      kv('Титул:', itemField(data, 'title', fallback: '—')),
                      kv('Гильдия:', itemField(data, 'guild', fallback: '—')),
                      kv('Герб:', itemField(data, 'guild_emblem', fallback: '—')),
                      const SizedBox(height: 10),
                      sectionTitle('СТАТИСТИКА'),
                      const SizedBox(height: 4),
                      kv('⚔️ ПВП побед:',
                          '${(pvp['pvp_wins'] as num?)?.toInt() ?? 0}'),
                      kv('👹 Монстров:',
                          '${(pvp['monsters'] as num?)?.toInt() ?? 0}'),
                      kv('💰 Заработано:',
                          '${(pvp['earned'] as num?)?.toInt() ?? 0}'),
                      kv('👑 Боссов:',
                          '${(pvp['bosses'] as num?)?.toInt() ?? 0}'),
                      const SizedBox(height: 10),
                      sectionTitle('АКТИВНЫЕ БАФЫ'),
                      const SizedBox(height: 4),
                      Text(
                        (() {
                          final food = _buffStatusLine(
                              buffs, 'active_food_buff', '🍽️');
                          final song = _buffStatusLine(
                              buffs, 'active_song_buff', '🎵');
                          final parts = [food, song]
                              .where((b) => b.isNotEmpty)
                              .toList();
                          return parts.isEmpty ? 'Нет активных бафов' : parts.join('\n');
                        })(),
                        style: const TextStyle(
                            color: Color(0xFF80FF80), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPlusRow extends StatelessWidget {
  final String label;
  final int value;
  final String statKey;
  final bool canSpend;

  const _StatPlusRow({
    required this.label,
    required this.value,
    required this.statKey,
    required this.canSpend,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label:',
              style: const TextStyle(color: Colors.white, fontSize: 13)),
          const SizedBox(width: 4),
          Text('$value',
              style: const TextStyle(color: kGoldColor, fontSize: 13)),
          const Spacer(),
          SizedBox(
            width: 30,
            height: 26,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                side: BorderSide(
                    color: canSpend ? kGoldColor : Colors.white24),
              ),
              onPressed: canSpend
                  ? () =>
                      PlayerRepository.instance.spendStatPoint(statKey)
                  : null,
              child: const Text('+',
                  style: TextStyle(color: kGoldColor, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
