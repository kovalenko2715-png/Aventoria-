import 'package:flutter/material.dart';

import '../main.dart';
import '../services/battle_engine.dart';
import 'battle_screen.dart';

class MonsterSelectScreen extends StatelessWidget {
  const MonsterSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const mobs = MobDatabase.mobs;
    return Scaffold(
      appBar: AppBar(title: const Text('Монстры и боссы')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: mobs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final mob = mobs[i];
          return Card(
            color: kPanelColor,
            child: ListTile(
              leading: Text(mob.emoji, style: const TextStyle(fontSize: 34)),
              title: Text(
                mob.name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white),
              ),
              subtitle: Text(
                'Ур. ${mob.level} • HP ${mob.hp} • ${mob.strength}⚔ ${mob.agility}💨 ${mob.defense}🛡',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              trailing: Text(
                '💰${mob.goldMin}-${mob.goldMax}',
                style: const TextStyle(color: kGoldColor, fontSize: 12),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BattleScreen(mob: mob),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
