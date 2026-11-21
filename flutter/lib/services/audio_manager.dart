import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  AudioManager._();
  static final AudioManager instance = AudioManager._();

  final AudioPlayer _player = AudioPlayer();

  static const List<String> _menuTracks = [
    'audio/menu1.mp3',
    'audio/menu2.mp3',
    'audio/menu.mp3',
  ];
  int _trackIndex = 0;

  Future<void> startLoginMusic() async {
    try {
      await _player.play(AssetSource('audio/evoria.mp3'));
    } catch (_) {}
  }

  Future<void> switchToGameMusic() async {
    await _player.stop();
    _trackIndex = 0;
    await _playCurrentMenuTrack();
    _player.onPlayerComplete.listen((_) => _playNextMenuTrack());
  }

  Future<void> _playCurrentMenuTrack() async {
    try {
      await _player.play(AssetSource(_menuTracks[_trackIndex]));
      await _player.setReleaseMode(ReleaseMode.loop);
    } catch (_) {
      _playNextMenuTrack();
    }
  }

  void _playNextMenuTrack() {
    _trackIndex = (_trackIndex + 1) % _menuTracks.length;
    _playCurrentMenuTrack();
  }
}
