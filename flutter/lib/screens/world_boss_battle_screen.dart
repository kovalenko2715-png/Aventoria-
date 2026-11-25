import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../services/battle_engine.dart';
import '../services/player_repository.dart';
import '../services/resource_service.dart';
import '../services/world_boss_service.dart';
import '../widgets/game_image.dart';

/// Командный бой с мировым боссом: общий HP босса дерутся все игроки комнаты,
/// раунды синхронны (60 сек на ход), дроп каждому — отдельный ролл.
class WorldBossBattleScreen extends StatefulWidget {
  final String roomId;
  const WorldBossBattleScreen({super.key, required this.roomId});

  @override
  State<WorldBossBattleScreen> createState() => _WorldBossBattleScreenState();
}

class _WorldBossBattleScreenState extends State<WorldBossBattleScreen> {
  final WorldBossService _svc = WorldBossService.instance;
  StreamSubscription? _sub;
  Map<String, dynamic>? _room;
  bool _submitted = false;
  Timer? _tick;
  int _secondsLeft = WorldBossService.turnSeconds;
  bool _rewardsShown = false;

  String? _myUid;
  String? _artId;

  String? _selAtk;
  String? _selAtk2;
  final Set<String> _selDef = {};

  static const Map<String, String> _bossArt = {
    'ancient_dragon': 'dragon',
    'demon_lord': 'demon',
  };

