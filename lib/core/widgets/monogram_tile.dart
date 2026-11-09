import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// Circular brand monogram (FR-REF-02, BR-REF-04): 1–2 Latin letters on a
/// neutral graphite tile. Never a logo and never brand colours.
///
/// [dashed] draws the "Other brand" variant. Monograms are decorative: the
/// brand name next to them is what screen readers announce.
class MonogramTile extends StatelessWidget {
  const MonogramTile({super.key, required this.letters, this.size = 40, this.dashed = false});

  const MonogramTile.add({super.key, this.size = 40}) : letters = '+', dashed = true;

  final String letters;
  final double size;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = Text(
      letters,
      style: TextStyle(
        fontFamily: AppFonts.inter,
        fontWeight: FontWeight.w600,
        fontSize: size * (letters.length > 1 ? 0.34 : 0.45),
        letterSpacing: 0.5,
        color: colors.textPrimary,
        height: 1,
      ),
      textDirection: TextDirection.ltr,
    );

    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: dashed
            ? CustomPaint(
                painter: _DashedCirclePainter(color: colors.borderStrong),
                child: Center(child: label),
              )
            : DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.surfaceRaised,
                  border: Border.all(color: colors.borderStrong),
                ),
                child: Center(child: label),
              ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final rect = Offset.zero & size;
    const dashes = 18;
    const sweep = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect.deflate(0.6), i * sweep, sweep * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter oldDelegate) => oldDelegate.color != color;
}
