import 'dart:math';

import 'package:flutter/foundation.dart';

class MobDef {
  final String id;
  final String name;
  final String emoji;
  final int level;
  final int hp;
  final int strength;
  final int agility;
  final int defense;
  final int attack;
  final int goldMin;
  final int goldMax;
  final int expMin;
  final int expMax;

  const MobDef(
    this.id,
    this.name,
    this.emoji, {
    required this.level,
    required this.hp,
    required this.strength,
    required this.agility,
    required this.defense,
    required this.attack,
    required this.goldMin,
    required this.goldMax,
    required this.expMin,
    required this.expMax,
  });
}

class MobDatabase {
  static const List<MobDef> mobs = [
    MobDef('rat', 'Крыса', '🐀',
        level: 1,
        hp: 30,
        strength: 5,
        agility: 6,
        defense: 10,
        attack: 15,
        goldMin: 2,
        goldMax: 8,
        expMin: 5,
        expMax: 12),
    MobDef('wolf', 'Волк', '🐺',
        level: 3,
        hp: 60,
        strength: 10,
        agility: 8,
        defense: 25,
        attack: 40,
        goldMin: 5,
        goldMax: 15,
        expMin: 10,
        expMax: 20),
    MobDef('skeleton', 'Скелет', '💀',
        level: 5,
        hp: 80,
        strength: 12,
        agility: 6,
        defense: 30,
        attack: 50,
        goldMin: 10,
        goldMax: 25,
        expMin: 15,
        expMax: 30),
    MobDef('troll', 'Тролль', '👹',
        level: 10,
        hp: 150,
        strength: 20,
        agility: 5,
        defense: 45,
        attack: 70,
        goldMin: 25,
        goldMax: 50,
        expMin: 30,
        expMax: 60),
    MobDef('orc', 'Орк', '👺',
        level: 15,
        hp: 200,
        strength: 25,
        agility: 7,
        defense: 50,
        attack: 90,
        goldMin: 40,
        goldMax: 80,
        expMin: 50,
        expMax: 90),
    MobDef('dragon', 'Дракон', '🐉',
        level: 20,
        hp: 500,
        strength: 35,
        agility: 15,
        defense: 80,
        attack: 120,
        goldMin: 100,
        goldMax: 300,
        expMin: 100,
        expMax: 200),
    MobDef('demon', 'Демон', '😈',
        level: 30,
        hp: 400,
        strength: 40,
        agility: 20,
        defense: 70,
        attack: 150,
        goldMin: 150,
        goldMax: 300,
        expMin: 150,
        expMax: 300),
    MobDef('boss', 'БОСС', '☠️',
        level: 50,
        hp: 1000,
        strength: 60,
        agility: 25,
        defense: 100,
        attack: 200,
        goldMin: 500,
        goldMax: 1000,
        expMin: 500,
        expMax: 1000),
  ];

  static MobDef byId(String id) => mobs.firstWhere((m) => m.id == id);
}

/// Боец: снапшот боевых характеристик на момент боя.
/// Атака/защита/крит/уклонение уже включают шмот (считает CombatService).
class Fighter {
  final String name;
  final int level;
  final int attack;
  final int defense;
  final int maxHp;
  final int critChance; // %
  final int critDamage; // %
  final int evasion; // %
  int hp;

  Fighter({
    required this.name,
    required this.level,
    required this.attack,
    required this.defense,
    required this.maxHp,
    this.critChance = 5,
    this.critDamage = 150,
    this.evasion = 5,
  }) : hp = maxHp;

  bool get isAlive => hp > 0;
}

/// Зоны тела и их множители урона — как в БК.
const Map<String, double> attackParts = {
  'head': 1.15,
  'chest': 1.0,
  'belly': 1.05,
  'groin': 1.10,
  'legs': 1.05,
};

const Map<String, String> attackPartNames = {
  'head': 'ГОЛОВА',
  'chest': 'ГРУДЬ',
  'belly': 'ЖИВОТ',
  'groin': 'ПОЯС',
  'legs': 'НОГИ',
};

/// Снаряжение мобов — визуальная кукла врага справа (как в БК шмотки врага).
const Map<String, Map<String, String>> mobGear = {
  'rat': {'helmet': '🥜', 'armor': '🧵', 'weapon': '🪡', 'boots': '🥾'},
  'wolf': {'helmet': '🌫️', 'armor': '🧥', 'weapon': '🦷', 'boots': '🐾'},
  'skeleton': {'helmet': '💀', 'armor': '🦴', 'weapon': '🗡️', 'shield': '🛡️'},
  'troll': {'helmet': '🪨', 'armor': '🧱', 'weapon': '🪓', 'necklace': '🦴'},
  'orc': {'helmet': '🪖', 'armor': '🛡️', 'weapon': '⚔️', 'belt': '🪢'},
  'dragon': {'helmet': '🐉', 'armor': '🔥', 'weapon': '🌋', 'necklace': '💎', 'wings': '🦇'},
  'demon': {'helmet': '😈', 'armor': '🕸️', 'weapon': '🔱', 'necklace': '🔮', 'wings': '🦇'},
  'boss': {'helmet': '👑', 'armor': '🛡️', 'weapon': '⚔️', 'ring1': '💍', 'cloak': '🌑'},
};