  @override
  void initState() {
    super.initState();
    _myUid = PlayerRepository.instance.uid;
    final bossId = _room?['boss_id']?.toString() ?? '';
    _artId = _bossArt[bossId] ?? '';
    _listen();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      final deadline =
          (_room?['turn_deadline'] as num?)?.toInt() ?? 0;
      final left =
          ((deadline - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();
      if (!mounted) return;
      setState(
          () => _secondsLeft = left.clamp(0, WorldBossService.turnSeconds));
      if (left <= 0 &&
          _room?['status']?.toString() == 'active' &&
          !_submitted) {
        _tryResolve();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  void _listen() {
    _sub = FirebaseFirestore.instance
        .collection('boss_rooms')
        .doc(widget.roomId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists) return;
      final r = Map<String, dynamic>.from(snap.data()!);
      final newRound = (r['round'] as num?)?.toInt() ?? 0;
      final oldRound = (_room?['round'] as num?)?.toInt() ?? 0;
      final bossId = r['boss_id']?.toString() ?? '';
      _artId = _bossArt[bossId] ?? '';
      _room = r;
      if (newRound != oldRound) {
        _submitted = false;
        _selAtk = null;
        _selAtk2 = null;
        _selDef.clear();
      }
      if (mounted) setState(() {});
      _tryResolve();
      if (r['status']?.toString() == 'finished' && !_rewardsShown) {
        _rewardsShown = true;
        _showRewards();
      }
    }, onError: (_) {});
  }

  Map<String, dynamic> _players() =>
      Map<String, dynamic>.from(
          _room?['players'] as Map<dynamic, dynamic>? ?? const {});

  Map<String, dynamic> _me() =>
      Map<String, dynamic>.from(_players()[_myUid] as Map<dynamic, dynamic>? ??
          const {});

  bool get _myDualWield => (_me()['dualWield'] as bool?) == true;

  bool get _myReady => _room?['ready']?[_myUid] == true || _submitted;

  int get _roundNo => (_room?['round'] as num?)?.toInt() ?? 0;

  bool get _waiting => _room?['status']?.toString() == 'waiting';
  bool get _finished => _room?['status']?.toString() == 'finished';
  bool get _isCreator =>
      _room?['creator_uid']?.toString() == _myUid ||
      _room?['creator_name']?.toString() ==
          PlayerRepository.instance.name;

  bool get _canStrike =>
      _room?['status']?.toString() == 'active' &&
      _selAtk != null &&
      _selDef.length == 2 &&
      (!_myDualWield || _selAtk2 != null) &&
      !_myReady &&
      _secondsLeft > 0 &&
      ((_me()['hp'] as num?)?.toInt() ?? 0) > 0;

  Future<void> _strike() async {
    if (!_canStrike || _myUid == null) return;
    _submitted = true;
    await _svc.submitSelection(
      roomId: widget.roomId,
      uid: _myUid!,
      atk: _selAtk!,
      atk2: _selAtk2 ?? '',
      def: _selDef,
    );
    if (mounted) setState(() {});
  }

  Future<void> _tryResolve() async {
    if (_myUid == null) return;
    try {
      await _svc.resolveIfReady(widget.roomId, _myUid!);
    } catch (_) {}
  }

  Future<void> _showRewards() async {
    try {
      final result = await _svc.claimRoomRewards(widget.roomId);
      if (!mounted) return;
      final won = result == 'win';
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: kPanelColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: won ? Colors.green : Colors.red, width: 2),
          ),
          title: Text(
            won ? '🏆 БОСС ПОВЕРЖЕН!' : '☠️ Герои пали...',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: won ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold),
          ),
          content: Text(
            won
                ? 'Награда получена: опыт, золото и твой личный ролл дропа — загляни в инвентарь!'
                : 'Босс победил в этот раз. Когда он пробудится снова — будет новый бой.',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context)
                ..pop()
                ..pop(),
              child: const Text('К боссам',
                  style: TextStyle(color: kGoldColor)),
            ),
          ],
        ),
      );
    } catch (_) {}
  }

  // ─── UI ─────────────────────────────────────────────────────────────────

  Widget _bossPanel(Map<String, dynamic> r) {
    final bossName = r['boss_name']?.toString() ?? 'Мировой босс';
    final hp = (r['boss_hp'] as num?)?.toInt() ?? 0;
    final maxHp = ((r['boss_max_hp'] as num?)?.toInt() ?? 1).clamp(1, 1 << 30);
    final pct = (hp / maxHp).clamp(0.0, 1.0);
    final icon =
        (WorldBossService.instance.bossDef(r['boss_id'] ?? '')?['icon'] ?? '💀')
            .toString();
    final useArt = _artId != null &&
        (_artId?.isNotEmpty ?? false) &&
        ResourceService.instance
                .filePath('images/mobs/$_artId.png') !=
            null;
    return Container(
      padding: const EdgeInsets.all(8),
      color: const Color(0x66000000),
      child: Row(
        children: [
          SizedBox(
            width: 86,
            height: 96,
            child: useArt
                ? GameImage('images/mobs/$_artId.png', fit: BoxFit.contain)
                : Center(
                    child: Text(icon, style: const TextStyle(fontSize: 44))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bossName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: kGoldColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Stack(children: [
                  Container(
                      height: 14,
                      decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(7))),
                  FractionallySizedBox(
                    widthFactor: pct,
                    child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                            color: const Color(0xFFB71C1C),
                            borderRadius: BorderRadius.circular(7))),
                  ),
                ]),
                const SizedBox(height: 2),
                Text('$hp / $maxHp HP',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _playerChip(String uid, Map<String, dynamic> p) {
    final hp = (p['hp'] as num?)?.toInt() ?? 0;
    final maxHp = ((p['maxHp'] as num?)?.toInt() ?? 1).clamp(1, 1 << 30);
    final ready = _room?['ready']?[uid] == true;
    final isMe = uid == _myUid;
    final dead = hp <= 0;
    return Container(
      width: 118,
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border.all(
            color: dead
                ? const Color(0xFF666666)
                : (isMe ? kGoldColor : const Color(0xFF4D6ECC)),
            width: 1),
        borderRadius: BorderRadius.circular(6),
        color: const Color(0x33221D18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dead
                ? '☠️ ${p['name'] ?? '?'}'
                : '${p['name'] ?? '?'} (ур. ${(p['level'] as num?)?.toInt() ?? 1})',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: dead ? const Color(0xFF888888) : Colors.white),
          ),
          const SizedBox(height: 3),
          LinearProgressIndicator(
            value: (hp / maxHp).clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: Colors.black45,
            valueColor: AlwaysStoppedAnimation<Color>(dead
                ? const Color(0xFF666666)
                : (isMe ? const Color(0xFF2E7D32) : const Color(0xFF4CAF50))),
          ),
          const SizedBox(height: 3),
          Text(
            dead
                ? 'пал в бою'
                : (ready ? '✅ готов' : '⏳ выбор...'),
            style: TextStyle(
                fontSize: 9,
                color: dead
                    ? const Color(0xFF888888)
                    : (ready
                        ? const Color(0xFF80FF80)
                        : Colors.white54)),
          ),
        ],
      ),
    );
  }

  Widget _logLine(Map<String, dynamic> e) {
    final kinds = {
      'damage': const Color(0xFFFF9248),
      'block': const Color(0xFF80CCFF),
      'dodge': const Color(0xFFCCCCCC),
      'crit': const Color(0xFFFFD700),
      'result': kGoldColor,
      'info': const Color(0xFFB0B0B0),
    };
    final ts = (e['t'] as num?)?.toInt() ?? 0;
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    final stamp =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(
              text: '$stamp ',
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF4CD964))),
          TextSpan(
              text: e['s']?.toString() ?? '',
              style:
                  TextStyle(fontSize: 12, color: kinds[e['k']] ?? Colors.white)),
        ]),
        style: const TextStyle(height: 1.3),
      ),
    );
  }

  Widget _zoneButton(String part, Color accent, bool on, VoidCallback tap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: SizedBox(
        width: 92,
        child: OutlinedButton(
          onPressed: _myReady ? null : tap,
          style: OutlinedButton.styleFrom(
            backgroundColor: on ? accent : null,
            side:
                BorderSide(color: on ? Colors.white : accent.withOpacity(0.7)),
            padding: const EdgeInsets.symmetric(vertical: 8),
            minimumSize: const Size(0, 0),
          ),
          child: Text(attackPartNames[part]!,
              maxLines: 1,
              style: const TextStyle(fontSize: 10, color: Colors.white)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = _room;
    if (r == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('🛡 Бой с боссом')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_finished
            ? '🛡 Бой завершён'
            : '🛡 Мировой босс — раунд ${_roundNo + 1}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _bossPanel(r),
          SizedBox(
            height: 96,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              children: [
                for (final e in _players().entries)
                  _playerChip(
                      e.key,
                      Map<String, dynamic>.from(e.value as Map)),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.black26),
          Expanded(
            child: Container(
              color: const Color(0xFF0D0D0D),
              child: ListView(
                reverse: true,
                padding: const EdgeInsets.all(8),
                children: [
                  for (final e in ((r['log'] as List<dynamic>? ?? const [])
                          .map((x) => Map<String, dynamic>.from(x as Map))
                          .toList()
                        ..sort((a, z) => ((a['t'] as num?) ?? 0)
                            .compareTo((z['t'] as num?) ?? 0)))
                      .reversed)
                    _logLine(e),
                ],
              ),
            ),
          ),
          if (_waiting)
            Container(
              color: kPanelColor,
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      'Комната собрана. Бой начнётся, когда создатель нажмёт «НАЧАТЬ БОЙ».',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _isCreator
                        ? () async {
                            await _svc.startBattle(widget.roomId);
                          }
                        : null,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0x80FFD700)),
                      backgroundColor: const Color(0xFF221D18),
                      minimumSize: const Size(200, 42),
                    ),
                    child: Text(
                        _isCreator
                            ? '⚔️ НАЧАТЬ БОЙ (${_players().length} игроков)'
                            : 'Ждём, пока создатель начнёт бой...',
                        style: const TextStyle(
                            color: kGoldColor, fontSize: 13)),
                  ),
                ],
              ),
            )
          else if (!_finished)
            Container(
              color: kPanelColor,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '⏱ Время на ход: ${_secondsLeft.round()} сек',
                    style: TextStyle(
                        fontSize: 12,
                        color: _secondsLeft <= 10
                            ? const Color(0xFFFF6B6B)
                            : Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      for (final part in attackParts.keys)
                        _zoneButton(
                            part,
                            const Color(0xFFCC4D4D),
                            _selAtk == part,
                            () => setState(() => _selAtk = part)),
                    ],
                  ),
                  if (_myDualWield) ...[
                    const SizedBox(height: 5),
                    Text('Атака — оружие 2 (удар слабее):',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white70)),
                    const SizedBox(height: 4),
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        for (final part in attackParts.keys)
                          _zoneButton(
                              part,
                              const Color(0xFFCC7A4D),
                              _selAtk2 == part,
                              () => setState(() => _selAtk2 = part)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text('Защита — выбери 2 зоны (${_selDef.length}/2):',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white70)),
                  const SizedBox(height: 4),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      for (final part in attackParts.keys)
                        _zoneButton(
                            part,
                            const Color(0xFF4D6ECC),
                            _selDef.contains(part),
                            () => setState(() {
                                  if (_selDef.contains(part)) {
                                    _selDef.remove(part);
                                  } else if (_selDef.length < 2) {
                                    _selDef.add(part);
                                  }
                                })),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: SizedBox(
                      width: 240,
                      height: 44,
                      child: FilledButton(
                        onPressed: _canStrike ? _strike : null,
                        style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFB71C1C)),
                        child: Text(
                          _myReady
                              ? 'Ждём остальных...'
                              : 'УДАРИТЬ! (${_players().length} в бою)',
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              color: kPanelColor,
              padding: const EdgeInsets.all(12),
              child: const Center(
                child: Text('Бой завершён. Награда — в инвентаре.',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ),
            ),
        ],
      ),
    );
  }
}
