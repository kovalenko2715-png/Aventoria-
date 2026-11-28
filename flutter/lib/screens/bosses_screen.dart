import 'dart:async';

import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../main.dart';
import '../services/battle_engine.dart';
import '../services/event_service.dart';
import '../services/world_boss_service.dart';
import '../widgets/mob_info_window.dart';
import '../widgets/module_window.dart';
import 'world_boss_battle_screen.dart';

/// БОССЫ: Подземелья / Мира (реальные таймеры пробуждения + комнаты) / События.
class BossesScreen extends StatefulWidget {
  const BossesScreen({super.key});

  @override
  State<BossesScreen> createState() => _BossesScreenState();
}

class _BossesScreenState extends State<BossesScreen> {
  Timer? _refresh;
  WorldBossService get _svc => WorldBossService.instance;

  @override
  void initState() {
    super.initState();
    // Тикаем, чтобы таймеры пробуждения считались живыми.
    _refresh = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  bool _eventActive(Map<String, dynamic> boss) {
    final now = DateTime.now();
    final sm = (boss['start_month'] as num?)?.toInt() ?? 0;
    final sd = (boss['start_day'] as num?)?.toInt() ?? 1;
    final em = (boss['end_month'] as num?)?.toInt() ?? 0;
    final ed = (boss['end_day'] as num?)?.toInt() ?? 1;
    final today = now.month * 100 + now.day;
    final start = sm * 100 + sd;
    final end = em * 100 + ed;
    if (start <= end) {
      return today >= start && today <= end;
    }
    return today >= start || today <= end;
  }

  void _openBoss(BuildContext context, MapEntry<String, dynamic> entry) {
    final mob = mobFromBoss(entry.key, entry.value as Map<String, dynamic>);
    // Как в оригинале: сначала окно с информацией, бой — по кнопке в нём.
    showMobInfoWindow(context, mob);
  }

  Widget _bossCard(BuildContext context, MapEntry<String, dynamic> entry) {
    final boss = entry.value as Map<String, dynamic>;
    final rewards = boss['rewards'] as Map<dynamic, dynamic>? ?? const {};
    final drops = (boss['drops'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(boss['icon']?.toString() ?? '💀',
                  style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(boss['name']?.toString() ?? '',
                    style: const TextStyle(
                        color: kGoldColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          Text(boss['description']?.toString() ?? '',
              style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 12)),
          const SizedBox(height: 4),
          Text(
              'Ур. ${boss['level']} • HP ${boss['hp']} • Атака ${boss['attack_min']}-${boss['attack_max']} • Защита ${boss['defense']} • ${boss['location_name'] ?? ''}',
              style: const TextStyle(color: Colors.white, fontSize: 12)),
          if (drops.isNotEmpty)
            Text(
                'Дроп: ${drops.map((d) => '${d['name']} (${d['chance']}%)').join(', ')}',
                style: const TextStyle(
                    color: Color(0xFF80FF80), fontSize: 11)),
          Text('Награда: ${rewards['exp'] ?? 0} оп, ${rewards['gold'] ?? 0} 💰',
              style: const TextStyle(color: kGoldColor, fontSize: 12)),
          if (boss['rumor'] != null)
            Text('💬 ${boss['rumor']}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.45), fontSize: 11)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _openBoss(context, entry),
                child: const Text('Атаковать',
                    style: TextStyle(color: kGoldColor, fontSize: 14)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── МИРОВЫЕ БОССЫ ─────────────────────────────────────────────────────

  String _fmtDuration(Duration d) {
    if (d.inSeconds <= 0) return 'скоро';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '$h ч $m мин';
    if (m > 0) return '$m мин $s сек';
    return '$s сек';
  }

  Widget _worldBossCard(BuildContext context, String id) {
    final def = _svc.bossDef(id);
    if (def == null) return const SizedBox.shrink();
    final now = DateTime.now().millisecondsSinceEpoch;
    final open = _svc.isOpen(id, now: now);
    final rewards = def['rewards'] as Map<dynamic, dynamic>? ?? const {};
    final drops = (def['drops'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final openMin = WorldBossService.scheduleDefaults[id]?[1] ?? 20;
    final periodMin = WorldBossService.scheduleDefaults[id]?[0] ?? 0;

    return GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(def['icon']?.toString() ?? '💀',
                  style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(def['name']?.toString() ?? '',
                    style: TextStyle(
                        color: open ? const Color(0xFFFF6A00) : kGoldColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: open
                      ? const Color(0x33FF6A00)
                      : const Color(0x33333333),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: open
                          ? const Color(0xFFFF6A00)
                          : const Color(0xFF888888)),
                ),
                child: Text(
                  open ? '🔥 ПРОБУДИЛСЯ' : '⏳ СПИТ',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: open
                          ? const Color(0xFFFFB347)
                          : const Color(0xFFAAAAAA)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            open
                ? '⚔️ Открыт ещё ${_fmtDuration(_svc.untilClose(id))} для нападения!'
                : 'Дата пробуждения через: ${_fmtDuration(_svc.untilNextOpen(id))}',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: open
                    ? const Color(0xFF80FF80)
                    : const Color(0xFFCCCCCC)),
          ),
          Text(def['description']?.toString() ?? '',
              style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 12)),
          const SizedBox(height: 4),
          Text(
              'Ур. ${def['level']} • HP ${def['hp']} • Атака ${def['attack_min']}-${def['attack_max']} • ${def['location_name'] ?? ''}',
              style: const TextStyle(color: Colors.white, fontSize: 12)),
          if (drops.isNotEmpty)
            Text(
                'Дроп (каждому свой ролл!): ${drops.map((d) => '${d['name']} (${d['chance']}%)').join(', ')}',
                style: const TextStyle(
                    color: Color(0xFF80FF80), fontSize: 11)),
          Text(
              'Награда: ${rewards['exp'] ?? 0} оп, ${rewards['gold'] ?? 0} 💰 каждый',
              style: const TextStyle(color: kGoldColor, fontSize: 12)),
          if (def['rumor'] != null)
            Text('💬 ${def['rumor']}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.45), fontSize: 11)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Окно: $openMin мин • Период: ${periodMin ~/ 60} ч ${periodMin % 60} мин',
                  style: const TextStyle(
                      color: Color(0xFF999999), fontSize: 10)),
              const Spacer(),
              OutlinedButton(
                onPressed: open ? () => _openRooms(context, id) : null,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: open
                          ? const Color(0x80FFD700)
                          : const Color(0x44888888)),
                  backgroundColor: const Color(0xFF221D18),
                  minimumSize: const Size(130, 36),
                ),
                child: Text(
                  open ? '⚔️ К БОССУ' : 'СПИТ',
                  style: TextStyle(
                      fontSize: 12,
                      color: open
                          ? kGoldColor
                          : const Color(0xFF888888)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openRooms(BuildContext context, String bossId) {
    if (!_svc.isOpen(bossId)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Босс уже покинул мир. Ждём пробуждения!')));
      return;
    }
    final def = _svc.bossDef(bossId);
    final now = DateTime.now().millisecondsSinceEpoch;
    final minsLeft =
        ((_svc.currentWindow(bossId).$2 - now) / 60000).ceil();
    pushModuleWindow(
      context,
      ModuleWindow(
        title: '🏰 ${def?['name'] ?? 'Мировой босс'}',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text('⏱ $minsLeft мин',
                style: const TextStyle(
                    color: Color(0xFF80FF80),
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
        ],
        maxWidth: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: OutlinedButton(
                onPressed: () async {
                  final id = await _svc.createRoom(bossId);
                  if (!context.mounted) return;
                  if (id == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'Не получается создать комнату. Попробуйте позже.')));
                    return;
                  }
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => WorldBossBattleScreen(roomId: id)));
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0x80FFD700)),
                  backgroundColor: const Color(0xFF221D18),
                  minimumSize: const Size(double.infinity, 42),
                ),
                child: const Text('➕ СОЗДАТЬ КОМНАТУ',
                    style: TextStyle(color: kGoldColor, fontSize: 13)),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Center(
                  child: Text('АКТИВНЫЕ КОМНАТЫ',
                      style: TextStyle(color: kGoldColor, fontSize: 13))),
            ),
            Expanded(
              child: StreamBuilder<
                  List<MapEntry<String, Map<String, dynamic>>>>(
                stream: _svc.roomsFor(bossId),
                builder: (context, snap0x) {
                  final rooms = (snap0x.data ?? const [])
                      .where((e) =>
                          (e.value['status']?.toString() ?? '') ==
                          'waiting')
                      .toList();
                  if (rooms.isEmpty) {
                    return const Center(
                      child: Text(
                          'Нет открытых комнат.\nСоздайте свою — босс ждёт!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Color(0xFF999999),
                              fontSize: 12)),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 10),
                    itemCount: rooms.length,
                    itemBuilder: (context, i) {
                      final e = rooms[i];
                      final count =
                          (e.value['players_count'] as num?)?.toInt() ??
                              ((e.value['players']
                                          as Map<dynamic, dynamic>? ??
                                      const {})
                                  .length);
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
                                child: Text('🏰',
                                    style: TextStyle(fontSize: 22)),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'Комната ${e.value['creator_name'] ?? '???'}',
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight:
                                                FontWeight.bold)),
                                    Text('👥 $count игроков ждут',
                                        style: const TextStyle(
                                            color: Color(0xFFCCCCCC),
                                            fontSize: 11)),
                                  ],
                                ),
                              ),
                              OutlinedButton(
                                onPressed: () async {
                                  final ok =
                                      await _svc.joinRoom(e.key);
                                  if (!context.mounted) return;
                                  if (!ok) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                            content: Text(
                                                'Бой уже начался или комната закрыта.')));
                                    return;
                                  }
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              WorldBossBattleScreen(
                                                  roomId: e.key)));
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: Color(0x80FFD700)),
                                  backgroundColor:
                                      const Color(0xFF221D18),
                                  minimumSize:
                                      const Size(100, 36),
                                ),
                                child: const Text('ВСТУПИТЬ',
                                    style: TextStyle(
                                        color: kGoldColor,
                                        fontSize: 12)),
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
      ),
    );
  }

  // ─── БИЛД ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final eventBosses = bossesEvent.entries.toList();
    final activeEventBosses = eventBosses
        .where((e) => _eventActive(e.value as Map<String, dynamic>))
        .toList();
    final inactiveEventBosses = eventBosses
        .where((e) => !_eventActive(e.value as Map<String, dynamic>))
        .toList();

    return ModuleWindow(
      title: '🍶 БОССЫ',
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              labelColor: kGoldColor,
              unselectedLabelColor: Colors.white54,
              indicatorColor: kGoldColor,
              isScrollable: true,
              tabs: [
                Tab(text: 'Подземелья'),
                Tab(text: 'Мира'),
                Tab(text: 'События'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _list(bossesDungeon.entries
                      .map((e) => _bossCard(context, e))
                      .toList()),
                  _list([
                    for (final id in WorldBossService.scheduleDefaults.keys) ...[
                      _worldBossCard(context, id),
                      const SizedBox(height: 6),
                    ],
                  ]),
                  _list([
                    ..._eventsCalendarSection(),
                    const SizedBox(height: 10),
                    const Text('🎮 ИВЕНТОВЫЕ БОССЫ',
                        style: TextStyle(
                            color: kGoldColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    const SizedBox(height: 4),
                    if (activeEventBosses.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                            'Сейчас нет активных событиевых боссов. Ждите следующую дату!',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 13)),
                      ),
                    for (final e in activeEventBosses) ...[
                      _bossCard(context, e),
                      const SizedBox(height: 6),
                    ],
                    for (final e in inactiveEventBosses)
                      Opacity(
                        opacity: 0.45,
                        child: _bossCard(context, e),
                      ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  List<Widget> _eventsCalendarSection() {
    final items = EventService.instance.calendar(daysAhead: 40);
    return [
      const Text('📅 КАЛЕНДАРЬ ИВЕНТОВ',
          style: TextStyle(
              color: kGoldColor, fontWeight: FontWeight.bold, fontSize: 13)),
      const SizedBox(height: 4),
      const Text(
          'Выходные x2 опыта и час золота (21:00–22:00) идут постоянно. Праздники автоматически.',
          style: TextStyle(color: Colors.white38, fontSize: 11)),
      const SizedBox(height: 6),
      for (final it in items)
        Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: it.active
                ? const Color(0xCC2A2005)
                : const Color(0xAA1A1508),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: it.active ? kGoldColor : Colors.white12, width: 1),
          ),
          child: Row(
            children: [
              Text(EventService.eventDefs[it.id]?['emoji'].toString() ?? '📅',
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${EventService.eventDefs[it.id]?['name'] ?? it.id}'
                      '${it.active ? '  🔥 ИДЁТ' : ''}',
                      style: TextStyle(
                          color: it.active ? kGoldColor : Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_twoDigits(it.start.day)}.${_twoDigits(it.start.month)} '
                      '${_twoDigits(it.start.hour)}:${_twoDigits(it.start.minute)} '
                      '— ${_twoDigits(it.end.day)}.${_twoDigits(it.end.month)} '
                      '${_twoDigits(it.end.hour)}:${_twoDigits(it.end.minute)}\n'
                      '${EventService.eventDefs[it.id]?['desc'] ?? ''}',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11, height: 1.25),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    ];
  }

  Widget _list(List<Widget> children) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final w in children) ...[w, const SizedBox(height: 6)],
        const SizedBox(height: 20),
      ],
    );
  }
}
