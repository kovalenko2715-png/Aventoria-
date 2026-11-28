import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../main.dart';
import '../services/chat_service.dart';
import '../services/github_publish_service.dart';
import '../services/event_service.dart';
import '../services/items_catalog.dart';
import '../services/item_drafts.dart';
import '../services/world_boss_service.dart';
import '../widgets/game_image.dart';
import '../widgets/module_window.dart';

const Map<String, String> _slotChoices = {
  'wings': 'wings',
  'bracelet': 'bracelet',
  'mask': 'mask',
  'helmet': 'helmet',
  'armor': 'armor',
  'gloves': 'gloves',
  'weapon': 'weapon',
  'weapon2': 'weapon2',
  'pants': 'pants',
  'boots': 'boots',
  'cloak': 'cloak',
  'necklace': 'necklace',
  'earring1': 'earring1',
  'earring2': 'earring2',
  'shield': 'shield',
  'shirt': 'shirt',
  'belt': 'belt',
  'ring1': 'ring1',
  'ring2': 'ring2',
  'bag': 'bag',
  'rune': 'rune',
};

Map<String, String> _pairsToText(Map<String, dynamic>? m) {
  return m?.map((k, v) => MapEntry(k, v.toString())) ?? const {};
}

Map<String, int> _textToPairs(String text) {
  final out = <String, int>{};
  for (final part in text.split(',')) {
    final kv = part.split(':');
    if (kv.length != 2) continue;
    final n = int.tryParse(kv[1].trim());
    if (n == null) continue;
    out[kv[0].trim()] = n;
  }
  return out;
}

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  Widget _adminButton(String label, VoidCallback onTap,
      {Color color = kGoldColor}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
            side: BorderSide(color: color.withOpacity(0.6))),
        onPressed: onTap,
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontSize: 13)),
      ),
    );
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>> userByQuery(
      String email, String name) async {
    final db = FirebaseFirestore.instance;
    if (email.trim().isNotEmpty) {
      final byEmail = await db
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();
      if (byEmail.docs.isNotEmpty) return byEmail.docs.first;
    }
    if (name.trim().isNotEmpty) {
      final byName = await db
          .collection('users')
          .where('name', isEqualTo: name.trim())
          .limit(1)
          .get();
      if (byName.docs.isNotEmpty) return byName.docs.first;
    }
    throw Exception('Игрок не найден');
  }

  TextField _field(TextEditingController c, String label,
      {String? hint, TextInputType? keyboard, bool enabled = true}) {
    return TextField(
      controller: c,
      enabled: enabled,
      keyboardType: keyboard ?? TextInputType.text,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
        enabledBorder:
            const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
      ),
    );
  }

  Future<void> _showItemForm(BuildContext context,
      {Map<String, dynamic>? existing, String? existingId}) async {
    final cId = TextEditingController(text: existingId ?? '');
    final cName =
        TextEditingController(text: existing?['name']?.toString() ?? '');
    final cIcon =
        TextEditingController(text: existing?['icon']?.toString() ?? '📤');
    final cLevel = TextEditingController(
        text: (existing?['level'] as num?)?.toString() ?? '1');
    final cPrice = TextEditingController(
        text: (existing?['price'] as num?)?.toString() ?? '0');
    final cDesc =
        TextEditingController(text: existing?['description']?.toString() ?? '');
    final cReqs = TextEditingController(
        text: _pairsToText(existing?['requirements'] as Map<String, dynamic>?)
            .entries
            .map((e) => '${e.key}:${e.value}')
            .join(','));
    final cBonus = TextEditingController(
        text: _pairsToText(existing?['bonuses'] as Map<String, dynamic>?)
            .entries
            .map((e) => '${e.key}:${e.value}')
            .join(','));
    final cSlot = ValueNotifier<String>(
        existing?['slot']?.toString() ?? 'weapon');
    final cTwoHanded = ValueNotifier<bool>(existing?['two_handed'] == true);
    final cType = ValueNotifier<String>(
        existing?['type']?.toString() ?? 'equipment');
    final cShop = ValueNotifier<bool>(false);
    final cPriceGold = TextEditingController(text: '0');
    final cPriceRune = TextEditingController(text: '0');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        title: Text(existing == null ? 'Новый предмет' : 'Правка предмета',
            style:
                const TextStyle(color: kGoldColor, fontFamily: 'monospace')),
        content: SizedBox(
          // Форма не масштабируется в дизайне — считаем от реального экрана,
          // иначе на телефоне диалог вылезает за края и «закрывается».
          width: min(MediaQuery.of(ctx).size.width - 64, 470),
          height: min(MediaQuery.of(ctx).size.height - 120, 560),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field(cId, 'ID предмета (латиницей, напр. new_sword)',
                    enabled: existingId == null),
                const SizedBox(height: 6),
                _field(cName, 'Название'),
                const SizedBox(height: 6),
                _field(cIcon, 'Иконка (эмодзи или ссылка на картинку)'),
                const SizedBox(height: 6),
                _field(cLevel, 'Уровень', keyboard: TextInputType.number),
                const SizedBox(height: 6),
                _field(cPrice, 'Цена продажи (золото)',
                    keyboard: TextInputType.number),
                const SizedBox(height: 6),
                ValueListenableBuilder<String>(
                    valueListenable: cType,
                    builder: (context, v, _) => Row(children: [
                          for (final (typ, label) in [
                            ('equipment', 'Экипировка'),
                            ('consumable', 'Расходник'),
                            ('material', 'Материал'),
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(label,
                                    style: const TextStyle(fontSize: 12)),
                                selected: v == typ,
                                selectedColor: kGoldColor,
                                onSelected: (_) => cType.value = typ,
                              ),
                            ),
                        ])),
                ValueListenableBuilder<String>(
                    valueListenable: cType,
                    builder: (context, v, _) {
                      if (v != 'equipment') return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: ValueListenableBuilder<String>(
                            valueListenable: cSlot,
                            builder: (context, sv, _) =>
                                DropdownButtonFormField<String>(
                                  value: sv,
                                  decoration: const InputDecoration(
                                      labelText: 'Слот',
                                      labelStyle: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12)),
                                  items: [
                                    for (final e in _slotChoices.entries)
                                      DropdownMenuItem(
                                          value: e.value,
                                          child: Text(e.value,
                                              style: const TextStyle(
                                                  fontSize: 12)))
                                  ],
                                  onChanged: (x) {
                                    if (x != null) cSlot.value = x;
                                  },
                                )),
                      );
                    }),
                const SizedBox(height: 6),
                                const SizedBox(height: 2),
                _buildTwoHandedCheck(cType, cSlot, cTwoHanded),
