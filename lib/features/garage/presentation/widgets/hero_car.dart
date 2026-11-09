import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/vehicle/car_illustration.dart';
import '../../../vehicles/domain/body_type.dart';
import '../../../vehicles/domain/paint_color.dart';

/// The hero car (spec S-09 item 3): the body-type illustration with its
/// reflection on the chrome floor, vertically centred at 45% of the area.
///
/// With [bleed], it's 115% of the width and anchored at the start margin,
/// so it runs off the trailing edge as in the reference (the left edge in
/// Arabic). Otherwise it's [widthFactor] of the width, centred. The
/// illustration itself is never mirrored.
class HeroCar extends StatelessWidget {
  const HeroCar({
    super.key,
    required this.bodyType,
    required this.paint,
    required this.semanticLabel,
    this.bleed = true,
    this.widthFactor = 0.8,
    this.arrival,
  });

  final BodyType bodyType;
  final PaintColor paint;

  /// "Midnight Blue Sedan".
  final String semanticLabel;
  final bool bleed;
  final double widthFactor;

  /// 0 → 1: the car drives in from the right after setup.
  final Animation<double>? arrival;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: context.colors.chromeFloor),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth * (bleed ? 1.15 : widthFactor);
            Widget car = SizedBox(
              width: width,
              child: AnimatedSwitcher(
                duration: AppMotion.standard,
                child: CarIllustration(key: ValueKey((bodyType, paint)), bodyType: bodyType, paint: paint.color),
              ),
            );
            final arrival = this.arrival;
            if (arrival != null) {
              final curved = CurvedAnimation(parent: arrival, curve: AppMotion.emphasisCurve);
              car = FadeTransition(
                opacity: curved,
                child: SlideTransition(
                  // Physical offset: the car faces left, so it drives in
                  // from the right in both languages.
                  position: Tween(begin: const Offset(0.6, 0), end: Offset.zero).animate(curved),
                  transformHitTests: false,
                  child: car,
                ),
              );
            }
            // Bleeding: start margin + car, wider than the area, pinned to
            // the start so the overflow falls off the trailing edge.
            final boxWidth = bleed ? width + AppSpacing.screenMargin : width;
            return ClipRect(
              child: OverflowBox(
                minWidth: boxWidth,
                maxWidth: boxWidth,
                maxHeight: double.infinity,
                alignment: bleed ? const AlignmentDirectional(-1, -0.1) : const Alignment(0, -0.1),
                child: bleed
                    ? Padding(
                        padding: const EdgeInsetsDirectional.only(start: AppSpacing.screenMargin),
                        child: car,
                      )
                    : car,
              ),
            );
          },
        ),
      ),
    );
  }
}
