import 'dart:io';

import 'package:flutter/material.dart';

import '../services/resource_service.dart';

/// Картинка из скачанных ресурсов игры; если их ещё нет — из бандла.
class GameImage extends StatelessWidget {
  final String asset;
  final BoxFit? fit;
  final double? width;
  final double? height;

  const GameImage(
    this.asset, {
    super.key,
    this.fit,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final path = ResourceService.instance.filePath(asset);
    if (path != null) {
      return Image.file(File(path),
          fit: fit, width: width, height: height);
    }
    return Image.asset('assets/$asset',
        fit: fit, width: width, height: height);
  }
}
