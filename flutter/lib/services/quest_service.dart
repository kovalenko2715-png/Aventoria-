import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'player_repository.dart';
import '../data/game_data.dart';

class QuestState {
  static QuestState instance = QuestState._();
  QuestState._();

  List<Map<String, dynamic>> _dailyOffers = [];
  List<Map<String, dynamic>> _weeklyOffers = [];

  List<Map<String, dynamic>> get dailyOffers => _dailyOffers;
  List<Map<String, dynamic>> get weeklyOffers => _weeklyOffers;

  static List<Map<String, dynamic>> buildAll() {
    final all = <Map<String, dynamic>>[];
    var id = 1;
    for (final e in questMobsDb.entries) {
      final mob = e.value as Map<String, dynamic>;
      for (final count in questKillCounts) {
        all.add({
          'id': 'q_${id++}',
          'name': '${mob['name']} ($count)',
          'type': 'kill',
          'rank': mob['rank'],
          'level_required': mob['level_req'],
          'location': mob['location_name'],
          'target_id': e.key,
          'target_name': mob['name'],
          'target_count': count,
          'reward_exp': count * 10,
          'reward_gold': count * 20,
          'reward_points': count ~/ 5 < 1 ? 1 : count ~/ 5,
          'icon': mob['icon'],
        });
      }
      for (final count in questCollectCounts) {
        all.add({
          'id': 'q_${id++}',
          'name': '${mob['item_name']} ($count)',
          'type': 'collect',
          'rank': mob['rank'],
          'level_required': mob['level_req'],
          'location': mob['location_name'],
          'target_id': mob['item'],
          'target_name': mob['item_name'],
          'target_count': count,
          'reward_exp': count * 8,
          'reward_gold': count * 15,
          'reward_points': count ~/ 5 < 1 ? 1 : count ~/ 5,
          'icon': '📦',
        });
      }
    }
    return all;
  }

  Map<String, dynamic> _makeOffer(
      Map<String, dynamic> base, DateTime now, Random rnd, bool daily) {
    final offer = Map<String, dynamic>.from(base);
    offer['current_count'] = 0;
    offer['expires_at'] = daily
        ? now.millisecondsSinceEpoch ~/ 1000 + (rnd.nextInt(41) + 20) * 60
        : now.millisecondsSinceEpoch ~/ 1000 + (rnd.nextInt(7) + 1) * 86400;
    return offer;
  }

  List<Map<String, dynamic>> generate(
      List<String> ranks, int count, Random rnd, bool daily, DateTime now) {
    final all = buildAll();
    final available = all
        .where((q) => ranks.contains(q['rank']))
        .toList()
      ..shuffle(rnd);
    return [
      for (final q in available.take(count)) _makeOffer(q, now, rnd, daily)
    ];
  }

  Future<void> load(PlayerRepository player) async {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day)
        .millisecondsSinceEpoch ~/ 86400000;
    final week = now.millisecondsSinceEpoch ~/ (86400000 * 7);
    final data = player.data ?? const {};

    var dailyDay = (data['quest_offers_daily_day'] as num?)?.toInt() ?? -1;
    var offersDailyRaw =
        data['quest_offers_daily'] as List<dynamic>? ?? <dynamic>[];
    if (dailyDay != day || offersDailyRaw.isEmpty) {
      _dailyOffers = generate(
          ['F', 'E', 'D'], 8, Random(day * 7919), true, now);
      offersDailyRaw = _dailyOffers;
      dailyDay = day;
      await player.replaceField('quest_offers_daily_day', day);
      await player.replaceField('quest_offers_daily', offersDailyRaw);
    } else {
      _dailyOffers = offersDailyRaw.cast<Map<String, dynamic>>();
    }

