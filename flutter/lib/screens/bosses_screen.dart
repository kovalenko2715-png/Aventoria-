import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../main.dart';
import '../services/battle_engine.dart';
import '../screens/battle_screen.dart';
import '../widgets/module_window.dart';

class BossesScreen extends StatelessWidget {
  const BossesScreen({super.key});

  bool _eventActive(Map<String, dynamic> boss) {
    final now = DateTime.now();
    final sm = (boss['start_month'] as num?)?.toInt() ?? 0;
    final sd = (boss['start_day'] as num?)?.toInt() ?? 1;
    final em = (boss['end_month'] as num?)?.toInt() ?? 0;
    final ed = (boss['end_day'] as num?)?.toInt() ?? 1;
    final today = now.month * 100 + now.day;
    final start = sm * 100 + sd;
    final end = em * 100 + ed;
    if (start <= end) {
      return today >= start && today <= end;
    }
    return today >= start || today <= end;
  }

  void _openBoss(BuildContext context, MapEntry<String, dynamic> entry) {
    final boss = entry.value as Map<String, dynamic>;
    final mob = mobFromBoss(entry.key, boss);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BattleScreen(mob: mob)),
    );
  }

  Widget _bossCard(BuildContext context, MapEntry<String, dynamic> entry) {
    final boss = entry.value as Map<String, dynamic>;
    final rewards = boss['rewards'] as Map<dynamic, dynamic>? ?? const {};
    final drops = (boss['drops'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(boss['icon']?.toString() ?? '💀',
                  style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(boss['name']?.toString() ?? '',
                    style: const TextStyle(
                        color: kGoldColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          Text(boss['description']?.toString() ?? '',
              style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 12)),
          const SizedBox(height: 4),
          Text(
              'Ур. ${boss['level']} • HP ${boss['hp']} • Атака ${boss['attack_min']}-${boss['attack_max']} • Защита ${boss['defense']} • ${boss['location_name'] ?? ''}',
              style: const TextStyle(color: Colors.white, fontSize: 12)),
          if (drops.isNotEmpty)
            Text(
                'Дроп: ${drops.map((d) => '${d['name']} (${d['chance']}%)').join(', ')}',
                style: const TextStyle(color: Color(0xFF80FF80), fontSize: 11)),
          Text('Награда: ${rewards['exp'] ?? 0} оп, ${rewards['gold'] ?? 0} 💰',
              style: const TextStyle(color: kGoldColor, fontSize: 12)),
          if (boss['rumor'] != null)
            Text('💬 ${boss['rumor']}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.45), fontSize: 11)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _openBoss(context, entry),
                child: const Text('Атаковать',
                    style: TextStyle(color: kGoldColor, fontSize: 14)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventBosses = bossesEvent.entries.toList();
    final activeEventBosses = eventBosses
        .where((e) => _eventActive(e.value as Map<String, dynamic>))
        .toList();
    final inactiveEventBosses = eventBosses
        .where((e) => !_eventActive(e.value as Map<String, dynamic>))
        .toList();

    return ModuleWindow(
      title: '🍻 Боссы',
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              labelColor: kGoldColor,
              unselectedLabelColor: Colors.white54,
              indicatorColor: kGoldColor,
              isScrollable: true,
              tabs: [
                Tab(text: 'Подземелья'),
                Tab(text: 'Мира'),
                Tab(text: 'События'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _list(bossesDungeon.entries
                      .map((e) => _bossCard(context, e))
                      .toList()),
                  _list(bossesWorld.entries
                      .map((e) => _bossCard(context, e))
                      .toList()),
                  _list([
                    if (activeEventBosses.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                            'Сейчас нет активных событий. Ждите следующую дату!',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 13)),
                      ),
                    for (final e in activeEventBosses) ...[
                      _bossCard(context, e),
                      const SizedBox(height: 6),
                    ],
                    const SizedBox(height: 10),
                    for (final e in inactiveEventBosses)
                      Opacity(
                        opacity: 0.45,
                        child: _bossCard(context, e),
                      ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(List<Widget> children) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final w in children) ...[w, const SizedBox(height: 6)],
        const SizedBox(height: 20),
      ],
    );
  }
}
