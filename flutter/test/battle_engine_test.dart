import 'dart:math';
import 'package:aventoria/services/battle_engine.dart';
import 'package:flutter_test/flutter_test.dart';

Fighter _player() => Fighter(
      name: 'Тест',
      level: 5,
      attack: 200,
      defense: 60,
      agility: 10,
      intuition: 20,
      maxHp: 200,
    );

void main() {
  test('block pairs cover every attack zone', () {
    final covered = <String>{};
    for (final parts in blockPairs.values) {
      covered.addAll(parts);
    }
    expect(covered, equals(attackParts.keys.toSet()));
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
        ..selectBlock(blockPairs.keys.elementAt(strikes % 5))
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
      ..selectBlock('head_chest')
      ..strike();
    expect(engine.selectedAttack, isNull);
    expect(engine.selectedBlock, isNull);
  });
}
