import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/format/app_formatters.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/layout/window_class.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/text/digits.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_banner.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_date_picker.dart';
import '../../../maintenance/domain/baseline_group.dart';
import '../../../maintenance/domain/baseline_validation.dart';
import '../../../maintenance/domain/schedule_rules.dart';
import '../../../maintenance/domain/vehicle_setup.dart';
import '../../../privacy/application/consent_providers.dart';
import '../../../vehicles/domain/vehicle_validation.dart';
import '../../application/service_baseline_controller.dart';
import '../country/country_labels.dart';
import '../widgets/setup_top_bar.dart';
import 'widgets/baseline_item_card.dart';
import 'widgets/new_car_card.dart';

/// S-07 Service baseline / "My car is new" (UI/UX spec S-07).
///
/// Asks when oil or service, brakes, tires and battery were last done, or
/// with "My car is new", only the delivery date and starting mileage.
/// "Save vehicle" saves the car with its schedule and opens the dashboard.
class ServiceBaselineScreen extends ConsumerStatefulWidget {
  const ServiceBaselineScreen({super.key, this.addingVehicle = false});

  final bool addingVehicle;

  @override
  ConsumerState<ServiceBaselineScreen> createState() => _ServiceBaselineScreenState();
}

/// The form state of one baseline card.
class _ItemForm {
  final mileage = TextEditingController();
  final focus = FocusNode();
  final key = GlobalKey();
  DateTime? date;
  bool unknown = false;

  void dispose() {
    mileage.dispose();
    focus.dispose();
  }
}

class _ServiceBaselineScreenState extends ConsumerState<ServiceBaselineScreen> {
  final _items = {for (final group in BaselineGroup.values) group: _ItemForm()};
  final _startingMileage = TextEditingController();
  final _startingFocus = FocusNode();
  final _newCarKey = GlobalKey();

