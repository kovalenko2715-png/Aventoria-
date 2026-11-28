import 'package:flutter/material.dart';

import '../main.dart';
import '../services/player_repository.dart';
import '../widgets/module_window.dart';
import 'arena_screen.dart';
import 'hall_screen.dart';
import 'quests_screen.dart';
import 'storage_screen.dart';

class GuildScreen extends StatelessWidget {
  const GuildScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Доброе утро';
    if (hour < 18) return 'Добрый день';
    return 'Добрый вечер';
  }

  @override
  Widget build(BuildContext context) {
    final player = PlayerRepository.instance;
    final points =
        (player.data?['guild_quest_points'] as num?)?.toInt() ?? 0;
    final navButtons = [
      ('📋 ДОСКА ЗАДАНИЙ',
          () => pushModuleWindow(context, const QuestsScreen(board: true))),
      ('⚔️ АРЕНА', () => pushModuleWindow(context, const ArenaScreen())),
      ('🏆 ЗАЛ СЛАВЫ', () => pushModuleWindow(context, const HallScreen())),
      ('📦 ХРАНИЛИЩЕ', () => pushModuleWindow(context, const StorageScreen())),
    ];

    return ModuleWindow(
      title: '🏰 ГИЛЬДИЯ АВАНТЮРИСТОВ 🏰',
      child: Column(
        children: [
          Row(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('👑', style: TextStyle(fontSize: 44)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Мастер Альдрик',
                        style: TextStyle(color: kGoldColor, fontSize: 18)),
                    Text(
                      '${_greeting()}, ${player.name}! Чем могу помочь?',
                      style: const TextStyle(
                          color: Color(0xFFE5E5E5), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 15,
              runSpacing: 10,
              children: [
                for (final (label, open) in navButtons)
                  OutlinedButton(
                    onPressed: open,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0x80FFD700), width: 1),
                      backgroundColor: const Color(0xFF221D18),
                      minimumSize: const Size(160, 45),
                    ),
                    child: Text(label,
                        style: const TextStyle(
                            color: kGoldColor, fontSize: 13)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xE61F1A14),
                border: Border.all(color: const Color(0x33FFD700)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  '🏪\n\nЗдесь ты можешь:\n\n📋 Брать задания на Доске\n⚔️ Сражаться на Арене\n🏆 Попасть в Зал Славы\n📦 Пользоваться Хранилищем',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 14),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text('🎖 Очки заданий: $points',
                style: const TextStyle(color: kGoldColor, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
