import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../services/battle_engine.dart';
import '../services/player_repository.dart';
import '../services/pvp_service.dart';
import '../widgets/module_window.dart';
import 'battle_screen.dart';
import 'pvp_battle_screen.dart';

/// АРЕНА — как в БК: входишь в список бойцов, видишь кто стоит в арене,
/// вызываешь на бой (можно с золотой ставкой), противник принимает/отклоняет.
class ArenaScreen extends StatefulWidget {
  const ArenaScreen({super.key});

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();

  static const MobDef _trainingDummy = MobDef(
    'arena_training',
    'Тренировочный манекен',
    '🎯',
    level: 1,
    hp: 999999,
    strength: 0,
    agility: 0,
    defense: 0,
    attack: 0,
    goldMin: 0,
    goldMax: 0,
    expMin: 0,
    expMax: 0,
  );
}

class _ArenaScreenState extends State<ArenaScreen> {
  static const Map<String, int> _kBetOptions = <String, int>{
    'Без ставки': 0,
    '100 💰': 100,
    '500 💰': 500,
  };

  final PvpService _pvp = PvpService.instance;
  StreamSubscription? _outSub;
  final Set<String> _handledChallenges = <String>{};

  /// Защита от двойного пуша (задвоенный евент стрима).
  bool battleActive = false;

  @override
  void initState() {
    super.initState();
    // Пока открыта арена — следим за своими вызовами: приняли / отклонили.
    _outSub = _pvp.myOutgoingChallenges().listen(_onOutgoing);
  }

  @override
  void dispose() {
    _outSub?.cancel();
    super.dispose();
  }