enum BattleLogKind { info, damage, block, dodge, crit, result }

class BattleLogEntry {
  final String text;
  final BattleLogKind kind;
  const BattleLogEntry(this.text, this.kind);
}

/// БК-бой: атака — 1 зона (или 2 при двух оружиях), защита — ровно 2 зоны.
/// Крит пробивает блок. Заблокированный удар — 25% урона.
class BattleEngine extends ChangeNotifier {
  final Fighter player;
  final MobDef mob;
  late final Fighter _enemy;
  final Random _rng;
  final bool dualWield;

  final List<BattleLogEntry> _log = [];

  /// Выбор игрока на текущий раунд.
  String? selectedAttack; // зона для оружия 1
  String? selectedAttack2; // зона для оружия 2 (только при dualWield)
  final Set<String> selectedDefense = {}; // ровно 2 зоны

  String? _mobAttack;
  final Set<String> _mobDefense = {};

  bool _finished = false;
  bool _victory = false;
  int round = 0;

  BattleEngine({
    required this.player,
    required this.mob,
    Random? rng,
    this.dualWield = false,
  }) : _rng = rng ?? Random() {
    _enemy = Fighter(
      name: mob.name,
      level: mob.level,
      attack: mob.attack,
      defense: mob.defense,
      maxHp: mob.hp,
      critChance: (5 + mob.agility * 0.5).toInt(),
      critDamage: 150,
      evasion: (5 + mob.agility * 0.5).toInt().clamp(0, 30),
    );
    _log.add(BattleLogEntry(
        '⚔️ Бой против ${mob.name} (ур. ${mob.level}) начался!',
        BattleLogKind.info));
    _log.add(const BattleLogEntry(
        'Атака — 1 зона, защита — 2 зоны. Крит пробивает блок.',
        BattleLogKind.info));
  }

  List<BattleLogEntry> get log => List.unmodifiable(_log);
  bool get finished => _finished;
  bool get victory => _victory;
  Fighter get enemy => _enemy;
  String? get lastMobAttack => _mobAttack;
  Set<String> get mobDefense => Set.unmodifiable(_mobDefense);

  int get expReward => mob.expMin + _rng.nextInt(mob.expMax - mob.expMin + 1);
  int get goldReward => mob.goldMin + _rng.nextInt(mob.goldMax - mob.goldMin + 1);

  int rollDamage(Fighter attacker, Fighter defender, String part,
      {double power = 1.0, bool crit = false}) {
    var dmg = (attacker.attack - defender.defense / 2) * attackParts[part]!;
    dmg *= power;
    if (crit) dmg *= attacker.critDamage / 100;
    dmg *= 0.85 + _rng.nextDouble() * 0.25;
    return max(1, dmg.round());
  }

  String _enemyAttackChoice() {
    const parts = ['head', 'chest', 'belly', 'groin', 'legs'];
    const weights = [0.30, 0.25, 0.20, 0.15, 0.10];
    final r = _rng.nextDouble();
    var cum = 0.0;
    for (var i = 0; i < parts.length; i++) {
      cum += weights[i];
      if (r <= cum) return parts[i];
    }
    return 'chest';
  }

  Set<String> _enemyDefenseChoice() {
    const all = ['head', 'chest', 'belly', 'groin', 'legs'];
    // Опытный противник (чем выше уровень — тем чаще) прикрывает самые
    // вероятные зоны атаки — голову и грудь.
    final smartChance = (0.40 + mob.level * 0.012).clamp(0.40, 0.75);
    if (_rng.nextDouble() < smartChance) {
      final zones = {'head', 'chest'}.toList()..shuffle(_rng);
      final outer = all.where((p) => !zones.contains(p)).toList()..shuffle(_rng);
      return {zones.first, outer.first};
    }
    final picked = all.toList()..shuffle(_rng);
    return {picked[0], picked[1]};
  }

  void selectAttack(String part) {
    if (_finished) return;
    selectedAttack = part;
    notifyListeners();
  }

  void selectAttack2(String part) {
    if (_finished || !dualWield) return;
    selectedAttack2 = part;
    notifyListeners();
  }

  void toggleDefense(String zone) {
    if (_finished) return;
    if (selectedDefense.contains(zone)) {
      selectedDefense.remove(zone);
    } else if (selectedDefense.length < 2) {
      selectedDefense.add(zone);
    }
    notifyListeners();
  }

