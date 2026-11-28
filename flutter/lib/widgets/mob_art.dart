import 'package:flutter/material.dart';

import '../services/resource_service.dart';
import 'game_image.dart';

/// Арт моба из скачанных ресурсов (`images/mobs/<id>.png`);
/// пока ресурсы не скачаны — эмодзи, как раньше.
class MobArt extends StatelessWidget {
  final String id;
  final String emoji;
  final double width;
  final double height;

  const MobArt(this.id, this.emoji,
      {super.key, this.width = 60, this.height = 60});

  @override
  Widget build(BuildContext context) {
    final asset = 'images/mobs/$id.png';
    final path = ResourceService.instance.filePath(asset);
    if (path != null) {
      return GameImage(asset,
          width: width, height: height, fit: BoxFit.contain);
    }
    return SizedBox(
      width: width,
      height: height,
      child: FittedBox(child: Text(emoji)),
    );
  }
}
