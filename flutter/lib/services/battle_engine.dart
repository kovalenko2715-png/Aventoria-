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

class Fighter {
  final String name;
  final int level;
  final int attack;
  final int defense;
  final int agility;
  final int intuition;
  final int maxHp;
  int hp;

  Fighter({
    required this.name,
    required this.level,
    required this.attack,
    required this.defense,
    required this.agility,
    required this.intuition,
    required this.maxHp,
  }) : hp = maxHp;

  bool get isAlive => hp > 0;
}

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

const Map<String, List<String>> blockPairs = {
  'head_chest': ['head', 'chest'],
  'chest_belly': ['chest', 'belly'],
  'belly_groin': ['belly', 'groin'],
  'groin_legs': ['groin', 'legs'],
  'legs_head': ['legs', 'head'],
};

const Map<String, String> blockPairNames = {
  'head_chest': 'ГОЛОВА+ГРУДЬ',
  'chest_belly': 'ГРУДЬ+ЖИВОТ',
  'belly_groin': 'ЖИВОТ+ПОЯС',
  'groin_legs': 'ПОЯС+НОГИ',
  'legs_head': 'НОГИ+ГОЛОВА',
};

enum BattleLogKind { info, damage, block, dodge, result }

class BattleLogEntry {
  final String text;
  final BattleLogKind kind;
  const BattleLogEntry(this.text, this.kind);
}

class BattleEngine extends ChangeNotifier {
  final Fighter player;
  final MobDef mob;
  late final Fighter _enemy;
  final Random _rng;

  final List<BattleLogEntry> _log = [];

  String? selectedAttack;
  String? selectedBlock;
  bool _finished = false;
  bool _victory = false;

  BattleEngine({
    required this.player,
    required this.mob,
    Random? rng,
  })  : _rng = rng ?? Random() {
    _enemy = Fighter(
      name: mob.name,
      level: mob.level,
      attack: mob.attack,
      defense: mob.defense,
      agility: mob.agility,
      intuition: 0,
      maxHp: mob.hp,
    );
    _log.add(BattleLogEntry(
        '⚔️ Бой против ${mob.name} (ур. ${mob.level}) начался!',
        BattleLogKind.info));
    _log.add(const BattleLogEntry(
        'Выберите зону атаки и пару защиты', BattleLogKind.info));
  }

  List<BattleLogEntry> get log => List.unmodifiable(_log);
  bool get finished => _finished;
  bool get victory => _victory;
  Fighter get enemy => _enemy;

  int get expReward => mob.expMin + _rng.nextInt(mob.expMax - mob.expMin + 1);
  int get goldReward => mob.goldMin + _rng.nextInt(mob.goldMax - mob.goldMin + 1);

  double dodgeChance(int agility) => min(0.30, 0.03 + agility * 0.004);
  double critChance(int intuition) => min(0.40, 0.05 + intuition * 0.005);

  int rollDamage(Fighter attacker, Fighter defender, String part) {
    var dmg = (attacker.attack - defender.defense / 2) * attackParts[part]!;
    if (_rng.nextDouble() < critChance(attacker.intuition)) dmg *= 1.75;
    dmg *= 0.85 + _rng.nextDouble() * 0.30;
    return max(1, dmg.round());
  }

  String enemyAttackChoice() {
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

  String enemyBlockChoice() =>
      blockPairs.keys.elementAt(_rng.nextInt(blockPairs.length));

  void selectAttack(String part) {
    if (_finished) return;
    selectedAttack = part;
    notifyListeners();
  }

  void selectBlock(String pair) {
    if (_finished) return;
    selectedBlock = pair;
    notifyListeners();
  }

  bool get readyToStrike =>
      !_finished && selectedAttack != null && selectedBlock != null;

  void strike() {
    if (!readyToStrike) return;
    final attackPart = selectedAttack!;
    final playerBlock = selectedBlock!;

    _log.add(const BattleLogEntry('━━━━━━━━━━━━━━━━━━━━', BattleLogKind.info));

    if (_rng.nextDouble() < dodgeChance(mob.agility)) {
      _log.add(BattleLogEntry(
          '💨 ${mob.name} уклонился от вашего удара!', BattleLogKind.dodge));
    } else {
      final dmg = rollDamage(player, _enemy, attackPart);
      _enemy.hp = max(0, _enemy.hp - dmg);
      _log.add(BattleLogEntry(
          '💥 Вы ударили ${mob.name} в ${attackPartNames[attackPart]!.toLowerCase()}: -$dmg HP',
          BattleLogKind.damage));
    }

    if (_enemy.isAlive) {
      final enemyPart = enemyAttackChoice();
      if (_rng.nextDouble() < dodgeChance(player.agility)) {
        _log.add(BattleLogEntry(
            '💨 Вы уклонились от атаки ${mob.name}!', BattleLogKind.dodge));
      } else {
        final blocked = blockPairs[playerBlock]!.contains(enemyPart);
        var dmg = rollDamage(_enemy, player, enemyPart);
        if (blocked) {
          dmg = max(1, (dmg * 0.25).round());
          _log.add(BattleLogEntry(
              '🛡️ Вы заблокировали удар в ${attackPartNames[enemyPart]!.toLowerCase()} (${blockPairNames[playerBlock]}): -$dmg HP',
              BattleLogKind.block));
        } else {
          _log.add(BattleLogEntry(
              '🔥 ${mob.name} попал в ${attackPartNames[enemyPart]!.toLowerCase()}: -$dmg HP',
              BattleLogKind.damage));
        }
        player.hp = max(0, player.hp - dmg);
      }
    }

    selectedAttack = null;
    selectedBlock = null;

    if (!player.isAlive) {
      _finished = true;
      _victory = false;
      _log.add(const BattleLogEntry('☠️ ПОРАЖЕНИЕ', BattleLogKind.result));
    } else if (!_enemy.isAlive) {
      _finished = true;
      _victory = true;
      _log.add(BattleLogEntry(
          '🏆 ПОБЕДА! ${mob.name} побеждён', BattleLogKind.result));
    }

    notifyListeners();
  }
}
