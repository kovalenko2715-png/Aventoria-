import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/chat_service.dart';
import '../main.dart';
import '../services/player_repository.dart';
import '../widgets/module_window.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  String _tab = 'general';

  static const _tabNames = {
    'general': 'Общий',
    'trade': 'Торговый',
    'guild': 'Гильдейский',
    'system': 'Система',
  };

  Color get _tabColor => switch (_tab) {
        'trade' => kChatTrade,
        'guild' => kChatGuild,
        'system' => kChatSystem,
        _ => kChatGeneral,
      };

  @override
  void initState() {
    super.initState();
    ChatService.instance.startHeartbeat();
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) return;
      setState(() {
        _tab = _tabNames.keys.elementAt(_tabs.index);
      });
    });
  }

  @override
  void dispose() {
    ChatService.instance.stopHeartbeat();
    _tabs.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    final user = FirebaseAuth.instance.currentUser;
    final player = PlayerRepository.instance;
    final needsGuild = _tab == 'guild';
    final guild = player.data?['guild'];
    if (needsGuild && (guild == null || guild == '—' || guild == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Вы не состоите в гильдии')));
      return;
    }
    await FirebaseFirestore.instance.collection('chat').add({
      'uid': user?.uid,
      'name': player.isLoaded ? player.name : 'Игрок',
      'tab': _tab,
      'text': text,
      'created_at': FieldValue.serverTimestamp(),
    });
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
      actions: [
        StreamBuilder<int>(
          stream: ChatService.instance.onlineCount(),
          builder: (context, snap) {
            final online = snap.data ?? 1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text('Онлайн $online',
                  style: const TextStyle(color: kGoldColor, fontSize: 12)),
            );
          },
        ),
      ],
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
            ],
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat')
                  .orderBy('created_at', descending: true)
                  .limit(200)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text('Ошибка чата: ${snap.error}',
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 12)),
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs
                    .where((d) =>
                        (d.data() as Map<String, dynamic>?)?['tab'] == _tab)
                    .take(60)
                    .toList();
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(10),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final msg =
                        docs[i].data() as Map<String, dynamic>? ?? const {};
                    final name = msg['name']?.toString() ?? '???';
                    final text = msg['text']?.toString() ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                              fontSize: chatFontSize, color: kChatGeneral),
                          children: [
                            TextSpan(
                              text: '$name: ',
                              style: const TextStyle(
                                  color: kGoldColor,
                                  fontWeight: FontWeight.w600),
                            ),
                            TextSpan(text: text),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
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
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Сообщение...',
                        hintStyle:
                            const TextStyle(color: Colors.white38, fontSize: 13),
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
