import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/page_dots.dart';

/// The four steps of first-vehicle setup (UI/UX spec S-03 to S-07).
enum SetupStepIndicator { country, brand, car, service }

/// App bar for the setup flow: back chevron at the start (only when there
/// is somewhere to go back to) and the step dots in the centre.
///
/// When adding another vehicle, pass [onClose]: a close (×) button replaces
/// the back chevron and the step dots are hidden (spec S-04 item 2).
class SetupTopBar extends StatelessWidget {
  const SetupTopBar({super.key, required this.step, this.onClose, this.onLight = false});

  final SetupStepIndicator step;
  final VoidCallback? onClose;

  /// Dark icons and dots for the bright spotlight on S-04.
  final bool onLight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final names = [l10n.stepCountry, l10n.stepBrand, l10n.stepCar, l10n.stepService];
    final canGoBack = GoRouter.of(context).canPop();
    final iconColor = onLight ? colors.textOnLight : colors.textPrimary;
    const side = AppSpacing.minTouchTarget + AppSpacing.xs;

    final Widget? leading = onClose != null
        ? IconButton(
            tooltip: l10n.actionClose,
            icon: Icon(Icons.close, color: iconColor),
            onPressed: onClose,
          )
        : (canGoBack ? BackButton(color: iconColor) : null);

    return SizedBox(
      height: AppSpacing.minTouchTarget + AppSpacing.xs,
      child: Row(
        children: [
          SizedBox(width: side, child: leading),
          Expanded(
            child: Center(
              child: onClose == null
                  ? PageDots(
                      count: names.length,
                      index: step.index,
                      semanticLabel: l10n.stepLabel(step.index + 1, names.length, names[step.index]),
                      activeColor: onLight ? colors.textOnLight : null,
                      inactiveColor: onLight ? const Color(0xFF6B727D) : null,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: side),
        ],
      ),
    );
  }
}
