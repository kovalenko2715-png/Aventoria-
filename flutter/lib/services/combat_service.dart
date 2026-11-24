import 'items_catalog.dart';

/// Итоговые боевые характеристики бойца: база от статов + бонусы надетого шмота.
/// База как в профилях (100 + сила×2 и т.д.), поверх — сумма бонусов всех
/// надетых предметов (обе руки считаются). Один и тот же расчёт используется
/// боем, профилем и профилем чужого игрока — так билд собирается из стат +
/// шмота и везде считается одинаково.
class CombatStats {
  final int attack;
  final int defense;
  final int maxHp;
  final int maxMana;
  final int critChance; // %
  final int critDamage; // %
  final int evasion; // %
  final int magicFind; // %
  final bool hasMainWeapon;
  final bool hasOffWeapon;
  final bool twoHanded;

  const CombatStats({
    required this.attack,
    required this.defense,
    required this.maxHp,
    required this.maxMana,
    required this.critChance,
    required this.critDamage,
    required this.evasion,
    required this.magicFind,
    required this.hasMainWeapon,
    required this.hasOffWeapon,
    required this.twoHanded,
  });

  /// Два оружия в руках: основное + второе (не двуручное).
  bool get dualWield => hasMainWeapon && hasOffWeapon && !twoHanded;

  /// Сколько ударов за раунд: двуручный боец бьёт дважды (второй слабее).
  int get strikesPerRound => dualWield ? 2 : 1;
}

class CombatService {
  /// Информация о предмете из инстанса в слоте: сначала снапшот инстанса,
  /// затем каталог (id → карточка из Firestore/базы).
  static Map<String, dynamic> _infoOf(Map<String, dynamic> inst) {
    final id = inst['id']?.toString() ?? '';
    final cat = id.isNotEmpty
        ? ItemsCatalog.instance.itemById(id)
        : const <String, dynamic>{};
    if (cat.isNotEmpty) return cat;
    return inst;
  }

  static bool isTwoHanded(dynamic inst) {
    if (inst is! Map<String, dynamic>) return false;
    if (inst['two_handed'] != null) return inst['two_handed'] == true;
    return _infoOf(inst)['two_handed'] == true;
  }

  static bool hasItem(Map<String, dynamic>? equipment, String slot) =>
      equipment?[slot] is Map;

  /// Сумма бонуса по ключу со всего надетого шмота (расходники quick* и самой
  /// сумки тут нет — только экипировка в слотах).
  static int gearBonus(Map<String, dynamic>? equipment, String key) {
    if (equipment == null) return 0;
    var total = 0;
    equipment.forEach((slot, inst) {
      if (slot.startsWith('quick')) return;
      if (inst is! Map<String, dynamic>) return;
      final bonuses =
          (inst['bonuses'] as Map?)?.cast<String, dynamic>() ?? const {};
      final own = (bonuses[key] as num?)?.toInt() ?? 0;
      if (own != 0) {
        total += own;
        return;
      }
      // у старых инстансов бонусы могли не сохраниться — смотрим каталог
      final catBonuses =
          ((_infoOf(inst)['bonuses'] as Map?)?.cast<String, dynamic>() ??
              const {});
      total += (catBonuses[key] as num?)?.toInt() ?? 0;
    });
    return total;
  }

  static CombatStats compute({
    required Map<String, dynamic> stats,
    Map<String, dynamic>? equipment,
  }) {
    int s(String k) => (stats[k] as num?)?.toInt() ?? 0;
    final eq = equipment ?? const <String, dynamic>{};
    final hasMain = hasItem(eq, 'weapon');
    final hasOff = hasItem(eq, 'weapon2');
    final mainTwoHanded = isTwoHanded(eq['weapon']);
    return CombatStats(
      attack: 100 + s('strength') * 2 + gearBonus(eq, 'attack'),
      defense: 50 + s('endurance') + gearBonus(eq, 'defense'),
      maxHp: 200 + s('endurance') * 5 + gearBonus(eq, 'max_hp'),
      maxMana: 100 + s('wisdom') * 3 + gearBonus(eq, 'max_mana'),
      critChance: (5 + s('agility') * 0.5).toInt() + gearBonus(eq, 'crit_chance'),
      critDamage: 150 + s('intuition') + gearBonus(eq, 'crit_damage'),
      evasion: (5 + s('agility') * 0.5).toInt() + gearBonus(eq, 'evasion'),
      magicFind: (5 + s('intuition') * 0.3).toInt() + gearBonus(eq, 'magic_find'),
      hasMainWeapon: hasMain,
      hasOffWeapon: hasOff,
      twoHanded: mainTwoHanded,
    );
  }}
