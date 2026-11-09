import 'package:flutter/material.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/widgets/app_button.dart';

/// Analytics consent (spec S-03, item 4; BR-PRV-01). Shown only where
/// consent is required. Allow and Don't allow look equal, neither is
/// preselected, and one must be chosen before continuing.
class AnalyticsConsentCard extends StatelessWidget {
  const AnalyticsConsentCard({
    super.key,
    required this.allowed,
    required this.onChanged,
    required this.onPrivacyPolicy,
  });

  /// `null` until the user chooses.
  final bool? allowed;
  final ValueChanged<bool> onChanged;
  final VoidCallback onPrivacyPolicy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text(l10n.consentTitle, style: text.titleM)),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.consentBody, style: text.bodyS.copyWith(color: colors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          _ChoiceButton(label: l10n.consentAllow, selected: allowed == true, onTap: () => onChanged(true)),
          const SizedBox(height: AppSpacing.xs),
          _ChoiceButton(label: l10n.consentDeny, selected: allowed == false, onTap: () => onChanged(false)),
          const SizedBox(height: AppSpacing.xxs),
          AppButton.text(label: l10n.privacyPolicy, onPressed: onPrivacyPolicy),
        ],
      ),
    );
  }
}

/// A secondary-style button that behaves like a radio option.
class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(AppRadii.button);

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: AppMotion.quick,
        constraints: const BoxConstraints(minHeight: 52),
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: radius,
          border: Border.all(color: selected ? colors.accentPrimary : colors.borderStrong, width: selected ? 2 : 1),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Icon(
                    selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    size: 22,
                    color: selected ? colors.accentPrimary : colors.textTertiary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(label, style: context.text.button)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