  bool _isNew = false;
  DateTime? _deliveryDate;
  bool _showDeliveryMissing = false;
  bool _initialised = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(serviceBaselineControllerProvider, (_, next) {
      final setup = next.value;
      if (!_initialised && setup != null && setup.hasDetails) _initialiseFrom(setup);
    }, fireImmediately: true);
    for (final controller in [_startingMileage, for (final item in _items.values) item.mileage]) {
      controller.addListener(() => setState(() {}));
    }
  }

  /// Starting mileage is prefilled with the current odometer (BR-MNT-12).
  void _initialiseFrom(ServiceBaselineSetup setup) {
    _initialised = true;
    _startingMileage.text = _grouped(fromKilometres(setup.currentOdometerKm, setup.unit));
  }

  static String _grouped(int value) =>
      GroupedNumberFormatter().formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: '$value')).text;

  @override
  void dispose() {
    for (final item in _items.values) {
      item.dispose();
    }
    _startingMileage.dispose();
    _startingFocus.dispose();
    super.dispose();
  }

  DateTime get _today => DateUtils.dateOnly(ref.read(clockProvider)());

  String? _mileageError(String input, ServiceBaselineSetup setup) {
    final l10n = AppLocalizations.of(context);
    return switch (checkBaselineKm(input, setup.unit, setup.currentOdometerKm)) {
      null => null,
      BaselineKmIssue.notANumber => l10n.odometerNotNumber,
      BaselineKmIssue.aboveOdometer => l10n.baselineKmAboveOdometer(_odometerText(setup)),
    };
  }

  /// "54,320 km": the odometer from S-06, in Western digits (BR-SET-05).
  String _odometerText(ServiceBaselineSetup setup) {
    final l10n = AppLocalizations.of(context);
    final value = const AppFormatters(languageCode: 'en')
        .formatOdometer(fromKilometres(setup.currentOdometerKm, setup.unit));
    return '$value ${distanceUnitLabel(l10n, setup.unit)}';
  }

  Future<DateChoice?> _pickDate(String title, DateTime? initial) => showAppDatePicker(
    context: context,
    title: title,
    initial: initial,
    lastDate: _today, // No future dates (spec S-07 validation).
  );

  Future<void> _pickItemDate(BaselineGroup group, String title) async {
    final choice = await _pickDate(title, _items[group]!.date);
    if (choice != null) setState(() => _items[group]!.date = choice.date);
  }

  Future<void> _pickDeliveryDate() async {
    final choice = await _pickDate(AppLocalizations.of(context).deliveryDateLabel, _deliveryDate);
    if (choice != null) setState(() => _deliveryDate = choice.date);
  }

  /// Scrolls to an invalid field and gives it focus (accessibility: focus
  /// moves to the first invalid field on Save).
  void _reveal(GlobalKey key, FocusNode? focus) {
    final target = key.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(target, duration: AppMotion.standard, alignment: 0.2);
    }
    focus?.requestFocus();
  }

  Future<void> _save(ServiceBaselineSetup setup) async {
    final VehicleSetup? vehicleSetup = _isNew ? await _newCarSetup(setup) : _baselineSetup(setup);
    if (vehicleSetup == null || !mounted) return;

    setState(() => _saving = true);
    try {
      final vehicleId = await ref.read(serviceBaselineControllerProvider.notifier).save(vehicleSetup);
      if (!mounted) return;
      // Setup is finished: the dashboard replaces the whole setup stack and
      // may offer the reminders primer (S-08).
      context.go(AppRoutes.garage, extra: DashboardArrival(vehicleId));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// The four answers, or `null` if a mileage is invalid.
  BaselineSetup? _baselineSetup(ServiceBaselineSetup setup) {
    for (final entry in _items.entries) {
      final item = entry.value;
      if (!item.unknown && _mileageError(item.mileage.text, setup) != null) {
        _reveal(item.key, item.focus);
        return null;
      }
    }
    return BaselineSetup({
      for (final MapEntry(key: group, value: item) in _items.entries)
        group: item.unknown
            ? const BaselineAnswer.unknown()
            : BaselineAnswer(
                date: item.date,
                km: baselineKmFrom(item.mileage.text, setup.unit, setup.currentOdometerKm),
              ),
    });
  }

  /// The delivery answers, or `null` if they're invalid or the user wants
  /// to change an old delivery date (BR-MNT-12, BR-MNT-13).
  Future<NewCarSetup?> _newCarSetup(ServiceBaselineSetup setup) async {
    final l10n = AppLocalizations.of(context);
    final delivery = _deliveryDate;
    if (delivery == null) {
      setState(() => _showDeliveryMissing = true);
      _reveal(_newCarKey, null);
      return null;
    }
    final startingKm = baselineKmFrom(_startingMileage.text, setup.unit, setup.currentOdometerKm);
    if (_mileageError(_startingMileage.text, setup) != null || startingKm == null) {
      _reveal(_newCarKey, _startingFocus);
      return null;
    }

    final newCar = NewCarSetup(deliveryDate: delivery, startingKm: startingKm);
    final dueCount = ref.read(serviceBaselineControllerProvider.notifier).countItemsDueSinceDelivery(newCar);
    if (dueCount == 0) return newCar;

    final months = monthsBetween(delivery, _today);
    final age = months >= 12 ? l10n.deliveryAgeYears(months ~/ 12) : l10n.deliveryAgeMonths(months);
    final keep = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deliveryOldTitle),
        content: Text(months >= 1 ? l10n.deliveryOldBody(age) : l10n.deliveryOldBodyDistance),
        actions: [
          AppButton.text(label: l10n.deliveryChange, onPressed: () => Navigator.pop(context, false)),
          AppButton.text(label: l10n.deliveryKeep, onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );
    if (keep == true) return newCar;
    if (keep == false && mounted) await _pickDeliveryDate();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final asyncSetup = ref.watch(serviceBaselineControllerProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SetupTopBar(step: SetupStepIndicator.service),
            Expanded(
              child: asyncSetup.when(
                loading: () => const DelayedSkeleton(),
                error: (_, _) => Center(
                  child: AppButton.secondary(
                    label: l10n.actionRetry,
                    onPressed: () => ref.invalidate(serviceBaselineControllerProvider),
                    expand: false,
                  ),
                ),
                data: (setup) => setup.hasDetails ? _content(setup) : const _NeedDetails(),
              ),
            ),
            if (asyncSetup.value case final setup? when setup.hasDetails)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenMargin,
                  AppSpacing.xs,
                  AppSpacing.screenMargin,
                  AppSpacing.md,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    // Always enabled: every item may be Unknown (UC-01 8a).
                    child: AppButton(label: l10n.actionSaveVehicle, isLoading: _saving, onPressed: () => _save(setup)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _content(ServiceBaselineSetup setup) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final unitLabel = distanceUnitLabel(l10n, setup.unit);
    final wide = WindowClass.of(context) != WindowClass.compact;

    final cards = [
      for (final MapEntry(key: group, value: item) in _items.entries)
        KeyedSubtree(
          key: item.key,
          child: BaselineItemCard(
            group: group,
            date: item.date,
            onPickDate: () => _pickItemDate(group, l10n.baselineDateLabel),
            mileageController: item.mileage,
            mileageFocus: item.focus,
            unitLabel: unitLabel,
            mileageError: _mileageError(item.mileage.text, setup),
            unknown: item.unknown,
            onUnknownChanged: (value) => setState(() => item.unknown = value),
          ),
        ),
    ];

    // Tablets: the four cards in a 2 × 2 grid (spec S-07 "Responsive").
    final Widget items = wide
        ? Column(
            children: [
              for (var i = 0; i < cards.length; i += 2) ...[
                if (i > 0) const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: cards[i]),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: cards[i + 1]),
                  ],
                ),
              ],
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < cards.length; i++) ...[if (i > 0) const SizedBox(height: AppSpacing.sm), cards[i]],
            ],
          );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.md,
        AppSpacing.screenMargin,
        AppSpacing.xl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: wide ? 720 : 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(header: true, child: Text(l10n.baselineTitle, style: text.titleL)),
              const SizedBox(height: AppSpacing.xxs),
              Text(l10n.baselineSubtitle, style: text.bodyS.copyWith(color: colors.textSecondary)),
              const SizedBox(height: AppSpacing.xl),
              KeyedSubtree(
                key: _newCarKey,
                child: NewCarCard(
                  isNew: _isNew,
                  onChanged: (value) => setState(() => _isNew = value),
                  deliveryDate: _deliveryDate,
                  onPickDeliveryDate: _pickDeliveryDate,
                  deliveryDateError: _showDeliveryMissing && _deliveryDate == null ? l10n.deliveryDateMissing : null,
                  startingMileage: _startingMileage,
                  startingMileageFocus: _startingFocus,
                  unitLabel: unitLabel,
                  startingMileageError: _mileageError(_startingMileage.text, setup),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AnimatedSwitcher(
                duration: AppMotion.standard,
                child: _isNew
                    ? AppBanner(key: const ValueKey('new'), message: l10n.newCarNote)
                    : KeyedSubtree(key: const ValueKey('items'), child: items),
              ),
              if (!_isNew) ...[
                const SizedBox(height: AppSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: colors.textTertiary),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(l10n.baselineFooter, style: text.caption.copyWith(color: colors.textTertiary)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Setup resumed here without the S-06 answers: send the user back.
class _NeedDetails extends StatelessWidget {
  const _NeedDetails();

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
            Text(l10n.baselineNeedDetailsTitle, style: context.text.titleM, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              l10n.baselineNeedDetailsBody,
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
