import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/game_data.dart';
import 'battle_engine.dart';
import 'chat_service.dart';
import 'combat_service.dart';
import 'items_catalog.dart';
import 'player_repository.dart';

/// === МИРОВЫЕ БОССЫ ===
///
/// У каждого босса свой детерминированный таймер: окно пробуждения
/// считается одинаково на всех клиентах от фиксированной "отправной точки".
/// Пока окно открыто — все игроки создают/вступают в комнаты и бьют босса
/// вместе (общий HP босса). Дроп — КАЖДОМУ отдельный ролл.
class WorldBossService {
  WorldBossService._();
  static final WorldBossService instance = WorldBossService._();

  static const int turnSeconds = 60;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Расписание: id босса → [период_мин, открыт_мин, сдвиг_мин].
  /// Период — раз в сколько часов пробуждается, открыт_мин — 15..25,
  /// сдвиг разводит боссов по времени, чтобы не просыпались все сразу.
  static const Map<String, List<int>> scheduleDefaults = {
    'ancient_dragon': [120, 20, 0],   // каждые 2 часа, открыт 20 мин
    'demon_lord': [180, 25, 45],      // каждые 3 часа, открыт 25 мин
    'archmage': [240, 15, 95],        // каждые 4 часа, открыт 15 мин
  };

  /// Отправная точка расписания: 2026-01-01 09:00 UTC (ms).
  static const int _anchor =
      1767258000000;

  Map<String, dynamic>? _settings;
  StreamSubscription? _settingsSub;

  /// Слушаем админ-настройки (принудительное открытие босса).
  void init() {
    _settingsSub ??= _db
        .collection('settings')
        .doc('world_bosses')
        .snapshots()
        .listen((snap) => _settings = snap.data(), onError: (_) {});
  }

  void dispose() {
    _settingsSub?.cancel();
    _settingsSub = null;
  }

  List<int> _scheduleFor(String id) =>
      scheduleDefaults[id] ?? const [180, 20, 0];

  /// (начало, конец) текущего/ближайшего окна пробуждения, ms.
  (int, int) currentWindow(String id, {int? now}) {
    final sched = _scheduleFor(id);
    final periodMin = sched[0], openMin = sched[1], offsetMin = sched[2];
    final offsetMs = offsetMin * 60000;
    final periodMs = periodMin * 60000;
    final t = (now ?? DateTime.now().millisecondsSinceEpoch) - _anchor - offsetMs;
    if (t < 0) {
      return (_anchor + offsetMs, _anchor + offsetMs + openMin * 60000);
    }
    final k = t ~/ periodMs;
    var start = _anchor + offsetMs + k * periodMs;
    // Принудительное открытие из админки: если указан force до этого времени
    // и обычное окно закрыто — считаем открытым "сейчас" на остаток.
    final forcedUntil = forcedOpen(id);
    if (forcedUntil != null) {
      final nowMs = now ?? DateTime.now().millisecondsSinceEpoch;
      if (nowMs >= start && nowMs < start + openMin * 60000) {
        // обычное окно уже открыто.
      } else if (nowMs < forcedUntil) {
        start = nowMs;
        return (start, forcedUntil);
      }
    }
    return (start, start + openMin * 60000);
  }

  int? forcedOpen(String id) {
    final forced =
        (_settings?['forced'] as Map<dynamic, dynamic>?) ?? const {};
    final v = (forced[id] as num?)?.toInt() ?? 0;
    if (v <= 0) return null;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    return v > nowMs ? v : null;
  }

  bool isOpen(String id, {int? now}) {
    final (s, e) = currentWindow(id, now: now);
    final t = now ?? DateTime.now().millisecondsSinceEpoch;
    return t >= s && t < e;
  }

  Duration untilNextOpen(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final (s, _) = currentWindow(id, now: now);
    return s > now ? Duration(milliseconds: s - now) : Duration.zero;
  }

  Duration untilClose(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final (_, e) = currentWindow(id, now: now);
    return now < e ? Duration(milliseconds: e - now) : Duration.zero;
  }

