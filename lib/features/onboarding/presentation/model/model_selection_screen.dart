import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/layout/window_class.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/monogram_tile.dart';
import '../../application/model_selection_controller.dart';
import '../widgets/setup_top_bar.dart';
import 'widgets/model_card.dart';
import 'widgets/other_model_card.dart';

/// S-05 Model selection (UI/UX spec S-05).
///
/// Shows the chosen brand's 3–4 models as cards with body-type thumbnails,
/// plus "Other model" (name + body type). Brands without models, and brands
/// typed under "Other brand", go straight to "Other model".
/// Continue saves the model and body type and opens S-06 Vehicle details.
class ModelSelectionScreen extends ConsumerStatefulWidget {
  const ModelSelectionScreen({super.key, this.addingVehicle = false, this.editing = false});

  final bool addingVehicle;

  /// Opened from S-32 Edit vehicle: Continue saves the model and returns.
  final bool editing;

  @override
  ConsumerState<ModelSelectionScreen> createState() => _ModelSelectionScreenState();
}

class _ModelSelectionScreenState extends ConsumerState<ModelSelectionScreen> {
  bool _saving = false;

  ModelSelectionController get _controller => ref.read(modelSelectionControllerProvider.notifier);

  Future<void> _continue() async {
    setState(() => _saving = true);
    try {
      await _controller.submit(addingVehicle: widget.addingVehicle || widget.editing);
      if (!mounted) return;
      if (widget.editing) {
        context.pop();
        return;
      }
      await context.push(widget.addingVehicle ? '${AppRoutes.setupDetails}?add=1' : AppRoutes.setupDetails);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(modelSelectionControllerProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SetupTopBar(step: SetupStepIndicator.brand),
            Expanded(
              child: asyncState.when(
                loading: () => const DelayedSkeleton(),
                error: (_, _) => Center(
                  child: AppButton.secondary(
                    label: l10n.actionRetry,
                    onPressed: () => ref.invalidate(modelSelectionControllerProvider),
                    expand: false,
                  ),
                ),
                data: (state) =>
                    state.hasBrand ? _ModelList(state: state, controller: _controller) : const _NeedBrand(),
              ),
            ),
            if (asyncState.value case final state? when state.hasBrand)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenMargin,
                  AppSpacing.xs,
                  AppSpacing.screenMargin,
                  AppSpacing.md,
                ),
                child: AppButton(
                  label: l10n.actionContinue,
                  isLoading: _saving,
                  onPressed: state.canContinue ? _continue : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ModelList extends StatelessWidget {
  const _ModelList({required this.state, required this.controller});

  final ModelSelectionState state;
  final ModelSelectionController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final language = Localizations.localeOf(context).languageCode;
    final columns = WindowClass.of(context).isCompact ? 1 : 2;
    final brandName = state.brand?.name(language) ?? state.brandOtherName ?? '';

    final cards = [
      for (final model in state.models)
        ModelCard(model: model, selected: state.selectedModel == model, onTap: () => controller.selectModel(model)),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.xl,
        AppSpacing.screenMargin,
        AppSpacing.xl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: the chosen brand (spec S-05 item 2).
              Center(child: MonogramTile(letters: state.monogram, size: 56)),
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                header: true,
                child: Text(brandName, style: text.headline, textAlign: TextAlign.center),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                l10n.modelSubtitle,
                style: text.bodyS.copyWith(color: colors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              for (var i = 0; i < cards.length; i += columns) ...[
                if (columns == 1)
                  cards[i]
                else
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: cards[i]),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: i + 1 < cards.length ? cards[i + 1] : const SizedBox()),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
              ],
              // "Other model" spans both columns on tablets.
              OtherModelCard(
                expanded: state.otherSelected,
                name: state.otherName,
                bodyType: state.otherBodyType,
                onToggle: state.models.isEmpty ? null : controller.toggleOther,
                onNameChanged: controller.setOtherName,
                onBodyType: controller.setOtherBodyType,
                hint: state.noModelsReason == NoModelsReason.comingSoon ? l10n.modelsComingSoon : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Setup resumed here but the brand is missing: send the user back to it.
class _NeedBrand extends StatelessWidget {
  const _NeedBrand();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenMargin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_car_outlined, size: 48, color: context.colors.textTertiary),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.modelNeedBrandTitle, style: context.text.titleM, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              l10n.modelNeedBrandBody,
              style: context.text.bodyS.copyWith(color: context.colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: l10n.modelNeedBrandAction,
              expand: false,
              onPressed: () => context.go(AppRoutes.setupBrand),
            ),
          ],
        ),
      ),
    );
  }
}
