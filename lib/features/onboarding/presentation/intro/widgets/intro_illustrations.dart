import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/format/app_formatters.dart';
import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/widgets/chrome_text.dart';
import '../../../../../core/widgets/stat_card.dart';
import '../../../../../core/widgets/vehicle/car_illustration.dart';
import '../../../../vehicles/domain/body_type.dart';
import '../../../../vehicles/domain/paint_color.dart';

/// Decorative illustrations for the three intro pages (UI/UX spec S-02).
/// They repeat what the page text says, so they're hidden from screen
/// readers. Each one scales down to fit its area.

/// Page 1: car with a health score of 89.
class IntroScoreIllustration extends StatelessWidget {
  const IntroScoreIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;

    return ExcludeSemantics(
      child: _Floor(
        child: FittedBox(
          child: SizedBox(
            width: 360,
            height: 300,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned(
                  left: 0,
                  right: 0,
                  top: 40,
                  child: CarIllustration(bodyType: BodyType.sedan, paint: Color(0xFFAEB4BC)),
                ),
                PositionedDirectional(
                  start: 8,
                  bottom: 8,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ChromeText('89', style: text.displayScore.copyWith(fontSize: 72, height: 1)),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 4, end: 12, bottom: 28),
                        child: Text('%', style: text.titleL.copyWith(color: colors.textSecondary)),
                      ),
                      Column(
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
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4FC3A1), // band.good
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(l10n.healthBandGood, style: text.label),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Page 2: the three dashboard stat cards, fanned out.
class IntroStatCardsIllustration extends StatelessWidget {
  const IntroStatCardsIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = AppFormatters(languageCode: Localizations.localeOf(context).languageCode);

    Widget fanned(double degrees, double dx, double dy, Widget card) => Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.rotate(angle: degrees * math.pi / 180, child: card),
    );

    return ExcludeSemantics(
      child: _Floor(
        child: FittedBox(
          child: SizedBox(
            width: 440,
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                fanned(
                  -10,
                  -134,
                  18,
                  StatCard(
                    label: l10n.statMileage,
                    sublabel: l10n.statMileageSub,
                    value: format.formatOdometer(54320),
                    unit: l10n.unitKm,
                  ),
                ),
                fanned(
                  10,
                  134,
                  18,
                  StatCard(
                    label: l10n.statThisYear,
                    sublabel: l10n.statThisYearSub,
                    value: format.moneyWhole(420, 'SAR'),
                  ),
                ),
                StatCard(
                  label: l10n.statNextService,
                  sublabel: l10n.statNextServiceSub,
                  value: format.integer(38),
                  focused: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Page 3: a phone with the garage on it, a cloud and a lock.
class IntroPrivateIllustration extends StatelessWidget {
  const IntroPrivateIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    Widget badge(IconData icon, Color fill, Color iconColor) => Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: colors.borderStrong),
        boxShadow: const [BoxShadow(color: Color(0x73000000), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: Icon(icon, size: 30, color: iconColor),
    );

    return ExcludeSemantics(
      child: _Floor(
        child: FittedBox(
          child: SizedBox(
            width: 320,
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Phone frame with a small car on screen.
                Container(
                  width: 150,
                  height: 280,
                  decoration: BoxDecoration(
                    color: colors.surfaceCard,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: colors.borderStrong, width: 2),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 40, 14, 20),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 6,
                        decoration: BoxDecoration(
                          color: colors.borderStrong,
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                      ),
                      const Spacer(),
                      CarIllustration(
                        bodyType: BodyType.sedan,
                        paint: PaintColor.midnightBlue.color,
                        showReflection: false,
                      ),
                      const Spacer(flex: 2),
                    ],
                  ),
                ),
                PositionedDirectional(
                  top: 24,
                  end: 8,
                  child: badge(Icons.cloud_done_outlined, colors.infoContainer, colors.onInfoContainer),
                ),
                PositionedDirectional(
                  bottom: 40,
                  start: 8,
                  child: badge(Icons.lock_outline, colors.surfaceRaised, colors.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The soft floor glow behind each illustration (`chrome.floor`).
class _Floor extends StatelessWidget {
  const _Floor({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: context.colors.chromeFloor),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin, vertical: AppSpacing.md),
        child: Center(child: child),
      ),
    );
  }
}
