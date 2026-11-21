import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../services/battle_engine.dart';
import '../services/player_repository.dart';
import '../widgets/module_window.dart';
import 'battle_screen.dart';

const _kColorWaiting = Color(0xFF4DCC4D);
const _kColorFighting = Color(0xFFCC8033);
const _kColorFinished = Color(0xFF808080);
const _kColorPrivate = Color(0xFFCC9933);

class ArenaScreen extends StatelessWidget {
  const ArenaScreen({super.key});

  static const MobDef _trainingDummy = MobDef(
    'arena_training',
    'Тренировочный манекен',
    '🎯',
    level: 1,
    hp: 999999,
    strength: 0,
    agility: 0,
    defense: 0,
    attack: 0,
    goldMin: 0,
    goldMax: 0,
    expMin: 0,
    expMax: 0,
  );

  Future<void> _openTraining(BuildContext context) async {
    await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const BattleScreen(mob: _trainingDummy)));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вы хорошо потренировались!')));
  }

  Future<void> _joinRoom(BuildContext context, String roomId,
      Map<String, dynamic> room) async {
    final player = PlayerRepository.instance;
    final name = player.name;
    final uid = player.uid;
    if (uid == null) return;
    final players = List<String>.from(room['players'] as List<dynamic>? ?? const []);
    if (players.contains(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Вы уже в этой комнате!')));
      return;
    }
    if (players.length >= ((room['max_players'] as num?)?.toInt() ?? 2)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Комната полна!')));
      return;
    }
    final privacy = room['privacy']?.toString() ?? 'public';
    if (privacy == 'private') {
      final pinOk = await _askPin(context, room);
      if (!pinOk) return;
    }
    final maxPlayers = (room['max_players'] as num?)?.toInt() ?? 2;
    players.add(name);
    final full = players.length >= maxPlayers;
    final roomRef =
        FirebaseFirestore.instance.collection('arena_rooms').doc(roomId);
    await roomRef.update({
      'players': players,
      'status': full ? 'fighting' : room['status'] ?? 'waiting',
    });
    if (!context.mounted) return;
    if (full) {
      final opponent = players.firstWhere((p) => p != name, orElse: () => 'Противник');
      final mob = MobDef(
        'pvp_$roomId',
        opponent,
        '👤',
        level: player.level,
        hp: 200,
        strength: 10,
        agility: 8,
        defense: 40,
        attack: 80,
        goldMin: 0,
        goldMax: 0,
        expMin: 0,
        expMax: 0,
      );
      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => BattleScreen(mob: mob)));
      await roomRef.update({'status': 'finished'});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Вы вошли в комнату "${room['name']}"! Ожидаем других игроков...')));
    }
  }

  Future<bool> _askPin(BuildContext context, Map<String, dynamic> room) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: kGoldColor.withOpacity(0.6))),
        title: Text('Вход в комнату: "${room['name']}"',
            style: const TextStyle(color: kGoldColor, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔒', style: TextStyle(fontSize: 32)),
            const Text('Введите PIN-код:',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              autofocus: true,
              obscureText: true,
              maxLength: 4,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '****'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('ОТМЕНА')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('ВОЙТИ', style: TextStyle(color: kGoldColor))),
        ],
      ),
    );
    if (ok != true) return false;
    if (controller.text.trim() != (room['pin']?.toString() ?? '')) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Неверный PIN-код!')));
      }
      return false;
    }
    return true;
  }

  Future<void> _openCreate(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    String battleType = '1x1';
    bool isPrivate = false;
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          backgroundColor: const Color(0xFF151515),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: kGoldColor.withOpacity(0.6))),
          title: const Text('СОЗДАНИЕ КОМНАТЫ',
              style: TextStyle(color: kGoldColor, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Название комнаты:',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        hintText: 'Введите название...')),
                const SizedBox(height: 12),
                const Text('Тип боя:',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                Row(
                  children: [
                    for (final t in const ['1x1', '2x2', '3x3'])
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Radio<String>(
                              value: t,
                              groupValue: battleType,
                              activeColor: kGoldColor,
                              onChanged: (v) => setDialog(
                                  () => battleType = v ?? '1x1')),
                          Text(t,
                              style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                  ],
                ),
                const Text('Тип комнаты:',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                Row(
                  children: [
                    Radio<bool>(
                        value: false,
                        groupValue: isPrivate,
                        activeColor: kGoldColor,
                        onChanged: (v) => setDialog(() => isPrivate = false)),
                    const Text('Публичная',
                        style: TextStyle(color: Colors.white)),
                    const SizedBox(width: 12),
                    Radio<bool>(
                        value: true,
                        groupValue: isPrivate,
                        activeColor: kGoldColor,
                        onChanged: (v) => setDialog(() => isPrivate = true)),
                    const Text('Приватная',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
                if (isPrivate) ...[
                  const Text('PIN-код (4 цифры):',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  TextField(
                    controller: pinCtrl,
                    obscureText: true,
                    maxLength: 4,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '****'),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('ОТМЕНА')),
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child:
                    const Text('СОЗДАТЬ', style: TextStyle(color: kGoldColor))),
          ],
        ),
      ),
    );
    if (created != true || !context.mounted) return;

    final roomName = nameCtrl.text.trim();
    if (roomName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Введите название комнаты!')));
      return;
    }
    final pinCode = pinCtrl.text.trim();
    if (isPrivate &&
        (pinCode.length != 4 || int.tryParse(pinCode) == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Введите корректный PIN-код (4 цифры)!')));
      return;
    }
    final uid = PlayerRepository.instance.uid;
    if (uid == null) return;
    final maxPlayers =
        battleType == '1x1' ? 2 : (battleType == '2x2' ? 4 : 6);
    await FirebaseFirestore.instance.collection('arena_rooms').add({
      'name': roomName,
      'creator': PlayerRepository.instance.name,
      'creator_uid': uid,
      'type': battleType,
      'privacy': isPrivate ? 'private' : 'public',
      'pin': isPrivate ? pinCode : '',
      'players': [PlayerRepository.instance.name],
      'max_players': maxPlayers,
      'status': 'waiting',
      'created_at': FieldValue.serverTimestamp(),
    });
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Комната "$roomName" создана!')));
  }

  @override
  Widget build(BuildContext context) {
    return ModuleWindow(
      title: '⚔️ АРЕНА ⚔️',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: OutlinedButton(
            onPressed: () => _openCreate(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0x80FFD700)),
              backgroundColor: const Color(0xFF221D18),
              minimumSize: const Size(200, 40),
            ),
            child: const Text('➕ СОЗДАТЬ КОМНАТУ',
                style: TextStyle(color: kGoldColor, fontSize: 13)),
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: const Color(0xFF1F1A14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
                side: BorderSide(color: kGoldColor.withOpacity(0.3))),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Text('🎯', style: TextStyle(fontSize: 36)),
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ТРЕНИРОВКА',
                            style: TextStyle(
                                color: kGoldColor, fontSize: 16)),
                        SizedBox(height: 2),
                        Text('Бой с манекеном. Проверьте свои силы!',
                            style: TextStyle(
                                color: Color(0xFFCCCCCC), fontSize: 12)),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => _openTraining(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0x80FFD700)),
                      backgroundColor: const Color(0xFF221D18),
                      minimumSize: const Size(120, 35),
                    ),
                    child: const Text('ТРЕНИРОВКА',
                        style: TextStyle(color: kGoldColor, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Center(
              child: Text('АКТИВНЫЕ КОМНАТЫ',
                  style: TextStyle(color: kGoldColor, fontSize: 16)),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('arena_rooms')
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                final docs = snap.data?.docs ?? const [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('Нет активных комнат.\nСоздайте свою!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Color(0xFF999999), fontSize: 14)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final room = docs[i].data();
                    final roomId = docs[i].id;
                    final status = room['status']?.toString() ?? 'waiting';
                    final privacy = room['privacy']?.toString() ?? 'public';
                    final players = (room['players'] as List<dynamic>? ?? const []);
                    final maxPlayers =
                        (room['max_players'] as num?)?.toInt() ?? 2;
                    final statusIcon = status == 'waiting'
                        ? '🟢'
                        : status == 'fighting'
                            ? '🟡'
                            : '🔴';
                    final statusColor = status == 'waiting'
                        ? _kColorWaiting
                        : status == 'fighting'
                            ? _kColorFighting
                            : _kColorFinished;
                    return Card(
                      color: const Color(0xFF1F1A14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                          side: BorderSide(
                              color: kGoldColor.withOpacity(0.3))),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Text(
                                  privacy == 'private' ? '🔒' : '🏠',
                                  style: const TextStyle(fontSize: 32)),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text('$statusIcon ${room['name'] ?? ''}',
                                          style: TextStyle(
                                              color: statusColor,
                                              fontSize: 15)),
                                      Text(' [${room['type'] ?? ''}]',
                                          style: const TextStyle(
                                              color: Color(0xFFB3B3B3),
                                              fontSize: 12)),
                                    ],
                                  ),
                                  Text(
                                      '👤 Создатель: ${room['creator'] ?? '???'}',
                                      style: const TextStyle(
                                          color: Color(0xFFCCCCCC),
                                          fontSize: 12)),
                                  Text(
                                      '👥 ${players.length}/$maxPlayers игроков',
                                      style: const TextStyle(
                                          color: Color(0xFFCCCCCC),
                                          fontSize: 12)),
                                  if (privacy == 'private')
                                    const Text(
                                        '🔒 Приватная комната (требуется PIN-код)',
                                        style: TextStyle(
                                            color: _kColorPrivate,
                                            fontSize: 11)),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              onPressed: status == 'waiting' &&
                                      players.length < maxPlayers
                                  ? () => _joinRoom(context, roomId, room)
                                  : null,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: Color(0x80FFD700)),
                                backgroundColor: const Color(0xFF221D18),
                                minimumSize: const Size(100, 35),
                              ),
                              child: Text(
                                status == 'waiting'
                                    ? (players.length < maxPlayers
                                        ? 'ВОЙТИ'
                                        : 'ПОЛНА')
                                    : status == 'fighting'
                                        ? 'В БОЮ'
                                        : 'ЗАВЕРШЕНА',
                                style: const TextStyle(
                                    color: kGoldColor, fontSize: 12),
                              ),
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
    );
  }
}