  Map<String, dynamic>? bossDef(String id) =>
      bossesWorld[id] as Map<String, dynamic>?;

  /// Объявление о пробуждении в чат (одноразовое на окно, безопасно с любого
  /// клиента — одинаковый id документа).
  Future<void> announceAwakens() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final id in scheduleDefaults.keys) {
      if (!isOpen(id, now: now)) continue;
      final (s, e) = currentWindow(id, now: now);
      final def = bossDef(id);
      if (def == null) continue;
      final minsLeft = ((e - now) / 60000).ceil();
      await ChatService.instance.systemOnce(
        'wb_${id}_$s',
        '🔥 ПРОБУДИЛСЯ МИРОВОЙ БОСС: ${def['name']} (ур. ${def['level']})! '
            '${def['location_name'] ?? ''}. Открыт ещё $minsLeft мин — успей вступить!',
      );
    }
  }

  // ─── КОМНАТЫ ───────────────────────────────────────────────────────────

  Stream<List<MapEntry<String, Map<String, dynamic>>>> roomsFor(
          String bossId) =>
      _db
          .collection('boss_rooms')
          .where('boss_id', isEqualTo: bossId)
          .snapshots()
          .map((s) => [
                for (final d in s.docs)
                  MapEntry(d.id, Map<String, dynamic>.from(d.data())),
              ])
          .handleError(
              (_) => <MapEntry<String, Map<String, dynamic>>>[]);

  Map<String, dynamic> _myCombat() {
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
    };
  }

  Future<String?> createRoom(String bossId) async {
    final player = PlayerRepository.instance;
    final uid = player.uid;
    final def = bossDef(bossId);
    if (uid == null || def == null) return null;
    final hp = (def['hp'] as num?)?.toInt() ?? 10000;
    final ref = await _db.collection('boss_rooms').add({
      'boss_id': bossId,
      'boss_name': def['name'],
      'creator_name': player.name,
      'creator_uid': uid,
      'players': {uid: _myCombat()},
      'boss_hp': hp,
      'boss_max_hp': hp,
      'status': 'waiting', // waiting → active → finished
      'round': 0,
      'round_seed': Random().nextInt(1 << 31),
      'sels': <String, dynamic>{},
      'ready': <String, dynamic>{},
      'log': [
        {
          't': DateTime.now().millisecondsSinceEpoch,
          'k': 'info',
          's': '🏰 ${player.name} создал комнату. Ждём героев...',
        },
      ],
      'created_at': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<bool> joinRoom(String roomId) async {
    final player = PlayerRepository.instance;
    final uid = player.uid;
    if (uid == null) return false;
    final ref = _db.collection('boss_rooms').doc(roomId);
    final ok = await _db.runTransaction<(bool, String)>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return (false, '');
      final room = snap.data()!;
      // Вступать можно только пока комната ещё не начала бой.
      if (room['status']?.toString() != 'waiting') return (false, '');
      final players = Map<String, dynamic>.from(
          room['players'] as Map<dynamic, dynamic>? ?? const {});
      if (players.length >= 20) return (false, '');
      players[uid] = _myCombat();
      tx.update(ref, {
        'players': players,
        'players_count': players.length,
      });
      return (true, room['boss_name']?.toString() ?? 'мировому боссу');
    });
    if (!ok.$1) return false;
    await ChatService.instance.systemOnce(
      'wrj_${roomId}_${player.name}',
      '👥 ${player.name} вступил в комнату против ${ok.$2}!',
    );
    return true;
  }

  Future<void> leaveRoom(String roomId) async {
    final player = PlayerRepository.instance;
    final uid = player.uid;
    if (uid == null) return;
    final ref = _db.collection('boss_rooms').doc(roomId);
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) return;
        final room = snap.data()!;
        final players = Map<String, dynamic>.from(
            room['players'] as Map<dynamic, dynamic>? ?? const {});
        players.remove(uid);
        if (players.isEmpty) {
          tx.delete(ref);
        } else {
          tx.update(ref, {
            'players': players,
            'players_count': players.length,
          });
        }
      });
    } catch (_) {}
  }

  Future<void> startBattle(String roomId) async {
    await _db.collection('boss_rooms').doc(roomId).update({
      'status': 'active',
      'turn_deadline':
          DateTime.now().millisecondsSinceEpoch + turnSeconds * 1000,
    });
  }

  Future<void> submitSelection({
    required String roomId,
    required String uid,
    required String atk,
    String atk2 = '',
    required Set<String> def,
  }) async {
    await _db.collection('boss_rooms').doc(roomId).set({
      'sels.$uid': {
        'atk': atk,
        if (atk2.isNotEmpty) 'atk2': atk2,
        'def': def.toList(),
      },
      'ready.$uid': true,
    }, SetOptions(merge: true));
  }

  /// Общий HP босса дерутся все игроки комнаты. Раунд решается транзакцией:
  /// все готовы ИЛИ вышло время (молчуны пропускают защитные зоны, как в БК).
  Future<bool> resolveIfReady(String roomId, String myUid) async {
    final ref = _db.collection('boss_rooms').doc(roomId);
    var resolved = false;
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final room = snap.data()!;
      if (room['status']?.toString() != 'active') return;
      final players = Map<String, dynamic>.from(
          room['players'] as Map<dynamic, dynamic>? ?? const {});
      if (players.isEmpty || !players.containsKey(myUid)) return;
      final readyRaw = room['ready'] as Map<dynamic, dynamic>? ?? const {};
      final now = DateTime.now().millisecondsSinceEpoch;
      final deadline = (room['turn_deadline'] as num?)?.toInt() ?? 0;
      final allReady = players.keys.every((u) => readyRaw[u] == true);
      final timeout = deadline > 0 && now > deadline;
      if (!allReady && !timeout) return;

      final selsRaw = room['sels'] as Map<dynamic, dynamic>? ?? const {};
      final sels = <String, Map<String, dynamic>>{};
      final parts = attackParts.keys.toList();
      for (final uid in players.keys) {
        final raw = selsRaw[uid];
        sels[uid] = raw is Map
            ? Map<String, dynamic>.from(raw)
            : {
                'atk': parts[Random((room['round_seed'] as num).toInt() +
                        uid.hashCode.abs())
                    .nextInt(parts.length)],
                'def': <String>[],
              };
      }

      final bossDefMap = bossDef(room['boss_id']?.toString() ?? '');
      var bossHp = (room['boss_hp'] as num?)?.toInt() ?? 0;
      final round = (room['round'] as num?)?.toInt() ?? 0;
      final seed = (room['round_seed'] as num?)?.toInt() ?? 1;
      final rng = Random(seed);
      final log = (room['log'] as List<dynamic>? ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final t = now;
      final bossName =
          bossDefMap?['name']?.toString() ?? 'Мировой босс';

      // 1) Каждый живой игрок бьёт босса.
      // 2) Босс бьёт каждого живого игрока.
      for (final entry in players.entries) {
        final uid = entry.key;
        final p = Map<String, dynamic>.from(entry.value as Map);
        if (((p['hp'] as num?)?.toInt() ?? 0) <= 0) {
          p['hp'] = 0;
          players[uid] = p;
          continue;
        }
        // Игрок → босс
        final sel = sels[uid] ?? const {};
        final part = (sel['atk'] ?? 'chest').toString();
        final zone = attackPartNames[part]?.toLowerCase() ?? 'грудь';
        var dmg = ((p['attack'] as num?)?.toDouble() ?? 50) *
            0.9 *
            (0.85 + rng.nextDouble() * 0.3);
        if (rng.nextDouble() * 100 <
            ((p['critChance'] as num?)?.toDouble() ?? 5)) {
          dmg *= ((p['critDamage'] as num?)?.toDouble() ?? 150) / 100;
          log.add({
            't': t,
            'k': 'crit',
            's': '💥 КРИТ! ${p['name']} пробивает $bossName в $zone: −${dmg.round()} HP',
          });
        } else {
          log.add({
            't': t,
            'k': 'damage',
            's': '🔥 ${p['name']} бьёт $bossName в $zone: −${dmg.round()} HP',
          });
        }
        bossHp = max(0, bossHp - dmg.round());
        if (bossHp <= 0) break;
        // Второе оружие.
        final atk2 = sel['atk2']?.toString() ?? '';
        if ((p['dualWield'] as bool?) == true && atk2.isNotEmpty && bossHp > 0) {
          var dmg2 = ((p['attack'] as num?)?.toDouble() ?? 50) *
              0.9 *
              0.65 *
              (0.85 + rng.nextDouble() * 0.3);
          if (bossHp - dmg2.round() <= 0) dmg2 = bossHp.toDouble();
          bossHp = max(0, bossHp - dmg2.round());
          log.add({
            't': t,
            'k': 'damage',
            's': '🔥 ${p['name']} бьёт вторым оружием: −${dmg2.round()} HP',
          });
          if (bossHp <= 0) break;
        }
      }

      // Босс отвечает, если жив.
      if (bossHp > 0) {
        final atkMin = (bossDefMap?['attack_min'] as num?)?.toDouble() ?? 100;
        final atkMax = (bossDefMap?['attack_max'] as num?)?.toDouble() ?? 200;
        final bossDamage = atkMin + rng.nextDouble() * (atkMax - atkMin);
        final availParts = attackParts.keys.toList();
        for (final entry in players.entries) {
          final uid = entry.key;
          final p = Map<String, dynamic>.from(entry.value as Map);
          if (((p['hp'] as num?)?.toInt() ?? 0) <= 0) {
            players[uid] = p;
            continue;
          }
          final part = availParts[rng.nextInt(availParts.length)];
          final defSel = sels[uid] ?? const {};
          final defZones = ((defSel['def'] as List?) ?? const [])
              .map((e) => e.toString())
              .toSet();
          final zone = attackPartNames[part]?.toLowerCase() ?? 'грудь';
          if (rng.nextDouble() * 100 <
              ((p['evasion'] as num?)?.toDouble() ?? 5)) {
            log.add({
              't': t,
              'k': 'dodge',
              's': '💨 ${p['name']} уворачивается от удара босса в $zone.',
            });
          } else {
            var dmg = (bossDamage *
                    (attackParts[part] ?? 1.0) *
                    (0.85 + rng.nextDouble() * 0.3))
                .round();
            if (defZones.contains(part)) {
              dmg = max(1, (dmg * 0.25).round());
              log.add({
                't': t,
                'k': 'block',
                's': '🛡 ${p['name']} блокирует удар босса в $zone: −$dmg HP',
              });
            } else {
              log.add({
                't': t,
                'k': 'damage',
                's': '🔥 Босс бьёт ${p['name']} в $zone: −$dmg HP',
              });
            }
            p['hp'] = max(0, ((p['hp'] as num?)?.toInt() ?? 0) - dmg);
            if (((p['hp'] as num?)?.toInt() ?? 0) <= 0) {
              log.add({
                't': t,
                'k': 'info',
                's': '☠️ ${p['name']} пал в бою!',
              });
            }
            players[uid] = p;
          }
        }
      }

      final newRound = round + 1;
      final update = <String, dynamic>{
        'players': players,
        'players_count': players.length,
        'boss_hp': bossHp,
        'sels': <String, dynamic>{},
        'ready': <String, dynamic>{},
        'round': newRound,
        'round_seed': (seed * 1103515245 + 12345) % (1 << 31),
        'log': log.length > 80 ? log.sublist(log.length - 80) : log,
      };

      String? outcome; // 'players' | 'failed'
      if (bossHp <= 0) outcome = 'players';
      final anyAlive = players.values.any(
          (v) => (((v as Map)['hp'] as num?)?.toInt() ?? 0) > 0);
      if (!anyAlive) outcome = 'failed';

      if (outcome != null) {
        update['status'] = 'finished';
        update['outcome'] = outcome;
        update['turn_deadline'] = 0;
        if (outcome == 'players') {
          update['loot'] = _rollLoot(bossDefMap, players, newRound);
          log.add({
            't': now,
            'k': 'result',
            's': '🏆 $bossName ПОВЕРЖЕН! ($newRound раундов). Дрол разослан каждому!',
          });
        } else {
          log.add({
            't': now,
            'k': 'result',
            's': '☠️ Все герои пали... $bossName победил. Возвращайтесь в следующее окно!',
          });
        }
        update['log'] = log.length > 80 ? log.sublist(log.length - 80) : log;
      } else {
        update['turn_deadline'] = now + turnSeconds * 1000;
      }
      tx.update(ref, update);
      resolved = true;
    });
    return resolved;
  }

  /// ИНДИВИДУАЛЬНЫЙ ролл дропа для каждого игрока (как договорились).
  Map<String, dynamic> _rollLoot(Map<String, dynamic>? bossDefMap,
      Map<String, dynamic> players, int seed) {
    final dropsRaw = (bossDefMap?['drops'] as List<dynamic>? ?? const [])
        .whereType<Map<dynamic, dynamic>>()
        .toList();
    final rewards = bossDefMap?['rewards'] as Map<dynamic, dynamic>? ?? const {};
    final exp = (rewards['exp'] as num?)?.toInt() ?? 0;
    final gold = (rewards['gold'] as num?)?.toInt() ?? 0;
    final loot = <String, dynamic>{};
    players.forEach((uid, v) {
      final rng = Random(seed.hashCode ^ uid.hashCode);
      final items = <Map<String, dynamic>>[];
      for (final d in dropsRaw) {
        final chance = (d['chance'] as num?)?.toDouble() ?? 0;
        final roll = rng.nextDouble() * 100;
        if (roll < chance) {
          final info = ItemsCatalog.instance.itemById(d['item']?.toString() ?? '');
          items.add({
            'id': d['item']?.toString() ?? '',
            'name': d['name']?.toString() ??
                info['name']?.toString() ??
                (d['item']?.toString() ?? ''),
            'icon': info['icon']?.toString() ??
                d['icon']?.toString() ??
                '❓',
            'quantity': 1,
          });
        }
      }
      loot[uid] = {
        'items': items,
        'exp': exp,
        'gold': gold,
      };
    });
    return loot;
  }

  /// Забрать свои награды за комнату (один раз на комнату).
  Future<String> claimRoomRewards(String roomId) async {
    final player = PlayerRepository.instance;
    try {
      final claimed = Map<String, dynamic>.from(
          player.data?['boss_rewarded'] as Map<dynamic, dynamic>? ?? {});
      if (claimed[roomId] == true) return 'already';
      final snap = await _db.collection('boss_rooms').doc(roomId).get();
      final room = snap.data();
      if (room == null || room['status']?.toString() != 'finished') {
        return 'no';
      }
      final uid = player.uid ?? '';
      final loot = Map<String, dynamic>.from(
          room['loot'] as Map<dynamic, dynamic>? ?? {});
      final mine = loot[uid] as Map<dynamic, dynamic>?;
      if (mine == null) {
        claimed[roomId] = true;
        await player.replaceField('boss_rewarded', claimed);
        return 'no';
      }
      final items = ((mine['items'] as List?) ?? const [])
          .whereType<Map<dynamic, dynamic>>();
      for (final it in items) {
        await player.addInventoryItem({
          'id': it['id'],
          'name': it['name'],
          'icon': it['icon'],
          'quantity': (it['quantity'] as num?)?.toInt() ?? 1,
        });
      }
      final won = room['outcome']?.toString() == 'players';
      await player.grantBattleRewards(
        gold: (mine['gold'] as num?)?.toInt() ?? 0,
        exp: (mine['exp'] as num?)?.toInt() ?? 0,
        victory: won,
      );
      claimed[roomId] = true;
      await player.replaceField('boss_rewarded', claimed);
      return won ? 'win' : 'lose';
    } catch (_) {
      return 'error';
    }
  }
}