  void _onOutgoing(QuerySnapshot<Map<String, dynamic>> snap) {
    for (final d in snap.docs) {
      final c = d.data();
      final status = c['status']?.toString() ?? '';
      if (status == 'accepted' && _handledChallenges.add(d.id)) {
        _startAcceptedBattle(c);
        return;
      }
      if (status == 'declined' && _handledChallenges.add(d.id)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '⚔️ ${c['to_name'] ?? 'Противник'} отклонил ваш вызов.')));
      }
    }
  }

  Future<void> _startAcceptedBattle(Map<String, dynamic> challenge) async {
    if (battleActive) return;
    battleActive = true;
    final battleId = await _pvp.createBattle(challenge);
    if (!mounted) return;
    if (battleId == null) {
      battleActive = false;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Не удалось создать аренный бой.')));
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PvpBattleScreen(battleId: battleId)));
    battleActive = false;
    if (mounted) setState(() {});
  }

  Future<void> _toggleArena() async {
    if (_pvp.inArena) {
      await _pvp.leaveArena();
    } else {
      await _pvp.enterArena();
    }
    if (mounted) setState(() {});
  }

  Future<void> _challenge(
      BuildContext context, String toUid, Map<String, dynamic> doc) async {
    final name = doc['name']?.toString() ?? '???';
    final level = (doc['level'] as num?)?.toInt() ?? 1;
    final rating = (doc['rating'] as num?)?.toInt() ?? 1000;
    final myGold = PlayerRepository.instance.gold;
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: kGoldColor.withOpacity(0.6))),
        title: Text('⚔️ Вызов: $name',
            style: const TextStyle(color: kGoldColor, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Уровень: $level   Рейтинг: ⭐$rating',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 4),
            Text('Ваше золото: 💰$myGold',
                style: const TextStyle(color: kGoldColor, fontSize: 13)),
            const SizedBox(height: 10),
            const Text('Ставка (проигравший теряет её):',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            for (final opt in _kBetOptions.keys)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(opt),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0x80FFD700)),
                    backgroundColor: const Color(0xFF221D18),
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  child: Text(opt,
                      style: const TextStyle(color: kGoldColor, fontSize: 13)),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('ОТМЕНА',
                  style: TextStyle(color: Colors.white54))),
        ],
      ),
    );
    if (picked == null || !context.mounted) return;
    final bet = _kBetOptions[picked] ?? 0;
    if (bet > 0 && myGold < bet) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Не хватает золота на такую ставку!')));
      return;
    }
    final id = await _pvp.challenge(toUid, doc, bet: bet);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(id == null
            ? 'Не удалось отправить вызов.'
            : '⚔️ Вызов отправлен $name (ставка: $picked). Ждём ответа...')));
  }

  Future<void> _openTraining(BuildContext context) async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => const BattleScreen(mob: ArenaScreen._trainingDummy)));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вы хорошо потренировались!')));
  }

  @override
  Widget build(BuildContext context) {
    final player = PlayerRepository.instance;
    final inArena = _pvp.inArena;
    final rating = _pvp.myRating;

    return ModuleWindow(
      title: '⚔️ АРЕНА ⚔️',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Шапка: мой рейтинг + вход/выход из списка бойцов.
          Card(
            color: const Color(0xFF1F1A14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
                side: BorderSide(color: kGoldColor.withOpacity(0.3))),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Text('⭐', style: TextStyle(fontSize: 30)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Рейтинг: $rating',
                            style: const TextStyle(
                                color: kGoldColor, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(
                          inArena
                              ? 'Вы стоите в списке бойцов арены'
                              : 'Вы не в списке бойцов',
                          style: TextStyle(
                              color: inArena
                                  ? const Color(0xFF4DCC4D)
                                  : const Color(0xFFCCCCCC),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _toggleArena,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0x80FFD700)),
                      backgroundColor: const Color(0xFF221D18),
                      minimumSize: const Size(130, 38),
                    ),
                    child: Text(inArena ? 'ВЫЙТИ' : 'В АРЕНУ',
                        style:
                            const TextStyle(color: kGoldColor, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
          // Тренировка с манекеном (как раньше).
          Card(
            color: const Color(0xFF1F1A14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
                side: BorderSide(color: kGoldColor.withOpacity(0.3))),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Text('🎯', style: TextStyle(fontSize: 30)),
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ТРЕНИРОВКА',
                            style: TextStyle(color: kGoldColor, fontSize: 15)),
                        SizedBox(height: 2),
                        Text('Бой с манекеном. Проверьте свои силы!',
                            style: TextStyle(
                                color: Color(0xFFCCCCCC), fontSize: 12)),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => _openTraining(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0x80FFD700)),
                      backgroundColor: const Color(0xFF221D18),
                      minimumSize: const Size(120, 35),
                    ),
                    child: const Text('ТРЕНИРОВКА',
                        style: TextStyle(color: kGoldColor, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Center(
              child: Text('БОЙЦЫ В АРЕНЕ',
                  style: TextStyle(color: kGoldColor, fontSize: 15)),
            ),
          ),
          Expanded(
            child: StreamBuilder<
                List<MapEntry<String, Map<String, dynamic>>>>(
              stream: _pvp.arenaPlayers(),
              builder: (context, snap) {
                final players = (snap.data ?? const [])
                    .where((e) => e.key != player.uid)
                    .toList();
                if (players.isEmpty) {
                  return Center(
                    child: Text(
                      inArena
                          ? 'Вы в списке. Ждите противника или вызовите его, когда он войдёт в арену.'
                          : 'Никого нет в арене. Нажмите «В АРЕНУ», чтобы встать в список бойцов.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFF999999), fontSize: 12),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: players.length,
                  itemBuilder: (context, i) {
                    final e = players[i];
                    final doc = e.value;
                    final name = doc['name']?.toString() ?? '???';
                    final level = (doc['level'] as num?)?.toInt() ?? 1;
                    final foeRating = (doc['rating'] as num?)?.toInt() ?? 1000;
                    return Card(
                      color: const Color(0xFF1F1A14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                          side: BorderSide(
                              color: kGoldColor.withOpacity(0.3))),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Text('🧍',
                                  style: TextStyle(fontSize: 24)),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold)),
                                  Text('Уровень $level   Рейтинг ⭐$foeRating',
                                      style: const TextStyle(
                                          color: Color(0xFFCCCCCC),
                                          fontSize: 11)),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () => _challenge(context, e.key, doc),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: Color(0x80FFD700)),
                                backgroundColor: const Color(0xFF221D18),
                                minimumSize: const Size(100, 36),
                              ),
                              child: const Text('⚔️ ВЫЗВАТЬ',
                                  style: TextStyle(
                                      color: kGoldColor, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
