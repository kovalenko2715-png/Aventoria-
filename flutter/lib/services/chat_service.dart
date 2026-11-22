import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'player_repository.dart';

const Color kChatGeneral = Color(0xFFFFFFFF);
const Color kChatTrade = Color(0xFF45FF45);
const Color kChatGuild = Color(0xFFFF9900);
const Color kChatSystem = Color(0xFFFF4545);
const Color kChatPersonal = Color(0xFFFF6EC7);

const Map<int, String> kAdminRankNames = {
  1: 'Модератор',
  2: 'Старший модератор',
  3: 'Гл. модератор',
  4: 'Зам. админа',
  5: 'Гл. админ',
};

Color nickColorForRank(int rank) {
  if (rank >= 5) return const Color(0xFFFF2020);
  if (rank >= 1) return const Color(0xFFFFA500);
  return kChatGeneral;
}

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
        'level': player.level,
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Stream<Map<String, Map<String, dynamic>>> presenceStream() => _presence
      .where('last_seen',
          isGreaterThan: DateTime.now().millisecondsSinceEpoch - kOnlineWindowMs)
      .snapshots()
      .map((s) => {
            for (final d in s.docs)
              d.id: (d.data() as Map<String, dynamic>? ?? const {})
          })
      .handleError((_) => <String, Map<String, dynamic>>{});

  Stream<int> adminRank() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(0);
    return FirebaseFirestore.instance
        .collection('admins')
        .doc(uid)
        .snapshots()
        .map((d) =>
            d.exists ? ((d['rank'] as num?)?.toInt() ?? 0) : 0)
        .handleError((_) => 0);
  }

  Stream<Map<String, int>> adminRanksStream() => FirebaseFirestore.instance
      .collection('admins')
      .snapshots()
      .map((s) => {
            for (final d in s.docs) d.id: (d['rank'] as num?)?.toInt() ?? 0
          })
      .handleError((_) => <String, int>{});

  Future<bool> hasPendingNickRequest() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('nick_requests')
          .doc(uid)
          .get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  Future<void> clearNickRequest() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('nick_requests')
          .doc(uid)
          .delete();
    } catch (_) {}
  }

  Future<String?> adminNickRequestMessage() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('nick_requests')
          .doc(uid)
          .get();
      if (!doc.exists) return null;
      return doc.data()?['message']?.toString();
    } catch (_) {
      return null;
    }
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('chat')
        .orderBy('created_at', descending: true)
        .limit(60)
        .snapshots()
        .map((s) {
      var n = 0;
      for (final d in s.docs) {
        final msg = d.data() as Map<String, dynamic>?;
        if (uid != null && msg?['uid'] == uid) continue;
        final ts = (msg?['created_at'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
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
