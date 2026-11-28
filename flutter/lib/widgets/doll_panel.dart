import 'package:flutter/material.dart';

import '../main.dart';
import '../services/resource_service.dart';
import 'game_image.dart';

/// Подписи слотов экипировки (общие для инвентаря, профиля и боя).
const Map<String, String> dollSlotLabels = {
  'wings': 'Крылья',
  'bracelet': 'Браслет',
  'mask': 'Маска',
  'helmet': 'Шлем',
  'armor': 'Броня',
  'gloves': 'Перчатки',
  'weapon': 'Оружие',
  'weapon2': 'Оружие 2',
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

/// Кукла бойца: облик в центре + ВСЕ слоты экипировки вокруг, как в инвентаре
/// БК. Один виджет для инвентаря (интерактивные слоты) и профиля (обзор).
class DollPanel extends StatelessWidget {
  final Map<String, dynamic> equipment;
  final String look;
  final String fallbackIcon;
  final double slotSize;
  final double dollWidth;
  final double dollHeight;
  final bool showQuickSlots;
  final void Function(String slotKey)? onSlotTap;

  const DollPanel({
    super.key,
    required this.equipment,
    required this.look,
    this.fallbackIcon = '🧍',
    this.slotSize = 38,
    this.dollWidth = 170,
    this.dollHeight = 230,
    this.showQuickSlots = false,
    this.onSlotTap,
  });

  bool _hasLook(String look) {
    if (look.isEmpty) return false;
    if (look.startsWith('http')) return true;
    return ResourceService.instance.filePath(look) != null;
  }

  Widget _slot(BuildContext context, String slotKey, [double? sizeOverride]) {
    final size = sizeOverride ?? slotSize;
    final equipped = equipment[slotKey];
    final has = equipped is Map<String, dynamic>;
    final label = dollSlotLabels[slotKey] ?? slotKey;
    final icon = has ? (equipped['icon']?.toString() ?? '') : '';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: label,
          triggerMode: TooltipTriggerMode.longPress,
          child: InkWell(
            onTap: has && onSlotTap != null
                ? () => onSlotTap!(slotKey)
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
                child: has
                    ? (icon.startsWith('http')
                        ? GameImage(icon,
                            width: size * 0.75,
                            height: size * 0.75,
                            fit: BoxFit.contain)
                        : Text(icon, style: TextStyle(fontSize: size * 0.48)))
                    : Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: TextStyle(
                            fontSize: size * 0.22,
                            color: Colors.white38,
                            height: 0.9),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLook = _hasLook(look);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _slot(context, 'wings'),
            const SizedBox(width: 4),
            _slot(context, 'bracelet'),
            const SizedBox(width: 4),
            _slot(context, 'mask'),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final k in ['helmet', 'armor', 'gloves']) ...[
                  _slot(context, k),
                  const SizedBox(height: 2),
                ],
                Row(
                  children: [
                    _slot(context, 'weapon'),
                    const SizedBox(width: 2),
                    _slot(context, 'weapon2'),
                  ],
                ),
                const SizedBox(height: 2),
                for (final k in ['pants', 'boots']) ...[
                  _slot(context, k),
                  const SizedBox(height: 2),
                ],
              ],
            ),
            const SizedBox(width: 4),
            Container(
              width: dollWidth,
              height: dollHeight,
              decoration: BoxDecoration(
                border: Border.all(color: kGoldColor, width: 2),
                borderRadius: BorderRadius.circular(8),
                color: const Color(0x33221D18),
              ),
              child: hasLook
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: GameImage(look, fit: BoxFit.contain)))
                  : Center(
                      child: Text(fallbackIcon,
                          style: TextStyle(
                              fontSize: dollHeight * 0.25,
                              color: Colors.white24)),
                    ),
            ),
            const SizedBox(width: 4),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final k in ['cloak', 'necklace']) ...[
                  _slot(context, k),
                  const SizedBox(height: 2),
                ],
                Row(
                  children: [
                    _slot(context, 'earring1', slotSize * 0.74),
                    const SizedBox(width: 2),
                    _slot(context, 'earring2', slotSize * 0.74),
                  ],
                ),
                const SizedBox(height: 2),
                for (final k in ['shield', 'shirt', 'belt']) ...[
                  _slot(context, k),
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
            _slot(context, 'ring1'),
            const SizedBox(width: 4),
            _slot(context, 'ring2'),
            const SizedBox(width: 4),
            _slot(context, 'bag'),
            const SizedBox(width: 4),
            _slot(context, 'rune'),
          ],
        ),
      ],
    );
  }
}
