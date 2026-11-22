import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../main.dart';
import '../services/items_catalog.dart';
import '../services/player_repository.dart';
import '../services/resource_service.dart';
import '../widgets/game_image.dart';
import '../widgets/module_window.dart';

Map<String, dynamic> _itemInfo(Map<String, dynamic> instance) {
  final id = instance['id']?.toString() ?? '';
  final fromDb = ItemsCatalog.instance.itemById(id);
  if (fromDb.isNotEmpty) return fromDb;
  return {
    'name': instance['name']?.toString() ?? id,
    'icon': instance['icon']?.toString() ?? '📤',
    'type': instance['type']?.toString() ?? 'material',
    'level': instance['level'] ?? 1,
    'description': instance['description']?.toString() ?? 'Трофей.',
    'durability': instance['durability'] ?? -1,
    'price': instance['price'] ?? 0,
    'requirements': instance['requirements'] ?? const {},
    'bonuses': instance['bonuses'] ?? const {},
  };
}

const Color _okColor = Color(0xFF00FF00);
const Color _badColor = Color(0xFFFF0000);
const Color _bonusColor = Color(0xFF80FF80);

const Map<String, String> _bonusNames = {
  'attack': 'Атака',
  'defense': 'Защита',
  'hp_restore': 'Восстановление HP',
  'mana_restore': 'Восстановление маны',
  'max_hp': 'Максимум HP',
  'crit_chance': 'Шанс крита',
  'crit_damage': 'Крит. урон',
  'evasion': 'Уклонение',
  'magic_find': 'Маг. фаинд',
  'exp_bonus': 'Бонус опыта',
  'gold_bonus': 'Бонус золота',
};

