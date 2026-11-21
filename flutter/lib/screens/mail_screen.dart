import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../services/player_repository.dart';
import '../widgets/module_window.dart';

class MailScreen extends StatefulWidget {
  const MailScreen({super.key});

  @override
  State<MailScreen> createState() => _MailScreenState();
}

class _MailScreenState extends State<MailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  final TextEditingController _toCtrl = TextEditingController();
  final TextEditingController _textCtrl = TextEditingController();
  String _tab = 'inbox';

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) return;
      setState(() => _tab = ['inbox', 'outgoing', 'write'][_tabs.index]);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _toCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  CollectionReference get _mails => FirebaseFirestore.instance.collection('mail');

  Query get _query {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return _tab == 'inbox'
        ? _mails.where('to_uid', isEqualTo: uid).orderBy('created_at', descending: true).limit(50)
        : _mails.where('from_uid', isEqualTo: uid).orderBy('created_at', descending: true).limit(50);
  }

  Future<void> _send() async {
    final player = (await _findUser(_toCtrl.text.trim()));
    if (player == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Игрок с таким именем не найден')));
      }
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _mails.add({
      'from_uid': uid,
      'from_name': PlayerRepository.instance.name,
      'to_uid': player['uid'],
      'to_name': player['name'],
      'text': _textCtrl.text.trim(),
      'attachment': null,
      'has_attachment': false,
      'created_at': FieldValue.serverTimestamp(),
    });
    _toCtrl.clear();
    _textCtrl.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Письмо отправлено')));
    }
  }

  Future<Map<String, dynamic>?> _findUser(String name) async {
    if (name.isEmpty) return null;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: name)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    final data = doc.data();
    if ((data['name']?.toString() ?? '').toLowerCase() != name.toLowerCase()) {
      return null;
    }
    return {...data, 'uid': doc.id};
  }

  Widget _mailCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? const {};
    final mine = FirebaseAuth.instance.currentUser?.uid == data['from_uid'];
    return GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(data['has_attachment'] == true ? '📎' : '✉️',
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    mine
                        ? 'Кому: ${data['to_name'] ?? ''}'
                        : 'От: ${data['from_name'] ?? ''}',
                    style: const TextStyle(
                        color: kGoldColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          Text(data['text']?.toString() ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModuleWindow(
      title: '📬 Почта',
      child: Column(
        children: [
          TabBar(
            controller: _tabs,
            labelColor: kGoldColor,
            unselectedLabelColor: Colors.white54,
            indicatorColor: kGoldColor,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Входящие'),
              Tab(text: 'Отправленные'),
              Tab(text: 'Написать'),
            ],
          ),
          Expanded(
            child: _tab == 'write'
                ? ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      TextField(
                        controller: _toCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Имя получателя',
                          labelStyle: TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Color(0xFF1A1A1A),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _textCtrl,
                        maxLines: 5,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Текст письма',
                          labelStyle: TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Color(0xFF1A1A1A),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFCC4D4D)),
                          onPressed: _send,
                          child: const Text('Отправить',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: _query.snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      final docs = snap.data!.docs;
                      if (docs.isEmpty) {
                        return const Center(
                            child: Text('Писем нет',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 15)));
                      }
                      return ListView(
                        padding: const EdgeInsets.all(12),
                        children: [
                          for (final doc in docs) ...[
                            _mailCard(doc),
                            const SizedBox(height: 6),
                          ],
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
