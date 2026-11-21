import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class PlayerRepository extends ChangeNotifier {
  PlayerRepository._();
  static final PlayerRepository instance = PlayerRepository._();

  static const _defaultStats = {
    'strength': 0,
    'agility': 0,
    'intuition': 0,
    'endurance': 0,
    'intellect': 0,
    'wisdom': 0,
    'spirit': 0,
  };

  static const _defaultElements = {
    'fire': 0,
    'water': 0,
    'earth': 0,
    'air': 0,
    'light': 0,
    'dark': 0,
  };

  static const _defaultStatsPvp = {
    'pvp_wins': 0,
    'monsters': 0,
    'earned': 0,
    'bosses': 0,
  };

  Map<String, dynamic>? _data;
  bool _loaded = false;

  Map<String, dynamic>? get data => _data;
  bool get isLoaded => _loaded;

  int get gold => (data?['gold'] as num?)?.toInt() ?? 1000;
  int get rune => (data?['rune'] as num?)?.toInt() ?? 50;
  int get level => (data?['level'] as num?)?.toInt() ?? 1;
  String get name => data?['name'] as String? ?? 'Герой';
  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> loadOrCreate(User user) async {
    final db = FirebaseFirestore.instance;
    final ref = db.collection('users').doc(user.uid);
    final doc = await ref.get();

    if (!doc.exists) {
      final email = user.email ?? '';
      final nick = (user.displayName?.isNotEmpty ?? false)
          ? user.displayName!
          : email.split('@').first;
      final fresh = <String, dynamic>{
        'name': nick.isEmpty ? 'Герой' : nick,
        'email': email,
        'gold': 1000,
        'rune': 50,
        'stat_points': 15,
        'level': 1,
        'gender': 'Не указан',
        'element': '—',
        'title': '—',
        'guild': '—',
        'guild_emblem': '—',
        'stats': _defaultStats,
        'elements': _defaultElements,
        'stats_pvp': _defaultStatsPvp,
        'inventory': <dynamic>[],
        'equipment': <String, dynamic>{},
        'quick_slots': <dynamic>[null, null, null, null],
        'guild_quest_points': 0,
        'personal_storage': <dynamic>[],
        'created_at': FieldValue.serverTimestamp(),
      };
      await ref.set(fresh);
      final created = await ref.get();
      _data = created.data();
    } else {
      _data = doc.data();
    }
    _loaded = true;
    notifyListeners();
  }

  void applyData(Map<String, dynamic>? value) {
    _data = value;
    _loaded = true;
    notifyListeners();
  }

  Future<void> updateField(String key, Object value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      key: value,
    });
  }

  List<dynamic> get inventory =>
      (data?['inventory'] as List<dynamic>?) ?? <dynamic>[];

  Map<String, dynamic> get statsMap =>
      (data?['stats'] as Map<String, dynamic>?) ?? const {};

  Future<bool> spendCurrency({required int gold, required int rune}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final ref = FirebaseFirestore.instance.collection('users').doc(uid);
    final ok = await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final current = snap.data() ?? const {};
      final haveGold = (current['gold'] as num?)?.toInt() ?? 0;
      final haveRune = (current['rune'] as num?)?.toInt() ?? 0;
      if (haveGold < gold || haveRune < rune) return false;
      tx.update(ref, {
        'gold': FieldValue.increment(-gold),
        'rune': FieldValue.increment(-rune),
      });
      return true;
    });
    if (!ok) return false;
    if (_data != null) {
      applyData({
        ..._data!,
        'gold': ((_data!['gold'] as num?)?.toInt() ?? 0) - gold,
        'rune': ((_data!['rune'] as num?)?.toInt() ?? 0) - rune,
      });
    }
    return true;
  }

  Future<bool> spendStatPoint(String stat) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final ref = FirebaseFirestore.instance.collection('users').doc(uid);
    final ok = await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final current = snap.data() ?? const {};
      final points = (current['stat_points'] as num?)?.toInt() ?? 0;
      if (points <= 0) return false;
      tx.update(ref, {
        'stat_points': FieldValue.increment(-1),
        'stats.$stat': FieldValue.increment(1),
      });
      return true;
    });
    if (!ok) return false;
    if (_data != null) {
      final stats = Map<String, dynamic>.from(
          _data!['stats'] as Map<String, dynamic>? ?? const {});
      stats[stat] = ((stats[stat] as num?)?.toInt() ?? 0) + 1;
      applyData({
        ..._data!,
        'stats': stats,
        'stat_points': ((_data!['stat_points'] as num?)?.toInt() ?? 0) - 1,
      });
    }
    return true;
  }

  Future<void> addInventoryItem(Map<String, dynamic> instance) async {
    final inv = List<dynamic>.from(inventory)..add(instance);
    _data = {...?_data, 'inventory': inv};
    notifyListeners();
    await updateField('inventory', inv);
  }

  Future<void> replaceInventory(List<dynamic> newInventory) async {
    _data = {...?_data, 'inventory': newInventory};
    notifyListeners();
    await updateField('inventory', newInventory);
  }

  Future<void> replaceEquipment(Map<String, dynamic> equipment) async {
    _data = {...?_data, 'equipment': equipment};
    notifyListeners();
    await updateField('equipment', equipment);
  }

  Future<void> replaceField(String key, Object value) async {
    _data = {...?_data, key: value};
    notifyListeners();
    await updateField(key, value);
  }
}

