import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Повторяет stretch-режим Godot: канва спроектирована под 1280x720,
/// режим "canvas_items" с аспектом "expand".
/// Всё приложение рисуется в этих координатах и масштабируется на экран,
/// поэтому интерфейс выглядит так же мелко, как в оригинале.
class GodotViewport extends StatelessWidget {
  final Widget child;

  const GodotViewport({super.key, required this.child});

  static const designWidth = 1280.0;
  static const designHeight = 720.0;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final scale = math.max(
      mq.size.width / designWidth,
      mq.size.height / designHeight,
    );
    final vw = mq.size.width / scale;
    final vh = mq.size.height / scale;
    return FittedBox(
      fit: BoxFit.fill,
      child: SizedBox(
        width: vw,
        height: vh,
        child: MediaQuery(
          data: mq.copyWith(
            size: Size(vw, vh),
            padding: mq.padding / scale,
            viewInsets: mq.viewInsets / scale,
            viewPadding: mq.viewPadding / scale,
          ),
          child: child,
        ),
      ),
    );
  }
}
