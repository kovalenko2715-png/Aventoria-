import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import 'resource_service.dart';

class AudioManager {
  AudioManager._();
  static final AudioManager instance = AudioManager._();

  static const List<String> _menuTracks = [
    'audio/menu2.mp3',
    'audio/menu3.mp3',
    'audio/menu.mp3',
  ];

  /// Боевая музыка: трек из пачки ресурсов, луп на весь бой.
  static const String _battleTrack = 'audio/battle_1.mp3';
  int _prevTrackIndex = 0;

  final AudioPlayer _player = AudioPlayer();
  int _trackIndex = 0;
  bool _enabled = true;
  double _volume = 1.0;
  StreamSubscription<void>? _completeSub;

  bool get isMusicEnabled => _enabled;
  double get musicVolume => _volume;

  Source _resolve(String asset) {
    final path = ResourceService.instance.filePath(asset);
    return path != null ? DeviceFileSource(path) : AssetSource(asset);
  }

  Future<void> startLoginMusic() async {
    try {
      await _player
          .play(_resolve('audio/evoria.mp3'))
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  Future<void> switchToGameMusic() async {
    await _completeSub?.cancel();
    _completeSub = _player.onPlayerComplete.listen((_) => _playNextMenuTrack());
    _trackIndex = 0;
    await _playCurrentMenuTrack();
  }

  /// Музыка боя (зацикливается). Запуск — на входе в бой.
  Future<void> startBattleMusic() async {
    try {
      _prevTrackIndex = _trackIndex;
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player
          .play(_resolve(_battleTrack))
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  /// Выход из боя: возвращаемся к обычному списку треков меню.
  Future<void> stopBattleMusic() async {
    try {
      await _player.stop();
    } catch (_) {}
    if (_enabled && _volume > 0) {
      _trackIndex = _prevTrackIndex;
      await _playCurrentMenuTrack();
    }
  }

  Future<void> _playCurrentMenuTrack() async {
    try {
      await _player
          .play(_resolve(_menuTracks[_trackIndex]))
          .timeout(const Duration(seconds: 5));
      await _player.setReleaseMode(ReleaseMode.loop);
    } catch (_) {
      _playNextMenuTrack();
    }
  }

  void _playNextMenuTrack() {
    _trackIndex = (_trackIndex + 1) % _menuTracks.length;
    _playCurrentMenuTrack();
  }

  Future<void> setMusicEnabled(bool enabled) async {
    _enabled = enabled;
    await _player.setVolume(enabled ? _volume : 0.0);
  }

  Future<void> setMusicVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (_enabled) await _player.setVolume(_volume);
  }
}
