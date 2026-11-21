import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../main.dart';
import '../services/player_repository.dart';
import '../widgets/module_window.dart';

class AuctionScreen extends StatefulWidget {
  const AuctionScreen({super.key});

  @override
  State<AuctionScreen> createState() => _AuctionScreenState();
}

class _AuctionScreenState extends State<AuctionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  CollectionReference get _lots => FirebaseFirestore.instance.collection('auction');

  Future<void> _buyLot(DocumentSnapshot lot) async {
    final player = PlayerRepository.instance;
    final data = lot.data() as Map<String, dynamic>? ?? const {};
    final runePrice = (data['price_rune'] as num?)?.toInt() ?? 0;
    final useRune = runePrice > 0;
    final price = useRune ? runePrice : (data['price'] as num?)?.toInt() ?? 0;
    if (data['seller_uid'] == FirebaseAuth.instance.currentUser?.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Это ваш собственный лот')));
      return;
    }
    final ok = await player.spendCurrency(
        gold: useRune ? 0 : price, rune: useRune ? price : 0);
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Недостаточно средств')));
      }
      return;
    }
    await player.addInventoryItem({
      'id': data['item_id'],
      'icon': data['icon'] ?? '📦',
      'name': data['name'],
      'level': data['level'] ?? 1,
      'type': data['type'] ?? 'material',
      'slot': data['slot'],
      'description': data['description'] ?? '',
      'durability': data['durability'] ?? -1,
      'price': (data['price'] as num?)?.toInt() ?? 0,
      'requirements': data['requirements'] ?? const {},
      'bonuses': data['bonuses'] ?? const {},
    });
    if (data['seller_uid'] != null && !useRune) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(data['seller_uid'])
          .update({'gold': FieldValue.increment(price)});
    }
    await lot.reference.delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Куплено: ${data['name']}')));
    }
  }

  Future<void> _putLot(BuildContext context, int index) async {
    final controller = TextEditingController();
    final instance =
        PlayerRepository.instance.inventory[index] as Map<String, dynamic>? ?? const {};
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Выставить лот',
            style: TextStyle(color: kGoldColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${instance['name'] ?? ''} • ваш лот',
                style: const TextStyle(color: Colors.white)),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  labelText: 'Цена в золоте',
                  labelStyle: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text('Отмена', style: TextStyle(color: Colors.white70))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Выставить',
                  style: TextStyle(color: kGoldColor))),
        ],
      ),
    );
    if (ok != true) return;
    final price = int.tryParse(controller.text) ?? 0;
    if (price <= 0) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final fromDb = itemDb[instance['id']] as Map<String, dynamic>?;
    final info = {...?fromDb, ...instance};
    await _lots.add({
      'seller_uid': uid,
      'seller': PlayerRepository.instance.name,
      'item_id': instance['id'],
      'name': info['name'],
      'icon': info['icon'] ?? '📦',
      'level': info['level'] ?? 1,
      'type': info['type'] ?? 'material',
      'slot': info['slot'],
      'description': info['description'] ?? '',
      'durability': info['durability'] ?? -1,
      'price': price,
      'price_rune': 0,
      'requirements': info['requirements'] ?? const {},
      'bonuses': info['bonuses'] ?? const {},
      'created_at': FieldValue.serverTimestamp(),
    });
    final inv =
        List<dynamic>.from(PlayerRepository.instance.inventory)..removeAt(index);
    await PlayerRepository.instance.replaceInventory(inv);
    if (!context.mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Лот выставлен за $price 💰')));
  }

  @override
  Widget build(BuildContext context) {
    return ModuleWindow(
      title: '⚖️ Аукцион',
      child: Column(
        children: [
          TabBar(
            controller: _tabs,
            labelColor: kGoldColor,
            unselectedLabelColor: Colors.white54,
            indicatorColor: kGoldColor,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Лоты'),
              Tab(text: 'Продать'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: _lots.orderBy('created_at', descending: true)
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }
                    final docs = snap.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(
                          child: Text('Лотов пока нет',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 15)));
                    }
                    return ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        for (final lot in docs)
                          _lotCard(lot),
                      ],
                    );
                  },
                ),
                ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (var i = 0;
                        i < PlayerRepository.instance.inventory.length;
                        i++)
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

  Widget _lotCard(DocumentSnapshot lot) {
    final data = lot.data() as Map<String, dynamic>? ?? const {};
    final price = (data['price'] as num?)?.toInt() ?? 0;
    return GameCard(
      child: Row(
        children: [
          Text(data['icon']?.toString() ?? '📦',
              style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${data['name']} [Ур.${data['level'] ?? 1}]',
                    style: const TextStyle(
                        color: kGoldColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                Text('Продавец: ${data['seller'] ?? 'Игрок'}',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _buyLot(lot),
            child: Text('Купить $price 💰',
                style: const TextStyle(color: kGoldColor, fontSize: 13)),
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
            onPressed: () => _putLot(context, index),
            child: const Text('Выставить лот',
                style: TextStyle(color: kGoldColor, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
