import 'package:flutter/material.dart';

import '../main.dart';
import '../services/items_catalog.dart';
import '../services/player_repository.dart';
import '../widgets/module_window.dart';

class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  static const int _slots = 36;

  List<dynamic> _storage() {
    final list = List<dynamic>.from(
        PlayerRepository.instance.data?['personal_storage'] as List<dynamic>? ??
            const []);
    while (list.length < _slots) {
      list.add(null);
    }
    while (list.length > _slots) {
      list.removeLast();
    }
    return list;
  }

  Map<String, dynamic>? _cellOf(List<dynamic> storage, int index) {
    if (index >= storage.length) return null;
    return storage[index] as Map<String, dynamic>?;
  }

  Future<void> _takeItem(List<dynamic> storage, int index) async {
    final item = _cellOf(storage, index);
    if (item == null) return;
    final id = item['id']?.toString() ?? '';
    final db = ItemsCatalog.instance.itemById(id);
    final instance = <String, dynamic>{
      'id': id,
      'icon': db['icon'] ?? item['icon'] ?? '📦',
      'name': db['name'] ?? item['name'] ?? '???',
      'level': db['level'] ?? 1,
      'type': db['type'] ?? 'material',
      'description':
          db['description'] ?? item['description'] ?? 'Нет описания',
      'durability': db['durability'] ?? 100,
      'price': db['price'] ?? 0,
      'requirements': db['requirements'] ?? const {},
      'bonuses': db['bonuses'] ?? const {},
    };
    await PlayerRepository.instance.addInventoryItem(instance);
    storage[index] = null;
    await PlayerRepository.instance.replaceField('personal_storage', storage);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Вы забрали ${instance['name']} x${item['quantity'] ?? 1}')));
  }

  Future<void> _putItemDialog() async {
    final player = PlayerRepository.instance;
    final inventory = List<dynamic>.from(player.inventory);
    if (inventory.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Инвентарь пуст')));
      return;
    }
    final index = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: kGoldColor.withOpacity(0.6))),
        title: const Text('ВЫБЕРИТЕ ПРЕДМЕТ ИЗ ИНВЕНТАРЯ',
            style: TextStyle(color: kGoldColor, fontSize: 16)),
        content: SizedBox(
          width: 420,
          height: 320,
          child: ListView.builder(
            itemCount: inventory.length,
            itemBuilder: (ctx, i) {
              final instance =
                  inventory[i] as Map<String, dynamic>? ?? const {};
              return ListTile(
                leading: Text(instance['icon']?.toString() ?? '📦',
                    style: const TextStyle(fontSize: 24)),
                title: Text(instance['name']?.toString() ?? '???',
                    style: const TextStyle(color: kGoldColor)),
                trailing: const Text('ПОЛОЖИТЬ',
                    style: TextStyle(color: kGoldColor, fontSize: 12)),
                onTap: () => Navigator.of(ctx).pop(i),
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('ОТМЕНА')),
        ],
      ),
    );
    if (index == null || !mounted) return;

    final storage = _storage();
    final freeSlot = storage.indexOf(null);
    if (freeSlot == -1) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Хранилище заполнено!')));
      return;
    }
    final item =
        (inventory[index] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    storage[freeSlot] = {
      'id': item['id'] ?? '',
      'name': item['name'] ?? '???',
      'icon': item['icon'] ?? '📦',
      'description': item['description'] ?? 'Нет описания',
      'quantity': 1,
    };
    inventory.removeAt(index);
    await PlayerRepository.instance.replaceInventory(inventory);
    await PlayerRepository.instance.replaceField('personal_storage', storage);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Вы положили ${item['name'] ?? 'предмет'}')));
  }

  void _showDetail(List<dynamic> storage, int index) {
    final item = _cellOf(storage, index);
    if (item == null) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: kGoldColor.withOpacity(0.6))),
        title: Text('📦 ${item['name'] ?? '???'}',
            style: const TextStyle(color: kGoldColor, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['description']?.toString() ?? 'Нет описания',
                style: const TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(height: 8),
            Text('Количество: x${item['quantity'] ?? 1}',
                style: const TextStyle(color: kGoldColor)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('ОТМЕНА')),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _takeItem(storage, index);
            },
            child: const Text('ЗАБРАТЬ', style: TextStyle(color: kGoldColor)),
          ),
        ],
      ),
    );
  }

  Widget _cell(List<dynamic> storage, int index) {
    final item = _cellOf(storage, index);
    final qty = (item?['quantity'] as num?)?.toInt() ?? 1;
    return GestureDetector(
      onTap: item == null ? null : () => _showDetail(storage, index),
      child: Container(
        width: 64,
        height: 76,
        decoration: BoxDecoration(
          border: Border.all(color: kGoldColor.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(8),
          color: const Color(0x33221D18),
        ),
        padding: const EdgeInsets.all(3),
        child: item == null
            ? const Center(
                child: Text('пусто',
                    style: TextStyle(color: Color(0xFF808080), fontSize: 8)))
            : Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Text(item['name']?.toString() ?? '???',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 9)),
                  ),
                  Center(
                    child: Text(item['icon']?.toString() ?? '📦',
                        style: const TextStyle(fontSize: 24)),
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
    final storage = _storage();
    return ModuleWindow(
      title: '📦 ЛИЧНОЕ ХРАНИЛИЩЕ',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: OutlinedButton(
            onPressed: _putItemDialog,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0x80FFD700)),
              backgroundColor: const Color(0xFF221D18),
              minimumSize: const Size(180, 40),
            ),
            child: const Text('ПОЛОЖИТЬ ПРЕДМЕТ',
                style: TextStyle(color: kGoldColor, fontSize: 12)),
          ),
        ),
      ],
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text('Ваше личное хранилище (36 слотов)',
                style: TextStyle(color: Color(0xFFB3B3B3))),
          ),
          Expanded(
            // Мелкие ячейки как в инвентаре (Компонент GridView растягивает
            // ячейки во всю ширину — поэтому Wrap с фиксированным размером).
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _slots; i++) _cell(storage, i),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
