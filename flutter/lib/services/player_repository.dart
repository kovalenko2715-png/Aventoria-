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
}
