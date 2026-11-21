import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../main.dart';
import '../services/player_repository.dart';
import '../widgets/module_window.dart';

class TavernScreen extends StatefulWidget {
  const TavernScreen({super.key});

  @override
  State<TavernScreen> createState() => _TavernScreenState();
}

class _TavernScreenState extends State<TavernScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _buyBuff(BuildContext context, Map<String, dynamic> item,
      {required bool song}) async {
    final player = PlayerRepository.instance;
    final price = (item['price_gold'] as num?)?.toInt() ?? 0;
    final ok = await player.spendCurrency(gold: price, rune: 0);
    if (!ok) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Недостаточно золота')));
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final buff = {
      'name': item['name'],
      'buff_type': item['buff_type'],
      'buff_value': item['buff_value'],
      'expires_at': now + ((item['duration'] as num?)?.toInt() ?? 1800),
    };
    final buffs = {...(player.data?['tavern_buffs'] as Map<String, dynamic>? ?? const {})};
    buffs[song ? 'active_song_buff' : 'active_food_buff'] = buff;
    await player.replaceField('tavern_buffs', buffs);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Получен баф: +${item['buff_value']}${buffNames[item['buff_type']] ?? ''}')));
  }

  Future<void> _buyRumor(BuildContext context, String id,
      Map<String, dynamic> rumor) async {
    final player = PlayerRepository.instance;
    final purchased = List<dynamic>.from(
        player.data?['purchased_rumors'] as List<dynamic>? ?? const []);
    if (purchased.contains(id)) return;
    final price = (rumor['price'] as num?)?.toInt() ?? 0;
    final ok = await player.spendCurrency(gold: price, rune: 0);
    if (!ok) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Недостаточно золота')));
      return;
    }
    purchased.add(id);
    await player.replaceField('purchased_rumors', purchased);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Слух записан: ${rumor['name']}')));
  }

  @override
  Widget build(BuildContext context) {
    final player = PlayerRepository.instance;
    final purchased = (player.data?['purchased_rumors'] as List<dynamic>?)
            ?.cast<String>() ??
        const <String>[];

    return ModuleWindow(
      title: '🍺 Таверна',
      child: Column(
        children: [
          TabBar(
            controller: _tabs,
            labelColor: kGoldColor,
            unselectedLabelColor: Colors.white54,
            indicatorColor: kGoldColor,
            isScrollable: true,
            tabs: const [
              Tab(text: '🍲 Еда'),
              Tab(text: '🎵 Песни'),
              Tab(text: '👁️ Слухи'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _buffList(foodDb, song: false),
                _buffList(songsDb, song: true),
                _rumorsList(purchased),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buffList(Map<String, dynamic> db, {required bool song}) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final e in db.entries) ...[
          _buffCard(e.value as Map<String, dynamic>, song: song),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  Widget _buffCard(Map<String, dynamic> item, {required bool song}) {
    final price = (item['price_gold'] as num?)?.toInt() ?? 0;
    final minutes = ((item['duration'] as num?)?.toInt() ?? 1800) ~/ 60;
    return GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(item['icon']?.toString() ?? '🍺',
                  style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(item['name']?.toString() ?? '',
                    style: const TextStyle(
                        color: kGoldColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          Text(item['description']?.toString() ?? '',
              style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 12)),
          const SizedBox(height: 4),
          Text(
              'Баф: +${item['buff_value']}${buffNames[item['buff_type']] ?? ' ${item['buff_type']}'} • $minutes мин • $price 💰',
              style: const TextStyle(color: Color(0xFF80FF80), fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _buyBuff(context, item, song: song),
                child: Text('Купить за $price 💰',
                    style: const TextStyle(color: kGoldColor, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rumorsList(List<String> purchased) {
    final player = PlayerRepository.instance;
    final boughtCards = allRumors
        .where((r) => purchased.contains(r.$1))
        .map((r) => _rumorCard(r.$2, bought: true))
        .toList();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (purchased.isNotEmpty) ...[
          const Text('Купленные слухи',
              style: TextStyle(
                  color: kGoldColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          ...boughtCards,
          const SizedBox(height: 10),
        ],
        for (final r in allRumors)
          if (!purchased.contains(r.$1)) ...[
            _rumorCard(r.$2, bought: false, onBuy: () => _buyRumor(context, r.$1, r.$2)),
            const SizedBox(height: 6),
          ],
        if (player.data == null) const SizedBox.shrink(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _rumorCard(Map<String, dynamic> rumor, {required bool bought, VoidCallback? onBuy}) {
    final sellers = {
      'stranger': 'Незнакомец',
      'guard': 'Стражник',
      'adventurer': 'Авантюрист',
    };
    return GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(rumor['icon']?.toString() ?? '👁️',
                  style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(rumor['name']?.toString() ?? '',
                    style: const TextStyle(
                        color: kGoldColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ),
              Text(sellers[rumor['seller']] ?? '',
                  style:
                      const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
          Text(rumor['text']?.toString() ?? '',
              style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 12)),
          if (!bought && onBuy != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onBuy,
                  child: Text('Купить за ${rumor['price']} 💰',
                      style: const TextStyle(color: kGoldColor, fontSize: 13)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
