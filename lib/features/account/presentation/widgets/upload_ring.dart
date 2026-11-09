import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';

/// The 120 pt upload ring with the percentage inside (spec S-29 step 2).
/// [paused] greys it while waiting for a connection. The ring animates
/// between values unless the system asks for reduced motion.
class UploadRing extends StatelessWidget {
  const UploadRing({super.key, required this.progress, required this.label, this.paused = false});

  final double progress;
  final String label;
  final bool paused;

  static const size = 120.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: label,
      child: Center(
        child: SizedBox.square(
          dimension: size,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: progress),
            duration: reduce ? Duration.zero : AppMotion.standard,
            builder: (context, value, _) => Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: value,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  backgroundColor: colors.surfaceRaised,
                  color: paused ? colors.textTertiary : colors.accentPrimary,
                ),
                Center(
                  child: ExcludeSemantics(child: Text(label, style: context.text.displayStat)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The success check: a green disc that scales in (spec S-29 "check
/// animation"); shown at once with reduced motion.
class UploadCheck extends StatelessWidget {
  const UploadCheck({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return ExcludeSemantics(
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: reduce ? 1 : 0, end: 1),
          duration: AppMotion.emphasis,
          curve: Curves.easeOutBack,
          builder: (context, value, child) => Transform.scale(scale: value, child: child),
          child: Container(
            width: UploadRing.size,
            height: UploadRing.size,
            decoration: BoxDecoration(shape: BoxShape.circle, color: colors.successContainer),
            child: Icon(Icons.check_rounded, size: 64, color: colors.success),
          ),
        ),
      ),
    );
  }
}
