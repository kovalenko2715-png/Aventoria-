import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../services/player_repository.dart';
import '../services/resource_service.dart';
import '../widgets/game_image.dart';
import '../widgets/module_window.dart';

class LooksScreen extends StatelessWidget {
  const LooksScreen({super.key});

  Future<void> _pick(BuildContext context, String asset) async {
    await PlayerRepository.instance.replaceField('look', asset);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Облик установлен')));
    }
  }

  Future<void> _reset(BuildContext context) async {
    await PlayerRepository.instance.replaceField('look', '');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Облик сброшен')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PlayerRepository.instance,
      builder: (context, _) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('catalog').snapshots(),
      builder: (context, snap0) {
        final catalogLooks = <String>[
          for (final d in (snap0.data?.docs ?? const []))
            if (d.id.startsWith('look_'))
              (d.data()['url']?.toString() ?? ''),
        ]..removeWhere((e) => !e.startsWith('http'));
        final localLooks = ResourceService.instance.listLooks();
        final looks = [...catalogLooks, ...localLooks];
    final current =
        PlayerRepository.instance.data?['look']?.toString() ?? '';
    return ModuleWindow(
      title: 'ОБЛИКИ',
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Выбери картинку облика — она будет стоять вместо куклы в профиле и инвентаре.',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            if (current.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _reset(context),
                  child: const Text('Сбросить облик',
                      style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: looks.isEmpty
                  ? const Center(
                      child: Text(
                          'Пока картинок обликов нет — они появятся с обновлением файлов игры.',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: Colors.white54, fontSize: 13)),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 110,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 0.75),
                      itemCount: looks.length,
                      itemBuilder: (context, i) {
                        final asset = looks[i];
                        final selected = asset == current;
                        return GestureDetector(
                          onTap: () => _pick(context, asset),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: selected
                                      ? kGoldColor
                                      : kGoldColor.withOpacity(0.4),
                                  width: selected ? 2 : 1),
                              borderRadius: BorderRadius.circular(8),
                              color: const Color(0x33221D18),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: GameImage(asset, fit: BoxFit.cover),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
    }
    );
    }
  );
  }
}
