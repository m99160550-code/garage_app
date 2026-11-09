import 'package:flutter/material.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/widgets/app_choice_chip.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../../../core/widgets/dashed_border.dart';
import '../../../../../core/widgets/vehicle/car_illustration.dart';
import '../../../../vehicles/domain/body_type.dart';
import '../../../../vehicles/domain/paint_color.dart';
import '../../../../vehicles/presentation/vehicle_labels.dart';
import 'model_card.dart';

/// "Other model" (spec S-05 item 4): a dashed card that opens to a "Model
/// name" field and a required body-type choice.
class OtherModelCard extends StatefulWidget {
  const OtherModelCard({
    super.key,
    required this.expanded,
    required this.name,
    required this.bodyType,
    required this.onToggle,
    required this.onNameChanged,
    required this.onBodyType,
    this.hint,
  });

  final bool expanded;
  final String name;
  final BodyType? bodyType;

  /// `null` when the card can't be closed (no models to pick instead).
  final VoidCallback? onToggle;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<BodyType> onBodyType;

  /// For example "Model list for this brand is coming soon."
  final String? hint;

  @override
  State<OtherModelCard> createState() => _OtherModelCardState();
}

class _OtherModelCardState extends State<OtherModelCard> {
  late final _controller = TextEditingController(text: widget.name);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final radius = BorderRadius.circular(AppRadii.card);

    final header = Row(
      children: [
        Container(
          width: 120,
          height: 64,
          alignment: Alignment.center,
          // Contrasts with the card in both states (the open card is
          // `surface.raised` too), so the tile never disappears.
          decoration: BoxDecoration(
            color: widget.expanded ? colors.surfaceCard : colors.surfaceRaised,
            borderRadius: BorderRadius.circular(AppRadii.input),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Icon(Icons.add, color: colors.textSecondary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.modelOther, style: text.titleM),
              const SizedBox(height: 2),
              Text(l10n.modelOtherHint, style: text.bodyS.copyWith(color: colors.textSecondary)),
            ],
          ),
        ),
        if (widget.onToggle != null) ...[
          const SizedBox(width: AppSpacing.xs),
          RadioIndicator(selected: widget.expanded),
        ],
      ],
    );

    return DashedBorder(
      color: widget.expanded ? colors.accentPrimary : colors.borderStrong,
      radius: AppRadii.card,
      strokeWidth: widget.expanded ? 1.5 : 1.2,
      child: AnimatedContainer(
        duration: AppMotion.standard,
        decoration: BoxDecoration(
          color: widget.expanded ? colors.surfaceRaised : colors.surfaceCard,
          borderRadius: radius,
        ),
        child: AnimatedSize(
          duration: AppMotion.standard,
          curve: AppMotion.standardCurve,
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  button: widget.onToggle != null,
                  selected: widget.expanded,
                  inMutuallyExclusiveGroup: true,
                  label: '${l10n.modelOther}, ${l10n.modelOtherHint}',
                  excludeSemantics: true,
                  child: InkWell(
                    borderRadius: radius,
                    onTap: widget.onToggle,
                    child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 72), child: header),
                  ),
                ),
                if (widget.hint != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Semantics(
                    liveRegion: true,
                    child: Text(widget.hint!, style: text.bodyS.copyWith(color: colors.onInfoContainer)),
                  ),
                ],
                if (widget.expanded) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    controller: _controller,
                    label: l10n.modelNameLabel,
                    maxLength: 60,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    onChanged: widget.onNameChanged,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Semantics(header: true, child: Text(l10n.bodyTypeLabel, style: text.label)),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(l10n.bodyTypeHelper, style: text.caption.copyWith(color: colors.textTertiary)),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      for (final type in BodyType.values)
                        AppChoiceChip(
                          label: bodyTypeLabel(l10n, type),
                          selected: widget.bodyType == type,
                          onTap: () => widget.onBodyType(type),
                          leading: SizedBox(
                            width: 30,
                            child: CarIllustration(
                              bodyType: type,
                              paint: widget.bodyType == type ? colors.textOnLight : PaintColor.silver.color,
                              showReflection: false,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
