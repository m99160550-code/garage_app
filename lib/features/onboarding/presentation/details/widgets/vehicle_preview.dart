import 'package:flutter/material.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/widgets/vehicle/car_illustration.dart';
import '../../../../vehicles/domain/body_type.dart';
import '../../../../vehicles/domain/paint_color.dart';
import '../../../../vehicles/presentation/vehicle_labels.dart';

/// Live preview of the car (spec S-06 item 2): the body-type illustration
/// in the chosen paint colour, with the reflective floor. Changes
/// cross-fade over 250 ms.
class VehiclePreview extends StatelessWidget {
  const VehiclePreview({super.key, required this.bodyType, required this.paint});

  final BodyType bodyType;
  final PaintColor paint;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(gradient: context.colors.chromeFloor),
      child: Semantics(
        image: true,
        label: '${paintColorLabel(l10n, paint)} ${bodyTypeLabel(l10n, bodyType)}',
        excludeSemantics: true,
        child: Center(
          child: AnimatedSwitcher(
            duration: AppMotion.standard,
            child: FittedBox(
              key: ValueKey((bodyType, paint)),
              child: SizedBox(
                width: 360,
                child: CarIllustration(bodyType: bodyType, paint: paint.color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pinned preview that shrinks from [maxExtent] to [minExtent] as the form
/// scrolls (spec S-06: 180 pt, shrinking to 96 pt and staying pinned).
class VehiclePreviewHeader extends SliverPersistentHeaderDelegate {
  VehiclePreviewHeader({
    required this.bodyType,
    required this.paint,
    required this.minExtent,
    required this.maxExtent,
    required this.background,
  });

  final BodyType bodyType;
  final PaintColor paint;
  final Color background;

  @override
  final double minExtent;

  @override
  final double maxExtent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(
      color: background,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xs),
        child: VehiclePreview(bodyType: bodyType, paint: paint),
      ),
    );
  }

  @override
  bool shouldRebuild(VehiclePreviewHeader old) =>
      old.bodyType != bodyType || old.paint != paint || old.minExtent != minExtent || old.maxExtent != maxExtent;
}
