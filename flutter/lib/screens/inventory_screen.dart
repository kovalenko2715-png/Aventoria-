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

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  static const Map<String, String> slotLabels = {
    'wings': 'Крылья',
    'bracelet': 'Браслет',
    'mask': 'Маска',
    'helmet': 'Шлем',
    'armor': 'Броня',
    'gloves': 'Перчатки',
    'weapon': 'Оружие',
    'pants': 'Штаны',
    'boots': 'Обувь',
    'cloak': 'Плащ',
    'necklace': 'Ожерелье',
    'earring1': 'Серьга',
    'earring2': 'Серьга',
    'shield': 'Щит',
    'shirt': 'Рубаха',
    'belt': 'Пояс',
    'ring1': 'Кольцо',
    'ring2': 'Кольцо',
    'bag': 'Сумка',
    'rune': 'Руна',
  };

  Future<void> _action(
      BuildContext context, String text, VoidCallback onYes) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        content: Text(text,
            style: const TextStyle(color: Colors.white, fontSize: 13)),
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

  Widget _slot(BuildContext context, String slotKey, double size) {
    final player = PlayerRepository.instance;
    final equipment =
        (player.data?['equipment'] as Map<String, dynamic>?) ?? const {};
    final equipped = equipment[slotKey];
    final label = slotLabels[slotKey] ?? slotKey;
    final info0 = equipped is Map<String, dynamic> ? _itemInfo(equipped) : null;
    final has = info0 != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: has
              ? () => _action(
                  context,
                  'Снять «${info0['name']}»?',
                  () => _unequip(context, slotKey, equipped))
              : null,
          customBorder: const CircleBorder(),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              border: Border.all(
                  color: has
                      ? kGoldColor
                      : kGoldColor.withOpacity(0.45),
                  width: has ? 2 : 1.2),
              borderRadius: BorderRadius.circular(8),
              color: const Color(0x33221D18),
            ),
            child: Center(
              child: Text(has ? '${info0['icon']}' : '',
                  style: TextStyle(
                      fontSize: size * 0.48,
                      color: Colors.white)),
            ),
          ),
        ),
        const SizedBox(height: 1),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 8)),
      ],
    );
  }

  Widget _itemCell(BuildContext context, int index,
      Map<String, dynamic> instance) {
    final info = _itemInfo(instance);
    final qty = (instance['quantity'] as num?)?.toInt() ?? 1;
    final type = info['type']?.toString() ?? '';
    return GestureDetector(
      onTap: () {
        if (type == 'equipment') {
          _action(context, 'Надеть «${info['name']}»?',
              () => _equip(context, index, instance, info));
        } else if (type == 'consumable') {
          _action(context, 'Использовать «${info['name']}»?', () async {
            final p = PlayerRepository.instance;
            final inv = List<dynamic>.from(p.inventory)..removeAt(index);
            await p.replaceInventory(inv);
          });
        } else if (((info['price'] as num?)?.toInt() ?? 0) > 0) {
          _action(
              context,
              'Продать «${info['name']}» за ${((info['price'] as num?)?.toInt() ?? 0) ~/ 2} золота?',
              () => _sell(context, index, instance, info));
        }
      },
      child: Container(
        width: 72,
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(color: kGoldColor.withOpacity(0.55)),
          borderRadius: BorderRadius.circular(8),
          color: const Color(0x33221D18),
        ),
        padding: const EdgeInsets.all(3),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Text(info['name']?.toString() ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 8)),
            ),
            Center(
              child: Text(info['icon']?.toString() ?? '📦',
                  style: const TextStyle(fontSize: 24)),
            ),
            if (qty > 1)
              Positioned(
                bottom: 0,
                right: 1,
                child: Text('x$qty',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 9)),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = PlayerRepository.instance;
    final inventory = player.inventory;
    final equipment =
        (player.data?['equipment'] as Map<String, dynamic>?) ?? {};

    Widget equipColumn() {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _slot(context, 'wings', 44),
              const SizedBox(width: 4),
              _slot(context, 'bracelet', 44),
              const SizedBox(width: 4),
              _slot(context, 'mask', 44),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final k in ['helmet', 'armor', 'gloves',
                      'weapon', 'pants', 'boots']) ...[
                    _slot(context, k, 44),
                    const SizedBox(height: 2),
                  ],
                ],
              ),
              const SizedBox(width: 4),
              Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: kGoldColor, width: 2),
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0x33221D18),
                ),
                child: const Center(
                  child: Text('🧍',
                      style: TextStyle(fontSize: 40, color: Colors.white24)),
                ),
              ),
              const SizedBox(width: 4),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final k in ['cloak', 'necklace']) ...[
                    _slot(context, k, 44),
                    const SizedBox(height: 2),
                  ],
                  Row(
                    children: [
                      _slot(context, 'earring1', 28),
                      const SizedBox(width: 2),
                      _slot(context, 'earring2', 28),
                    ],
                  ),
                  const SizedBox(height: 2),
                  for (final k in ['shield', 'shirt', 'belt']) ...[
                    _slot(context, k, 44),
                    const SizedBox(height: 2),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _slot(context, 'ring1', 44),
              const SizedBox(width: 4),
              _slot(context, 'ring2', 44),
              const SizedBox(width: 4),
              _slot(context, 'bag', 44),
              const SizedBox(width: 4),
              _slot(context, 'rune', 44),
            ],
          ),
          const SizedBox(height: 8),
          const Text('СЛОТЫ РАСХОДНИКОВ',
              style: TextStyle(
                  color: kGoldColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 4; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: kGoldColor.withOpacity(0.45)),
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0x33221D18),
                    ),
                    child: Text(
                        equipment['quick$i'] is Map
                            ? '${_itemInfo(equipment['quick$i'] as Map<String, dynamic>)['icon']}'
                            : '',
                        style: const TextStyle(fontSize: 18)),
                  ),
                ),
            ],
          ),
        ],
      );
    }

    return ModuleWindow(
      title: 'ИНВЕНТАРЬ',
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 385, child: equipColumn()),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 520,
                    child: Column(
                      children: [
                        const Text('ИНВЕНТАРЬ',
                            style: TextStyle(
                                color: kGoldColor,
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        if (inventory.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text('Инвентарь пуст',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 13)),
                          )
                        else
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (var i = 0; i < inventory.length; i++)
                                _itemCell(context, i,
                                    inventory[i] as Map<String, dynamic>? ??
                                        const {}),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
