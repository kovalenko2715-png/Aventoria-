import 'dart:math';

import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../main.dart';
import '../services/battle_engine.dart';
import '../services/player_repository.dart';
import '../services/quest_service.dart';

class BattleScreen extends StatefulWidget {
  final MobDef mob;

  const BattleScreen({super.key, required this.mob});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  late BattleEngine _engine;
  bool _rewardsGranted = false;

  @override
  void initState() {
    super.initState();
    _engine = BattleEngine(player: _makePlayerFighter(), mob: widget.mob);
    _engine.addListener(_onEngineChanged);
  }

  @override
  void dispose() {
    _engine.removeListener(_onEngineChanged);
    super.dispose();
  }

  Fighter _makePlayerFighter() {
    final player = PlayerRepository.instance;
    final stats = player.data?['stats'] as Map<String, dynamic>? ?? const {};
    int stat(String key) => (stats[key] as num?)?.toInt() ?? 0;
    final level = player.level;
    return Fighter(
      name: player.name,
      level: level,
      attack: 40 + stat('strength') * 2 + level * 2,
      defense: 25 + stat('endurance') * 2,
      agility: stat('agility'),
      intuition: stat('intuition'),
      maxHp: 100 + stat('endurance') * 5 + level * 10,
    );
  }

  void _onEngineChanged() {
    if (_engine.finished && !_rewardsGranted) {
      _rewardsGranted = true;
      _grantRewards();
    }
    if (mounted) setState(() {});
  }

  Map<String, dynamic>? get _bossDef {
    final id = widget.mob.id;
    if (!id.startsWith('boss_')) return null;
    final short = id.substring(5);
    for (final db in [bossesDungeon, bossesWorld, bossesEvent]) {
      final def = db[short] as Map<String, dynamic>?;
      if (def != null) return def;
    }
    return null;
  }

  Future<String?> _rollBossDrop() async {
    final boss = _bossDef;
    final player = PlayerRepository.instance;
    if (boss != null) {
      final pvp = Map<String, dynamic>.from(
          player.data?['stats_pvp'] as Map<String, dynamic>? ?? const {});
      pvp['bosses'] = ((pvp['bosses'] as num?)?.toInt() ?? 0) + 1;
      await player.replaceField('stats_pvp', pvp);
      for (final drop in (boss['drops'] as List<dynamic>? ?? const [])) {
        final chance = ((drop as Map<String, dynamic>)['chance'] as num?)?.toInt() ?? 0;
        if (Random().nextInt(100) < chance) {
          await player.addInventoryItem({
            'id': drop['item'],
            'icon': drop['icon'] ?? '🎁',
            'name': drop['name'],
            'level': boss['level'] ?? 1,
            'type': 'material',
            'description': 'Трофей босса ${boss['name']}.',
            'durability': 100,
            'price': chance * 10,
            'requirements': const {},
            'bonuses': const {},
          });
          return drop['name']?.toString();
        }
      }
    }
    return null;
  }

