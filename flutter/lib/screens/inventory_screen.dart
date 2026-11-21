import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../main.dart';
import '../services/player_repository.dart';
import '../widgets/module_window.dart';

Map<String, dynamic> _itemInfo(Map<String, dynamic> instance) {
  final id = instance['id']?.toString() ?? '';
  final fromDb = itemDb[id] as Map<String, dynamic>?;
  if (fromDb != null) return fromDb;
  return {
    'name': instance['name']?.toString() ?? id,
    'icon': instance['icon']?.toString() ?? '📦',
    'type': instance['type']?.toString() ?? 'material',
    'level': instance['level'] ?? 1,
    'description': instance['description']?.toString() ?? 'Трофей.',
    'durability': instance['durability'] ?? -1,
    'price': instance['price'] ?? 0,
    'requirements': const {},
    'bonuses': instance['bonuses'] ?? const {},
  };
}

const Map<String, String> slotNames = {
  'weapon': 'Оружие',
  'armor': 'Броня',
  'helmet': 'Шлем',
  'boots': 'Обувь',
  'ring': 'Кольцо',
  'amulet': 'Амулет',
};

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  Future<void> _action(
      BuildContext context, String text, VoidCallback onYes) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        content: Text(text,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена',
                  style: TextStyle(color: Colors.white70))),
          TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                onYes();
              },
              child: const Text('Да', style: TextStyle(color: kGoldColor))),
        ],
      ),
    );
  }

  Future<void> _equip(BuildContext context, int index,
      Map<String, dynamic> instance, Map<String, dynamic> info) async {
    final player = PlayerRepository.instance;
    final slot = info['slot']?.toString() ?? 'weapon';
    final equipment =
        Map<String, dynamic>.from(player.data?['equipment'] ?? const {});
    final newInv = List<dynamic>.from(player.inventory);
    final previous = equipment[slot];
    final instanceSnapshot = {
      ...instance,
      'icon': info['icon'],
      'name': info['name'],
      'level': info['level'],
      'type': info['type'],
      'slot': info['slot'],
      'description': info['description'],
      'durability': info['durability'],
      'price': info['price'],
      'requirements': info['requirements'],
      'bonuses': info['bonuses'],
    };
    equipment[slot] = instanceSnapshot;
    if (previous != null && previous is Map<String, dynamic>) {
      newInv.add(previous);
    }
    newInv.removeAt(index);
    await player.replaceInventory(newInv);
    await player.replaceEquipment(equipment);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Надето: ${info['name']} • $slot')));
    }
  }

  Future<void> _unequip(BuildContext context, String slot, dynamic equipped) async {
    final player = PlayerRepository.instance;
    if (equipped == null) return;
    final equipment =
        Map<String, dynamic>.from(player.data?['equipment'] ?? const {});
    equipment.remove(slot);
    final newInv = List<dynamic>.from(player.inventory)..add(equipped);
    await player.replaceInventory(newInv);
    await player.replaceEquipment(equipment);
  }

  Future<void> _sell(BuildContext context, int index,
      Map<String, dynamic> instance, Map<String, dynamic> info) async {
    final player = PlayerRepository.instance;
    final fullPrice = (info['price'] as num?)?.toInt() ?? 0;
    final price = fullPrice ~/ 2;
    if (price <= 0) return;
    final newInv = List<dynamic>.from(player.inventory)..removeAt(index);
    await player.replaceInventory(newInv);
    await player.spendCurrency(gold: -price, rune: 0);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Продано «${info['name']}» за $price 💰')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = PlayerRepository.instance;
    final inventory = player.inventory;
    final equipment = (player.data?['equipment'] as Map<String, dynamic>?) ?? {};

    Widget invCard(int index) {
      final instance = inventory[index] as Map<String, dynamic>? ?? const {};
      final info = _itemInfo(instance);
      final type = info['type']?.toString() ?? '';
      final bonuses = bonusesLine(info['bonuses'] as Map<dynamic, dynamic>? ?? {});
      final dur = (info['durability'] as num?)?.toInt() ?? -1;
      return GameCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(info['icon']?.toString() ?? '📦',
                    style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                      '${info['name']} [Ур.${info['level'] ?? 1}]',
                      style: const TextStyle(
                          color: kGoldColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(info['description']?.toString() ?? '',
                style: const TextStyle(
                    color: Color(0xFFCCCCCC), fontSize: 12)),
            if (bonuses.isNotEmpty)
              Text(bonuses,
                  style: const TextStyle(
                      color: Color(0xFF80FF80), fontSize: 12)),
            if (dur >= 0)
              Text('Прочность: $dur',
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (type == 'equipment')
                  TextButton(
                    onPressed: () => _action(
                        context,
                        'Надеть «${info['name']}»?',
                        () => _equip(context, index,
                            instance, info)).then((_) {}),
                    child: const Text('Надеть',
                        style: TextStyle(color: kGoldColor)),
                  ),
                if (type == 'consumable')
                  TextButton(
                    onPressed: () => _action(
                        context,
                        'Использовать «${info['name']}»?',
                        () async {
                          final p = PlayerRepository.instance;
                          final inv = List<dynamic>.from(p.inventory)
                            ..removeAt(index);
                          await p.replaceInventory(inv);
                        }),
                    child: const Text('Использовать',
                        style: TextStyle(color: kGoldColor)),
                  ),
                if (type == 'material' &&
                    ((info['price'] as num?)?.toInt() ?? 0) > 0)
                  TextButton(
                    onPressed: () => _action(
                        context,
                        'Продать «${info['name']}» за ${(itemInt(info, 'price')) ~/ 2} золота?',
                        () => _sell(context, index, instance, info)),
                    child: const Text('Продать',
                        style: TextStyle(color: kGoldColor)),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    return ModuleWindow(
      title: '🎒 Рюкзак',
      child: inventory.isEmpty && equipment.isEmpty
          ? const Center(
              child: Text('Рюкзак пуст',
                  style: TextStyle(color: Colors.white54, fontSize: 16)))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (equipment.isNotEmpty) ...[
                  const Text('Надето',
                      style: TextStyle(
                          color: kGoldColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  for (final slot in equipment.keys.toList())
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: GameCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                  '${slotNames[slot] ?? slot}: ${_itemInfo(equipment[slot] as Map<String, dynamic>? ?? const {})['name']}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14)),
                            ),
                            TextButton(
                              onPressed: () => _unequip(context, slot, equipment[slot]),
                              child: const Text('Снять',
                                  style: TextStyle(color: kGoldColor)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                ],
                for (var i = 0; i < inventory.length; i++) ...[
                  invCard(i),
                  const SizedBox(height: 6),
                ],
              ],
            ),
    );
  }
}