  bool get readyToStrike =>
      !_finished &&
      selectedAttack != null &&
      selectedDefense.length == 2 &&
      (!dualWield || selectedAttack2 != null);

  /// Один удар одного бойца. Возвращает запись в лог.
  void _performStrike({
    required Fighter attacker,
    required Fighter defender,
    required String part,
    required String attackerTitle,
    required String victimTitle,
    Set<String>? blockZones,
    double power = 1.0,
    String weaponNote = '',
  }) {
    if (!attacker.isAlive || !defender.isAlive) return;

    if (_rng.nextDouble() * 100 < defender.evasion) {
      _log.add(BattleLogEntry(
          '💨 $victimTitle увернулся$weaponNote от удара в ${attackPartNames[part]!.toLowerCase()}!',
          BattleLogKind.dodge));
      return;
    }

    final crit = _rng.nextDouble() * 100 < attacker.critChance;
    var dmg = rollDamage(attacker, defender, part, power: power, crit: crit);
    final blocked =
        !crit && blockZones != null && blockZones.contains(part);

    if (blocked) {
      dmg = max(1, (dmg * 0.25).round());
      _log.add(BattleLogEntry(
          '🛡️ $victimTitle заблокировал$weaponNote ${attackPartNames[part]!.toLowerCase()}: $attackerTitle −$dmg HP',
          BattleLogKind.block));
    } else if (crit) {
      _log.add(BattleLogEntry(
          '💥 КРИТ! $attackerTitle пробивает$weaponNote ${attackPartNames[part]!.toLowerCase()} $victimTitle: −$dmg HP',
          BattleLogKind.crit));
    } else {
      _log.add(BattleLogEntry(
          '🔥 $attackerTitle бьёт$weaponNote в ${attackPartNames[part]!.toLowerCase()} $victimTitle: −$dmg HP',
          BattleLogKind.damage));
    }
    defender.hp = max(0, defender.hp - dmg);
  }

  void strike() {
    if (!readyToStrike) return;
    round++;
    _log.add(BattleLogEntry('──── Раунд $round ────', BattleLogKind.info));

    // Моб выбирает свои зоны на этот раунд.
    _mobAttack = _enemyAttackChoice();
    _mobDefense
      ..clear()
      ..addAll(_enemyDefenseChoice());

    // Первый (или единственный) удар игрока.
    _performStrike(
      attacker: player,
      defender: _enemy,
      part: selectedAttack!,
      attackerTitle: 'Вы',
      victimTitle: mob.name,
      blockZones: _mobDefense,
    );

    // Второе оружие: два страйка за раунд, вторая рука слабее.
    if (!_finished && dualWield && _enemy.isAlive) {
      _performStrike(
        attacker: player,
        defender: _enemy,
        part: selectedAttack2 ?? selectedAttack!,
        attackerTitle: 'Вы',
        victimTitle: mob.name,
        blockZones: _mobDefense,
        power: 0.65,
        weaponNote: ' вторым оружием',
      );
    }

    // Ответ моба.
    if (_enemy.isAlive && player.isAlive) {
      _performStrike(
        attacker: _enemy,
        defender: player,
        part: _mobAttack!,
        attackerTitle: mob.name,
        victimTitle: 'Вы',
        blockZones: selectedDefense,
      );
    }

    selectedAttack = null;
    selectedAttack2 = null;
    selectedDefense.clear();

    if (!player.isAlive) {
      _finished = true;
      _victory = false;
      _log.add(const BattleLogEntry('☠️ ПОРАЖЕНИЕ', BattleLogKind.result));
    } else if (!_enemy.isAlive) {
      _finished = true;
      _victory = true;
      _log.add(BattleLogEntry(
          '🏆 ПОБЕДА! ${mob.name} побеждён за $round раундов',
          BattleLogKind.result));
    }

    notifyListeners();
  }
}

MobDef mobFromBoss(String id, Map<String, dynamic> boss) {
  final atkMin = (boss['attack_min'] as num?)?.toInt() ?? 10;
  final atkMax = (boss['attack_max'] as num?)?.toInt() ?? 20;
  final rewards = boss['rewards'] as Map<dynamic, dynamic>? ?? const {};
  final exp = (rewards['exp'] as num?)?.toInt() ?? 0;
  final gold = (rewards['gold'] as num?)?.toInt() ?? 0;
  return MobDef(
    'boss_$id',
    boss['name']?.toString() ?? id,
    boss['icon']?.toString() ?? '💀',
    level: (boss['level'] as num?)?.toInt() ?? 1,
    hp: (boss['hp'] as num?)?.toInt() ?? 100,
    strength: atkMax ~/ 2,
    agility: 10,
    defense: (boss['defense'] as num?)?.toInt() ?? 10,
    attack: (atkMin + atkMax) ~/ 2,
    goldMin: gold,
    goldMax: gold,
    expMin: exp,
    expMax: exp,
  );
}
