import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Segmented control (UI/UX spec 1.7): 40 pt high (44 pt tap area), radius
/// full, `surface.card` track. The selected segment is `surface.raised`
/// with `text.primary`. Up to 4 segments. Nothing selected is allowed.
class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    required this.semanticPrefix,
  });

  final List<(T, String)> segments;
  final T? selected;
  final ValueChanged<T> onChanged;

  /// Spoken before each segment, for example "Fuel type".
  final String semanticPrefix;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          for (var i = 0; i < segments.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: segments[i].$1 == selected,
                inMutuallyExclusiveGroup: true,
                label: '$semanticPrefix, ${segments[i].$2}, ${l10n.positionOf(i + 1, segments.length)}',
                excludeSemantics: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  onTap: () => onChanged(segments[i].$1),
                  child: AnimatedContainer(
                    duration: AppMotion.quick,
                    constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: segments[i].$1 == selected ? colors.surfaceRaised : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      border: segments[i].$1 == selected ? Border.all(color: colors.borderStrong) : null,
                    ),
                    child: _SegmentLabel(
                      segments[i].$2,
                      style: text.label.copyWith(
                        fontSize: 14,
                        color: segments[i].$1 == selected ? colors.textPrimary : colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A segment's label. Several words may wrap onto two lines; a single
/// word ("Maintenance") never breaks in the middle and shrinks to fit
/// instead.
class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel(this.label, {required this.style});

  final String label;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final text = Text(label, textAlign: TextAlign.center, style: style, maxLines: label.contains(' ') ? null : 1);
    return label.contains(' ') ? text : FittedBox(fit: BoxFit.scaleDown, child: text);
  }
}
