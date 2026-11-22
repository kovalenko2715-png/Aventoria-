import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'player_repository.dart';

const Color kChatGeneral = Color(0xFFFFFFFF);
const Color kChatTrade = Color(0xFF45FF45);
const Color kChatGuild = Color(0xFFFF9900);
const Color kChatSystem = Color(0xFFFF4545);

const int kOnlineWindowMs = 90 * 1000;

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  CollectionReference get _presence =>
      FirebaseFirestore.instance.collection('presence');

  Timer? _heartbeat;

  void startHeartbeat() {
    _heartbeat?.cancel();
    _push();
    _heartbeat = Timer.periodic(const Duration(seconds: 30), (_) => _push());
  }

  void stopHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = null;
  }

  Future<void> _push() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final player = PlayerRepository.instance;
    try {
      await _presence.doc(user.uid).set({
        'name': player.isLoaded ? player.name : 'Игрок',
        'last_seen': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Stream<int> onlineCount() => _presence
      .where('last_seen',
          isGreaterThan: DateTime.now().millisecondsSinceEpoch - kOnlineWindowMs)
      .snapshots()
      .map((s) => s.docs.length)
      .handleError((_) => 0);

  Stream<int> unreadCount() {
    final lastRead =
        (PlayerRepository.instance.data?['chat_last_read'] as num?)
                ?.toInt() ??
            0;
    return FirebaseFirestore.instance
        .collection('chat')
        .orderBy('created_at', descending: true)
        .limit(60)
        .snapshots()
        .map((s) {
      var n = 0;
      for (final d in s.docs) {
        final ts = (d['created_at'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        if (ts > lastRead) n++;
      }
      return n;
    }).handleError((_) => 0);
  }

  Future<void> markChatRead() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('chat')
          .orderBy('created_at', descending: true)
          .limit(1)
          .get();
      var latest = DateTime.now().millisecondsSinceEpoch;
      if (snap.docs.isNotEmpty) {
        final ts = snap.docs.first['created_at'];
        if (ts is Timestamp) latest = ts.millisecondsSinceEpoch;
      }
      await PlayerRepository.instance.replaceField(
        'chat_last_read',
        latest + 1,
      );
    } catch (_) {}
  }
}