  Future<void> _grantRewards() async {
    final exp = _engine.victory ? _engine.expReward : (_engine.expReward ~/ 5);
    final gold = _engine.victory ? _engine.goldReward : 0;
    final result = await PlayerRepository.instance
        .grantBattleRewards(gold: gold, exp: exp, victory: _engine.victory);
    await QuestState.instance.recordKillProgress(
        PlayerRepository.instance, widget.mob.id,
        kills: _engine.victory ? 1 : 0);
    final dropName = _engine.victory ? await _rollBossDrop() : null;
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: kPanelColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: _engine.victory ? Colors.green : Colors.red,
            width: 2,
          ),
        ),
        title: Text(
          _engine.victory ? '🏆 ПОБЕДА!' : '☠️ ПОРАЖЕНИЕ',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _engine.victory ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dropName != null) ...[
              _rewardRow('🎁 Трофей: $dropName!'),
              const SizedBox(height: 4),
            ],
            if (_engine.victory) ...[
              _rewardRow('💰 Золото: +${result.goldGained}'),
              _rewardRow('⭐ Опыт: +${result.expGained}'),
            ] else
              _rewardRow('⭐ Опыт за мужество: +${result.expGained}'),
            if (result.leveledUp) ...[
              const SizedBox(height: 8),
              _rewardRow(
                  '🎉 Новый уровень: ${result.levelBefore} → ${result.levelAfter}!'),
              _rewardRow('● Очков статов: +${result.statPointsGained}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('К списку монстров'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _engine = BattleEngine(
                    player: _makePlayerFighter(), mob: widget.mob);
                _rewardsGranted = false;
              });
            },
            child: const Text('Бой снова'),
          ),
        ],
      ),
    );
  }

  Widget _rewardRow(String text) => Text(
        text,
        style: const TextStyle(color: kGoldColor, fontSize: 16),
      );

  Color _logColor(BattleLogKind kind) {
    switch (kind) {
      case BattleLogKind.damage:
        return const Color(0xFFFF8080);
      case BattleLogKind.block:
        return const Color(0xFF80CCFF);
      case BattleLogKind.dodge:
        return const Color(0xFFCCCCCC);
      case BattleLogKind.result:
        return kGoldColor;
      case BattleLogKind.info:
        return const Color(0xFFB0B0B0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('⚔️ ${widget.mob.emoji} ${widget.mob.name}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _hpPanels(),
          const Divider(height: 1, color: Colors.black26),
          Expanded(child: _logPanel()),
          _choicePanels(),
        ],
      ),
    );
  }

  Widget _hpPanels() {
    final player = _engine.player;
    final enemy = _engine.enemy;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _fighterPanel(player, const Color(0xFF2E7D32))),
          const Icon(Icons.sports_mma, color: kGoldColor, size: 28),
          Expanded(child: _fighterPanel(enemy, const Color(0xFFB71C1C))),
        ],
      ),
    );
  }

  Widget _fighterPanel(Fighter f, Color barColor) {
    final pct = f.hp / f.maxHp;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${f.name} (ур. ${f.level})',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(
              height: 14,
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            FractionallySizedBox(
              widthFactor: pct.clamp(0.0, 1.0),
              child: Container(
                height: 14,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text('${f.hp}/${f.maxHp}',
            style: const TextStyle(fontSize: 11, color: Colors.white54)),
      ],
    );
  }

  Widget _logPanel() {
    final log = _engine.log.reversed.toList();
    return Container(
      color: const Color(0xFF0D0D0D),
      child: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: log.length,
        itemBuilder: (context, i) {
          final entry = log[i];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              entry.text,
              style: TextStyle(
                fontSize: 12,
                color: _logColor(entry.kind),
                height: 1.3,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _choicePanels() {
    return Container(
      color: kPanelColor,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('АТАКА — выберите зону:',
                style: TextStyle(fontSize: 12, color: Colors.white70)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final part in attackParts.keys)
                Expanded(child: _zoneButton(part)),
            ],
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('ЗАЩИТА — выберите пару:',
                style: TextStyle(fontSize: 12, color: Colors.white70)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final pair in blockPairs.keys)
                Expanded(child: _blockButton(pair)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _engine.readyToStrike ? _engine.strike : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C),
              ),
              child: Text(
                _engine.finished ? 'Бой окончен' : 'УДАРИТЬ!',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _zoneButton(String part) {
    final selected = _engine.selectedAttack == part;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: OutlinedButton(
        onPressed: () => _engine.selectAttack(part),
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? const Color(0xFFCC4D4D) : null,
          side: BorderSide(
            color: selected ? Colors.white : const Color(0xFFCC4D4D),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: Text(
          attackPartNames[part]!,
          style: const TextStyle(fontSize: 10, color: Colors.white),
        ),
      ),
    );
  }

  Widget _blockButton(String pair) {
    final selected = _engine.selectedBlock == pair;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: OutlinedButton(
        onPressed: () => _engine.selectBlock(pair),
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? const Color(0xFF4D6ECC) : null,
          side: BorderSide(
            color: selected ? Colors.white : const Color(0xFF4D6ECC),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: Text(
          blockPairNames[pair]!,
          style: const TextStyle(fontSize: 9, color: Colors.white),
        ),
      ),
    );
  }
}
