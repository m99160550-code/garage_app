import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../application/country_step_controller.dart';
import '../widgets/setup_top_bar.dart';
import 'country_labels.dart';
import 'widgets/analytics_consent_card.dart';
import 'widgets/country_card.dart';
import 'widgets/country_picker_sheet.dart';

/// S-03 Country & analytics consent (UI/UX spec S-03).
///
/// * The country is preselected from the device region and presets
///   currency, distance unit and the Popular brands list.
/// * Where the law requires it, the user must choose Allow or Don't allow
///   before Continue is enabled.
/// * Continue saves both and opens S-04 Brand selection.
class CountryScreen extends ConsumerStatefulWidget {
  const CountryScreen({super.key});

  @override
  ConsumerState<CountryScreen> createState() => _CountryScreenState();
}

class _CountryScreenState extends ConsumerState<CountryScreen> {
  bool _saving = false;

  CountryStepController get _controller => ref.read(countryStepControllerProvider.notifier);

  Future<void> _pickCountry(CountryStepState state) async {
    final choice = await showCountryPicker(context: context, countries: state.countries, selected: state.selected);
    if (choice != null) _controller.selectCountry(choice.country);
  }

  Future<void> _continue() async {
    setState(() => _saving = true);
    try {
      await _controller.submit();
      if (mounted) await context.push(AppRoutes.setupBrand);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(countryStepControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SetupTopBar(step: SetupStepIndicator.country),
            Expanded(
              child: asyncState.when(
                data: (state) => _CountryForm(
                  state: state,
                  onChangeCountry: () => _pickCountry(state),
                  onConsent: (allowed) => _controller.setAnalyticsAllowed(allowed: allowed),
                  onPrivacyPolicy: () => context.push(AppRoutes.privacyPolicy),
                ),
                loading: () => const DelayedSkeleton(),
                error: (error, _) => _LoadError(onRetry: () => ref.invalidate(countryStepControllerProvider)),
              ),
            ),
            if (asyncState.hasValue)
              _BottomBar(canContinue: asyncState.requireValue.canContinue, saving: _saving, onContinue: _continue),
          ],
        ),
      ),
    );
  }
}

class _CountryForm extends StatelessWidget {
  const _CountryForm({
    required this.state,
    required this.onChangeCountry,
    required this.onConsent,
    required this.onPrivacyPolicy,
  });

  final CountryStepState state;
  final VoidCallback onChangeCountry;
  final ValueChanged<bool> onConsent;
  final VoidCallback onPrivacyPolicy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final language = Localizations.localeOf(context).languageCode;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.md,
        AppSpacing.screenMargin,
        AppSpacing.xl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(header: true, child: Text(l10n.countryTitle, style: text.titleL)),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.countryBody, style: text.body.copyWith(color: colors.textSecondary)),
              const SizedBox(height: AppSpacing.xl),
              CountryCard(
                countryName: state.selected?.name(language) ?? l10n.countryNotSet,
                presetsLine: countryPresetsLine(l10n, state.preferences, state.selected),
                onChange: onChangeCountry,
              ),
              if (state.consentRequired) ...[
                const SizedBox(height: AppSpacing.xl),
                AnalyticsConsentCard(
                  allowed: state.analyticsAllowed,
                  onChanged: onConsent,
                  onPrivacyPolicy: onPrivacyPolicy,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Continue, pinned at the bottom. When it's disabled, a short line says
/// why, so the reason isn't conveyed by the dimmed button alone.
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.canContinue, required this.saving, required this.onContinue});

  final bool canContinue;
  final bool saving;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.xs,
        AppSpacing.screenMargin,
        AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!canContinue) ...[
            Text(
              l10n.consentRequiredHint,
              style: context.text.bodyS.copyWith(color: context.colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          AppButton(label: l10n.actionContinue, isLoading: saving, onPressed: canContinue ? onContinue : null),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenMargin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.launchErrorTitle, style: context.text.titleM, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            AppButton.secondary(label: l10n.actionRetry, onPressed: onRetry, expand: false),
          ],
        ),
      ),
    );
  }
}
