import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/widgets/vehicle/car_illustration.dart';
import '../../../../reference/domain/vehicle_model.dart';
import '../../../../vehicles/domain/body_type.dart';
import '../../../../vehicles/domain/paint_color.dart';
import '../../../../vehicles/presentation/vehicle_labels.dart';

/// A model card (spec S-05 item 3): body-type thumbnail, model name, body
/// type and usual fuel, and a radio indicator. Selected cards are raised
/// with a 1.5 pt Signal Blue border.
class ModelCard extends StatelessWidget {
  const ModelCard({super.key, required this.model, required this.selected, required this.onTap});

  final VehicleModel model;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final language = Localizations.localeOf(context).languageCode;
    final radius = BorderRadius.circular(AppRadii.card);

    final details = [
      bodyTypeLabel(l10n, model.bodyType),
      if (model.defaultFuelType case final fuel?) usualFuelLabel(l10n, fuel),
    ].join(' · ');

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: '${model.name(language)}, $details',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: AppMotion.standard,
        decoration: BoxDecoration(
          color: selected ? colors.surfaceRaised : colors.surfaceCard,
          borderRadius: radius,
          border: Border.all(color: selected ? colors.accentPrimary : colors.borderSubtle, width: selected ? 1.5 : 1),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 96),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    BodyTypeThumbnail(bodyType: model.bodyType),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(model.name(language), style: text.titleM),
                          const SizedBox(height: 2),
                          Text(details, style: text.bodyS.copyWith(color: colors.textSecondary)),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    RadioIndicator(selected: selected),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 120 × 64 pt body-type thumbnail in silver on a small floor glow.
class BodyTypeThumbnail extends StatelessWidget {
  const BodyTypeThumbnail({super.key, required this.bodyType, this.width = 120});

  final BodyType bodyType;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * 64 / 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: context.colors.chromeFloor,
        borderRadius: BorderRadius.circular(AppRadii.input),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: CarIllustration(bodyType: bodyType, paint: PaintColor.silver.color, showReflection: false),
    );
  }
}

/// 24 pt radio ring, filled with a check when selected (spec S-05 item 3).
class RadioIndicator extends StatelessWidget {
  const RadioIndicator({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedContainer(
      duration: AppMotion.quick,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? colors.accentPrimary : Colors.transparent,
        border: Border.all(color: selected ? colors.accentPrimary : colors.borderStrong, width: 2),
      ),
      child: selected ? Icon(Icons.check, size: 16, color: colors.textOnLight) : null,
    );
  }
}
