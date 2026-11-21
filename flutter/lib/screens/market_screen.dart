import 'dart:math';

import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../main.dart';
import '../services/player_repository.dart';
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
    final custom = shopItems[id] as Map<String, dynamic>? ?? const {};
    final fromDb = itemDb[id] as Map<String, dynamic>?;
    return {
      ...?fromDb,
      ...custom,
    };
  }

  bool _meetsRequirements(Map<String, dynamic> info, int level) {
    final reqs = info['requirements'] as Map<dynamic, dynamic>? ?? const {};
    final stats = PlayerRepository.instance.statsMap;
    for (final e in reqs.entries) {
      if (e.key == 'level') {
        if (level < ((e.value as num?)?.toInt() ?? 0)) return false;
        continue;
      }
      final have = (stats[e.key] as num?)?.toInt() ?? 0;
      if (have < ((e.value as num?)?.toInt() ?? 0)) return false;
    }
    return true;
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

    if (!_meetsRequirements(info, player.level)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Не выполнены требования предмета')));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Куплено: ${info['name']}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = PlayerRepository.instance;
    final inventory = player.inventory;

    final runeItems = shopItems.entries
        .where((e) =>
            (((e.value as Map<String, dynamic>)['price_rune'] as num?)
                    ?.toInt() ??
                0) >
            0)
        .toList();

    return ModuleWindow(
      title: '💰 Лавка',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text('«$_greeting»',
                style:
                    const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13)),
          ),
          TabBar(
            controller: _tabs,
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
                _buildItemList(shopItems.entries
                    .where((e) =>
                        ((e.value as Map<String, dynamic>)['price_gold'] as num?)
                                ?.toInt() !=
                            0)
                    .toList()),
                _buildItemList(runeItems),
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

  Widget _buildItemList(List<MapEntry<String, dynamic>> items) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final e in items) ...[
          _itemCard(e.key),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  Widget _itemCard(String id) {
    final info = _infoOf(id);
    final goldPrice = (info['price_gold'] as num?)?.toInt() ?? 0;
    final runePrice = (info['price_rune'] as num?)?.toInt() ?? 0;
    final reqs = info['requirements'] as Map<dynamic, dynamic>? ?? const {};
    final reqLine = reqs.entries
        .map((e) =>
            '${playerStatNames[e.key] ?? 'Ур.'} ${e.value}')
        .join(', ');
    final bonuses = bonusesLine(
        info['bonuses'] as Map<dynamic, dynamic>? ?? const {});

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
                    '${info['name']} [Ур.${info['level'] ?? 1}] • ${info['rarity'] ?? ''}',
                    style: const TextStyle(
                        color: kGoldColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          Text(info['description']?.toString() ?? '',
              style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 12)),
          if (bonuses.isNotEmpty)
            Text(bonuses,
                style: const TextStyle(
                    color: Color(0xFF80FF80), fontSize: 12)),
          if (reqLine.isNotEmpty)
            Text('Требуется: $reqLine',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (goldPrice > 0)
                TextButton(
                    onPressed: () {
                      setState(() => _mode = Mode.gold);
                      _buy(id, info);
                    },
                    child: Text('Купить за $goldPrice 💰',
                        style: const TextStyle(color: kGoldColor))),
              if (runePrice > 0)
                TextButton(
                    onPressed: () {
                      setState(() => _mode = Mode.rune);
                      _buy(id, info);
                    },
                    child: Text('Купить за $runePrice 🔮',
                        style: const TextStyle(color: kRuneBlue))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sellRow(BuildContext context, int index) {
    final player = PlayerRepository.instance;
    final instance = player.inventory[index] as Map<String, dynamic>? ?? const {};
    final fromDb = itemDb[instance['id']] as Map<String, dynamic>?;
    final info = {...?fromDb, ...instance};
    final sellPrice = ((info['price'] as num?)?.toInt() ?? 0) ~/ 2;
    return GameCard(
      child: Row(
        children: [
          Text(info['icon']?.toString() ?? '📦',
              style: const TextStyle(fontSize: 22)),
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
