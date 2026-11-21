import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../main.dart';
import '../services/player_repository.dart';
import '../widgets/module_window.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _buffStatusLine(dynamic buff, String prefix) {
    if (buff == null) return '';
    final name = buff['name'] ?? '';
    final expires = (buff['expires_at'] as num?)?.toInt() ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final remaining = expires - now;
    if (remaining <= 0) return '';
    final m = remaining ~/ 60;
    final s = remaining % 60;
    return '$prefix $name ($m:${s.toString().padLeft(2, '0')})';
  }

  @override
  Widget build(BuildContext context) {
    final player = PlayerRepository.instance;
    final data = player.data ?? const {};
    final stats = player.statsMap;
    final pvp = (data['stats_pvp'] as Map<String, dynamic>?) ?? const {};
    final exp = (data['exp'] as num?)?.toInt() ?? 0;
    final expInLevel = exp % 300;
    final buffs = (data['tavern_buffs'] as Map<String, dynamic>?) ?? const {};
    final foodBuff = _buffStatusLine(buffs['active_food_buff'], '🍽️');
    final songBuff = _buffStatusLine(buffs['active_song_buff'], '🎵');

    return ModuleWindow(
      title: '👤 Профиль',
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          GameCard(
            child: Column(
              children: [
                Text(player.name,
                    style: const TextStyle(
                        color: kGoldColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                    'Уровень ${player.level} • Опыт $expInLevel/300 • ${itemField(data, 'title', fallback: '—')}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text('💰 ${player.gold}',
                        style: const TextStyle(
                            color: kGoldColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    Text('🔮 ${player.rune}',
                        style: const TextStyle(
                            color: kRuneBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          if (foodBuff.isNotEmpty || songBuff.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GameCard(
                child: Text(
                    'Активные бафы: ${[foodBuff, songBuff].where((b) => b.isNotEmpty).join(' | ')}',
                    style:
                        const TextStyle(color: Color(0xFF80FF80), fontSize: 13)),
              ),
            ),
          const SizedBox(height: 12),
          GameCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Характеристики',
                        style: TextStyle(
                            color: kGoldColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('Очки: ${data['stat_points'] ?? 0}',
                        style: const TextStyle(color: kGoldColor, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
                for (final stat in playerStatOrder)
                  _StatRow(
                    label: playerStatNames[stat]!,
                    value: (stats[stat] as num?)?.toInt() ?? 0,
                    statKey: stat,
                    canSpend:
                        ((data['stat_points'] as num?)?.toInt() ?? 0) > 0,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GameCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Статистика',
                    style: TextStyle(
                        color: kGoldColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('Побед в PvP: ${pvp['pvp_wins'] ?? 0}',
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
                Text('Побед над монстрами: ${pvp['monsters'] ?? 0}',
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
                Text('Заработано: ${pvp['earned'] ?? 0}',
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
                Text('Побеждено боссов: ${pvp['bosses'] ?? 0}',
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int value;
  final String statKey;
  final bool canSpend;

  const _StatRow({
    required this.label,
    required this.value,
    required this.statKey,
    required this.canSpend,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text('$label: $value',
                style: const TextStyle(color: Colors.white, fontSize: 15)),
          ),
          SizedBox(
            width: 36,
            height: 30,
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
                  style: TextStyle(color: kGoldColor, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
