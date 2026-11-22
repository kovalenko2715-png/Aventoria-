import 'package:flutter/material.dart';

import '../main.dart';
import '../services/player_repository.dart';
import '../services/quest_service.dart';
import '../widgets/module_window.dart';

class QuestsScreen extends StatefulWidget {
  final bool board;
  const QuestsScreen({super.key, this.board = false});

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await QuestState.instance.load(PlayerRepository.instance);
    QuestState.instance.refreshCollectProgress(PlayerRepository.instance);
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _active() =>
      QuestState.instance.myQuests(PlayerRepository.instance);

  bool _expired(Map<String, dynamic> q) {
    final expires = (q['expires_at'] as num?)?.toInt() ?? 0;
    return expires <= DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  Future<void> _accept(Map<String, dynamic> offer) async {
    await QuestState.instance
        .accept(PlayerRepository.instance, offer);
    if (mounted) setState(() {});
  }

  Future<void> _complete(Map<String, dynamic> quest) async {
    final reward = await QuestState.instance
        .complete(PlayerRepository.instance, quest);
    if (!mounted) return;
    if (reward == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Задание «${reward['name']}» выполнено! +${reward['exp']} оп, +${reward['gold']} 💰, +${reward['points']} очков гильдии')));
    setState(() {});
  }

  Widget _questCard(Map<String, dynamic> q, {required bool accepted}) {
    final current = (q['current_count'] as num?)?.toInt() ?? 0;
    final target = (q['target_count'] as num?)?.toInt() ?? 1;
    final expired = accepted && _expired(q);
    final done = current >= target;
    final rankColor = switch (q['rank']?.toString()) {
      'F' => const Color(0xFFCCCCCC),
      'E' => const Color(0xFF80FF80),
      'D' => const Color(0xFF80CCFF),
      'C' => const Color(0xFFCC80FF),
      'B' => const Color(0xFFFFD700),
      'A' => const Color(0xFFFF8080),
      _ => const Color(0xFFFF6060),
    };
    return GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(q['icon']?.toString() ?? '📜',
                  style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(q['name']?.toString() ?? '',
                    style: const TextStyle(
                        color: kGoldColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ),
              Badge(
                backgroundColor: rankColor,
                label: Text('${q['rank']}',
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Text(
              '${q['type'] == 'kill' ? 'Убить' : 'Собрать'}: ${q['target_name']} $current/$target • ${q['location']}',
              style: const TextStyle(color: Colors.white, fontSize: 12)),
          Text(
              'Ур.${q['level_required']}+ • Награда: ${q['reward_exp']} оп, ${q['reward_gold']} 💰, ${q['reward_points']} очк.',
              style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 12)),
          if (expired)
            const Text('Истекло',
                style: TextStyle(color: Color(0xFFFF6060), fontSize: 12)),
          if (!accepted && !expired)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () => _accept(q),
                    child: const Text('Взять задание',
                        style: TextStyle(color: kGoldColor, fontSize: 13))),
              ],
            ),
          if (accepted && done)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () => _complete(q),
                    child: const Text('Завершить',
                        style: TextStyle(color: Color(0xFF80FF80), fontSize: 13))),
              ],
            ),
        ],
      ),
    );
  }

  List<Widget> _offers(List<Map<String, dynamic>> offers) {
    final active = _active();
    final activeIds = active.map((q) => q['id'] as String).toSet();
    return [
      for (final q in offers)
        if (!activeIds.contains(q['id'])) ...[
          _questCard(q, accepted: false),
          const SizedBox(height: 6),
        ],
      if (offers.every((q) => activeIds.contains(q['id'])))
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Все доступные задания взяты',
              style: TextStyle(color: Colors.white54, fontSize: 14)),
        ),
    ];
  }



  @override
  Widget build(BuildContext context) {
    final player = PlayerRepository.instance;
    final board = widget.board;
    return ModuleWindow(
      title: board ? '📋 Доска заданий' : '📜 Мои задания',
      maxWidth: 720,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : !board
              ? ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                          'Очки гильдейских заданий: ${player.data?['guild_quest_points'] ?? 0}',
                          style: const TextStyle(color: kGoldColor, fontSize: 13)),
                    ),
                    if (_active().isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                            'У вас нет принятых заданий.\nЗадания берутся в Гильдии → Доска заданий',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white54, fontSize: 14)),
                      ),
                    for (final q in _active()) ...[
                      _questCard(q, accepted: true),
                      const SizedBox(height: 6),
                    ],
                  ],
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: Text(
                          'Очки гильдейских заданий: ${player.data?['guild_quest_points'] ?? 0}',
                          style: const TextStyle(
                              color: kGoldColor, fontSize: 13)),
                    ),
                    TabBar(
                      controller: _tabs,
                      labelColor: kGoldColor,
                      unselectedLabelColor: Colors.white54,
                      indicatorColor: kGoldColor,
                      isScrollable: true,
                      tabs: const [
                        Tab(text: 'ЕЖЕДНЕВНЫЕ'),
                        Tab(text: 'ЕЖЕНЕДЕЛЬНЫЕ'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabs,
                        children: [
                          ListView(
                            padding: const EdgeInsets.all(12),
                            children:
                                _offers(QuestState.instance.dailyOffers),
                          ),
                          ListView(
                            padding: const EdgeInsets.all(12),
                            children:
                                _offers(QuestState.instance.weeklyOffers),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
