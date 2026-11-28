import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'battle_engine.dart';
import 'combat_service.dart';
import 'player_repository.dart';

/// === АРЕНА (PvP) ===
///
/// Модель данных в Firestore:
///  arena/{uid}            — кто стоит в арене ({name, level, rating, since})
///  pvp_challenges/{id}    — вызов на бой ({from_uid, to_uid, status, bet})
///  pvp_battles/{id}       — сам бой
///
/// Раунды считаются детерминированно: оба клиента по одинаковому seed
/// получают одинаковый результат, в Firestore пишет только один (транзакция).
class PvpService {
  PvpService._();
  static final PvpService instance = PvpService._();

  static const int turnSeconds = 60;
  static const int ratingWin = 25;
  static const int ratingLose = 15;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ─── ПРИСУТСТВИЕ В АРЕНЕ ─────────────────────────────────────────────

  Future<void> enterArena() async {
    final player = PlayerRepository.instance;
    final uid = player.uid;
    if (uid == null) return;
    await player.replaceField('in_arena', true);
    player.applyData({...?player.data, 'in_arena': true});
    await _db.collection('arena').doc(uid).set({
      'name': player.name,
      'level': player.level,
      'rating': myRating,
      'since': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> leaveArena() async {
    final player = PlayerRepository.instance;
    final uid = player.uid;
    if (uid == null) return;
    await player.replaceField('in_arena', false);
    player.applyData({...?player.data, 'in_arena': false});
    try {
      await _db.collection('arena').doc(uid).delete();
    } catch (_) {}
  }

  bool get inArena =>
      (PlayerRepository.instance.data?['in_arena'] as bool?) == true;

  int get myRating =>
      (PlayerRepository.instance.data?['rating'] as num?)?.toInt() ?? 1000;

  // ─── ВЫЗОВ НА БОЙ ────────────────────────────────────────────────────

  Future<String?> challenge(String toUid, Map<String, dynamic> toDoc,
      {required int bet}) async {
    final player = PlayerRepository.instance;
    final uid = player.uid;
    if (uid == null || uid == toUid) return null;
    final ref = await _db.collection('pvp_challenges').add({
      'from_uid': uid,
      'from_name': player.name,
      'from_level': player.level,
      'from_rating': myRating,
      'to_uid': toUid,
      'to_name': toDoc['name']?.toString() ?? '???',
      'to_level': (toDoc['level'] as num?)?.toInt() ?? 1,
      'bet': bet,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> respondChallenge(String challengeId, bool accept) async {
    await _db
        .collection('pvp_challenges')
        .doc(challengeId)
        .update({'status': accept ? 'accepted' : 'declined'});
  }

  /// Живой поток вызовов, адресованных мне (их надо принять/отклонить).
  Stream<QuerySnapshot<Map<String, dynamic>>> incomingChallenges() => _db
      .collection('pvp_challenges')
      .where('to_uid', isEqualTo: PlayerRepository.instance.uid)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .handleError((_) {});

  /// Живой поток МОИХ вызовов (вижу ответы: принял/отклонён).
  Stream<QuerySnapshot<Map<String, dynamic>>> myOutgoingChallenges() => _db
      .collection('pvp_challenges')
      .where('from_uid', isEqualTo: PlayerRepository.instance.uid)
      .snapshots()
      .handleError((_) {});

  /// Список бойцов в арене.
  Stream<List<MapEntry<String, Map<String, dynamic>>>> arenaPlayers() => _db
      .collection('arena')
      .snapshots()
      .map((s) => [
            for (final d in s.docs)
              MapEntry(d.id, Map<String, dynamic>.from(d.data())),
          ])
      .handleError((_) => <MapEntry<String, Map<String, dynamic>>>[]);

  // ─── БОЙ ─────────────────────────────────────────────────────────────

  Map<String, dynamic> _myCombatSnapshot() {
    final player = PlayerRepository.instance;
    final stats = player.data?['stats'] as Map<String, dynamic>? ?? const {};
    final equipment =
        (player.data?['equipment'] as Map<String, dynamic>?) ?? const {};
    final c = CombatService.compute(stats: stats, equipment: equipment);
    return {
      'name': player.name,
      'level': player.level,
      'attack': c.attack,
      'defense': c.defense,
      'maxHp': c.maxHp,
      'hp': c.maxHp,
      'critChance': c.critChance,
      'critDamage': c.critDamage,
      'evasion': c.evasion,
      'dualWield': c.dualWield,
      'look': player.data?['look']?.toString() ?? '',
      'equipment': equipment,
      'rating': myRating,
    };
  }

  Map<String, dynamic> _combatFromUserDoc(Map<String, dynamic> user) {
    final stats = user['stats'] as Map<String, dynamic>? ?? const {};
    final equipment = (user['equipment'] as Map<String, dynamic>?) ?? const {};
    final c = CombatService.compute(stats: stats, equipment: equipment);
    return {
      'name': ((user['name']?.toString() ?? '').isNotEmpty)
          ? user['name'].toString()
          : 'Противник',
      'level': (user['level'] as num?)?.toInt() ?? 1,
      'attack': c.attack,
      'defense': c.defense,
      'maxHp': c.maxHp,
      'hp': c.maxHp,
      'critChance': c.critChance,
      'critDamage': c.critDamage,
      'evasion': c.evasion,
      'dualWield': c.dualWield,
      'look': user['look']?.toString() ?? '',
      'equipment': equipment,
      'rating': (user['rating'] as num?)?.toInt() ?? 1000,
    };
  }

  /// Создаёт документ боя (тот, кто ПРИНЯЛ вызов, создаёт бой).
  Future<String?> createBattle(Map<String, dynamic> challenge) async {
    final player = PlayerRepository.instance;
    final myUid = player.uid;
    final fromUid = challenge['from_uid']?.toString() ?? '';
    if (myUid == null || fromUid.isEmpty) return null;

    // Читаем статы/шмот вызвавшего — обоим рисуется кукла со шмотом.
    Map<String, dynamic> foeCombat;
    try {
      final foeDoc = await _db.collection('users').doc(fromUid).get();
      foeCombat = _combatFromUserDoc(foeDoc.data() ?? const {});
    } catch (_) {
      foeCombat = _combatFromUserDoc(const {});
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final battle = {
      'ps': [fromUid, myUid], // ps[0] бьёт первым в чётных раундах
      'combat': {
        fromUid: foeCombat,
        myUid: _myCombatSnapshot(),
      },
      'bet': (challenge['bet'] as num?)?.toInt() ?? 0,
      'round': 0,
      'round_seed': Random().nextInt(1 << 31),
      'status': 'active',
      'winner': null,
      'turn_deadline': now + turnSeconds * 1000,
      'sels': <String, dynamic>{},
      'ready': <String, bool>{},
      'log': [
        {
          't': now,
          'k': 'info',
          's': '⚔️ PvP! ${foeCombat['name']} против ${player.name}!',
        },
        {
          't': now,
          'k': 'info',
          's': 'Атака — 1 зона, защита — 2 зоны. На ход 60 секунд.',
        },
      ],
      'created_at': FieldValue.serverTimestamp(),
    };
    final ref = await _db.collection('pvp_battles').add(battle);
    return ref.id;
  }

  /// Публикует мой выбор зон + готовность.
  Future<void> submitSelection({
    required String battleId,
    required String uid,
    required String atk,
    String atk2 = '',
    required Set<String> def,
  }) async {
    final ref = _db.collection('pvp_battles').doc(battleId);
    await ref.set({
      'sels.$uid': {
        'atk': atk,
        if (atk2.isNotEmpty) 'atk2': atk2,
        'def': def.toList(),
      },
      'ready.$uid': true,
    }, SetOptions(merge: true));
  }

  /// Пытается рассчитать раунд — транзакцией, чтобы оба клиента
  /// не записали разный результат. true — расчёт прошёл (не важно кто).
  Future<bool> resolveIfReady(String battleId, String myUid) async {
    final ref = _db.collection('pvp_battles').doc(battleId);
    var resolved = false;
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final b = snap.data()!;
      if (b['status']?.toString() != 'active') return;
      final ps = List<String>.from(b['ps'] as List<dynamic>);
      if (ps.length < 2 || !ps.contains(myUid)) return;
      final ready = Map<String, dynamic>.from(
          b['ready'] as Map<String, dynamic>? ?? const {});
      final now = DateTime.now().millisecondsSinceEpoch;
      final deadline = (b['turn_deadline'] as num?)?.toInt() ?? 0;

      final bothReady = ready[ps[0]] == true && ready[ps[1]] == true;
      final timeout = deadline > 0 && now > deadline;
      if (!bothReady && !timeout) return;

      final combatMap = Map<String, dynamic>.from(
          b['combat'] as Map<String, dynamic>? ?? const {});
      final selsRaw = Map<String, dynamic>.from(
          b['sels'] as Map<String, dynamic>? ?? const {});

      final statsOf = <String, Map<String, dynamic>>{};
      for (final uid in ps) {
        statsOf[uid] = Map<String, dynamic>.from(
            combatMap[uid] as Map<String, dynamic>? ?? const {});
      }

      final sels = <String, Map<String, dynamic>>{};
      final parts = attackParts.keys.toList();
      final seed = (b['round_seed'] as num?)?.toInt() ?? 1;
      for (final uid in ps) {
        final raw = selsRaw[uid];
        if (raw is Map) {
          sels[uid] = Map<String, dynamic>.from(raw);
        } else {
          // Молчун (время вышло) — случайный удар, защиты нет (пропуск, как в БК).
          final idx = ps.indexOf(uid);
          sels[uid] = {
            'atk': parts[Random(seed + idx).nextInt(parts.length)],
            'def': <String>[],
          };
        }
      }

      var round = (b['round'] as num?)?.toInt() ?? 0;
      final log = (b['log'] as List<dynamic>? ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final first = ps[round % 2];
      final second = ps[(round + 1) % 2];
      _strike(
        rng: Random(seed),
        atkUid: first,
        defUid: second,
        sels: sels,
        statsOf: statsOf,
        log: log,
        power: 1.0,
        secondWeapon: false,
      );
      // Второе оружие: добивающий удар, только если оба ещё живы.
      if (sels[first]?['atk2'] is String &&
          (sels[first]?['atk2'] as String).isNotEmpty &&
          _alive(statsOf, first) &&
          _alive(statsOf, second)) {
        _strike(
          rng: Random(seed),
          atkUid: first,
          defUid: second,
          sels: sels,
          statsOf: statsOf,
          log: log,
          power: 0.65,
          secondWeapon: true,
        );
      }
      if (_alive(statsOf, first) && _alive(statsOf, second)) {
        _strike(
          rng: Random(seed),
          atkUid: second,
          defUid: first,
          sels: sels,
          statsOf: statsOf,
          log: log,
          power: 1.0,
          secondWeapon: false,
        );
        if (sels[second]?['atk2'] is String &&
            (sels[second]?['atk2'] as String).isNotEmpty &&
            _alive(statsOf, first) &&
            _alive(statsOf, second)) {
          _strike(
            rng: Random(seed),
            atkUid: second,
            defUid: first,
            sels: sels,
            statsOf: statsOf,
            log: log,
            power: 0.65,
            secondWeapon: true,
          );
        }
      }

      round++;
      resolved = true;

      String? winner;
      if (!_alive(statsOf, ps[0]) || !_alive(statsOf, ps[1])) {
        winner = !_alive(statsOf, ps[0]) ? ps[1] : ps[0];
        log.add({
          't': now,
          'k': 'result',
          's':
              '🏆 ПОБЕДА: ${statsOf[winner]?['name'] ?? '?'}! Бой завершён ($round раундов).',
        });
      }

      final update = <String, dynamic>{
        'combat': {ps[0]: statsOf[ps[0]], ps[1]: statsOf[ps[1]]},
        'sels': <String, dynamic>{},
        'ready': <String, bool>{},
        'round': round,
        'round_seed': (seed * 1103515245 + 12345) % (1 << 31),
        'log': log.length > 80 ? log.sublist(log.length - 80) : log,
        'last_resolved': now,
      };
      if (winner != null) {
        update['status'] = 'finished';
        update['winner'] = winner;
        update['turn_deadline'] = 0;
      } else {
        update['turn_deadline'] = now + turnSeconds * 1000;
      }
      tx.update(ref, update);
    });
    return resolved;
  }

  bool _alive(Map<String, Map<String, dynamic>> statsOf, String uid) =>
      ((statsOf[uid]?['hp'] as num?)?.toInt() ?? 0) > 0;

  /// Один удар: как в BattleEngine — уклон / блок 25% / крит (пробивает) / обычный.
  void _strike({
    required Random rng,
    required String atkUid,
    required String defUid,
    required Map<String, Map<String, dynamic>> sels,
    required Map<String, Map<String, dynamic>> statsOf,
    required List<Map<String, dynamic>> log,
    required double power,
    required bool secondWeapon,
  }) {
    final a = statsOf[atkUid];
    final d = statsOf[defUid];
    if (a == null || d == null) return;
    if (((a['hp'] as num?)?.toInt() ?? 0) <= 0) return;
    if (((d['hp'] as num?)?.toInt() ?? 0) <= 0) return;
    final sel = Map<String, dynamic>.from(sels[atkUid] ?? const {});
    final part =
        (secondWeapon ? (sel['atk2'] ?? sel['atk']) : (sel['atk'] ?? 'chest'))
            .toString();
    final defSel = Map<String, dynamic>.from(sels[defUid] ?? const {});
    final defZones = ((defSel['def'] as List?) ?? const [])
        .map((e) => e.toString())
        .toSet();

    final t = DateTime.now().millisecondsSinceEpoch;
    final atkName = a['name']?.toString() ?? '?';
    final defName = d['name']?.toString() ?? '?';
    final zone = attackPartNames[part]?.toLowerCase() ?? 'грудь';
    final note = secondWeapon ? ' вторым оружием' : '';

    // Уклонение.
    if (rng.nextDouble() * 100 < ((d['evasion'] as num?)?.toDouble() ?? 5)) {
      log.add({
        't': t,
        'k': 'dodge',
        's': '💨 $defName увернулся от удара$note $atkName в $zone.',
      });
      return;
    }
    final crit =
        rng.nextDouble() * 100 < ((a['critChance'] as num?)?.toDouble() ?? 5);
    var dmg = ((a['attack'] as num).toDouble() - ((d['defense'] as num?)?.toDouble() ?? 0) / 2) *
        (attackParts[part] ?? 1.0) *
        power *
        (0.85 + rng.nextDouble() * 0.25);
    if (crit) {
      dmg *= ((a['critDamage'] as num?)?.toDouble() ?? 150) / 100;
    }
    final blocked = !crit && defZones.contains(part);
    if (blocked) {
      dmg = max(1, (dmg * 0.25).round().toDouble());
      log.add({
        't': t,
        'k': 'block',
        's':
            '🛡 $defName заблокировал удар$note $atkName в $zone: −${dmg.round()} HP',
      });
    } else if (crit) {
      log.add({
        't': t,
        'k': 'crit',
        's': '💥 КРИТ! $atkName пробивает$note $defName в $zone: −${dmg.round()} HP',
      });
    } else {
      log.add({
        't': t,
        'k': 'damage',
        's': '🔥 $atkName бьёт$note в $zone $defName: −${dmg.round()} HP',
      });
    }
    d['hp'] = max(0, ((d['hp'] as num?)?.toInt() ?? 0) - dmg.round());
  }

  // ─── НАГРАДЫ ПОСЛЕ БОЯ ───────────────────────────────────────────────

  /// Выдаёт награду за завершённый бой моей стороне. Один раз на бой.
  Future<String> grantRewards(String battleId) async {
    final player = PlayerRepository.instance;
    try {
      // Уже получил награду за этот бой?
      final claimed = Map<String, dynamic>.from(
          player.data?['pvp_rewarded'] as Map<String, dynamic>? ?? {});
      if (claimed[battleId] == true) return 'already';

      final snap = await _db.collection('pvp_battles').doc(battleId).get();
      final b = snap.data();
      if (b == null || b['status']?.toString() != 'finished') return 'no';
      final myUid = player.uid ?? '';
      final winner = b['winner']?.toString() ?? '';
      if (winner.isEmpty) return 'no';

      final ps = (b['ps'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList();
      final foeUid = ps.firstWhere((u) => u != myUid, orElse: () => myUid);
      final combat = Map<String, dynamic>.from(
          b['combat'] as Map<String, dynamic>? ?? const {});
      final myStats = Map<String, dynamic>.from(
          combat[myUid] as Map<String, dynamic>? ?? const {});
      final foeStats = Map<String, dynamic>.from(
          combat[foeUid] as Map<String, dynamic>? ?? const {});
      final foeLevel = (foeStats['level'] as num?)?.toInt() ?? 1;
      final bet = (b['bet'] as num?)?.toInt() ?? 0;
      final iWon = winner == myUid;

      claimed[battleId] = true;
      final curRating = (myStats['rating'] as num?)?.toInt() ?? myRating;
      final newRating = curRating + (iWon ? ratingWin : -ratingLose);
      await player.replaceField('rating', newRating);
      player.applyData({...?player.data, 'rating': newRating});
      if (bet > 0) {
        final moved = await player.spendCurrency(gold: iWon ? -bet : bet, rune: 0);
        if (!moved) {
          // Ставку не удалось перевести (не хватило золота) — просто пропускаем.
        }
      }
      final exp = iWon ? 20 + foeLevel * 6 : 8 + foeLevel * 2;
      await player.grantBattleRewards(gold: 0, exp: exp, victory: iWon);
      await player.replaceField('pvp_rewarded', claimed);

      final stats = Map<String, dynamic>.from(
          player.data?['stats_pvp'] as Map<String, dynamic>? ?? const {});
      if (iWon) {
        stats['pvp_wins'] = ((stats['pvp_wins'] as num?)?.toInt() ?? 0) + 1;
      }
      await player.replaceField('stats_pvp', stats);
      return iWon ? 'win' : 'lose';
    } catch (_) {
      return 'error';
    }
  }
}