    var weeklyWeek = (data['quest_offers_weekly_week'] as num?)?.toInt() ?? -1;
    var offersWeeklyRaw =
        data['quest_offers_weekly'] as List<dynamic>? ?? <dynamic>[];
    if (weeklyWeek != week || offersWeeklyRaw.isEmpty) {
      _weeklyOffers = generate(
          ['C', 'B', 'A', 'S'], 4, Random(week * 104729), false, now);
      offersWeeklyRaw = _weeklyOffers;
      weeklyWeek = week;
      await player.replaceField('quest_offers_weekly_week', week);
      await player.replaceField('quest_offers_weekly', offersWeeklyRaw);
    } else {
      _weeklyOffers = offersWeeklyRaw.cast<Map<String, dynamic>>();
    }
  }

  List<Map<String, dynamic>> myQuests(PlayerRepository player) =>
      ((player.data?['my_quests'] as List<dynamic>?) ?? <dynamic>[])
          .cast<Map<String, dynamic>>();

  Future<void> accept(PlayerRepository player, Map<String, dynamic> offer) async {
    final mine = myQuests(player);
    if (mine.any((q) => q['id'] == offer['id'])) return;
    mine.add({...offer, 'current_count': 0});
    await player.replaceField('my_quests', mine);
  }

  Future<void> recordKillProgress(PlayerRepository player, String mobId,
      {int kills = 1}) async {
    final mine = myQuests(player);
    var changed = false;
    for (final q in mine) {
      if (q['type'] == 'kill' && q['target_id'] == mobId) {
        final current = (q['current_count'] as num?)?.toInt() ?? 0;
        final target = (q['target_count'] as num?)?.toInt() ?? 1;
        if (current < target) {
          q['current_count'] = min(current + kills, target);
          changed = true;
        }
      }
    }
    if (changed) await player.replaceField('my_quests', mine);
  }

  bool _hasItems(List<dynamic> inventory, String itemId, int count) {
    var total = 0;
    for (final inst in inventory) {
      if (inst is Map<String, dynamic> && inst['id'] == itemId) total++;
    }
    return total >= count;
  }

  void refreshCollectProgress(PlayerRepository player) {
    final inv = player.inventory;
    for (final q in myQuests(player)) {
      if (q['type'] == 'collect') {
        final has = _hasItems(
            inv, q['target_id'].toString(),
            (q['target_count'] as num?)?.toInt() ?? 1);
        q['current_count'] = has ? q['target_count'] : 0;
      }
    }
  }

  Future<Map<String, dynamic>?> complete(
      PlayerRepository player, Map<String, dynamic> quest) async {
    final target = (quest['target_count'] as num?)?.toInt() ?? 1;
    final current = (quest['current_count'] as num?)?.toInt() ?? 0;
    if (current < target) return null;

    if (quest['type'] == 'collect') {
      final inv = List<dynamic>.from(player.inventory);
      var left = target;
      inv.removeWhere((inst) {
        if (left <= 0) return false;
        if (inst is Map<String, dynamic> && inst['id'] == quest['target_id']) {
          left--;
          return true;
        }
        return false;
      });
      await player.replaceInventory(inv);
    }

    final exp = (quest['reward_exp'] as num?)?.toInt() ?? 0;
    final gold = (quest['reward_gold'] as num?)?.toInt() ?? 0;
    final points = (quest['reward_points'] as num?)?.toInt() ?? 1;

    final oldPlayerExp = (player.data?['exp'] as num?)?.toInt() ?? 0;
    final playerGold = player.gold;
    final playerStatPoints = (player.data?['stat_points'] as num?)?.toInt() ?? 0;
    final playerPoints = (player.data?['guild_quest_points'] as num?)?.toInt() ?? 0;
    final questName = quest['name']?.toString() ?? '';
    final levelBeforeLocal = (player.data?['level'] as num?)?.toInt() ?? 1;
    int levelAfterLocal = levelBeforeLocal;
    int statGainLocal = 0;

    await FirebaseFirestore.instance
        .runTransaction((tx) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw StateError('no user');
      final ref = FirebaseFirestore.instance.collection('users').doc(uid);
      final snap = await tx.get(ref);
      final data = snap.data() ?? const {};
      final oldExp = (data['exp'] as num?)?.toInt() ?? 0;
      final newExp = oldExp + exp;
      final levelAfter = 1 + newExp ~/ 300;
      final statGain = (levelAfter - levelBeforeLocal) * 3;
      tx.update(ref, {
        'exp': newExp,
        'level': levelAfter,
        'gold': FieldValue.increment(gold),
        'stat_points': FieldValue.increment(statGain),
        'guild_quest_points': FieldValue.increment(points),
      });
      levelAfterLocal = levelAfter;
      statGainLocal = statGain;
    });

    final mine =
        ((player.data?['my_quests'] as List<dynamic>?) ?? <dynamic>[])
            .cast<Map<String, dynamic>>();
    mine.removeWhere((q) => q['id'] == quest['id']);
    await player.replaceField('my_quests', mine);
    final statsPvp = Map<String, dynamic>.from(
        player.data?['stats_pvp'] as Map<String, dynamic>? ?? const {});
    statsPvp['earned'] =
        ((statsPvp['earned'] as num?)?.toInt() ?? 0) + gold;
    player.applyData({
      ...?player.data,
      'exp': oldPlayerExp + exp,
      'level': levelAfterLocal,
      'gold': playerGold + gold,
      'stat_points': playerStatPoints + statGainLocal,
      'guild_quest_points': playerPoints + points,
      'stats_pvp': statsPvp,
    });

    return {
      'exp': exp,
      'gold': gold,
      'points': points,
      'name': questName,
    };
  }
}
