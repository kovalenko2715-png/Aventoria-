import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'chat_service.dart';

/// Авто-календарь игровых событий + ручное управление из админки.
///
/// Все события считаются по локальному времени устройства:
///  - выходные x2 опыт  (сб 00:00 — пн 00:00)
///  - час золота        (каждый день 21:00 — 22:00)
///  - Пасха 🐣          (западная Пасха + 1 день, по году)
///  - Хэллоуин 🎃       (31.10 — 02.11)
///  - Новый год 🎄      (30.12 — 02.01)
///
/// Админ может принудительно открыть любое событие (settings/events forced)
/// или отключить авто-событие (settings/events off).
class EventService {
  EventService._();
  static final EventService instance = EventService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  Map<String, dynamic>? _settings;

  /// id -> {name, emoji, desc, exp, gold}
  static const Map<String, Map<String, dynamic>> eventDefs = {
    'weekend_exp': {
      'name': 'ВЫХОДНЫЕ x2 ОПЫТА',
      'emoji': '🎉',
      'desc': 'По выходным опыт за бои удваивается!',
      'exp': 2,
      'gold': 1,
    },
    'gold_hour': {
      'name': 'ЧАС ЗОЛОТА',
      'emoji': '💰',
      'desc': 'Каждый день с 21:00 до 22:00 золото за бои удваивается!',
      'exp': 1,
      'gold': 2,
    },
    'easter': {
      'name': 'Пасха',
      'emoji': '🐣',
      'desc': 'Пасхальный двойной опыт и золото!',
      'exp': 2,
      'gold': 2,
    },
    'halloween': {
      'name': 'Хэллоуин',
      'emoji': '🎃',
      'desc': 'Ночь страхов: двойной опыт и золото!',
      'exp': 2,
      'gold': 2,
    },
    'newyear': {
      'name': 'Новый год',
      'emoji': '🎄',
      'desc': 'Праздничный двойной опыт и золото!',
      'exp': 2,
      'gold': 2,
    },
  };

  void init() {
    _sub ??= _db
        .collection('settings')
        .doc('events')
        .snapshots()
        .listen((s) => _settings = s.data());
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _settings = null;
  }

  Map<String, dynamic>? def(String id) => eventDefs[id];

  bool autoOff(String id) {
    final off = (_settings?['off'] as Map<dynamic, dynamic>?);
    return off?[id] == true;
  }

  int? _forcedUntil(String id) {
    final forced = (_settings?['forced'] as Map<dynamic, dynamic>?);
    final v = (forced?[id] as num?)?.toInt() ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    return v > now ? v : null;
  }

  /// Окно события [id], содержащее [now] (или null — сейчас не активен).
  /// Mixed into multipliers + calendar UI.
  (DateTime, DateTime)? _autoWindow(String id, DateTime now) {
    switch (id) {
      case 'weekend_exp':
        // Сб 00:00 — Пн 00:00.
        final daysToSat = (DateTime.saturday - now.weekday) % 7;
        final start = DateTime(now.year, now.month, now.day)
            .add(Duration(days: daysToSat));
        if (now.isBefore(start)) return null;
        final end = start.add(const Duration(days: 2));
        return (start, end);
      case 'gold_hour':
        final start = DateTime(now.year, now.month, now.day, 21);
        if (now.isBefore(start)) return null;
        final endDt = start.add(const Duration(hours: 1));
        return now.isBefore(endDt) ? (start, endDt) : null;
      case 'easter':
        final sunday = easterSunday(now.year);
        final start = DateTime(sunday.year, sunday.month, sunday.day - 1);
        final end = DateTime(sunday.year, sunday.month, sunday.day + 1, 23, 59, 59);
        return (now.isBefore(start) || now.isAfter(end)) ? null : (start, end);
      case 'halloween':
        final start = DateTime(now.year, 10, 31);
        final end = DateTime(now.year, 11, 2, 23, 59, 59);
        return (now.isBefore(start) || now.isAfter(end)) ? null : (start, end);
      case 'newyear':
        // 30.12 — 02.01 (через границу года).
        final start = DateTime(now.year, 12, 30);
        final end = DateTime(now.year + 1, 1, 2, 23, 59, 59);
        final prevStart = DateTime(now.year - 1, 12, 30);
        final prevEnd = DateTime(now.year, 1, 2, 23, 59, 59);
        if (now.isAfter(start) && now.isBefore(end)) return (start, end);
        if (now.isAfter(prevStart) && now.isBefore(prevEnd)) {
          return (prevStart, prevEnd);
        }
        return null;
    }
    return null;
  }

