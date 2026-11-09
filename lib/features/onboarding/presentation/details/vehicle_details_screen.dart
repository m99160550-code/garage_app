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
import '../../../privacy/application/consent_providers.dart';
import '../../../vehicles/domain/vehicle_validation.dart';
import '../../application/vehicle_details_controller.dart';
import '../widgets/setup_top_bar.dart';
import '../../../vehicles/presentation/vehicle_form.dart';
import 'widgets/vehicle_preview.dart';

/// S-06 Vehicle details (UI/UX spec S-06).
///
/// Required: fuel type and current odometer. Appearance: paint colour and
/// body type, shown live in the preview. Optional "More details": nickname,
/// year, licence plate, VIN and purchase date.
/// Continue checks the VIN, warns about a duplicate VIN in the garage, saves
/// the answers and opens S-07 Service baseline.
class VehicleDetailsScreen extends ConsumerStatefulWidget {
  const VehicleDetailsScreen({super.key, this.addingVehicle = false});

  final bool addingVehicle;

  @override
  ConsumerState<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends ConsumerState<VehicleDetailsScreen> {
  final _form = VehicleFormController();
  bool _initialised = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Fill the form once, when the setup data arrives.
    ref.listenManual(vehicleDetailsControllerProvider, (_, next) {
      final setup = next.value;
      if (!_initialised && setup != null) _initialiseFrom(setup);
    }, fireImmediately: true);
    _form.addListener(() => setState(() {}));
  }

  void _initialiseFrom(VehicleDetailsSetup setup) {
    _initialised = true;
    final existing = setup.existing;
    if (existing == null) {
      _form
        ..body = setup.bodyType
        ..fuel = setup.suggestedFuel;
      return;
    }
    _form.fill(existing, setup.unit);
    _form.body = setup.bodyType;
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _continue(VehicleDetailsSetup setup) async {
    final l10n = AppLocalizations.of(context);
    final vin = _form.vin.text.trim();

    if (checkVin(vin) == VinIssue.invalidCharacters) {
      _form.focusVin();
      return;
    }

    // Duplicate VIN in this garage (BR-VEH-03): warn, let the user decide.
    if (setup.duplicateOf(vin) case final other?) {
      final addAnyway = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.duplicateVinTitle),
          content: Text(l10n.duplicateVinBody(other.nickname ?? l10n.duplicateVinUnnamed)),
          actions: [
            AppButton.text(label: l10n.duplicateVinChange, onPressed: () => Navigator.pop(context, false)),
            AppButton.text(label: l10n.duplicateVinAdd, onPressed: () => Navigator.pop(context, true)),
          ],
        ),
      );
      if (addAnyway != true) {
        _form.focusVin();
        return;
      }
    }

    final details = _form.toDetails(setup.unit);
    setState(() => _saving = true);
    try {
      await ref.read(vehicleDetailsControllerProvider.notifier).save(details, addingVehicle: widget.addingVehicle);
      if (!mounted) return;
      await context.push(widget.addingVehicle ? '${AppRoutes.setupBaseline}?add=1' : AppRoutes.setupBaseline);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncSetup = ref.watch(vehicleDetailsControllerProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SetupTopBar(step: SetupStepIndicator.car),
            Expanded(
              child: asyncSetup.when(
                loading: () => const DelayedSkeleton(),
                error: (_, _) => Center(
                  child: AppButton.secondary(
                    label: l10n.actionRetry,
                    onPressed: () => ref.invalidate(vehicleDetailsControllerProvider),
                    expand: false,
                  ),
                ),
                data: (setup) => setup.hasModel ? _layout(setup) : const _NeedModel(),
              ),
            ),
            if (asyncSetup.value case final setup? when setup.hasModel)
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
                  onPressed: _form.isValid(setup.unit) ? () => _continue(setup) : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _layout(VehicleDetailsSetup setup) {
    final colors = context.colors;
    final windowClass = WindowClass.of(context);
    final form = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.md,
        AppSpacing.screenMargin,
        AppSpacing.xl,
      ),
      child: _fields(setup),
    );

    // Tablet landscape: large preview on the start side, form on the end.
    if (windowClass == WindowClass.expanded) {
      return Row(
        children: [
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: VehiclePreview(bodyType: _form.body, paint: _form.paint),
            ),
          ),
          Expanded(flex: 6, child: SingleChildScrollView(child: form)),
        ],
      );
    }

    // Phones and tablet portrait: preview pinned at the top, shrinking as
    // the form scrolls.
    return CustomScrollView(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: VehiclePreviewHeader(
            bodyType: _form.body,
            paint: _form.paint,
            minExtent: 96,
            maxExtent: windowClass == WindowClass.medium ? 240 : 180,
            background: colors.bgBase,
          ),
        ),
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: form),
          ),
        ),
      ],
    );
  }

  Widget _fields(VehicleDetailsSetup setup) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final language = Localizations.localeOf(context).languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text(setup.title(language), style: text.titleL)),
        const SizedBox(height: AppSpacing.xxs),
        Text(l10n.detailsSubtitle, style: text.bodyS.copyWith(color: colors.textSecondary)),
        const SizedBox(height: AppSpacing.xl),
        VehicleFormFields(controller: _form, unit: setup.unit, today: ref.read(clockProvider)()),
      ],
    );
  }
}

/// Setup resumed here without a model: send the user back to the start.
class _NeedModel extends StatelessWidget {
  const _NeedModel();

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
            Text(l10n.detailsNeedModelTitle, style: context.text.titleM, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              l10n.detailsNeedModelBody,
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
