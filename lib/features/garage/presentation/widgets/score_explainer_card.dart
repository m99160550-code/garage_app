import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_button.dart';

/// "How the score works" (spec S-11 item 5): collapsed by default, it
/// explains the weights and names the template the intervals come from.
class ScoreExplainerCard extends StatefulWidget {
  const ScoreExplainerCard({super.key, required this.templateLine, required this.onSeeSchedule});

  /// "Typical intervals for Hybrid · template v3".
  final String templateLine;
  final VoidCallback onSeeSchedule;

  @override
  State<ScoreExplainerCard> createState() => _ScoreExplainerCardState();
}

class _ScoreExplainerCardState extends State<ScoreExplainerCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;

    return Material(
      color: colors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: BorderSide(color: colors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _open,
            label: l10n.healthHowTitle,
            excludeSemantics: true,
            child: InkWell(
              onTap: () => setState(() => _open = !_open),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: colors.textSecondary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(l10n.healthHowTitle, style: text.titleM)),
                      AnimatedRotation(
                        turns: _open ? 0.5 : 0,
                        duration: AppMotion.standard,
                        child: Icon(Icons.expand_more, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: AppMotion.standard,
            curve: AppMotion.standardCurve,
            alignment: Alignment.topCenter,
            child: !_open
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.healthHowBody, style: text.bodyS.copyWith(color: colors.textSecondary)),
                        const SizedBox(height: AppSpacing.sm),
                        Text(widget.templateLine, style: text.caption.copyWith(color: colors.textTertiary)),
                        AppButton.text(label: l10n.healthSeeSchedule, onPressed: widget.onSeeSchedule),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