Widget _itemIconW(String? icon, double fontSize, {double? box}) {
  final iconText = (icon == null || icon.isEmpty) ? '📦' : icon;
  if (iconText.startsWith('http')) {
    return GameImage(iconText,
        width: box ?? fontSize * 1.4,
        height: box ?? fontSize * 1.4,
        fit: BoxFit.contain);
  }
  return Text(iconText, style: TextStyle(fontSize: fontSize));
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

  bool _canEquip(Map<String, dynamic> info) {
    final player = PlayerRepository.instance;
    if ((info['type']?.toString() ?? '') != 'equipment') return false;
    final playerLevel =
        (player.data?['level'] as num?)?.toInt() ?? 1;
    final itemLevel = (info['level'] as num?)?.toInt() ?? 1;
    if (playerLevel < itemLevel) return false;
    final stats = player.statsMap;
    final reqs = (info['requirements'] as Map<String, dynamic>?) ?? const {};
    for (final key in reqs.keys) {
      final need = (reqs[key] as num?)?.toInt() ?? 0;
      final have = (stats[key] as num?)?.toInt() ?? 0;
      if (have < need) return false;
    }
    return true;
  }

  List<dynamic> _inventoryWithout(List<dynamic> inv, int index, int count) {
    final entry =
        (inv[index] as Map<String, dynamic>? ?? const {}).cast<String, dynamic>();
    final qty = (entry['quantity'] as num?)?.toInt() ?? 1;
    final newInv = List<dynamic>.from(inv);
    if (qty - count <= 0) {
      newInv.removeAt(index);
    } else {
      newInv[index] = {...entry, 'quantity': qty - count};
    }
    return newInv;
  }

  Future<void> _consumeItem(
      BuildContext context, int index, Map<String, dynamic> info) async {
    final player = PlayerRepository.instance;
    final inv = _inventoryWithout(player.inventory, index, 1);
    await player.replaceInventory(inv);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Использовано: ${info['name']}')));
    }
  }

  Future<void> _placeInQuickSlot(
      BuildContext context, int index, Map<String, dynamic> info) async {
    final player = PlayerRepository.instance;
    final equipment =
        Map<String, dynamic>.from(player.data?['equipment'] ?? const {});
    final entry = (player.inventory[index] as Map<String, dynamic>? ?? const {})
        .cast<String, dynamic>();
    String? target;
    for (var i = 0; i < 4; i++) {
      if (equipment['quick$i'] == null) {
        target = 'quick$i';
        break;
      }
    }
    if (target == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Слоты расходников заняты')));
      }
      return;
    }
    equipment[target] = {
      'id': entry['id'],
      'quantity': (entry['quantity'] as num?)?.toInt() ?? 1,
      'icon': info['icon'],
      'name': info['name'],
    };
    await player.replaceEquipment(equipment);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${info['name']} → в слот расходников')));
    }
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

  Future<void> _drop(BuildContext context, int index) async {
    final player = PlayerRepository.instance;
    final inv = _inventoryWithout(player.inventory, index, 1);
    await player.replaceInventory(inv);
  }

  void _showItemDetail(
    BuildContext context, {
    required Map<String, dynamic> instance,
    required Map<String, dynamic> info,
    required bool equipped,
    dynamic equippedItem,
    int? index,
    String? slotKey,
  }) {
    final player = PlayerRepository.instance;
    final playerLevel = (player.data?['level'] as num?)?.toInt() ?? 1;
    final itemLevel = (info['level'] as num?)?.toInt() ?? 1;
    final reqs = (info['requirements'] as Map<String, dynamic>?) ?? const {};
    final bonuses = (info['bonuses'] as Map<String, dynamic>?) ?? const {};
    final stats = player.statsMap;
    final type = info['type']?.toString() ?? '';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 440,
          constraints: const BoxConstraints(maxHeight: 430),
          decoration: BoxDecoration(
            color: const Color(0xFA1A1A1A),
            border: Border.all(color: kGoldColor.withOpacity(0.8), width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _itemIconW(info['icon']?.toString(), 30,
                            box: 40),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(info['name']?.toString() ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: kGoldColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600)),
                        ),
                        // (иконка показана отдельно в слоте заголовка)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close, color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Уровень предмета: $itemLevel',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('Ваш уровень: $playerLevel / $itemLevel',
                        style: TextStyle(
                            color: playerLevel >= itemLevel
                                ? _okColor
                                : _badColor,
                            fontSize: 14)),
                    if (reqs.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      const Text('Требования:',
                          style: TextStyle(
                              color: kGoldColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      for (final key in reqs.keys)
                        () {
                          final need =
                              (reqs[key] as num?)?.toInt() ?? 0;
                          final have =
                              (stats[key] as num?)?.toInt() ?? 0;
                          final ok = have >= need;
                          return Text(
                              '${playerStatNames[key] ?? key}: $have / $need',
                              style: TextStyle(
                                  color: ok ? _okColor : _badColor,
                                  fontSize: 14));
                        }(),
                    ],
                    if (bonuses.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      const Text('Бонусы:',
                          style: TextStyle(
                              color: kGoldColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      for (final key in bonuses.keys)
                        Text(
                            '${_bonusNames[key] ?? key}: +${bonuses[key]}',
                            style: const TextStyle(
                                color: _bonusColor, fontSize: 14)),
                    ],
                    const SizedBox(height: 6),
                    Text(info['description']?.toString() ?? '',
                        softWrap: true,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (equipped)
                          _detailButton('СНЯТЬ', () {
                            Navigator.pop(ctx);
                            _unequip(
                                context, slotKey!, equippedItem ?? instance);
                          })
                        else ...[
                          if (type == 'equipment')
                            _detailButton(
                                'НАДЕТЬ',
                                index == null
                                    ? null
                                    : () {
                                        Navigator.pop(ctx);
                                        _equip(
                                            context, index, instance, info);
                                      },
                                disabled: !_canEquip(info)),
                          if (type == 'consumable' &&
                              bonuses.containsKey('hp_restore'))
                            _detailButton('ИСПОЛЬЗОВАТЬ', index == null
                                ? null
                                : () {
                                    Navigator.pop(ctx);
                                    _consumeItem(
                                        context, index, info);
                                  }),
                          if (type == 'consumable' &&
                              !bonuses.containsKey('hp_restore'))
                            _detailButton('В СЛОТ', index == null
                                ? null
                                : () {
                                    Navigator.pop(ctx);
                                    _placeInQuickSlot(
                                        context, index, info);
                                  }),
                          _detailButton('ВЫБРОСИТЬ', index == null
                              ? null
                              : () {
                                  Navigator.pop(ctx);
                                  _drop(context, index);
                                }),
                        ],
                        const SizedBox(width: 10),
                        _detailButton('ОТМЕНА', () => Navigator.pop(ctx)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    );
  }

  Widget _detailButton(String label, VoidCallback? onPressed,
      {bool disabled = false}) {
    final enabled = onPressed != null && !disabled;
    return SizedBox(
      height: 35,
      child: TextButton(
        onPressed: enabled ? onPressed : null,
        style: TextButton.styleFrom(
          backgroundColor:
              enabled ? const Color(0xFF2A2A2A) : Colors.transparent,
          side: BorderSide(
              color: enabled
                  ? kGoldColor.withOpacity(0.7)
                  : Colors.white24),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Text(label,
            style: TextStyle(
                color: enabled ? Colors.white : Colors.white30,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ),
    );
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
              ? () => _showItemDetail(
                  context,
                  instance: equipped is Map<String, dynamic>
                      ? equipped
                      : const {},
                  info: info0,
                  equipped: true,
                  equippedItem: equipped,
                  slotKey: slotKey)
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
    return GestureDetector(
      onTap: () => _showItemDetail(context,
          instance: instance,
          info: info,
          equipped: false,
          index: index),
      child: Container(
        width: 95,
        height: 105,
        decoration: BoxDecoration(
          border: Border.all(color: kGoldColor.withOpacity(0.55)),
          borderRadius: BorderRadius.circular(8),
          color: const Color(0x33221D18),
        ),
        padding: const EdgeInsets.all(4),
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
                      color: Colors.white, fontSize: 11)),
            ),
            Center(
              child: _itemIconW(info['icon']?.toString(), 26,
                  box: 34),
            ),
            if (qty > 1)
              Positioned(
                bottom: 0,
                right: 2,
                child: Text('x$qty',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11)),
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
    final look = player.data?['look']?.toString() ?? '';

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
                child: look.isNotEmpty &&
                        ResourceService.instance.filePath(look) != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child:
                            GameImage(look, fit: BoxFit.cover))
                    : const Center(
                        child: Text('🧍',
                            style: TextStyle(
                                fontSize: 40,
                                color: Colors.white24)),
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
                          LayoutBuilder(builder: (context, c) {
                            final cellW = 95 + 8;
                            final cols =
                                (c.maxWidth / cellW).floor().clamp(1, 6);
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: cols,
                                      mainAxisSpacing: 8,
                                      crossAxisSpacing: 8,
                                      childAspectRatio: 95 / 105),
                              itemCount: inventory.length,
                              itemBuilder: (context, i) => _itemCell(
                                  context,
                                  i,
                                  inventory[i] as Map<String, dynamic>? ??
                                      const {}),
                            );
                          }),
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
