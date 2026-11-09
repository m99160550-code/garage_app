import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/status_badge.dart';

enum ScoreRowTone { danger, warning, info }

/// One row on S-11 (spec S-11 item 3): a status icon in a 40 pt tile, the
/// item name and reason, the points ("−5", with "×2" when doubled) and a
/// chevron to the item (S-15). Rows under "Not counted" have no points.
class ScoreRow extends StatelessWidget {
  const ScoreRow({
    super.key,
    required this.tone,
    required this.title,
    required this.reason,
    required this.semanticLabel,
    required this.onTap,
    this.points,
    this.doubled = false,
  });

  final ScoreRowTone tone;
  final String title;
  final String reason;

  /// Negative, or `null` for items that don't count.
  final int? points;
  final bool doubled;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final (container, onContainer, solid, icon) = switch (tone) {
      ScoreRowTone.danger => (colors.dangerContainer, colors.onDangerContainer, colors.danger, Icons.error_outline),
      ScoreRowTone.warning => (colors.warningContainer, colors.onWarningContainer, colors.warning, Icons.schedule),
      ScoreRowTone.info => (colors.infoContainer, colors.onInfoContainer, colors.info, Icons.help_outline),
    };

    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: colors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.row),
          side: BorderSide(color: colors.borderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.md, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: container, borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, size: 22, color: onContainer),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, style: text.titleM),
                        Text(reason, style: text.bodyS.copyWith(color: colors.textSecondary)),
                      ],
                    ),
                  ),
                  if (points != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    if (doubled) ...[
                      StatusBadge(label: l10n.healthDoubleBadge, tone: BadgeTone.danger),
                      const SizedBox(width: AppSpacing.xxs),
                    ],
                    // Numbers read left to right in Arabic too ("−2", not "2−").
                    Text(
                      '−${points!.abs()}',
                      textDirection: TextDirection.ltr,
                      style: AppTextStyles.tabular(text.titleM).copyWith(color: solid),
                    ),
                  ],
                  Icon(Icons.chevron_right, color: colors.textTertiary, textDirection: Directionality.of(context)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
