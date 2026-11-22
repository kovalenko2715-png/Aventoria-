import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/game_data.dart';

/// Каталог предметов: статичная база из original Godot + правки из Firestore
/// (коллекция catalog, документ item_<id> или shop_<id>), которые админ правит
/// из панели — игроки видят изменения без обновления приложения.
class ItemsCatalog extends ChangeNotifier {
  ItemsCatalog._();
  static final ItemsCatalog instance = ItemsCatalog._();

  Map<String, Map<String, dynamic>> _items = {};
  Map<String, Map<String, dynamic>> _shop = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  Map<String, Map<String, dynamic>> get adminOverrides => _items;

  void start() {
    if (_sub != null) return;
    _sub = FirebaseFirestore.instance
        .collection('catalog')
        .snapshots()
        .listen((s) {
      final items = <String, Map<String, dynamic>>{};
      final shop = <String, Map<String, dynamic>>{};
      for (final d in s.docs) {
        final data = d.data();
        if (d.id.startsWith('item_')) {
          items[d.id.substring(5)] = data;
        } else if (d.id.startsWith('shop_')) {
          shop[d.id.substring(5)] = data;
        }
      }
      _items = items;
      _shop = shop;
      notifyListeners();
    }, onError: (_) {});
  }

  Map<String, dynamic> itemById(String id) {
    final base = itemDb[id] as Map<String, dynamic>? ?? const {};
    final over = _items[id] ?? const {};
    if (base.isEmpty && over.isEmpty) return {};
    return {...base, ...over};
  }

  List<String> get catalogOnlyIds =>
      _items.keys.where((id) => itemDb[id] == null).toList()..sort();

  /// Всё, что лежит в магазине: статика + админские добавки.
  Map<String, Map<String, dynamic>> shopEntries() {
    final merged = <String, Map<String, dynamic>>{};
    for (final e in (shopItems as Map<String, dynamic>).entries) {
      if (e.value is Map<String, dynamic>) {
        merged[e.key] = Map<String, dynamic>.from(e.value as Map<String, dynamic>);
      }
    }
    for (final e in _shop.entries) {
      merged[e.key] = {...?merged[e.key], ...e.value};
    }
    for (final e in _shop.entries) {
      final item = _items[e.key];
      if (item != null) merged[e.key] = {...merged[e.key]!, ...item};
    }
    merged.removeWhere((id, data) {
      final removed = data['shop_removed'];
      return removed == true;
    });
    return merged;
  }

  Future<void> saveItem(String id, Map<String, dynamic> fields,
      {bool shop = false, Map<String, dynamic> shopFields = const {}}) async {
    final db = FirebaseFirestore.instance;
    await db.collection('catalog').doc('item_$id').set(fields);
    if (shop) {
      await db.collection('catalog').doc('shop_$id').set(shopFields);
    }
  }

  Future<void> removeShopEntry(String id) async {
    await FirebaseFirestore.instance
        .collection('catalog')
        .doc('shop_$id')
        .delete();
  }

  Future<void> removeItemOverride(String id) async {
    await FirebaseFirestore.instance
        .collection('catalog')
        .doc('item_$id')
        .delete();
  }
}
