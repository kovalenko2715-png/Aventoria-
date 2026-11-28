import 'dart:math';
import 'package:aventoria/services/battle_engine.dart';
import 'package:flutter_test/flutter_test.dart';

Fighter _player() => Fighter(
      name: 'Тест',
      level: 5,
      attack: 200,
      defense: 60,
      maxHp: 200,
      critChance: 10,
      critDamage: 150,
      evasion: 10,
    );

void main() {
  test('defense takes exactly 2 distinct zones', () {
    final engine = BattleEngine(
      player: _player(),
      mob: MobDatabase.byId('rat'),
      rng: Random(1),
    );
    engine.toggleDefense('head');
    engine.toggleDefense('legs');
    expect(engine.selectedDefense, {'head', 'legs'});
    // третья зона не берётся
    engine.toggleDefense('chest');
    expect(engine.selectedDefense.length, 2);
    // повторный тап снимает выбор
    engine.toggleDefense('head');
    expect(engine.selectedDefense, {'legs'});
  });

  test('ready requires attack + 2 defense zones', () {
    final engine = BattleEngine(
      player: _player(),
      mob: MobDatabase.byId('rat'),
      rng: Random(1),
    );
    engine.selectAttack('head');
    expect(engine.readyToStrike, isFalse);
    engine.toggleDefense('head');
    engine.toggleDefense('chest');
    expect(engine.readyToStrike, isTrue);
  });

  test('dual wield demands a zone for the second weapon', () {
    final engine = BattleEngine(
      player: _player(),
      mob: MobDatabase.byId('rat'),
      rng: Random(1),
      dualWield: true,
    );
    engine.selectAttack('head');
    engine.toggleDefense('head');
    engine.toggleDefense('chest');
    expect(engine.readyToStrike, isFalse);
    engine.selectAttack2('legs');
    expect(engine.readyToStrike, isTrue);
  });

  test('damage is always positive', () {
    final rng = Random(1);
    final engine = BattleEngine(
      player: _player(),
      mob: MobDatabase.byId('rat'),
      rng: rng,
    );
    for (var i = 0; i < 200; i++) {
      final dmg = engine.rollDamage(
        engine.player,
        engine.enemy,
        attackParts.keys.elementAt(i % attackParts.length),
      );
      expect(dmg, greaterThanOrEqualTo(1));
    }
  });

  test('overpowered player defeats the rat', () {
    final rng = Random(42);
    final engine = BattleEngine(
      player: _player(),
      mob: MobDatabase.byId('rat'),
      rng: rng,
    );
    var strikes = 0;
    while (!engine.finished && strikes < 200) {
      engine
        ..selectAttack(attackParts.keys.elementAt(strikes % 5))
        ..toggleDefense('head')
        ..toggleDefense('chest')
        ..strike();
      strikes++;
    }
    expect(engine.finished, isTrue);
    expect(engine.victory, isTrue);
    expect(engine.enemy.hp, 0);
    expect(engine.player.hp, greaterThan(0));
    expect(
      engine.log.any(
        (e) => e.kind == BattleLogKind.result && e.text.contains('ПОБЕДА'),
      ),
      isTrue,
    );
  });

  test('selection resets after each round', () {
    final engine = BattleEngine(
      player: _player(),
      mob: MobDatabase.byId('rat'),
      rng: Random(7),
    );
    engine
      ..selectAttack('head')
      ..toggleDefense('head')
      ..toggleDefense('chest')
      ..strike();
    expect(engine.selectedAttack, isNull);
    expect(engine.selectedDefense, isEmpty);
    expect(engine.round, 1);
  });
}
