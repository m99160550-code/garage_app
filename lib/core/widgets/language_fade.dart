import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// When [language] changes, the app fades in over 250 ms (spec S-26) so the
/// switch, including the mirrored layout, doesn't jump. The subtree is
/// kept, so navigation and form state survive. Respects reduced motion.
class LanguageFade extends StatefulWidget {
  const LanguageFade({super.key, required this.language, required this.child});

  final String language;
  final Widget child;

  @override
  State<LanguageFade> createState() => _LanguageFadeState();
}

class _LanguageFadeState extends State<LanguageFade> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 250), value: 1);

  @override
  void didUpdateWidget(LanguageFade oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.language != widget.language && !MediaQuery.disableAnimationsOf(context)) {
      _controller.forward(from: 0.3);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: CurvedAnimation(parent: _controller, curve: AppMotion.standardCurve),
    child: widget.child,
  );
}
