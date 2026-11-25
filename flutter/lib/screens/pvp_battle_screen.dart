import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../services/battle_engine.dart';
import '../services/player_repository.dart';
import '../services/pvp_service.dart';
import '../services/resource_service.dart';
import '../widgets/game_image.dart';

/// Реальный PvP-бой через Firestore. Слева — я, справа — противник.
/// Лог общий (как в БК на арене), выбор зон синхронный.
class PvpBattleScreen extends StatefulWidget {
  final String battleId;
  const PvpBattleScreen({super.key, required this.battleId});

  @override
  State<PvpBattleScreen> createState() => _PvpBattleScreenState();
}

class _PvpBattleScreenState extends State<PvpBattleScreen> {
  final PvpService _pvp = PvpService.instance;
  StreamSubscription? _sub;
  Map<String, dynamic>? _battle;
  bool _submitted = false;
  Timer? _tick;
  int _secondsLeft = PvpService.turnSeconds;
  bool _rewardsShown = false;

  String? _myUid;
  String? _foeUid;

  // Мой выбор на текущий раунд.
  String? _selAtk;
  String? _selAtk2;
  final Set<String> _selDef = {};

  @override
  void initState() {
    super.initState();
    _myUid = PlayerRepository.instance.uid;
    _listen();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      final deadline =
          (_battle?['turn_deadline'] as num?)?.toInt() ?? 0;
      final left = ((deadline - DateTime.now().millisecondsSinceEpoch) / 1000)
          .ceil();
      if (!mounted) return;
      setState(() => _secondsLeft = left.clamp(0, PvpService.turnSeconds));
      // Время вышло — пусть любой клиент подтолкнёт раунд (пропуски как в БК).
      if (left <= 0 && _battle?['status']?.toString() == 'active' && !_submitted) {
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
        .collection('pvp_battles')
        .doc(widget.battleId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists) return;
      final b = Map<String, dynamic>.from(snap.data()!);
      final ps = (b['ps'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList();
      final newRound = (b['round'] as num?)?.toInt() ?? 0;
      final oldRound = (_battle?['round'] as num?)?.toInt() ?? 0;
      _battle = b;
      if (ps.length >= 2) {
        _foeUid = ps.firstWhere((u) => u != _myUid, orElse: () => ps.first);
      }
      if (newRound != oldRound) {
        // Новый раунд — сбрасываем выбор.
        _submitted = false;
        _selAtk = null;
        _selAtk2 = null;
        _selDef.clear();
      }
      if (mounted) setState(() {});
      _tryResolve();
      if (b['status']?.toString() == 'finished' && !_rewardsShown) {
        _rewardsShown = true;
        _showRewards();
      }
    }, onError: (_) {});
  }

  Map<String, dynamic> _statsOf(String uid) {
    final c = Map<String, dynamic>.from(
        _battle?['combat'] as Map<String, dynamic>? ?? const {});
    return Map<String, dynamic>.from(c[uid] as Map<String, dynamic>? ?? const {});
  }

  bool get _myDualWield {
    final s = _statsOf(_myUid ?? '');
    final has2 = (s['dualWield'] as bool?) == true;
    return has2;
  }

  bool get _myReady =>
      _battle?['ready']?[_myUid] == true || _submitted;

  bool get _foeReady => _battle?['ready']?[_foeUid] == true;

  int get _roundNo => (_battle?['round'] as num?)?.toInt() ?? 0;

  bool get _canStrike =>
      _battle?['status']?.toString() == 'active' &&
      _selAtk != null &&
      _selDef.length == 2 &&
      (!_myDualWield || _selAtk2 != null) &&
      !_myReady &&
      _secondsLeft > 0;

  Future<void> _strike() async {
    if (!_canStrike || _myUid == null) return;
    _submitted = true;
    await _pvp.submitSelection(
      battleId: widget.battleId,
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
      await _pvp.resolveIfReady(widget.battleId, _myUid!);
    } catch (_) {}
  }

  Future<void> _showRewards() async {
    final iWon = _battle?['winner']?.toString() == _myUid;
    final bet = ((_battle?['bet'] as num?)?.toInt() ?? 0);
    try {
      await _pvp.grantRewards(widget.battleId);
    } catch (_) {}
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: kPanelColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: iWon ? Colors.green : Colors.red, width: 2),
        ),
        title: Text(
          iWon ? '🏆 ПОБЕДА В АРЕНЕ!' : '☠️ ПОРАЖЕНИЕ',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: iWon ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              iWon
                  ? '⭐ Рейтинг: +${PvpService.ratingWin}'
                  : '⭐ Рейтинг: −${PvpService.ratingLose}',
              style: const TextStyle(color: kGoldColor, fontSize: 16),
            ),
            if (bet > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  iWon
                      ? '💰 Ставка выиграна: +$bet'
                      : '💰 Ставка проиграна: −$bet',
                  style: const TextStyle(color: kGoldColor, fontSize: 15),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context)
                ..pop() // диалог
                ..pop(); // бой
            },
            child: const Text('К арене',
                style: TextStyle(color: kGoldColor)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── КУКЛЫ И ИНТЕРФЕЙС ────────────────────────

  Widget _statLine(Map<String, dynamic> s) {
    final parts = [
      '⚔️${(s['attack'] as num?)?.toInt() ?? 0}',
      '🛡️${(s['defense'] as num?)?.toInt() ?? 0}',
      '💨${(s['evasion'] as num?)?.toInt() ?? 0}%',
      '🎯${(s['critChance'] as num?)?.toInt() ?? 0}%',
      if ((s['dualWield'] as bool?) == true) '✌️2×удар',
    ];
    return Text(parts.join('  '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 10, color: Colors.white70));
  }

  Widget _hpBar(Map<String, dynamic> s, Color color) {
    final hp = (s['hp'] as num?)?.toInt() ?? 0;
    final maxHp = ((s['maxHp'] as num?)?.toInt() ?? 1).clamp(1, 1 << 30);
    final pct = (hp / maxHp).clamp(0.0, 1.0);
    return Column(
      children: [
        Text('${s['name'] ?? '?'} (ур. ${(s['level'] as num?)?.toInt() ?? 1})',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Stack(children: [
          Container(
              height: 12,
              decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(6))),
          FractionallySizedBox(
            widthFactor: pct,
            child: Container(
                height: 12,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(6))),
          ),
        ]),
        const SizedBox(height: 2),
        Text('$hp/$maxHp',
            style: const TextStyle(fontSize: 10, color: Colors.white54)),
      ],
    );
  }

  Widget _gearSlot(Map<String, dynamic> equipment, String key, double size) {
    final inst = equipment[key];
    final has = inst is Map<String, dynamic>;
    final icon = has ? (inst['icon']?.toString() ?? '') : '';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(
            color: has ? kGoldColor : kGoldColor.withOpacity(0.35),
            width: has ? 1.5 : 1),
        borderRadius: BorderRadius.circular(6),
        color: const Color(0x33221D18),
      ),
      child: Center(
        child: has && icon.startsWith('http')
            ? GameImage(icon,
                width: size * 0.7, height: size * 0.7, fit: BoxFit.contain)
            : Text(icon,
                style: TextStyle(
                    fontSize: has ? size * 0.55 : 8,
                    color: has ? Colors.white : Colors.white24)),
      ),
    );
  }

  Widget _gearColumn(Map<String, dynamic> equipment, List<String> keys,
      {double size = 20}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final k in keys)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: _gearSlot(equipment, k, size),
          ),
      ],
    );
  }

  Widget _fighterPanel(String? uid, {required bool isMe}) {
    final s = _statsOf(uid ?? '');
    final equipment =
        (s['equipment'] as Map<String, dynamic>?) ?? const {};
    final look = s['look']?.toString() ?? '';
    final doll = Container(
      width: 108,
      height: 152,
      decoration: BoxDecoration(
        border: Border.all(
            color: isMe ? kGoldColor : const Color(0xFFCC4D4D), width: 1.5),
        borderRadius: BorderRadius.circular(8),
        color: const Color(0x33221D18),
      ),
      child: look.isNotEmpty &&
              (look.startsWith('http') ||
                  ResourceService.instance.filePath(look) != null)
          ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: GameImage(look, fit: BoxFit.contain)))
          : const Center(
              child: Text('🧍',
                  style: TextStyle(fontSize: 44, color: Colors.white24))),
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _hpBar(s, isMe ? const Color(0xFF2E7D32) : const Color(0xFFB71C1C)),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _gearColumn(
                equipment, ['mask', 'helmet', 'armor', 'shirt', 'pants', 'boots']),
            const SizedBox(width: 5),
            doll,
            const SizedBox(width: 5),
            _gearColumn(equipment, [
              'weapon',
              'weapon2',
              'shield',
              'gloves',
              'cloak',
              'necklace',
              'bracelet'
            ]),
          ],
        ),
        const SizedBox(height: 3),
        _statLine(s),
        if (isMe && _myReady)
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text('✅ Выбор сделан — ждём противника...',
                style: TextStyle(fontSize: 10, color: Color(0xFF80FF80))),
          )
        else if (!isMe && _foeReady)
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text('⚡ Противник готов!',
                style: TextStyle(fontSize: 10, color: Color(0xFFFFB34D))),
          ),
      ],
    );
  }

  Widget _logLine(Map<String, dynamic> e, Color base) {
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
              style: const TextStyle(fontSize: 11, color: Color(0xFF4CD964))),
          TextSpan(
              text: e['s']?.toString() ?? '',
              style: TextStyle(fontSize: 12, color: kinds[e['k']] ?? base)),
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
            side: BorderSide(
                color: on ? Colors.white : accent.withOpacity(0.7)),
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
    final b = _battle;
    if (b == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('⚔️ Аренный бой')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final finished = b['status']?.toString() != 'active';

    return Scaffold(
      appBar: AppBar(
        title: Text('⚔️ Арена — раунд ${_roundNo + (finished ? 0 : 1)}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 252,
            child: Container(
              width: double.infinity,
              color: const Color(0x33000000),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(children: [
                Expanded(child: _fighterPanel(_myUid, isMe: true)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text('⚔️',
                      style: TextStyle(fontSize: 24, color: kGoldColor)),
                ),
                Expanded(child: _fighterPanel(_foeUid, isMe: false)),
              ]),
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
                  for (final e
                      in ((b['log'] as List<dynamic>? ?? const [])
                            .map((x) =>
                                Map<String, dynamic>.from(x as Map))
                            .toList()
                          ..sort((a, z) =>
                              ((a['t'] as num?) ?? 0)
                                  .compareTo((z['t'] as num?) ?? 0)))
                          .reversed)
                    _logLine(e, Colors.white),
                ],
              ),
            ),
          ),
          Container(
            color: kPanelColor,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  finished
                      ? 'Бой окончен'
                      : '⏱ Время на ход: ${_secondsLeft.round()} сек',
                  style: TextStyle(
                      fontSize: 12,
                      color: finished
                          ? Colors.white54
                          : (_secondsLeft <= 10
                              ? const Color(0xFFFF6B6B)
                              : Colors.white70)),
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
                Text(
                    'Защита — выбери 2 зоны (${_selDef.length}/2):',
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
                        finished
                            ? 'Бой окончен'
                            : (_myReady ? 'Ждём противника…' : 'УДАРИТЬ!'),
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
