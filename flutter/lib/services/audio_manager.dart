import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  AudioManager._();
  static final AudioManager instance = AudioManager._();

  final AudioPlayer _musicPlayer = AudioPlayer();
  final List<String> _menuTracks = [
    'audio/menu.mp3',
    'audio/menu2.mp3',
    'audio/menu3.mp3',
    'audio/evoria.mp3',
  ];
  int _trackIndex = 0;
  bool _started = false;

  Future<void> startMenuMusic() async {
    if (_started) return;
    _started = true;
    _musicPlayer.onPlayerComplete.listen((_) => _playNextTrack());
    await _playCurrentTrack();
  }

  Future<void> _playCurrentTrack() async {
    try {
      await _musicPlayer.play(AssetSource(_menuTracks[_trackIndex]));
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    } catch (_) {
      _trackIndex = (_trackIndex + 1) % _menuTracks.length;
    }
  }

  void _playNextTrack() {
    _trackIndex = (_trackIndex + 1) % _menuTracks.length;
    _playCurrentTrack();
  }
}