const int _expPerLevel = 300;

class BattleRewardResult {
  final int goldGained;
  final int expGained;
  final int levelBefore;
  final int levelAfter;
  final int statPointsGained;

  const BattleRewardResult({
    required this.goldGained,
    required this.expGained,
    required this.levelBefore,
    required this.levelAfter,
    required this.statPointsGained,
  });

  bool get leveledUp => levelAfter > levelBefore;
}

extension BattleRewards on PlayerRepository {
  Future<BattleRewardResult> grantBattleRewards({
    required int gold,
    required int exp,
    required bool victory,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const BattleRewardResult(
          goldGained: 0,
          expGained: 0,
          levelBefore: 1,
          levelAfter: 1,
          statPointsGained: 0);
    }
    final db = FirebaseFirestore.instance;
    final ref = db.collection('users').doc(uid);

    final result = await db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final current = snap.data() ?? const {};
      final levelBefore = (current['level'] as num?)?.toInt() ?? 1;
      final oldExp = (current['exp'] as num?)?.toInt() ?? 0;
      final newExp = oldExp + exp;
      final levelAfter = 1 + newExp ~/ _expPerLevel;
      final statGain = levelAfter > levelBefore ? (levelAfter - levelBefore) * 3 : 0;

      tx.update(ref, {
        'gold': FieldValue.increment(gold),
        'exp': newExp,
        'level': levelAfter,
        'stat_points': FieldValue.increment(statGain),
        'stats_pvp.monsters': FieldValue.increment(victory ? 1 : 0),
        'stats_pvp.earned': FieldValue.increment(gold),
      });

      return BattleRewardResult(
        goldGained: gold,
        expGained: exp,
        levelBefore: levelBefore,
        levelAfter: levelAfter,
        statPointsGained: statGain,
      );
    });

    if (_data != null) {
      final stats = Map<String, dynamic>.from(
          _data!['stats_pvp'] as Map<String, dynamic>? ?? const {});
      stats['monsters'] =
          ((stats['monsters'] as num?)?.toInt() ?? 0) + (victory ? 1 : 0);
      stats['earned'] = ((stats['earned'] as num?)?.toInt() ?? 0) + gold;
      applyData({
        ..._data!,
        'gold': gold + ((_data!['gold'] as num?)?.toInt() ?? 0),
        'exp': exp + ((_data!['exp'] as num?)?.toInt() ?? 0),
        'level': result.levelAfter,
        'stat_points': ((_data!['stat_points'] as num?)?.toInt() ?? 0) +
            result.statPointsGained,
        'stats_pvp': stats,
      });
    }
    return result;
  }
}
