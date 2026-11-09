import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/alert_pill.dart';

/// A bell over the dashboard alert pill, 96 pt (spec S-08 item 1).
/// Decorative: the title and body say the same thing.
class PrimerIllustration extends StatelessWidget {
  const PrimerIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ExcludeSemantics(
      child: SizedBox(
        height: 96,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              bottom: 0,
              child: AlertPill(label: AppLocalizations.of(context).primerPillExample, tone: AlertPillTone.warning),
            ),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.surfaceRaised,
                border: Border.all(color: colors.borderStrong),
                boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 20, offset: Offset(0, 8))],
              ),
              child: Icon(Icons.notifications_active_outlined, size: 30, color: colors.textPrimary),
            ),
            // The "new" dot on the bell. Illustrations are never mirrored.
            Positioned(
              top: 6,
              child: Transform.translate(
                offset: const Offset(18, 0),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.accentPrimary,
                    border: Border.all(color: colors.bgSheet, width: 2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