  /// Пасха (западная), алгоритм Гаусса.
  DateTime easterSunday(int year) {
    final a = year % 19;
    final b = year ~/ 100, c = year % 100;
    final d = b ~/ 4, e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4, k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime(year, month, day);
  }

  /// Активно ли событие сейчас (форс из админки имеет приоритет).
  bool isActive(String id, {DateTime? now}) {
    final t = now ?? DateTime.now();
    final f = _forcedUntil(id);
    if (f != null) return true;
    if (autoOff(id)) return false;
    return _autoWindow(id, t) != null;
  }

  Duration? untilEnd(String id, {DateTime? now}) {
    final t = now ?? DateTime.now();
    final f = _forcedUntil(id);
    if (f != null) {
      return Duration(milliseconds: f - t.millisecondsSinceEpoch);
    }
    final w = _autoWindow(id, t);
    return w == null ? null : w.$2.difference(t);
  }

  /// Итоговые множители по всем активным событиям (произведение).
  ({double exp, double gold}) multipliers({DateTime? now}) {
    double exp = 1, gold = 1;
    for (final id in eventDefs.keys) {
      if (!isActive(id, now: now)) continue;
      exp *= ((eventDefs[id]!['exp'] as num?)?.toDouble()) ?? 1;
      gold *= ((eventDefs[id]!['gold'] as num?)?.toDouble()) ?? 1;
    }
    return (exp: exp, gold: gold);
  }

  /// Все окна событий в ближайшие [daysAhead] дней — для строки событий
  /// (вкладка «События»): активные первыми.
  List<({String id, DateTime start, DateTime end, bool active})> calendar(
      {int daysAhead = 35}) {
    final now = DateTime.now();
    final to = now.add(Duration(days: daysAhead));
    final out = <({String id, DateTime start, DateTime end, bool active})>[];
    for (final id in eventDefs.keys) {
      final f = _forcedUntil(id);
      var hasAuto = false;
      for (var day = -2; day <= daysAhead; day++) {
        final probe = now.add(Duration(days: day));
        final w = _autoWindow(id, probe);
        if (w == null) continue;
        if (w.$2.isBefore(now)) continue;
        hasAuto = true;
        if (out.any((e) => e.id == id && e.start == w.$1)) continue;
        if (w.$1.isAfter(to)) break;
        out.add((id: id, start: w.$1, end: w.$2, active: true));
        break;
      }
      if (f != null) {
        final start = now;
        if (hasAuto) continue;
        out.add((
          id: id,
          start: start,
          end: DateTime.fromMillisecondsSinceEpoch(f),
          active: true,
        ));
      }
    }
    out.sort((a, b) {
      final ah = isActive(a.id) ? 0 : 1;
      final bh = isActive(b.id) ? 0 : 1;
      if (ah != bh) return ah - bh;
      return a.start.compareTo(b.start);
    });
    return out;
  }

  /// Объявление в чат о только что начавшихся событиях
  /// (один ключ на событие за окно — повторов от разных клиентов не будет).
  Future<void> announceActive() async {
    final now = DateTime.now();
    for (final id in eventDefs.keys) {
      if (!isActive(id, now: now)) continue;
      final end = untilEnd(id, now: now);
      final def = eventDefs[id]!;
      final key = forcedOpen(id) != null
          ? 'ev_forced_${id}_${now.year}${now.month}${now.day}'
          : 'ev_${id}_${now.year}${now.month}${now.day}';
      final mins = end?.inMinutes ?? 0;
      final timePart = mins >= 60
          ? 'осталось ${mins ~/ 60} ч ${mins % 60} мин'
          : 'осталось $mins мин';
      await ChatService.instance.systemOnce(
        key,
        '${def['emoji']} НАЧАЛОСЬ СОБЫТИЕ: ${def['name']}! ${def['desc']} ($timePart)',
        tab: 'system',
      );
    }
  }

  int? forcedOpen(String id) => _forcedUntil(id);
}
