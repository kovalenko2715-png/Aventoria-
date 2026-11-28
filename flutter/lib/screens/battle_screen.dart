import 'dart:math';

import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../main.dart';
import '../services/audio_manager.dart';
import '../services/battle_engine.dart';
import '../services/combat_service.dart';
import '../services/player_repository.dart';
import '../services/quest_service.dart';
import '../services/resource_service.dart';
import '../widgets/game_image.dart';
import '../widgets/mob_art.dart';

class BattleScreen extends StatefulWidget {
  final MobDef mob;

  const BattleScreen({super.key, required this.mob});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  late BattleEngine _engine;
  bool _rewardsGranted = false;

  // Итоговые статы игрока со шмотом — показываем на панели куклы.
  late final CombatStats _combat;

  @override
  void initState() {
    super.initState();
    _combat = _computeCombat();
    _engine = BattleEngine(
        player: _makePlayerFighter(_combat), mob: widget.mob,
        dualWield: _combat.dualWield);
    _engine.addListener(_onEngineChanged);
    AudioManager.instance.startBattleMusic();
  }

  @override
  void dispose() {
    _engine.removeListener(_onEngineChanged);
    AudioManager.instance.stopBattleMusic();
    super.dispose();
  }

  CombatStats _computeCombat() {
    final player = PlayerRepository.instance;
    final stats = player.data?['stats'] as Map<String, dynamic>? ?? const {};
    final equipment =
        (player.data?['equipment'] as Map<String, dynamic>?) ?? const {};
    return CombatService.compute(stats: stats, equipment: equipment);
  }

