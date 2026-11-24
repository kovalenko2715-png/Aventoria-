import 'package:flutter/material.dart';

import '../main.dart';

class ModuleWindow extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final double? maxWidth;

  const ModuleWindow({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0) * 0.85),
        ),
        child: maxWidth == null
            ? _window(context)
            : Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth!),
                  child: _window(context),
                ),
              ),
      ),
    );
  }

  Widget _window(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          color: const Color(0xFA141110),
          border: Border.all(color: kGoldColor.withOpacity(0.6), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kGoldColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (actions != null) ...actions!,
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
    );
  }
}

/// Открыть экран как плавающее окно поверх текущего (стек окон, как в БК):
/// затемняет предыдущее окно, само закрывается крестиком.
Future<void> pushModuleWindow(BuildContext context, Widget screen) async {
  await Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black.withOpacity(0.45),
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (_, __, ___) => Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 78, 14, 62),
            child: Align(
              alignment: Alignment.topCenter,
              child: screen,
            ),
          ),
        ),
      ),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.93, end: 1.0).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      ),
    ),
  );
}

class GameCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;

  const GameCard({super.key, required this.child, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFF221D18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor ?? kGoldColor.withOpacity(0.35)),
      ),
      child: child,
    );
  }
}
