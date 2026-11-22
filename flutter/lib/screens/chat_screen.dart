import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/chat_service.dart';
import '../main.dart';
import '../services/player_repository.dart';
import '../widgets/module_window.dart';
import '../widgets/nickname_dialog.dart';
import '../widgets/player_profile_view.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 5, vsync: this);
  late final AnimationController _blink;
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  String _tab = 'general';
  String? _pmTargetUid;
  String _pmTargetName = '';

  static const _tabNames = {
    'general': 'Общий',
    'trade': 'Торговый',
    'guild': 'Гильдейский',
    'system': 'Система',
    'personal': 'Личные',
  };

  Color get _tabColor => switch (_tab) {
        'trade' => kChatTrade,
        'guild' => kChatGuild,
        'system' => kChatSystem,
        'personal' => kChatPersonal,
        _ => kChatGeneral,
      };

  @override
  void initState() {
    super.initState();
    ChatService.instance.startHeartbeat();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) return;
      setState(() {
        _tab = _tabNames.keys.elementAt(_tabs.index);
        if (_tab != 'personal') _pmTargetUid = null;
      });
    });
  }

  @override
  void dispose() {
    ChatService.instance.stopHeartbeat();
    _tabs.dispose();
    _blink.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (PlayerRepository.instance.nicknameMissing) {
      await showNicknameDialog(context);
      if (PlayerRepository.instance.nicknameMissing) return;
    }
    final text = _input.text.trim();
    if (text.isEmpty) return;
    if (_tab == 'personal' && _pmTargetUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Выбери игрока справа и «Написать»')));
      return;
    }
    _input.clear();
    final user = FirebaseAuth.instance.currentUser;
    final player = PlayerRepository.instance;
    final needsGuild = _tab == 'guild';
    final guild = player.data?['guild'];
    if (needsGuild && (guild == null || guild == '—')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Вы не состоите в гильдии')));
      return;
    }
    await FirebaseFirestore.instance.collection('chat').add({
      'uid': user?.uid,
      'name': player.isLoaded ? player.name : 'Игрок',
      'level': player.level,
      'tab': _tab,
      'text': text,
      if (_tab == 'personal' && _pmTargetUid != null) ...{
        'to_uid': _pmTargetUid,
        'to_name': _pmTargetName,
      },
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  void _openProfile(String uid) {
    showDialog(
      context: context,
      builder: (ctx) => ModuleWindow(
        title: 'ПРОФИЛЬ ИГРОКА',
        child: PlayerProfileView(uid: uid),
      ),
    );
  }

  void _openPlayerMenu(String uid, String name) {
    final me = FirebaseAuth.instance.currentUser?.uid;
    final isMe = uid == me;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 340,
          decoration: BoxDecoration(
            color: const Color(0xFA1A1A1A),
            border: Border.all(
                color: kGoldColor.withOpacity(0.8), width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    left: 12, right: 4, top: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                          isMe ? 'Твой профиль' : name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: kGoldColor,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close,
                          color: Colors.white70, size: 20),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 4),
              Padding(
                padding:
                    const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _menuBtn('Посмотреть профиль', Icons.person_outline,
                        kGoldColor, () {
                      Navigator.pop(ctx);
                      _openProfile(uid);
                    }),
                    if (!isMe) ...[
                      const SizedBox(height: 6),
                      _menuBtn('Написать', Icons.mail_outline,
                          kChatPersonal, () {
                        Navigator.pop(ctx);
                        setState(() {
                          _tabs.animateTo(4);
                          _tab = 'personal';
                          _pmTargetUid = uid;
                          _pmTargetName = name;
                        });
                      }),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuBtn(String label, IconData icon, Color color,
      VoidCallback onTap) {
    return SizedBox(
      height: 34,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF2A2A2A),
          side: BorderSide(color: color.withOpacity(0.6)),
          alignment: Alignment.centerLeft,
        ),
        icon: Icon(icon, color: color, size: 17),
        label: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 13)),
      ),
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _visibleMessages(
      QuerySnapshot<Map<String, dynamic>> snap) {
    final me = FirebaseAuth.instance.currentUser?.uid;
    return snap.docs.where((d) {
      final msg = d.data();
      if (_tab == 'personal') {
        return msg['tab'] == 'personal' &&
            (msg['uid'] == me || msg['to_uid'] == me);
      }
      return msg['tab'] == _tab;
    }).take(60).toList();
  }

  Widget _messageRow(QueryDocumentSnapshot<Map<String, dynamic>> doc,
      Map<String, int> ranks, double chatFontSize) {
    final msg = doc.data();
    final uid = msg['uid']?.toString() ?? '';
    final name = msg['name']?.toString() ?? '???';
    final text = msg['text']?.toString() ?? '';
    final me = FirebaseAuth.instance.currentUser?.uid;
    final rank = ranks[uid] ?? 0;
    final nameColor = nickColorForRank(rank);
    final outgoing = _tab == 'personal' && uid == me;
    final target = outgoing ? (msg['to_name']?.toString() ?? '???') : name;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (rank > 0)
            FadeTransition(
              opacity: _blink,
              child: Text(
                (kAdminRankNames[rank] ?? 'Админ').toUpperCase(),
                style: TextStyle(
                    color: nameColor,
                    fontSize: chatFontSize - 2,
                    height: 1.0),
              ),
            ),
          GestureDetector(
            onTap: () => _openPlayerMenu(uid, name),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                    fontSize: chatFontSize,
                    color: Colors.white,
                    height: 1.1),
                children: [
                  if (outgoing)
                    TextSpan(
                        text: 'ты → $target: ',
                        style: const TextStyle(color: kChatPersonal)),
                  TextSpan(text: '$name: ',
                      style: TextStyle(
                          color: nameColor
                              .withOpacity(uid == me ? 0.7 : 1.0),
                          fontWeight: FontWeight.w600)),
                  TextSpan(
                      text: text,
                      style: TextStyle(color: _tabColor)),
                ],
              ),
            ),
          ),
          Text('уровень ${(msg['level'] as num?)?.toInt() ?? '?'}',
              style: TextStyle(
                  color: Colors.white54,
                  fontSize: chatFontSize - 3,
                  height: 1.0)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fontVal = PlayerRepository
            .instance.data?['settings_chat_font']?.toString() ??
        'medium';
    const fontSizes = {'small': 10.0, 'medium': 12.0, 'large': 14.0};
    final chatFontSize = fontSizes[fontVal] ?? 12.0;
    return ModuleWindow(
      title: '💬 Чат',
      child: Column(
        children: [
          TabBar(
            controller: _tabs,
            labelColor: _tabColor,
            unselectedLabelColor: Colors.white54,
            indicatorColor: _tabColor,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Общий'),
              Tab(text: 'Торговый'),
              Tab(text: 'Гильдейский'),
              Tab(text: 'Система'),
              Tab(text: 'Личные'),
            ],
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      if (_tab == 'personal')
                        Container(
                          width: double.infinity,
                          color: const Color(0xFF221D18),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _pmTargetUid == null
                                      ? 'Личные: выбери игрока справа → «Написать»'
                                      : 'Личное для: $_pmTargetName',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: _pmTargetUid == null
                                          ? Colors.white38
                                          : kChatPersonal,
                                      fontSize: 11),
                                ),
                              ),
                              if (_pmTargetUid != null)
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _pmTargetUid = null),
                                  child: const Icon(Icons.close,
                                      size: 14, color: Colors.white38),
                                ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: StreamBuilder<
                                QuerySnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('chat')
                              .withConverter<Map<String, dynamic>>(
                                  fromFirestore: (s, _) =>
                                      s.data() ?? <String, dynamic>{},
                                  toFirestore: (m, _) => m)
                              .orderBy('created_at', descending: true)
                              .limit(200)
                              .snapshots(),
                          builder: (context, snap0) {
                            if (snap0.hasError) {
                              return Center(
                                child: Text(
                                    'Ошибка чата: ${snap0.error}',
                                    style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 12)),
                              );
                            }
                            if (!snap0.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            final docs = _visibleMessages(snap0.data!);
                            return StreamBuilder<Map<String, int>>(
                              stream:
                                  ChatService.instance.adminRanksStream(),
                              builder: (context, ranksSnap) {
                                final ranks = ranksSnap.data ?? const {};
                                return ListView.builder(
                                  controller: _scroll,
                                  padding: const EdgeInsets.fromLTRB(
                                      10, 8, 10, 8),
                                  itemCount: docs.length,
                                  itemBuilder: (context, i) =>
                                      _messageRow(docs[i],
                                          ranks, chatFontSize),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1, indent: 4, endIndent: 4, color: Color(0x40FFFFFF)),
                SizedBox(
                  width: 128,
                  child: Container(
                    color: const Color(0x14141414),
                    child: StreamBuilder<
                            Map<String, Map<String, dynamic>>>(
                        stream: ChatService.instance.presenceStream(),
                        builder: (context, psnap) {
                          if (psnap.hasError) {
                            return const Center(
                              child: Text('Нет списка\nонлайн',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 11)),
                            );
                          }
                          if (!psnap.hasData) {
                            return const Center(
                                child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            ));
                          }
                          final players = psnap.data ?? const {};
                          return StreamBuilder<Map<String, int>>(
                            stream:
                                ChatService.instance.adminRanksStream(),
                            builder: (context, ranksSnap) {
                              final ranks = ranksSnap.data ?? const {};
                              final ids = players.keys.toList()
                                ..sort((a, b) => (players[a]?['name']
                                            ?.toString() ??
                                        '')
                                    .compareTo(players[b]?['name']
                                            ?.toString() ??
                                        ''));
                              return ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                itemCount: ids.length,
                                itemBuilder: (context, i) {
                                  final puid = ids[i];
                                  final p = players[puid] ?? {};
                                  final pname =
                                      p['name']?.toString() ?? '???';
                                  final rank = ranks[puid] ?? 0;
                                  return GestureDetector(
                                    onTap: () =>
                                        _openPlayerMenu(puid, pname),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(pname,
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  color:
                                                      nickColorForRank(
                                                          rank),
                                                  fontSize: 11)),
                                          Text(
                                              '${(p['level'] as num?)?.toInt() ?? 1} ур.',
                                              style: const TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 9)),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        }),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: _tab == 'personal'
                            ? 'Личное сообщение...'
                            : 'Сообщение...',
                        hintStyle: const TextStyle(
                            color: Colors.white38, fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFF1A1A1A),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    onPressed: _send,
                    icon:
                        const Icon(Icons.send_outlined, color: kGoldColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
