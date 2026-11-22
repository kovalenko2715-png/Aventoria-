import 'package:flutter/material.dart';

import '../main.dart';
import '../services/player_repository.dart';

Future<void> showNicknameDialog(BuildContext context) async {
  final controller = TextEditingController();
  String? error;
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDlg) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        title: const Text('Придумайте ник персонажа',
            style: TextStyle(
                color: kGoldColor,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Без ника нельзя писать в чат. Он должен быть уникальным.',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLength: 16,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Ник (3–16 символов)',
                hintStyle:
                    const TextStyle(color: Colors.white38, fontSize: 12),
                errorText: error,
                errorStyle:
                    const TextStyle(color: Color(0xFFFF4545), fontSize: 11),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final nick = controller.text.trim();
              final ok =
                  await PlayerRepository.instance.claimNickname(nick);
              if (!ctx.mounted) return;
              if (!ok) {
                setDlg(() => error = (nick.trim().length < 3
                    ? 'Минимум 3 символа'
                    : 'Этот ник уже занят'));
                return;
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child:
                const Text('Сохранить', style: TextStyle(color: kGoldColor)),
          ),
        ],
      ),
    ),
  );
}