_statEditor('ТРЕБОВАНИЯ — какой герой может надеть (0 = без требований)',
                    cReqs, _reqStats),
                const SizedBox(height: 6),
                _statEditor('БОНУСЫ — что даёт предмет', cBonus, _bonusStats),
                const SizedBox(height: 6),
                _field(cDesc, 'Описание и лор'),
                const SizedBox(height: 8),
                ValueListenableBuilder<bool>(
                    valueListenable: cShop,
                    builder: (context, v, _) {
                      return Column(children: [
                        CheckboxListTile(
                          dense: true,
                          title: const Text('Поставить в магазин',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 13)),
                          value: v,
                          activeColor: kGoldColor,
                          onChanged: (x) => cShop.value = x ?? false,
                        ),
                        if (v)
                          Row(children: [
                            Expanded(
                                child: _field(cPriceGold, 'Цена в золоте',
                                    keyboard: TextInputType.number),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                                child: _field(cPriceRune, 'Цена в рунах',
                                    keyboard: TextInputType.number),
                            ),
                          ]),
                      ]);
                    }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена',
                  style: TextStyle(color: Colors.white54))),
          TextButton(
              onPressed: () async {
                final id = cId.text.trim();
                if (id.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Заполните ID предмета (латиницей)')));
                  return;
                }
                final fields = <String, dynamic>{
                  'name': cName.text.trim(),
                  'icon': cIcon.text.trim(),
                  'type': cType.value,
                  'level': int.tryParse(cLevel.text.trim()) ?? 1,
                  'price': int.tryParse(cPrice.text.trim()) ?? 0,
                  'description': cDesc.text.trim(),
                  'requirements': _textToPairs(cReqs.text),
                  'bonuses': _textToPairs(cBonus.text),
                };
                if (cType.value == 'equipment') {
                  fields['slot'] = cSlot.value;
                  fields['two_handed'] = cTwoHanded.value;
                }
                if (cType.value == 'consumable') {
                  fields['durability'] = -1;
                } else {
                  fields['durability'] = existing?['durability'] ?? 100;
                }
                final cat = ItemsCatalog.instance;
                try {
                  await cat.saveItem(id, fields,
                      shop: cShop.value, shopFields: {
                        'name': fields['name'],
                        'icon': fields['icon'],
                        if (cShop.value)
                          'price_gold':
                              int.tryParse(cPriceGold.text.trim()) ?? 0,
                        if (cShop.value)
                          'price_rune':
                              int.tryParse(cPriceRune.text.trim()) ?? 0,
                      });
                } catch (e) {
                  // Окно НЕ закрываем — сохранение не прошло.
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Не удалось сохранить: $e')));
                  return;
                }
                final syncMsg = await _syncGameData([
                  {
                    'id': id,
                    'fields': fields,
                    'shop': cShop.value,
                    'shopFields': {
                      'name': fields['name'],
                      'icon': fields['icon'],
                      if (cShop.value)
                        'price_gold': int.tryParse(cPriceGold.text.trim()) ?? 0,
                      if (cShop.value)
                        'price_rune': int.tryParse(cPriceRune.text.trim()) ?? 0,
                    },
                  }
                ]);
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(syncMsg == null
                          ? 'Сохранено (в game_data.dart не отправлено — нужен токен GitHub)'
                          : 'Сохранено. ' + syncMsg!)));
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Сохранить',
                  style: TextStyle(
                      color: kGoldColor, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  String _modSize(int bytes) {
    final kb = bytes / 1024;
    if (kb >= 1024) return '${(kb / 1024).toStringAsFixed(1)} МБ';
    return '${kb.toStringAsFixed(0)} КБ';
  }

  // ─── СИНХРОНИЗАЦИЯ ПРЕДМЕТОВ В game_data.dart (GITHUB) ───

  /// Обновляет itemDb (+shopItems) в flutter/lib/data/game_data.dart в репо.
  /// null = не отправлено (нет токена / нет изменений / ошибка).
  Future<String?> _syncGameData(List<Map<String, dynamic>> items) async {
    final gh = GithubPublishService.instance;
    if (!await gh.hasToken()) return null;
    const path = 'flutter/lib/data/game_data.dart';
    try {
      final src = await gh.readText(path);
      var out = src;
      var changed = 0;
      for (final it in items) {
        final id = it['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        final before = out;
        out = _upsertMapEntry(out, 'itemDb', id,
            Map<String, dynamic>.from(it['fields'] as Map));
        if (it['shop'] == true) {
          out = _upsertMapEntry(out, 'shopItems', id,
              Map<String, dynamic>.from(it['shopFields'] as Map));
        }
        if (out != before) changed++;
      }
      if (changed == 0 || out == src) return null;
      final err = await gh.writeText(
          path, out, 'Aventoria: обновить game_data ($changed предм.)');
      return err == null ? 'game_data.dart обновлён на GitHub.' : null;
    } catch (_) {
      return null;
    }
  }

  /// Вставляет или заменяет запись id внутри карты mapName в исходнике.
  String _upsertMapEntry(String src, String mapName, String id,
      Map<String, dynamic> fields) {
    final mapStart = src.indexOf("final Map<String, dynamic> " + mapName + " = {");
    if (mapStart < 0) return src;
    final openBrace = src.indexOf('{', mapStart);
    var depth = 0;
    var closeIdx = -1;
    for (var i = openBrace; i < src.length; i++) {
      if (src[i] == '{') depth++;
      if (src[i] == '}') {
        depth--;
        if (depth == 0) {
          closeIdx = i;
          break;
        }
      }
    }
    if (closeIdx < 0) return src;
    final body = src.substring(openBrace + 1, closeIdx);
    final entry = '"' + id + '": ' + jsonEncode(fields) + ',';
    final entryStart = body.indexOf('"' + id + '": {');
    String newBody;
    if (entryStart >= 0) {
      final eOpen = body.indexOf('{', entryStart);
      var d2 = 0;
      var end2 = -1;
      for (var i = eOpen; i < body.length; i++) {
        if (body[i] == '{') d2++;
        if (body[i] == '}') {
          d2--;
          if (d2 == 0) {
            end2 = i;
            break;
          }
        }
      }
      if (end2 < 0) return src;
      newBody = body.replaceRange(
          entryStart, end2 + 1, entry.substring(0, entry.length - 1));
    } else {
      newBody = '\n  ' + entry.substring(0, entry.length - 1) + ',' + body;
    }
    return src.replaceRange(openBrace + 1, closeIdx, newBody);
  }

  // ─── ПРОСТОЙ РЕДАКТОР СТАТОВ ───

  static const List<List<String>> _reqStats = [
    ['strength', '💪 Сила'],
    ['agility', '🏹 Ловкость'],
    ['intuition', '🔮 Интуиция'],
    ['endurance', '🛡 Выносливость'],
    ['intellect', '📚 Интеллект'],
    ['wisdom', '🦉 Мудрость'],
    ['spirit', '✨ Дух'],
  ];
  static const List<List<String>> _bonusStats = [
    ['attack', '⚔️ Атака'],
    ['defense', '🛡 Защита'],
    ['hp', '❤️ HP (жизни)'],
    ['crit_chance', '💥 Шанс крита, %'],
    ['evasion', '💨 Уклонение, %'],
    ['hp_restore', '🧪 Восстановление HP'],
  ];

  int _statValue(String text, String key) {
    final m = RegExp(key + r'\s*:\s*(-?\d+)').firstMatch(text);
    return m == null ? 0 : int.parse(m.group(1)!);
  }

  void _setStatValue(TextEditingController c, String key, int v) {
    final re = RegExp(key + r'\s*:\s*(-?\d+)');
    final m = re.firstMatch(c.text);
    String next;
    if (m != null) {
      next = c.text.replaceRange(m.start, m.end, key + ':' + v.toString());
    } else if (v != 0) {
      next = c.text.trim().isEmpty
          ? key + ':' + v.toString()
          : c.text.trim() + ',' + key + ':' + v.toString();
    } else {
      return;
    }
    c.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length));
  }

  /// Список статов с кнопками − / значение / + / +10.
  /// Пишет в тот же контроллер (key:value через запятую) — данные совместимы.
  Widget _statEditor(
      String title, TextEditingController c, List<List<String>> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 2),
        for (final s in stats)
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: c,
            builder: (context, _, __) {
              final v = _statValue(c.text, s[0]);
              return Row(children: [
                Expanded(
                    child: Text(s[1],
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12))),
                IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.remove_circle_outline,
                        size: 18, color: Colors.white38),
                    onPressed:
                        v <= 0 ? null : () => _setStatValue(c, s[0], v - 1)),
                SizedBox(
                    width: 34,
                    child: Text(v.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: kGoldColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold))),
                IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add_circle_outline,
                        size: 18, color: kGoldColor),
                    onPressed: () => _setStatValue(c, s[0], v + 1)),
                SizedBox(
                    width: 40,
                    child: TextButton(
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(30, 30)),
                        onPressed: () => _setStatValue(c, s[0], v + 10),
                        child: const Text('+10',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 10)))),
              ]);
            },
          ),
      ],
    );
  }

  // ─── ВЫДАЧА РЕСУРСОВ ИГРОКУ (ДЛЯ ТЕСТОВ) ───

  Future<void> _showGrantDialog(BuildContext context) async {
    final cEmail = TextEditingController();
    final cName = TextEditingController();
    final cGold = TextEditingController();
    final cRune = TextEditingController();
    final cExp = TextEditingController();
    final cLevel = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        title: const Text('Выдать игроку (тесты)',
            style: TextStyle(color: kGoldColor, fontSize: 16)),
        content: SizedBox(
          width: min(MediaQuery.of(ctx).size.width - 64, 400),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _field(cEmail, 'Почта игрока (или имя ниже)'),
              const SizedBox(height: 6),
              _field(cName, 'Имя игрока'),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                    child: _field(cGold, 'Золото +/−',
                        keyboard: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(
                    child: _field(cRune, 'Руны +/−',
                        keyboard: TextInputType.number)),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                    child: _field(cExp, 'Опыт +/−',
                        keyboard: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(
                    child: _field(cLevel, 'Уровень (точно)',
                        keyboard: TextInputType.number)),
              ]),
              const SizedBox(height: 6),
              const Text(
                  'Пустое поле = не менять. С минусом отнимает: −500 убавит 500 золота. Уровень ставится точно. Пустые почта и имя = выдать себе (удобно для тестов).',
                  style: TextStyle(color: Colors.white24, fontSize: 11)),
            ]),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('Отмена', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              try {
                final self = cEmail.text.trim().isEmpty &&
                    cName.text.trim().isEmpty;
                final doc = self
                    ? await FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid ?? '')
                        .get()
                    : await userByQuery(cEmail.text, cName.text);
                if (!doc.exists) throw Exception('Игрок не найден');
                final data = <String, dynamic>{};
                final g = int.tryParse(cGold.text.trim());
                if (g != null && g != 0) data['gold'] = FieldValue.increment(g);
                final ru = int.tryParse(cRune.text.trim());
                if (ru != null && ru != 0) data['rune'] = FieldValue.increment(ru);
                final ex = int.tryParse(cExp.text.trim());
                if (ex != null && ex != 0) data['exp'] = FieldValue.increment(ex);
                final lvl = int.tryParse(cLevel.text.trim());
                if (lvl != null && lvl > 0) data['level'] = lvl;
                if (data.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Нечего выдавать — все поля пустые')));
                  return;
                }
                await doc.reference.update(data);
                final who = doc.data()?['name']?.toString() ?? 'игроку';
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Выдано: ' + who)));
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Ошибка: ' + e.toString())));
                }
              }
            },
            child: const Text('Выдать',
                style:
                    TextStyle(color: kGoldColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _showTokenDialog(BuildContext context) async {
    final cToken = TextEditingController();
    final has = await GithubPublishService.instance.hasToken();
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        title: const Text('Токен GitHub',
            style: TextStyle(color: kGoldColor, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                has
                    ? 'Токен уже сохранён (только на этом телефоне).\nМожно вставить новый — он заменит старый.'
                    : 'Вставь Personal Access Token (github_pat_...).\nХранится только на телефоне, в базу и в APK не попадает.',
                style: const TextStyle(
                    color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 8),
            _field(cToken, 'github_pat_...',
                keyboard: TextInputType.visiblePassword),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена',
                  style: TextStyle(color: Colors.white54))),
          TextButton(
              onPressed: () async {
                if (cToken.text.trim().isEmpty) return;
                await GithubPublishService.instance.saveToken(cToken.text);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Сохранить',
                  style: TextStyle(color: kGoldColor))),
        ],
      ),
    );
  }


  /// Чекбокс «Двуручное оружие» — виден только для слота weapon.
  Widget _buildTwoHandedCheck(ValueNotifier<String> cType,
      ValueNotifier<String> cSlot, ValueNotifier<bool> cTwoHanded) {
    return ValueListenableBuilder<String>(
        valueListenable: cType,
        builder: (context, tv, _) => tv != 'equipment'
            ? const SizedBox.shrink()
            : ValueListenableBuilder<String>(
                valueListenable: cSlot,
                builder: (context, sv, _) {
                  if (sv != 'weapon') return const SizedBox.shrink();
                  return ValueListenableBuilder<bool>(
                    valueListenable: cTwoHanded,
                    builder: (context, v, _) => CheckboxListTile(
                      dense: true,
                      title: const Text('✌️ Двуручное оружие (обе руки)',
                          style: TextStyle(color: Colors.white, fontSize: 13)),
                      value: v,
                      activeColor: kGoldColor,
                      onChanged: (x) => cTwoHanded.value = x ?? false,
                    ),
                  );
                }));
  }

  /// Форма черновика: как форма предмета, но сохраняет в локальную пачку
  /// и позволяет выбрать картинку с телефона.
  Future<void> _showDraftForm(BuildContext context) async {
    final cId = TextEditingController();
    final cName = TextEditingController();
    final cIcon = TextEditingController(text: '');
    final cLevel = TextEditingController(text: '1');
    final cPrice = TextEditingController(text: '0');
    final cDesc = TextEditingController();
    final cReqs = TextEditingController();
    final cBonus = TextEditingController();
    final cSlot = ValueNotifier<String>('weapon');
    final cType = ValueNotifier<String>('equipment');
    final cShop = ValueNotifier<bool>(false);
    final cPriceGold = TextEditingController(text: '0');
    final cPriceRune = TextEditingController(text: '0');
    final cTwoHanded = ValueNotifier<bool>(false);
    final imagePath = ValueNotifier<String?>(null);
    int imageBytes = 0;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        title: const Text('Предмет в пачку',
            style:
                TextStyle(color: kGoldColor, fontFamily: 'monospace')),
        content: SizedBox(
          // Форма не масштабируется в дизайне — считаем от реального экрана,
          // иначе на телефоне диалог вылезает за края и «закрывается».
          width: min(MediaQuery.of(ctx).size.width - 64, 470),
          height: min(MediaQuery.of(ctx).size.height - 120, 560),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field(cId, 'ID предмета (латинцей, напр. new_sword)'),
                const SizedBox(height: 6),
                _field(cName, 'Название'),
                const SizedBox(height: 6),
                _field(cIcon, 'Иконка (эмодзи, если нет картинки)'),
                const SizedBox(height: 6),
                _field(cLevel, 'Уровень', keyboard: TextInputType.number),
                const SizedBox(height: 6),
                _field(cPrice, 'Цена продажи (золото)',
                    keyboard: TextInputType.number),
                const SizedBox(height: 6),
                ValueListenableBuilder<String>(
                    valueListenable: cType,
                    builder: (context, v, _) => Row(children: [
                          for (final (typ, label) in [
                            ('equipment', 'Экипировка'),
                            ('consumable', 'Расходник'),
                            ('material', 'Материал'),
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(label,
                                    style: const TextStyle(fontSize: 12)),
                                selected: v == typ,
                                selectedColor: kGoldColor,
                                onSelected: (_) => cType.value = typ,
                              ),
                            ),
                        ])),
                ValueListenableBuilder<String>(
                    valueListenable: cType,
                    builder: (context, v, _) {
                      if (v != 'equipment') return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: ValueListenableBuilder<String>(
                            valueListenable: cSlot,
                            builder: (context, sv, _) =>
                                DropdownButtonFormField<String>(
                                  value: sv,
                                  decoration: const InputDecoration(
                                      labelText: 'Слот',
                                      labelStyle: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12)),
                                  items: [
                                    for (final e in _slotChoices.entries)
                                      DropdownMenuItem(
                                          value: e.value,
                                          child: Text(e.value,
                                              style: const TextStyle(
                                                  fontSize: 12)))
                                  ],
                                  onChanged: (x) {
                                    if (x != null) cSlot.value = x;
                                  },
                                )),
                      );
                    }),
                const SizedBox(height: 2),
                _buildTwoHandedCheck(cType, cSlot, cTwoHanded),
                const SizedBox(height: 2),
                ValueListenableBuilder<String?>(
                    valueListenable: imagePath,
                    builder: (context, path, _) {
                      return Column(children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: kGoldColor.withOpacity(0.6))),
                          onPressed: () async {
                            final picker = ImagePicker();
                            final x = await picker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 95);
                            if (x == null) return;
                            imagePath.value = x.path;
                            imageBytes = File(x.path).lengthSync();
                          },
                          icon: const Icon(Icons.image, size: 18),
                          label: Text('Выбрать картинку с телефона',
                              style: const TextStyle(
                                  color: kGoldColor, fontSize: 12)),
                        ),
                        if (path != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(children: [
                              Image.file(File(path),
                                  width: 40, height: 40,
                                  fit: BoxFit.contain),
                              const SizedBox(width: 8),
                              Text('Выбрано (${_modSize(imageBytes)})',
                                  style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11)),
                            ]),
                          ),
                      ]);
                    }),
                const SizedBox(height: 6),
                _statEditor(
                    'ТРЕБОВАНИЯ — какой герой может надеть (0 = без требований)',
                    cReqs, _reqStats),
                const SizedBox(height: 6),
                _statEditor('БОНУСЫ — что даёт предмет', cBonus, _bonusStats),
                const SizedBox(height: 6),
                _field(cDesc, 'Описание и лор'),
                const SizedBox(height: 8),
                ValueListenableBuilder<bool>(
                    valueListenable: cShop,
                    builder: (context, v, _) {
                      return Column(children: [
                        CheckboxListTile(
                          dense: true,
                          title: const Text('Поставить в магазин',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 13)),
                          value: v,
                          activeColor: kGoldColor,
                          onChanged: (x) => cShop.value = x ?? false,
                        ),
                        if (v)
                          Row(children: [
                            Expanded(
                                child: _field(cPriceGold, 'Цена в золоте',
                                    keyboard: TextInputType.number),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                                child: _field(cPriceRune, 'Цена в рунах',
                                    keyboard: TextInputType.number),
                            ),
                          ]),
                      ]);
                    }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена',
                  style: TextStyle(color: Colors.white54))),
          TextButton(
              onPressed: () async {
                final id = cId.text.trim();
                final imgPath = imagePath.value;
                if (id.isEmpty || !RegExp(r'^[a-z0-9_]+$').hasMatch(id)) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content:
                          Text('ID: только латиница, цифры и _ (напр. new_sword)')));
                  return;
                }
                await ItemDrafts.instance.add(ItemDraft(
                  id: id,
                  name: cName.text.trim(),
                  icon: cIcon.text.trim().isEmpty && imgPath == null
                      ? '📦'
                      : cIcon.text.trim(),
                  imagePath: imgPath,
                  type: cType.value,
                  slot: cType.value == 'equipment' ? cSlot.value : null,
                  twoHanded: cTwoHanded.value,
                  level: int.tryParse(cLevel.text.trim()) ?? 1,
                  price: int.tryParse(cPrice.text.trim()) ?? 0,
                  description: cDesc.text.trim(),
                  requirements: _textToPairs(cReqs.text),
                  bonuses: _textToPairs(cBonus.text),
                  shop: cShop.value,
                  priceGold: int.tryParse(cPriceGold.text.trim()) ?? 0,
                  priceRune: int.tryParse(cPriceRune.text.trim()) ?? 0,
                ));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('В пачку',
                  style: TextStyle(
                      color: kGoldColor, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Future<void> _showDraftListDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        title: const Text('Пачка предметов',
            style: TextStyle(color: kGoldColor)),
        content: SizedBox(
          width: min(MediaQuery.of(ctx).size.width - 64, 420),
          height: min(MediaQuery.of(ctx).size.height - 140, 420),
          child: ListenableBuilder(
            listenable: ItemDrafts.instance,
            builder: (context, _) => ItemDrafts.instance.items.isEmpty
                ? const Text('Пачка пустая',
                    style: TextStyle(color: Colors.white54, fontSize: 12))
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final d in ItemDrafts.instance.items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(children: [
                              SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: d.imagePath != null
                                      ? Image.file(File(d.imagePath!),
                                          fit: BoxFit.contain)
                                      : Text(d.icon, style: const TextStyle(fontSize: 20))),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                    '${d.name.isEmpty ? d.id : d.name} (${d.id})\nур ${d.level}${d.shop ? ' · магазин' : ''}',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12)),
                              ),
                              IconButton(
                                  iconSize: 18,
                                  onPressed: () =>
                                      ItemDrafts.instance.remove(d.id),
                                  icon: const Icon(Icons.delete,
                                      color: Colors.redAccent)),
                              IconButton(
                                  iconSize: 18,
                                  onPressed: () => _publishDraft(context, d),
                                  icon: const Icon(Icons.upload,
                                      color: kGoldColor)),
                            ]),
                          ),
                        const SizedBox(height: 4),
                        Text(
                            '${ItemDrafts.instance.items.length} шт. Картинки жмутся до 256px и уходят в GitHub; предмет попадает в каталог и магазин.',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Закрыть',
                  style: TextStyle(color: kGoldColor))),
        ],
      ),
    );
  }

  /// Публикация одного черновика (картинка → GitHub, предмет → каталог).
  Future<void> _publishDraft(BuildContext context, ItemDraft d) async {
    final gh = GithubPublishService.instance;
    String? iconValue = d.icon.isEmpty ? '📦' : d.icon;
    if (d.imagePath != null && File(d.imagePath!).existsSync()) {
      final bytes = await gh.compressImage(File(d.imagePath!));
      if (bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Картинка ${d.id} не читается — предмет без неё')));
      } else {
        final err = await gh.uploadFile(
            'flutter/assets/images/items/${d.id}.png',
            bytes,
            'Aventoria: item image ${d.id}');
        if (err != null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Не отправилось: $err')));
          }
          return;
        }
        iconValue = 'images/items/${d.id}.png';
      }
    }
    await ItemsCatalog.instance.saveItem(d.id, {
      'name': d.name.isEmpty ? d.id : d.name,
      'icon': iconValue,
      'type': d.type,
      'level': d.level,
      'price': d.price,
      'description': d.description,
      'requirements': d.requirements,
      'bonuses': d.bonuses,
      if (d.type == 'consumable') 'durability': -1 else 'durability': 100,
      if (d.slot != null) 'slot': d.slot,
      if (d.type == 'equipment' && d.twoHanded) 'two_handed': true,
    }, shop: d.shop, shopFields: {
      'name': d.name.isEmpty ? d.id : d.name,
      'icon': iconValue,
      if (d.shop) 'price_gold': d.priceGold,
      if (d.shop) 'price_rune': d.priceRune,
    });
    await ItemDrafts.instance.remove(d.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${d.id}: картинка в GitHub, предмет в каталоге. Ресурсы обновятся после сборки CI.')));
    }
  }

  /// Публикация всей пачки (картинки → GitHub, предметы → каталог).
  Future<void> _publishBatch(BuildContext context) async {
    final gh = GithubPublishService.instance;
    if (await gh.hasToken() == false) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Сначала вставь токен GitHub')));
      }
      return;
    }
    final all = ItemDrafts.instance.items;
    if (all.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Пачка пустая')));
      return;
    }
    var ok = 0, failed = 0;
    String lastErr = '';
    final payloads = <Map<String, dynamic>>[];
    for (final d in all) {
      try {
        await _publishDraft(context, d);
        ok++;
        final hasImage = d.imagePath != null && d.imagePath!.isNotEmpty;
        final iconValue = hasImage
            ? 'images/items/' + d.id + '.png'
            : (d.icon.isEmpty ? '📤' : d.icon);
        final fields = <String, dynamic>{
          'name': d.name.isEmpty ? d.id : d.name,
          'icon': iconValue,
          'type': d.type,
          'level': d.level,
          'price': d.price,
          'description': d.description,
          'requirements': d.requirements,
          'bonuses': d.bonuses,
          'durability': d.type == 'consumable' ? -1 : 100,
          if (d.type == 'equipment' && d.slot != null) 'slot': d.slot,
          if (d.type == 'equipment' && d.twoHanded) 'two_handed': true,
        };
        payloads.add({
          'id': d.id,
          'fields': fields,
          'shop': d.shop,
          'shopFields': {
            'name': d.name.isEmpty ? d.id : d.name,
            'icon': iconValue,
            'type': d.type,
            'level': d.level,
            'description': d.description,
            'durability': d.type == 'consumable' ? -1 : 100,
            'price_gold': d.priceGold,
            'price_rune': d.priceRune,
            'rarity': 'обычный',
            'requirements': d.requirements,
            'bonuses': d.bonuses,
          },
        });
      } catch (e) {
        failed++;
        lastErr = '$e';
      }
    }
    final syncMsg =
        payloads.isEmpty ? null : await _syncGameData(payloads);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Отправлено: $ok, ошибок: $failed. $lastErr'
              + (syncMsg == null ? '' : ' ' + syncMsg!))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModuleWindow(
      title: 'АДМИН ПАНЕЛЬ',
      maxWidth: 1240,
      child: StreamBuilder<int>(
        stream: ChatService.instance.adminRank(),
        builder: (context, snap) {
          final rank = snap.data ?? 0;
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (rank <= 0) {
            return const Center(
                child: Text('Нет доступа.',
                    style: TextStyle(color: Colors.redAccent, fontSize: 14)));
          }
          final rankName =
              kAdminRankNames[rank > 5 ? 5 : rank] ?? 'Модератор';
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text('Твой ранг: $rankName (${rank})',
                  style:
                      const TextStyle(color: kGoldColor, fontSize: 13)),
              const Divider(color: Colors.white12),
              const Text('ПРЕДМЕТЫ',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              _adminButton('➕ Создать предмет (сразу в игру, уйдёт в GitHub при наличии токена)',
                  () => _showItemForm(context)),
              const SizedBox(height: 6),
              _adminButton('📝 Изменить предмет по ID / выкинуть картинку',
                  () => _showPickItemDialog(context)),
              const SizedBox(height: 6),
              _adminButton('💰 Выдать золото / руны / опыт / уровень (пустые почта и имя = себе)',
                  () => _showGrantDialog(context)),
              const SizedBox(height: 12),
              const Text('📦 ПАЧКА НА GITHUB (создание пачкой + картинки)',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              _adminButton('🔑 Токен GitHub (вставить один раз)',
                  () => _showTokenDialog(context)),
              const SizedBox(height: 6),
              _adminButton('➕ Добавить предмет в пачку (картинка с телефона)',
                  () => _showDraftForm(context)),
              const SizedBox(height: 6),
              ListenableBuilder(
                listenable: ItemDrafts.instance,
                builder: (context, _) => _adminButton(
                    '📜 Пачка: ${ItemDrafts.instance.count} шт. (просмотр/удалить/отправить)',
                    () => _showDraftListDialog(context)),
              ),
              const SizedBox(height: 6),
              ListenableBuilder(
                listenable: ItemDrafts.instance,
                builder: (context, _) => _adminButton(
                    '🚀 Отправить ВСЮ пачку на GitHub (${ItemDrafts.instance.count} шт.)',
                    () => _publishBatch(context)),
              ),
              const SizedBox(height: 12),
              const Text('ОБЛИКИ',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              _adminButton('🖼️ Добавить облик по ссылке',
                  () => _showAddLookDialog(context)),
              const SizedBox(height: 6),
              _adminButton('📋 Список обликов (удалить)',
                  () => _showLooksListDialog(context)),
              const SizedBox(height: 12),
              const Text('🔥 МИРОВЫЕ БОССЫ',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              _adminButton('🔥 Принудительно открыть босса',
                  () => _showWorldBossDialog(context)),
              const SizedBox(height: 12),
              const Text('📅 ИВЕНТЫ',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              _adminButton('📅 Управление ивентами',
                  () => _showEventsDialog(context)),
              if (rank >= 4) ...[
                const SizedBox(height: 12),
                const Text('АДМИНЫ И РАНГИ',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                _adminButton('👑 Назначить / изменить админа',
                    () => _showAdminAssignDialog(context)),
              ],
              const SizedBox(height: 12),
              const Text('ЗАПРОС СМЕНЫ НИКА',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              _adminButton('📨 Отправить игроку запрос на смену ника',
                  () => _showNickRequestDialog(context)),
            ],
          );
        },
      ),
    );
  }

  String _wbName(String id) {
    final def = WorldBossService.instance.bossDef(id);
    return def == null ? id : '${def['icon'] ?? '👹'} ${def['name']} (ур. ${def['level']})';
  }

  Future<void> _forceWorldBoss(
      BuildContext context, String id, int minutes) async {
    await FirebaseFirestore.instance
        .collection('settings')
        .doc('world_bosses')
        .set(
      {
        'forced.$id': minutes > 0
            ? DateTime.now().millisecondsSinceEpoch + minutes * 60000
            : 0,
      },
      SetOptions(merge: true),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(minutes > 0
              ? 'Босс открыт на $minutes мин (объява появится в чате)'
              : 'Принудительное открытие сброшено')));
    }
    if (minutes > 0) {
      await WorldBossService.instance.announceAwakens();
    }
  }

  Future<void> _showWorldBossDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        title: const Text('Мировые боссы',
            style: TextStyle(color: kGoldColor)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final id in WorldBossService.scheduleDefaults.keys)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_wbName(id),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(children: [
                        ElevatedButton(
                          style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFF3A1A05)),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _forceWorldBoss(context, id, 20);
                          },
                          child: const Text('Открыть 20 мин',
                              style: TextStyle(
                                  color: Colors.orangeAccent, fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFF202020)),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _forceWorldBoss(context, id, 0);
                          },
                          child: const Text('Закрыть',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                        ),
                      ]),
                    ],
                  ),
                ),
              const Text(
                  '«Открыть» будит босса сразу на 20 минут, даже если по таймеру он ещё спит. Объявление появится в общем чате. «Закрыть» снимает принудительное открытие.',
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Закрыть окно',
                  style: TextStyle(color: Colors.white54))),
        ],
      ),
    );
  }

  Future<void> _eventAction(BuildContext context, String keyBase,
      Map<String, dynamic> docUpdate) async {
    await FirebaseFirestore.instance
        .collection('settings')
        .doc('events')
        .set(docUpdate, SetOptions(merge: true));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ивент обновлён: $keyBase')));
    }
    if (docUpdate.containsKey('forced')) {
      await EventService.instance.announceActive();
    }
  }

  Future<void> _showEventsDialog(BuildContext context) async {
    final fmt = (DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}'
        ' ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        title: const Text('Ивенты', style: TextStyle(color: kGoldColor)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final entry in EventService.eventDefs.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.value['emoji']} ${entry.value['name']}\n'
                        '${EventService.instance.isActive(entry.key) ? '🔥 АКТИВЕН сейчас' : 'спит'}'
                        '${EventService.instance.autoOff(entry.key) ? ' • автоматика ВЫКЛ' : ''}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12, height: 1.3),
                      ),
                      Builder(builder: (context) {
                        final left = EventService.instance.untilEnd(entry.key);
                        return left != null
                            ? Text('осталось ${left.inMinutes} мин',
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 11))
                            : const SizedBox.shrink();
                      }),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          ElevatedButton(
                            style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFF2A2005)),
                            onPressed: () => _eventAction(context, entry.key, {
                              'forced.${entry.key}':
                                  DateTime.now().millisecondsSinceEpoch +
                                      3600000,
                            }),
                            child: const Text('Открыть 1 ч',
                                style: TextStyle(
                                    color: Colors.orangeAccent, fontSize: 11)),
                          ),
                          ElevatedButton(
                            style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFF202020)),
                            onPressed: () => _eventAction(context, entry.key, {
                              'forced.${entry.key}': 0,
                            }),
                            child: const Text('Снять форс',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 11)),
                          ),
                          ElevatedButton(
                            style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFF202020)),
                            onPressed: () async {
                              final nowOff =
                                  EventService.instance.autoOff(entry.key);
                              await FirebaseFirestore.instance
                                  .collection('settings')
                                  .doc('events')
                                  .set({
                                'off.${entry.key}': !nowOff,
                              }, SetOptions(merge: true));
                            },
                            child: Text(
                                EventService.instance.autoOff(entry.key)
                                    ? 'Вкл авто'
                                    : 'Откл авто',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const Text(
                  '«Открыть 1 ч» запускает событие вручную на час (объявление в чат). '
                  '«Откл авто» отключает авто-расписание события (форс продолжает работать). '
                  'Авто-расписание: выходные x2 опыт, час золота 21:00–22:00, '
                  'Пасха, Хэллоуин 31.10–02.11, Новый год 30.12–02.01.',
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
              Text('Локальное время устройства: ${fmt(DateTime.now())}',
                  style: const TextStyle(color: Colors.white24, fontSize: 10)),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Закрыть окно',
                  style: TextStyle(color: Colors.white54))),
        ],
      ),
    );
  }

  Future<void> _showPickItemDialog(BuildContext context) async {
    final cId = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        title: const Text('Изменить предмет',
            style: TextStyle(color: kGoldColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(cId, 'ID предмета (напр. iron_sword)'),
            const Text(
                'Также можно вводить ID предметов, созданных админами.',
                style: TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена',
                  style: TextStyle(color: Colors.white54))),
          TextButton(
              onPressed: () async {
                final id = cId.text.trim();
                final info = ItemsCatalog.instance.itemById(id);
                if (info.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                      content: Text('Предмет $id не найден')));
                  return;
                }
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _showItemForm(context, existing: info, existingId: id);
              },
              child: const Text('Править',
                  style: TextStyle(color: kGoldColor))),
        ],
      ),
    );
  }

  Future<void> _showAddLookDialog(BuildContext context) async {
    final cName = TextEditingController();
    final cUrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        title: const Text('Добавить облик',
            style: TextStyle(color: kGoldColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(cName, 'Название облика (напр. knight_red)'),
            const SizedBox(height: 6),
            _field(cUrl, 'Прямая ссылка на картинку (https://...)'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена',
                  style: TextStyle(color: Colors.white54))),
          TextButton(
              onPressed: () async {
                final name = cName.text.trim();
                final url = cUrl.text.trim();
                if (name.isEmpty || !url.startsWith('http')) return;
                await FirebaseFirestore.instance
                    .collection('catalog')
                    .doc('look_$name')
                    .set({'url': url});
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Добавить',
                  style: TextStyle(color: kGoldColor))),
        ],
      ),
    );
  }

  Future<void> _showLooksListDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        title: const Text('Облики',
            style: TextStyle(color: kGoldColor)),
        content: SizedBox(
          width: 420,
          height: 340,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('catalog')
                .snapshots(),
            builder: (context, snap0) {
              final docs = (snap0.data?.docs ?? [])
                  .where((d) => d.id.startsWith('look_'))
                  .toList();
              if (docs.isEmpty) {
                return const Center(
                    child: Text('Пока нет обликов',
                        style: TextStyle(color: Colors.white54)));
              }
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final name = docs[i].id.substring(5);
                  final url = docs[i].data()['url']?.toString() ?? '';
                  return ListTile(
                    dense: true,
                    leading: GameImage(url,
                        width: 32, height: 44, fit: BoxFit.cover),
                    title: Text(name,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12)),
                    trailing: IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline,
                          color: Color(0xFFFF4545), size: 20),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('catalog')
                            .doc(docs[i].id)
                            .delete();
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Закрыть',
                  style: TextStyle(color: kGoldColor))),
        ],
      ),
    );
  }

  Future<void> _showAdminAssignDialog(BuildContext context) async {
    final cEmail = TextEditingController();
    final cName = TextEditingController();
    final cRank = TextEditingController(text: '1');
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        title: const Text('Назначить админа',
            style: TextStyle(color: kGoldColor)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(cEmail, 'Почта игрока'),
              const SizedBox(height: 6),
              _field(cName, '...или ник игрока'),
              const SizedBox(height: 6),
              _field(cRank, 'Ранг 1–5 (5 = гл. админ)',
                  keyboard: TextInputType.number),
              const Text(
                  '1 — модератор, 2 — ст. мод, 3 — гл. мод, 4 — зам, 5 — гл. админ',
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена',
                  style: TextStyle(color: Colors.white54))),
          TextButton(
              onPressed: () async {
                try {
                  final doc = await userByQuery(cEmail.text, cName.text);
                  final rank = int.tryParse(cRank.text.trim()) ?? 1;
                  if (rank < 1 || rank > 5) throw Exception('Ранг 1–5');
                  await FirebaseFirestore.instance
                      .collection('admins')
                      .doc(doc.id)
                      .set({
                    'rank': rank,
                    'name': doc.data()?['name'] ?? '',
                    'email': doc.data()?['email'] ?? '',
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('$e')));
                }
              },
              child: const Text('Сохранить',
                  style: TextStyle(color: kGoldColor))),
        ],
      ),
    );
  }

  Future<void> _showNickRequestDialog(BuildContext context) async {
    final cName = TextEditingController();
    final cMsg = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        title: const Text('Запрос смены ника',
            style: TextStyle(color: kGoldColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(cName, 'Ник игрока (персонаж)'),
            const SizedBox(height: 6),
            _field(cMsg, 'Сообщение игроку (необязательно)'),
            const Text(
                'Игрок получит окно с просьбой сменить ник — у него остаётся право согласиться и придумать новый.',
                style: TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена',
                  style: TextStyle(color: Colors.white54))),
          TextButton(
              onPressed: () async {
                try {
                  final doc = await userByQuery('', cName.text);
                  await FirebaseFirestore.instance
                      .collection('nick_requests')
                      .doc(doc.id)
                      .set({
                    'message':
                        cMsg.text.trim().isEmpty
                            ? ''
                            : cMsg.text.trim(),
                    'created_at': FieldValue.serverTimestamp(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('$e')));
                }
              },
              child: const Text('Отправить',
                  style: TextStyle(color: kGoldColor))),
        ],
      ),
    );
  }
}
