import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../service_history/application/service_history_providers.dart';
import '../../vehicles/presentation/delete_vehicle_dialog.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/layout/window_class.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/navigation/floating_nav_bar.dart';
import '../../../core/widgets/page_dots.dart';
import '../../../core/widgets/stat_card.dart';
import '../../maintenance/application/template_update_controller.dart';
import '../../maintenance/domain/dashboard_summary.dart';
import '../../maintenance/domain/item_due.dart';
import '../../vehicles/presentation/vehicle_labels.dart';
import '../application/current_vehicle_controller.dart';
import '../application/dashboard_data.dart';
import 'widgets/dashboard_alert_pill.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/dashboard_stats.dart';
import 'widgets/health_score_block.dart';
import 'widgets/hero_car.dart';
import 'widgets/stat_carousel.dart';
import '../../account/presentation/widgets/sync_indicator.dart';
import '../../mileage/presentation/mileage_review_sheet.dart';
import '../../notifications/domain/notification_target.dart';
import '../../notifications/presentation/reminder_bundle_sheet.dart';
import '../../mileage/presentation/update_mileage_sheet.dart';
import '../../maintenance/presentation/next_service_sheet.dart';
import '../../maintenance/presentation/template_update_sheet.dart';
import 'vehicle_switcher_sheet.dart';
import 'widgets/upcoming_list.dart';

