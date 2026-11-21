import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../services/audio_manager.dart';
import '../services/player_repository.dart';
import '../widgets/module_window.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _musicEnabled = AudioManager.instance.isMusicEnabled;
  double _volume = AudioManager.instance.musicVolume * 100;
  String _fontSize = 'medium';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fontSize = PlayerRepository.instance.data?['settings_chat_font']
            ?.toString() ??
        'medium';
    setState(() => _loading = false);
  }

  Future<void> _toggleMusic() async {
    setState(() => _musicEnabled = !_musicEnabled);
    await AudioManager.instance.setMusicEnabled(_musicEnabled);
  }

  Future<void> _changeVolume(double value) async {
    setState(() => _volume = value);
    await AudioManager.instance.setMusicVolume(value / 100);
  }

  Future<void> _setFont(String size) async {
    setState(() => _fontSize = size);
    await PlayerRepository.instance.replaceField('settings_chat_font', size);
  }

  Future<void> _changePassword() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null || email.isEmpty) return;
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Письмо для смены пароля отправлено на $email')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ModuleWindow(
          title: '⚙️ Настройки', child: Center(child: CircularProgressIndicator()));
    }
    return ModuleWindow(
      title: '⚙️ Настройки',
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          GameCard(
            child: Row(
              children: [
                const Expanded(
                  child: Text('Музыка',
                      style: TextStyle(color: Colors.white, fontSize: 15)),
                ),
                TextButton(
                    onPressed: _toggleMusic,
                    child: Text(_musicEnabled ? 'Вкл' : 'Выкл',
                        style: TextStyle(
                            color: _musicEnabled
                                ? const Color(0xFF80FF80)
                                : const Color(0xFFFF4545),
                            fontSize: 14))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GameCard(
            child: Row(
              children: [
                const Text('Громкость',
                    style: TextStyle(color: Colors.white, fontSize: 15)),
                Expanded(
                  child: Slider(
                    value: _volume,
                    min: 0,
                    max: 100,
                    divisions: 10,
                    label: '${_volume.round()}',
                    activeColor: kGoldColor,
                    onChanged: _changeVolume,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GameCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Размер шрифта чата',
                    style: TextStyle(color: Colors.white, fontSize: 15)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (final (label, value) in [
                      ('Мелкий', 'small'),
                      ('Средний', 'medium'),
                      ('Крупный', 'large'),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: _fontSize == value
                                    ? kGoldColor
                                    : Colors.white24),
                          ),
                          onPressed: () => _setFont(value),
                          child: Text(label,
                              style: TextStyle(
                                  color: _fontSize == value
                                      ? kGoldColor
                                      : Colors.white70,
                                  fontSize: 13)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GameCard(
            child: Row(
              children: [
                const Expanded(
                  child: Text('Сменить пароль',
                      style: TextStyle(color: Colors.white, fontSize: 15)),
                ),
                TextButton(
                    onPressed: _changePassword,
                    child: const Text('Отправить письмо',
                        style: TextStyle(color: kGoldColor, fontSize: 13))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
