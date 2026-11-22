import 'package:flutter/material.dart';

import '../main.dart';

class ModuleWindow extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;

  const ModuleWindow({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
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
                  const EdgeInsets.only(left: 16, right: 8, top: 6, bottom: 2),
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
                        fontSize: 20,
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
      ),
    );
  }
}

class GameCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;

  const GameCard({super.key, required this.child, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF221D18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor ?? kGoldColor.withOpacity(0.35)),
      ),
      child: child,
    );
  }
}
