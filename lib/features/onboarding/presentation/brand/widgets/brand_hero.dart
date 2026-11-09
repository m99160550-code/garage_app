import 'package:flutter/material.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/widgets/chrome_text.dart';
import '../../widgets/setup_top_bar.dart';

/// The top of S-04 (spec S-04 items 1–4): chrome spotlight, top bar,
/// "Select your car brand" prompt and the large chrome "Garage" title.
class BrandHero extends StatelessWidget {
  const BrandHero({super.key, this.onClose, this.showTitle = true});

  /// Set when adding another vehicle: close (×) instead of back and steps.
  final VoidCallback? onClose;

  /// Hidden at the largest text sizes (spec S-04 Accessibility).
  final bool showTitle;

  /// Prompt colour on the brightest part of the spotlight (7.6:1).
  static const promptColor = Color(0xFF3A404A);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = context.text;

    return DecoratedBox(
      decoration: BoxDecoration(gradient: context.colors.chromeSpotlight),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SetupTopBar(step: SetupStepIndicator.brand, onClose: onClose, onLight: true),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              header: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.directions_car_outlined, size: 16, color: promptColor),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      l10n.brandPrompt,
                      style: text.bodyS.copyWith(color: promptColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            if (showTitle) ...[
              const SizedBox(height: AppSpacing.xs),
              // Decorative: the prompt above is the screen's title for
              // screen readers. The soft shadow keeps the chrome letters
              // readable on the light spotlight (spec S-04 item 4).
              ExcludeSemantics(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Stack(
                    children: [
                      Text(
                        l10n.garageTitle,
                        style: text.displayHero.copyWith(
                          color: Colors.transparent,
                          shadows: const [Shadow(color: Color(0x59000000), blurRadius: 12, offset: Offset(0, 2))],
                        ),
                      ),
                      ChromeText(l10n.garageTitle, style: text.displayHero),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
