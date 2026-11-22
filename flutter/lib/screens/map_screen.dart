import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../main.dart';
import '../services/battle_engine.dart';
import '../screens/battle_screen.dart';
import '../widgets/game_image.dart';
import '../widgets/module_window.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  MobDef? _mobById(String? mobId) {
    if (mobId == null) return null;
    for (final mob in MobDatabase.mobs) {
      if (mob.id == mobId) return mob;
    }
    return null;
  }

  void _openLocation(BuildContext context, String locId,
      Map<String, dynamic> loc) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF141110),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: kGoldColor.withOpacity(0.6), width: 2),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${loc['icon'] ?? ''} ${loc['name'] ?? ''}',
                  style: const TextStyle(
                      color: kGoldColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(loc['desc']?.toString() ?? '',
                  style: const TextStyle(
                      color: Color(0xFFCCCCCC), fontSize: 13)),
              if (loc['rumor'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('💬 ${loc['rumor']}',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 12)),
                ),
              const SizedBox(height: 10),
              const Text('Противники:',
                  style: TextStyle(
                      color: kGoldColor, fontSize: 13)),
              for (final enemy in (loc['enemies'] as List<dynamic>? ?? const []))
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Text(
                          '${(enemy as Map<String, dynamic>)['icon'] ?? ''} ${(enemy)['name'] ?? ''} (Ур.${(enemy)['level']}, ${(enemy)['damage']})',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13)),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          final mob = _mobById(
                              (enemy)['mob_id']?.toString());
                          if (mob != null && context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => BattleScreen(mob: mob)),
                            );
                          }
                        },
                        child: const Text('Бой',
                            style: TextStyle(color: kGoldColor)),
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Закрыть',
                      style: TextStyle(color: Colors.white70)),
                ),
              ),
            ],
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
                  for (final e in mapLocations.entries)
                    Positioned(
                      left: ((e.value as Map<String, dynamic>)['x'] as num)
                              .toDouble() *
                          constraints.maxWidth -
                          22,
                      top: ((e.value as Map<String, dynamic>)['y'] as num)
                              .toDouble() *
                          mapHeight -
                          22,
                      child: GestureDetector(
                        onTap: () => _openLocation(
                            context, e.key, e.value as Map<String, dynamic>),
                        child: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xCC1A1A1A),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                                color: kGoldColor.withOpacity(0.6), width: 2),
                          ),
                          child: Text(
                              (e.value as Map<String, dynamic>)['icon']
                                      ?.toString() ??
                                  '📍',
                              style: const TextStyle(fontSize: 18)),
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