/// S-09 Vehicle dashboard (UI/UX spec S-09): the car's health, mileage,
/// next service, this year's spend and the one thing to do now.
///
/// After setup ([arrival]), the car drives in and the score counts up.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key, this.arrival, this.deepLink});

  final DashboardArrival? arrival;

  /// The route's address. A reminder's deep link carries its vehicle and
  /// what to open (spec S-35, FR-NOT-04).
  final Uri? deepLink;

  /// The car arrival and score count-up after setup.
  static const arrivalDuration = Duration(milliseconds: 1400);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with TickerProviderStateMixin {
  /// Car arrival (first half) and score count-up (second part).
  late final AnimationController _arrival = AnimationController(
    vsync: this,
    duration: DashboardScreen.arrivalDuration,
    value: widget.arrival == null ? 1 : 0,
  );
  late final Animation<double> _carIn = CurvedAnimation(parent: _arrival, curve: const Interval(0, 0.5));
  late final Animation<double> _countUp = CurvedAnimation(
    parent: _arrival,
    curve: const Interval(0.3, 1, curve: Curves.easeOutCubic),
  );

  /// The Mileage card counts from the old value to the new one after an
  /// update (spec S-12 "After save": 400 ms).
  late final AnimationController _mileageCount = AnimationController(
    vsync: this,
    duration: AppMotion.emphasis,
    value: 1,
  );
  int _mileageFrom = 0;

  /// The last data shown, kept while the next vehicle loads.
  DashboardData? _shown;
  bool _showVehicleDots = false;

  /// A car picked in the switcher, waiting for its data to drive in.
  String? _arrivalPendingFor;
  Timer? _dotsTimer;

  /// The deep link already opened, so a rebuild doesn't open it again.
  Uri? _openedLink;

  @override
  void initState() {
    super.initState();
    _openDeepLink();
  }

  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _openDeepLink();
  }

  /// Shows the reminder's vehicle, then opens its item, the bundle sheet
  /// or Update mileage (spec S-35 "Deep link").
  void _openDeepLink() {
    final link = widget.deepLink;
    if (link == null || link == _openedLink) return;
    final target = NotificationTarget.fromQuery(link.queryParameters);
    if (target == null) return;
    _openedLink = link;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final vehicles = await ref.read(garageVehiclesProvider.future);
      if (!mounted || !vehicles.any((v) => v.id == target.vehicleId)) return;
      await ref.read(currentVehicleProvider.notifier).select(target.vehicleId);
      if (!mounted) return;
      switch (target) {
        case OpenItem(:final code):
          await context.push(AppRoutes.garageItem(code));
        case OpenBundle(:final codes):
          await showReminderBundle(context, vehicleId: target.vehicleId, codes: codes);
        case OpenMileage():
          await showUpdateMileage(context, vehicleId: target.vehicleId);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.arrival != null && _arrival.value == 0) {
      // No motion with Reduce Motion.
      MediaQuery.disableAnimationsOf(context) ? _arrival.value = 1 : _arrival.forward();
    }
  }

  /// S-12: the two-tap mileage update for the car on screen.
  void _reviewMileage(String readingId) {
    final id = _shown?.vehicle.id;
    if (id != null) showMileageReview(context, vehicleId: id, readingId: readingId);
  }

  void _updateMileage() {
    final id = _shown?.vehicle.id;
    if (id != null) showUpdateMileage(context, vehicleId: id);
  }

  /// The switcher (S-10): picking a car shows it with the arrival
  /// animation and remembers it (BR-VEH-05).
  Future<void> _openSwitcher(String currentId) async {
    final choice = await showVehicleSwitcher(context, currentVehicleId: currentId);
    if (!mounted || choice == null) return;
    switch (choice) {
      case SwitchToVehicle(:final vehicleId):
        if (vehicleId == currentId) return;
        // The arrival animation starts once the new car's data is shown.
        if (!MediaQuery.disableAnimationsOf(context)) _arrivalPendingFor = vehicleId;
        await ref.read(currentVehicleProvider.notifier).select(vehicleId);
      case AddVehicleChoice():
        await context.push('${AppRoutes.setupBrand}?add=1');
      case ManageVehiclesChoice():
        _push(AppRoutes.garageManageVehicles);
    }
  }

  @override
  void dispose() {
    _arrival.dispose();
    _mileageCount.dispose();
    _dotsTimer?.cancel();
    super.dispose();
  }

  // Navigation targets (spec S-09).
  void _push(String location) => context.push(location);

  void _onAlert(DashboardAlert alert) => switch (alert) {
    OverdueAlert(:final items) when items.length == 1 => _push(AppRoutes.garageItem(items.single.item.code)),
    OverdueAlert() => _push(AppRoutes.garageScheduleFiltered('overdue')),
    DueSoonAlert(:final item) => _push(AppRoutes.garageItem(item.item.code)),
    UnknownItemsAlert() => _push(AppRoutes.garageScheduleFiltered('unknown')),
    StaleMileageAlert() => _updateMileage(),
    MileageReviewAlert(:final readingId) => _reviewMileage(readingId),
    AllGoodAlert() => _push(AppRoutes.garageSchedule),
  };

  Future<void> _onMenu(DashboardMenuAction action, DashboardData data) async {
    switch (action) {
      case DashboardMenuAction.templateUpdate:
        final update = ref.read(templateUpdateProvider(data.vehicle.id)).value;
        if (update != null) await reviewTemplateUpdate(context, ref, update: update, unit: data.unit);
      case DashboardMenuAction.schedule:
        _push(AppRoutes.garageSchedule);
      case DashboardMenuAction.mileageHistory:
        _push(AppRoutes.garageMileageHistory);
      case DashboardMenuAction.editVehicle:
        _push(AppRoutes.garageEditVehicle);
      case DashboardMenuAction.deleteVehicle:
        await _confirmDelete(data);
    }
  }

  /// FR-VEH-12: delete after confirmation. The last vehicle returns the
  /// user to brand selection (BR-VEH-06).
  Future<void> _confirmDelete(DashboardData data) async {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final name = data.vehicle.nickname ?? '${data.brandName(language)} ${data.modelName(language)}'.trim();
    final records = (await ref.read(serviceRecordRepositoryProvider).records(data.vehicle.id)).length;
    if (!mounted) return;
    final confirmed = await confirmDeleteVehicle(context, name: name, recordCount: records);
    if (!confirmed || !mounted) return;
    final next = await ref.read(currentVehicleProvider.notifier).delete(data.vehicle.id);
    if (!mounted) return;
    _shown = null;
    if (next == null) {
      context.go(AppRoutes.setupBrand);
    } else {
      showAppToast(context, l10n.deleteVehicleDone(name));
    }
  }

  /// Swiping the hero switches to the next or previous vehicle, and the
  /// vehicle dots show for 1.5 s (spec S-09 "Interactions").
  void _onHeroSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 200) return;
    final vehicles = ref.read(garageVehiclesProvider).value ?? const [];
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // Swiping towards the start shows the next vehicle.
    final next = rtl ? velocity > 0 : velocity < 0;
    final target = ref.read(currentVehicleProvider.notifier).neighbour(vehicles, next: next);
    if (target == null) return;
    ref.read(currentVehicleProvider.notifier).select(target);
    setState(() => _showVehicleDots = true);
    _dotsTimer?.cancel();
    _dotsTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _showVehicleDots = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehicleId = ref.watch(currentVehicleProvider).value;
    if (vehicleId != null) {
      final data = ref.watch(dashboardDataProvider(vehicleId)).value;
      final previous = _shown;
      if (data != null &&
          previous != null &&
          previous.vehicle.id == data.vehicle.id &&
          previous.vehicle.odometerKm != data.vehicle.odometerKm &&
          !MediaQuery.disableAnimationsOf(context)) {
        _mileageFrom = previous.vehicle.odometerKm;
        _mileageCount.value = 0;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _mileageCount.forward();
        });
      }
      if (data != null) _shown = data;
      if (data != null && data.vehicle.id == _arrivalPendingFor) {
        _arrivalPendingFor = null;
        _arrival.value = 0;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _arrival.forward(from: 0);
        });
      }
    }
    final data = _shown;

    return Scaffold(
      body: data == null
          ? const SizedBox.expand()
          : AnimatedBuilder(
              animation: _mileageCount,
              builder: (context, _) => switch (WindowClass.of(context)) {
                WindowClass.compact => _compact(data),
                WindowClass.medium => _medium(data),
                WindowClass.expanded => _expanded(data),
              },
            ),
    );
  }

  // Building blocks.

  Widget _header(DashboardData data) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final model = data.modelName(language);
    final year = data.vehicle.year;
    return DashboardHeader(
      monogram: data.monogram,
      brandName: data.brandName(language),
      subline: data.vehicle.nickname ?? (year == null ? model : l10n.dashboardModelYear(model, '$year')),
      onSwitchVehicle: () => _openSwitcher(data.vehicle.id),
      onMenu: (action) => _onMenu(action, data),
      templateUpdate: ref.watch(templateUpdateProvider(data.vehicle.id)).value != null,
      syncIndicator: SyncIndicator(needsReview: data.alert is MileageReviewAlert),
    );
  }

  Widget _hero(DashboardData data, {bool bleed = true, double widthFactor = 0.8}) {
    final l10n = AppLocalizations.of(context);
    final vehicle = data.vehicle;
    return GestureDetector(
      onHorizontalDragEnd: _onHeroSwipe,
      child: HeroCar(
        bodyType: vehicle.bodyType,
        paint: vehicle.paint,
        semanticLabel: '${paintColorLabel(l10n, vehicle.paint)} ${bodyTypeLabel(l10n, vehicle.bodyType)}',
        bleed: bleed,
        widthFactor: widthFactor,
        arrival: _carIn,
      ),
    );
  }

  Widget _vehicleDots() {
    final l10n = AppLocalizations.of(context);
    final vehicles = ref.watch(garageVehiclesProvider).value ?? const [];
    final current = vehicles.indexWhere((v) => v.id == _shown?.vehicle.id);
    if (vehicles.length < 2 || current < 0) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _showVehicleDots ? 1 : 0,
        duration: AppMotion.standard,
        child: PageDots(
          count: vehicles.length,
          index: current,
          semanticLabel: l10n.dashboardVehicleDots(current + 1, vehicles.length),
        ),
      ),
    );
  }

  Widget _score(DashboardData data) => AnimatedBuilder(
    animation: _countUp,
    builder: (context, _) => HealthScoreBlock(
      health: data.health,
      displayedScore: (data.health.score * _countUp.value).round(),
      onTap: () => _push(AppRoutes.garageHealth),
    ),
  );

  List<DashboardStat> _stats(DashboardData data) => buildDashboardStats(
    displayedOdometerKm: _mileageCount.value < 1
        ? (_mileageFrom + (data.vehicle.odometerKm - _mileageFrom) * _mileageCount.value).round()
        : null,
    l10n: AppLocalizations.of(context),
    colors: context.colors,
    languageCode: Localizations.localeOf(context).languageCode,
    data: data,
    actions: DashboardStatActions(
      updateMileage: _updateMileage,
      nextService: () => showNextServiceSheet(context, vehicleId: data.vehicle.id),
      setUpSchedule: () => _push(AppRoutes.garageSchedule),
      spend: () => _push(AppRoutes.garageSpend),
    ),
  );

  Widget _card(DashboardStat stat, {bool horizontal = false, double? height = StatCarousel.cardHeight}) => StatCard(
    label: stat.label,
    sublabel: stat.sublabel,
    value: stat.value,
    unit: stat.unit,
    footer: stat.footer,
    valueColor: stat.valueColor,
    sublabelIcon: stat.sublabelIcon,
    semanticLabel: stat.semanticLabel,
    onTap: stat.onTap,
    width: null,
    height: height,
    horizontal: horizontal,
  );

  Widget _pill(DashboardData data) => Center(
    child: DashboardAlertPill(alert: data.alert, onTap: _onAlert),
  );

  // Layouts (spec S-09 "Layout" and "Responsive").

  /// Phones: no scrolling at the default text size. The hero takes the
  /// space the rest leaves, and the score overlaps it by 24 pt.
  Widget _compact(DashboardData data) {
    final bottomClearance =
        FloatingNavBar.height + AppSpacing.xs + AppSpacing.md + MediaQuery.paddingOf(context).bottom;
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 16 * 1.3;
    const margins = EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin);

    if (largeText) {
      // Large text: the screen scrolls and the cards stack (full width).
      return SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(top: AppSpacing.sm, bottom: bottomClearance),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(padding: margins, child: _header(data)),
              SizedBox(height: 220, child: _hero(data)),
              Padding(padding: margins, child: _score(data)),
              const SizedBox(height: AppSpacing.xl),
              for (final stat in _stats(data))
                Padding(
                  padding: margins.copyWith(bottom: AppSpacing.sm),
                  child: _card(stat, horizontal: true, height: null),
                ),
              const SizedBox(height: AppSpacing.sm),
              Padding(padding: margins, child: _pill(data)),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Padding(padding: margins, child: _header(data)),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: _hero(data)),
                Positioned(
                  top: AppSpacing.xs,
                  left: 0,
                  right: 0,
                  child: Center(child: _vehicleDots()),
                ),
              ],
            ),
          ),
          // Overlaps the bottom of the hero by 24 pt; the gap it leaves
          // below is the 24 pt before the carousel.
          Transform.translate(
            offset: const Offset(0, -AppSpacing.xl),
            child: Padding(padding: margins, child: _score(data)),
          ),
          StatCarousel(key: ValueKey(data.vehicle.id), stats: _stats(data)),
          const SizedBox(height: AppSpacing.lg),
          Padding(padding: margins, child: _pill(data)),
          SizedBox(height: bottomClearance),
        ],
      ),
    );
  }

  /// iPad portrait: the hero doesn't bleed, the score sits below it and the
  /// three cards are in a row. Max width 720.
  Widget _medium(DashboardData data) {
    final stats = _stats(data);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(data),
                SizedBox(height: 360, child: _hero(data, bleed: false)),
                _score(data),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    for (var i = 0; i < stats.length; i++) ...[
                      if (i > 0) const SizedBox(width: AppSpacing.sm),
                      Expanded(child: _card(stats[i])),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _pill(data),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// iPad landscape: two columns. Start (55%): header, hero and score.
  /// End (45%): the stacked cards, the pill and "Upcoming".
  Widget _expanded(DashboardData data) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 55,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(data),
                  Expanded(child: _hero(data, bleed: false, widthFactor: 0.95)),
                  _score(data),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              flex: 45,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final stat in _stats(data)) ...[
                      _card(stat, horizontal: true, height: 120),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    _pill(data),
                    const SizedBox(height: AppSpacing.xl),
                    UpcomingList(
                      items: data.upcoming,
                      today: data.today,
                      unit: data.unit,
                      onItem: (ItemDue due) => _push(AppRoutes.garageItem(due.item.code)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