  Fighter _makePlayerFighter(CombatStats combat) {
    final player = PlayerRepository.instance;
    final level = player.level;
    return Fighter(
      name: player.name,
      level: level,
      attack: combat.attack,
      defense: combat.defense,
      maxHp: combat.maxHp,
      critChance: combat.critChance,
      critDamage: combat.critDamage,
      evasion: combat.evasion,
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
    if (widget.mob.id.startsWith('pvp_') && _engine.victory) {
      final pvpStats = Map<String, dynamic>.from(
          PlayerRepository.instance.data?['stats_pvp'] as Map<String, dynamic>? ??
              const {});
      pvpStats['pvp_wins'] =
          ((pvpStats['pvp_wins'] as num?)?.toInt() ?? 0) + 1;
      await PlayerRepository.instance.replaceField('stats_pvp', pvpStats);
    }
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
                final combat = _computeCombat();
                _engine = BattleEngine(
                    player: _makePlayerFighter(combat),
                    mob: widget.mob,
                    dualWield: combat.dualWield);
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
        return const Color(0xFFFF9248); // оранжевый удар — как в БК
      case BattleLogKind.block:
        return const Color(0xFF80CCFF); // синий блок
      case BattleLogKind.dodge:
        return const Color(0xFFCCCCCC);
      case BattleLogKind.crit:
        return const Color(0xFFFFD700); // золото крита
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
          SizedBox(height: 252, child: _battlefield()),
          const Divider(height: 1, color: Colors.black26),
          Expanded(child: _logPanel()),
          _choicePanels(),
        ],
      ),
    );
  }

  // ─────────────────────────── КУКЛЫ БОЙЦОВ ───────────────────────────

  Widget _battlefield() {
    return Container(
      width: double.infinity,
      color: const Color(0x33000000),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          Expanded(child: _playerPanel()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text('⚔️',
                style: TextStyle(fontSize: 24, color: kGoldColor)),
          ),
          Expanded(child: _enemyPanel()),
        ],
      ),
    );
  }

  Widget _fighterCaption(Fighter f, Color barColor) {
    final pct = (f.hp / f.maxHp).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '${f.name} (ур. ${f.level})',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            FractionallySizedBox(
              widthFactor: pct,
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text('${f.hp}/${f.maxHp}',
            style: const TextStyle(fontSize: 10, color: Colors.white54)),
      ],
    );
  }

  /// Мини-слот шмота на кукле (только иконка, подпись по долгому тапу).
  Widget _gearSlot(Map<String, dynamic> equipment, String key, double size) {
    final inst = equipment[key];
    final has = inst is Map<String, dynamic>;
    final icon = has ? (inst['icon']?.toString() ?? '') : '';
    return Tooltip(
      message: key,
      triggerMode: TooltipTriggerMode.longPress,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(
              color: has
                  ? kGoldColor
                  : kGoldColor.withOpacity(0.35),
              width: has ? 1.5 : 1),
          borderRadius: BorderRadius.circular(6),
          color: const Color(0x33221D18),
        ),
        child: Center(
          child: has && icon.startsWith('http')
              ? GameImage(icon, width: size * 0.7, height: size * 0.7,
                  fit: BoxFit.contain)
              : Text(icon,
                  style: TextStyle(
                      fontSize: has ? size * 0.55 : 8,
                      color: has ? Colors.white : Colors.white24)),
        ),
      ),
    );
  }

  Widget _gearColumn(Map<String, dynamic> equipment, List<String> keys,
      {double size = 26}) {
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

  Widget _miniStats(Fighter f, bool isPlayer) {
    final parts = <String>[
      '⚔️${f.attack}',
      '🛡️${f.defense}',
      '💨${f.evasion}%',
      '🎯${f.critChance}%',
      '💥${f.critDamage}%',
      if (isPlayer && _combat.dualWield) '✌️2×удар',
    ];
    return Text(
      parts.join('  '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 10, color: Colors.white70),
    );
  }

  Widget _playerPanel() {
    final player = PlayerRepository.instance;
    final equipment =
        (player.data?['equipment'] as Map<String, dynamic>?) ?? const {};
    final look = player.data?['look']?.toString() ?? '';
    final doll = Container(
      width: 108,
      height: 152,
      decoration: BoxDecoration(
        border: Border.all(color: kGoldColor, width: 1.5),
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
                  style: TextStyle(fontSize: 44, color: Colors.white24)),
            ),
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _fighterCaption(_engine.player, const Color(0xFF2E7D32)),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _gearColumn(equipment,
                ['mask', 'helmet', 'armor', 'shirt', 'pants', 'boots'],
                size: 20),
            const SizedBox(width: 5),
            doll,
            const SizedBox(width: 5),
            _gearColumn(
                equipment,
                [
                  'weapon',
                  'weapon2',
                  'shield',
                  'gloves',
                  'cloak',
                  'necklace',
                  'bracelet'
                ],
                size: 20),
          ],
        ),
        const SizedBox(height: 3),
        _gearColumn(equipment,
            const ['wings', 'earring1', 'earring2', 'ring1', 'ring2', 'bag', 'rune'],
            size: 17),
        const SizedBox(height: 3),
        _miniStats(_engine.player, true),
      ],
    );
  }

  Widget _enemyPanel() {
    final gear = mobGear[widget.mob.id] ??
        mobGear[widget.mob.id.replaceFirst('boss_', '')] ??
        const {'weapon': '⚔️', 'armor': '🛡️'};
    final art = Container(
      width: 108,
      height: 152,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCC4D4D), width: 1.5),
        borderRadius: BorderRadius.circular(8),
        color: const Color(0x33221D18),
      ),
      child: MobArt(widget.mob.id, widget.mob.emoji, width: 100, height: 144),
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _fighterCaption(_engine.enemy, const Color(0xFFB71C1C)),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _mobGearColumn(gear, front: false),
            const SizedBox(width: 6),
            art,
            const SizedBox(width: 6),
            _mobGearColumn(gear, front: true),
          ],
        ),
        const SizedBox(height: 5),
        _miniStats(_engine.enemy, false),
      ],
    );
  }

  /// Виртуальные слоты моба распределяем по двум колонкам вокруг куклы.
  Widget _mobGearColumn(Map<String, String> gear, {required bool front}) {
    final keys = gear.keys.toList();
    return _gearColumn(
      {
        for (final k in front ? keys.sublist(keys.length ~/ 2) : keys.take(keys.length ~/ 2))
          k: {'icon': gear[k]},
      },
      [
        for (final k in front ? keys.sublist(keys.length ~/ 2) : keys.take(keys.length ~/ 2))
          k,
      ],
    );
  }

  Widget _logPanel() {
    final log = _engine.log.reversed.toList();
    return Container(
      color: const Color(0xFF0D0D0D),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: log.length,
        itemBuilder: (context, i) {
          final entry = log[i];
          // Как в БК: время зелёным слева, текст строки — цветной по типу события.
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${logStamp(entry.time)} ',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF4CD964)),
                  ),
                  TextSpan(
                    text: entry.text,
                    style: TextStyle(
                      fontSize: 12,
                      color: _logColor(entry.kind),
                    ),
                  ),
                ],
              ),
              style: const TextStyle(height: 1.3),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────── ВЫБОР ЗОН ───────────────────────────

  /// Зоны — компактным рядом мелких кнопок (как в БК): атака сверху,
  /// защита под ней, всё по центру. Лог остаётся в центре экрана.
  Widget _zoneRows() {
    Widget zoneBtn(String part, Color accent, bool on, VoidCallback tap) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: SizedBox(
          width: 92,
          child: OutlinedButton(
            onPressed: tap,
            style: OutlinedButton.styleFrom(
              backgroundColor: on ? accent : null,
              side: BorderSide(color: on ? Colors.white : accent),
              padding: const EdgeInsets.symmetric(vertical: 8),
              minimumSize: const Size(0, 0),
            ),
            child: Text(
              attackPartNames[part]!,
              maxLines: 1,
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _combat.dualWield
              ? 'АТАКА — оружие 1:'
              : 'АТАКА — выбери 1 зону:',
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
        const SizedBox(height: 4),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            for (final part in attackParts.keys)
              zoneBtn(part, const Color(0xFFCC4D4D),
                  _engine.selectedAttack == part,
                  () => _engine.selectAttack(part)),
          ],
        ),
        if (_combat.dualWield) ...[
          const SizedBox(height: 5),
          Text('АТАКА — оружие 2 (удар слабее):',
              style: const TextStyle(fontSize: 11, color: Colors.white70)),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              for (final part in attackParts.keys)
                zoneBtn(part, const Color(0xFFCC7A4D),
                    _engine.selectedAttack2 == part,
                    () => _engine.selectAttack2(part)),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Text('ЗАЩИТА — выбери 2 зоны (${_engine.selectedDefense.length}/2):',
            style: const TextStyle(fontSize: 11, color: Colors.white70)),
        const SizedBox(height: 4),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            for (final part in attackParts.keys)
              zoneBtn(part, const Color(0xFF4D6ECC),
                  _engine.selectedDefense.contains(part),
                  () => _engine.toggleDefense(part)),
          ],
        ),
        const SizedBox(height: 10),
        Center(
          child: SizedBox(
            width: 240,
            height: 44,
            child: FilledButton(
              onPressed: _engine.readyToStrike ? _engine.strike : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C),
              ),
              child: Text(
                _engine.finished ? 'Бой окончен' : 'УДАРИТЬ!',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _choicePanels() {
    return Container(
      color: kPanelColor,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: _zoneRows(),
    );
  }
}
