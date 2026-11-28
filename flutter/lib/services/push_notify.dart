import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'world_boss_service.dart';

/// Локальные push-уведомления: планируем ближайшие окна пробуждения
/// мировых боссов. Работают, даже если игра закрыта (планировщик системы).
class PushNotify {
  PushNotify._();
  static final PushNotify instance = PushNotify._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _inited = false;

  Future<void> init() async {
    if (_inited) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(
          const InitializationSettings(android: android));
      final impl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      // Android 13+ спрашивает разрешение; на старых — просто ок.
      await impl?.requestNotificationsPermission();
      // Канал создаётся плагином автоматически по AndroidNotificationDetails,
      // отдельный createChannel в 17.x не нужен.
      _inited = true;
    } catch (_) {
      _inited = false;
    }
  }

  /// Планируем ближайшие N окон каждого босса. Вызываем при каждом запуске игры.
  Future<void> scheduleBossWindows({int windowsAhead = 2}) async {
    await init();
    if (!_inited) return;
    try {
      await _plugin.cancelAll();
      final now = DateTime.now().millisecondsSinceEpoch;
      var idGen = 100;
      for (final id in WorldBossService.scheduleDefaults.keys) {
        final def = WorldBossService.instance.bossDef(id);
        if (def == null) continue;
        final name = def['name']?.toString() ?? 'Мировой босс';
        final sched = WorldBossService.scheduleDefaults[id]!;
        final first = WorldBossService.instance.currentWindow(id, now: now);
        final durationMs = sched[1] * 60000;
        for (var w = 0; w < windowsAhead; w++) {
          final start = first.$1 + w * sched[0] * 60000;
          final end = start + durationMs;
          if (start <= now || end <= now) continue;
          idGen++;
          await _plugin.zonedSchedule(
            idGen,
            '🔥 Босс пробуждается!',
            '$name вышел на охоту. Успей вступить!',
            _tz(start),
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'boss_awaken',
                'Мировые боссы',
                channelDescription: 'Пробуждение мировых боссов',
                importance: Importance.high,
                priority: Priority.high,
                playSound: true,
                sound: const RawResourceAndroidNotificationSound('boss_alert'),
                styleInformation: BigPictureStyleInformation(
                  DrawableResourceAndroidBitmap('boss_push_banner'),
                  largeIcon: DrawableResourceAndroidBitmap('boss_push_banner'),
                ),
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }
    } catch (_) {}
  }

  tz.TZDateTime _tz(int ms) {
    tzdata.initializeTimeZones();
    return tz.TZDateTime.from(
        DateTime.fromMillisecondsSinceEpoch(ms), tz.local);
  }
}
