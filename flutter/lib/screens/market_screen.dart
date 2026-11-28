import 'dart:math';

import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../main.dart';
import '../services/items_catalog.dart';
import '../services/player_repository.dart';
import '../widgets/game_image.dart';
import '../widgets/module_window.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  late final String _greeting =
      marketGreetings[Random().nextInt(marketGreetings.length)];

  Map<String, dynamic> _infoOf(String id) {
    return ItemsCatalog.instance.itemById(id);
  }

  List<MapEntry<String, Map<String, dynamic>>> _shopList() {
    return ItemsCatalog.instance.shopEntries().entries
        .where((e) =>
            ((e.value['price_gold'] as num?)?.toInt() ?? 0) > 0 ||
            ((e.value['price_rune'] as num?)?.toInt() ?? 0) > 0)
        .toList();
  }

  /// Почему кнопку покупки нельзя нажать — чтобы игрок понимал, а не гадал.
  String? _buyBlockReason(Map<String, dynamic> info, Mode mode) {
    final player = PlayerRepository.instance;
    final stats = player.statsMap;
    final level = player.level;
    final reqs = info['requirements'] as Map<dynamic, dynamic>? ?? const {};
    for (final e in reqs.entries) {
      if (e.key == 'level') {
        final need = (e.value as num?)?.toInt() ?? 0;
        if (level < need) return 'Требуется уровень $need';
        continue;
      }
      final need = (e.value as num?)?.toInt() ?? 0;
      final have = (stats[e.key] as num?)?.toInt() ?? 0;
      if (have < need) return '${playerStatNames[e.key] ?? e.key}: $need (у вас $have)';
    }
    final price = mode == Mode.gold
        ? ((info['price_gold'] as num?)?.toInt() ?? 0)
        : ((info['price_rune'] as num?)?.toInt() ?? 0);
    final balance = mode == Mode.gold ? player.gold : player.rune;
    if (balance < price) {
      return mode == Mode.gold ? 'Не хватает золота' : 'Не хватает рун';
    }
    return null;
  }

  Mode _mode = Mode.gold;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _buy(String id, Map<String, dynamic> info) async {
    final player = PlayerRepository.instance;
    final goldPrice = (info['price_gold'] as num?)?.toInt() ?? 0;
    final runePrice = (info['price_rune'] as num?)?.toInt() ?? 0;
    final payGold = _mode == Mode.gold ? goldPrice : 0;
    final payRune = _mode == Mode.gold ? 0 : runePrice;

    final reason = _buyBlockReason(info, _mode);
    if (reason != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(reason)));
      }
      return;
    }
    final ok = await player.spendCurrency(gold: payGold, rune: payRune);
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Недостаточно средств')));
      }
      return;
    }
    await player.addInventoryItem({
      'id': id,
      'icon': info['icon'] ?? '📦',
      'name': info['name'],
      'level': info['level'] ?? 1,
      'type': info['type'],
      'slot': info['slot'],
      'description': info['description'],
      'durability': info['durability'] ?? -1,
      'price': _mode == Mode.gold ? goldPrice : runePrice,
      'requirements': info['requirements'] ?? const {},
      'bonuses': info['bonuses'] ?? const {},
    });
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Куплено: ${info['name']}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = PlayerRepository.instance;
    final inventory = player.inventory;

    final shopList = _shopList();
    final goldItems = shopList
        .where((e) =>
            ((e.value['price_gold'] as num?)?.toInt() ?? 0) > 0)
        .toList();
    final runeItems = shopList
        .where((e) =>
            ((e.value['price_rune'] as num?)?.toInt() ?? 0) > 0)
        .toList();

    return ModuleWindow(
      title: '💰 Лавка',
      child: Column(
        children: [
          // Шапка с балансом — сразу видно сколько денег.
          Container(
            margin: const EdgeInsets.fromLTRB(10, 8, 10, 2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0x33FFD700),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kGoldColor.withOpacity(0.45)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('💰 ${player.gold} зол.',
                    style: const TextStyle(
                        color: kGoldColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 24),
                Text('🔮 ${player.rune} рун',
                    style: const TextStyle(
                        color: kRuneBlue,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 24),
                TextButton(
                  onPressed: () =>
                      setState(() => _mode = _mode == Mode.gold ? Mode.rune : Mode.gold),
                  child: Text(
                    _mode == Mode.gold ? 'валюта: золото 💰' : 'валюта: руны 🔮',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text('«$_greeting»',
                style:
                    const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13)),
          ),
          TabBar(
            controller: _tabs,
            // Товары — за золото, Руны — за руны: валюта таба = валюта покупки.
            onTap: (i) => setState(() {
              if (i == 0) _mode = Mode.gold;
              if (i == 1) _mode = Mode.rune;
            }),
            labelColor: kGoldColor,
            unselectedLabelColor: Colors.white54,
            indicatorColor: kGoldColor,
            tabs: const [
              Tab(text: 'Товары'),
              Tab(text: 'Руны'),
              Tab(text: 'Продажа'),
            ],
            isScrollable: true,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _tab(goldItems),
                _tab(runeItems),
                ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (var i = 0; i < inventory.length; i++)
                      _sellRow(context, i),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(List<MapEntry<String, Map<String, dynamic>>> items) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
                child: Text('Нет товаров за эту валюту',
                    style: TextStyle(color: Colors.white54, fontSize: 13))),
          ),
        for (final e in items) ...[
          _itemCard(e.key),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Color _rarityColor(String? rarity) {
    switch (rarity) {
      case 'редкий':
        return const Color(0xFF66CCFF);
      case 'легендарный':
        return const Color(0xFFFFB347);
      case 'эпический':
        return const Color(0xFFCC66FF);
      default:
        return const Color(0xFFCCCCCC);
    }
  }

  Widget _itemIcon(String icon, double size) {
    if (icon.startsWith('http')) {
      return GameImage(icon, width: size, height: size, fit: BoxFit.contain);
    }
    return Text(icon, style: TextStyle(fontSize: size));
  }

  Widget _itemCard(String id) {
    final info = _infoOf(id);
    final goldPrice = (info['price_gold'] as num?)?.toInt() ?? 0;
    final runePrice = (info['price_rune'] as num?)?.toInt() ?? 0;
    final price = _mode == Mode.gold ? goldPrice : runePrice;
    final reqs = info['requirements'] as Map<dynamic, dynamic>? ?? const {};
    final bonuses = bonusesLine(
        info['bonuses'] as Map<dynamic, dynamic>? ?? const {});
    final reason = _buyBlockReason(info, _mode);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xE61A1613),
        border: Border.all(color: kGoldColor.withOpacity(0.55), width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Крупная иконка в рамке — слева, как витрина товара.
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0x33221D18),
              border: Border.all(
                  color: _rarityColor(info['rarity']?.toString()), width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
                child:
                    _itemIcon(info['icon']?.toString() ?? '📦', 30)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${info['name']}  [Ур.${info['level'] ?? 1}]',
                    style: const TextStyle(
                        color: kGoldColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                if ((info['rarity'] ?? '').toString().isNotEmpty)
                  Text(info['rarity'].toString(),
                      style: TextStyle(
                          color: _rarityColor(info['rarity']?.toString()),
                          fontSize: 12)),
                if ((info['description'] ?? '').toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(info['description'].toString(),
                        style: const TextStyle(
                            color: Color(0xFFCCCCCC), fontSize: 12)),
                  ),
                if (bonuses.isNotEmpty)
                  Text(bonuses,
                      style: const TextStyle(
                          color: Color(0xFF80FF80), fontSize: 12)),
                if (reqs.isNotEmpty)
                  Text(
                    reqs.entries
                        .map((e) => '${playerStatNames[e.key] ?? 'Ур.'} ${e.value}')
                        .join(', '),
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    SizedBox(
                      height: 34,
                      child: OutlinedButton(
                        onPressed: reason == null
                            ? () => _buy(id, info)
                            : null,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: reason == null
                                  ? kGoldColor
                                  : kGoldColor.withOpacity(0.25)),
                        ),
                        child: Text(
                          reason ??
                              'Купить за $price ${_mode == Mode.gold ? '💰' : '🔮'}',
                          style: TextStyle(
                            color: reason == null
                                ? kGoldColor
                                : const Color(0xFFFF6B6B),
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ),
                    if (reason == null) ...[
                      const SizedBox(width: 8),
                      Text(
                        'доступно ✅',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sellRow(BuildContext context, int index) {
    final player = PlayerRepository.instance;
    final instance = player.inventory[index] as Map<String, dynamic>? ?? const {};
    final fromDb = ItemsCatalog.instance.itemById(instance['id']?.toString() ?? '');
    final info = {...fromDb, ...instance};
    final sellPrice = ((info['price'] as num?)?.toInt() ?? 0) ~/ 2;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xE61A1613),
        border: Border.all(color: kGoldColor.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0x33221D18),
              border: Border.all(
                  color: _rarityColor(info['rarity']?.toString()), width: 1.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
                child: _itemIcon(info['icon']?.toString() ?? '📦', 24)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(info['name']?.toString() ?? '',
                style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          TextButton(
            onPressed: sellPrice <= 0
                ? null
                : () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1A1A),
                        content: Text(
                            'Продать «${info['name']}» за $sellPrice золота?',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14)),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Отмена',
                                  style: TextStyle(color: Colors.white70))),
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Продать',
                                  style: TextStyle(color: kGoldColor))),
                        ],
                      ),
                    );
                    if (ok == true) {
                      final p = PlayerRepository.instance;
                      final inv = List<dynamic>.from(p.inventory)
                        ..removeAt(index);
                      await p.replaceInventory(inv);
                      await p.spendCurrency(gold: -sellPrice, rune: 0);
                      if (mounted) {
                        setState(() {});
                      }
                    }
                  },
            child: Text('Продать за $sellPrice 💰',
                style: const TextStyle(color: kGoldColor, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

enum Mode { gold, rune }
