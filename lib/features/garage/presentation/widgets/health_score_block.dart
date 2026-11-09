import 'package:flutter/material.dart';

import '../../../../core/format/app_formatters.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/chrome_text.dart';
import '../../../maintenance/domain/health_score.dart';

String healthBandLabel(AppLocalizations l10n, HealthBand band) => switch (band) {
  HealthBand.excellent => l10n.bandExcellent,
  HealthBand.good => l10n.bandGood,
  HealthBand.needsAttention => l10n.bandNeedsAttention,
  HealthBand.urgent => l10n.bandUrgent,
};

/// The health score (spec S-09 item 4): chrome digits and "%", the "Health
/// score" label with the band, and "Based on typical intervals · 9 unknown"
/// while items are Unknown (FR-HLT-05). One button that opens S-11.
///
/// [displayedScore] can lag behind [health] during the count-up.
class HealthScoreBlock extends StatelessWidget {
  const HealthScoreBlock({super.key, required this.health, required this.displayedScore, required this.onTap});

  final HealthScore health;
  final int displayedScore;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final band = health.band;
    final bandColor = switch (band) {
      HealthBand.excellent || HealthBand.good => colors.success,
      HealthBand.needsAttention => colors.warning,
      HealthBand.urgent => colors.danger,
    };
    // Digits are capped at 1.3× with large text; the label block then
    // moves under them (spec S-09 "Responsive").
    final scaler = MediaQuery.textScalerOf(context);
    final largeText = scaler.scale(16) > 16 * 1.3;

    final digits = MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: scaler.clamp(maxScaleFactor: 1.3)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChromeText(
            AppFormatters(languageCode: Localizations.localeOf(context).languageCode).integer(displayedScore),
            style: AppTextStyles.tabular(text.displayScore),
            decorative: true,
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: ChromeText('%', style: text.titleL, decorative: true),
          ),
        ],
      ),
    );
    final labels = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.healthScoreLabel, style: text.bodyS.copyWith(color: colors.textSecondary)),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: bandColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Flexible(child: Text(healthBandLabel(l10n, band), style: text.label)),
          ],
        ),
      ],
    );

    return Semantics(
      button: true,
      label: [
        l10n.healthSemantic(health.score, healthBandLabel(l10n, band)),
        if (health.basedOnTypicalIntervals) l10n.healthBasedOnTypical(health.unknownCount),
      ].join(', '),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.row),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (largeText) ...[
                digits,
                labels,
              ] else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    digits,
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(child: labels),
                  ],
                ),
              if (health.basedOnTypicalIntervals)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 14, color: colors.textTertiary),
                    const SizedBox(width: AppSpacing.xxs),
                    Flexible(
                      child: Text(
                        l10n.healthBasedOnTypical(health.unknownCount),
                        style: text.caption.copyWith(color: colors.textTertiary),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
