import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../main.dart';
import '../screens/battle_screen.dart';
import '../services/battle_engine.dart';
import '../widgets/mob_art.dart';
import 'module_window.dart';

/// Окно информации о мобе/боссе — как в оригинале: тап открывает карточку
/// со статами, шмоткой, дропом и слухом, в бой только по кнопке.
void showMobInfoWindow(BuildContext context, MobDef mob) {
  pushModuleWindow(
    context,
    _MobInfoWindow(mob: mob),
  );
}

class _MobInfoWindow extends StatelessWidget {
  final MobDef mob;
  const _MobInfoWindow({required this.mob});

  Map<String, dynamic>? get _bossDef {
    if (!mob.id.startsWith('boss_')) return null;
    final short = mob.id.substring(5);
    for (final db in [bossesDungeon, bossesWorld, bossesEvent]) {
      final def = db[short] as Map<String, dynamic>?;
      if (def != null) return def;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final boss = _bossDef;
    final drops = (boss?['drops'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final rewards = boss?['rewards'] as Map<String, dynamic>? ?? const {};
    final gear = mobGear[mob.id] ??
        mobGear[mob.id.replaceFirst('boss_', '')] ??
        const <String, String>{};
    final crit = (5 + mob.agility * 0.5).toInt();
    final evasion = (5 + mob.agility * 0.5).toInt().clamp(0, 30);

    Widget statLine(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Text('$label $value',
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        );

    return ModuleWindow(
      title: mob.id.startsWith('boss_') ? '💀 БОСС' : '👹 МОБ',
      maxWidth: 560,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 150,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFCC4D4D), width: 2),
                borderRadius: BorderRadius.circular(8),
                color: const Color(0x33000000),
              ),
              child: MobArt(mob.id, mob.emoji, width: 140, height: 192),
            ),
            const SizedBox(height: 8),
            Text(mob.name,
                style: const TextStyle(
                    color: kGoldColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 2,
              children: [
                statLine('❤️', '${mob.hp}'),
                statLine('⚔️', '${mob.attack}'),
                statLine('🛡️', '${mob.defense}'),
                statLine('🎯', '$crit%'),
                statLine('💨', '$evasion%'),
              ],
            ),
            const SizedBox(height: 8),
            Text('Уровень: ${mob.level}',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text('💰 ${mob.goldMin}–${mob.goldMax}   ⭐ ${mob.expMin}–${mob.expMax}',
                style: const TextStyle(color: Color(0xFF80FF80), fontSize: 13)),
            if (gear.isNotEmpty) ...[
              const Divider(color: Colors.white12, height: 18),
              const Text('СНАРЯЖЕНИЕ',
                  style: TextStyle(
                      color: kGoldColor, fontSize: 13, letterSpacing: 1)),
              const SizedBox(height: 4),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final e in gear.entries)
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: kGoldColor.withOpacity(0.45)),
                        borderRadius: BorderRadius.circular(6),
                        color: const Color(0x33221D18),
                      ),
                      child: Text(e.value,
                          style: const TextStyle(fontSize: 17)),
                    ),
                ],
              ),
            ],
            if (drops.isNotEmpty) ...[
              const Divider(color: Colors.white12, height: 18),
              const Text('🎁 ДОБЫЧА',
                  style: TextStyle(
                      color: kGoldColor, fontSize: 13, letterSpacing: 1)),
              for (final d in drops)
                Text('${d['icon'] ?? '🎁'} ${d['name']} — шанс ${d['chance']}%',
                    style: const TextStyle(
                        color: Color(0xFF80FF80), fontSize: 13)),
            ],
            if (rewards.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                  'Награда: ${rewards['exp'] ?? 0} опыта, ${rewards['gold'] ?? 0} 💰',
                  style: const TextStyle(color: kGoldColor, fontSize: 13)),
            ],
            if (boss?['rumor'] != null) ...[
              const Divider(color: Colors.white12, height: 18),
              const Text('💬 СЛУХ',
                  style: TextStyle(
                      color: kGoldColor, fontSize: 13, letterSpacing: 1)),
              Text(boss!['rumor']!.toString(),
                  softWrap: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFB0C4FF), fontSize: 13)),
            ],
            if (boss?['description'] != null) ...[
              const SizedBox(height: 6),
              Text(boss!['description']!.toString(),
                  softWrap: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13)),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: 240,
              height: 44,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C)),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => BattleScreen(mob: mob)));
                },
                child: const Text('⚔️ В БОЙ',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
