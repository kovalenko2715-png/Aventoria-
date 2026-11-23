import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Черновик предмета: живёт ТОЛЬКО локально (файл в документах приложения).
/// В Firestore уходит уже после отправки на GitHub — так в базе не копится мусор.
class ItemDraft {
  String id;
  String name;
  String icon; // эмодзи-фолбэк, картинка отдельно
  String? imagePath; // локальный путь к выбранной картинке
  String type; // equipment | consumable | material
  String? slot;
  int level;
  int price;
  String description;
  Map<String, int> requirements;
  Map<String, int> bonuses;
  bool shop;
  int priceGold;
  int priceRune;

  ItemDraft({
    required this.id,
    this.name = '',
    this.icon = '',
    this.imagePath,
    this.type = 'equipment',
    this.slot,
    this.level = 1,
    this.price = 0,
    this.description = '',
    this.requirements = const {},
    this.bonuses = const {},
    this.shop = false,
    this.priceGold = 0,
    this.priceRune = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'image_path': imagePath,
        'type': type,
        'slot': slot,
        'level': level,
        'price': price,
        'description': description,
        'requirements': requirements,
        'bonuses': bonuses,
        'shop': shop,
        'price_gold': priceGold,
        'price_rune': priceRune,
      };

  static ItemDraft fromJson(Map<String, dynamic> j) => ItemDraft(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        icon: j['icon']?.toString() ?? '',
        imagePath: j['image_path']?.toString(),
        type: j['type']?.toString() ?? 'equipment',
        slot: j['slot']?.toString(),
        level: (j['level'] as num?)?.toInt() ?? 1,
        price: (j['price'] as num?)?.toInt() ?? 0,
        description: j['description']?.toString() ?? '',
        requirements:
            Map<String, int>.from(j['requirements'] as Map? ?? const {}),
        bonuses: Map<String, int>.from(j['bonuses'] as Map? ?? const {}),
        shop: j['shop'] == true,
        priceGold: (j['price_gold'] as num?)?.toInt() ?? 0,
        priceRune: (j['price_rune'] as num?)?.toInt() ?? 0,
      );
}

class ItemDrafts extends ChangeNotifier {
  ItemDrafts._();
  static final ItemDrafts instance = ItemDrafts._();

  List<ItemDraft> _items = [];
  List<ItemDraft> get items => List.unmodifiable(_items);
  int get count => _items.length;
  bool hasId(String id) => _items.any((d) => d.id == id);

  Future<void> load() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}/item_drafts.json');
      if (!f.existsSync()) return;
      final list = jsonDecode(f.readAsStringSync()) as List;
      _items = list.map((e) => ItemDraft.fromJson(e)).toList();
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      File('${dir.path}/item_drafts.json')
          .writeAsStringSync(jsonEncode(_items.map((d) => d.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> add(ItemDraft d) async {
    _items.removeWhere((x) => x.id == d.id);
    _items.add(d);
    await _persist();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _items.removeWhere((d) => d.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> clearAndNotify() async {
    _items.clear();
    await _persist();
    notifyListeners();
  }
}
