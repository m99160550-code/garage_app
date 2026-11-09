import 'package:flutter/material.dart';

import '../../../core/format/app_formatters.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/text/digits.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_choice_chip.dart';
import '../../../core/widgets/app_date_picker.dart';
import '../../../core/widgets/app_segmented_control.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/vehicle/car_illustration.dart';
import '../../onboarding/presentation/country/country_labels.dart';
import '../../onboarding/presentation/details/widgets/paint_swatches.dart';
import '../../onboarding/presentation/details/widgets/year_picker_sheet.dart';
import '../../settings/domain/distance_unit.dart';
import '../domain/body_type.dart';
import '../domain/fuel_type.dart';
import '../domain/paint_color.dart';
import '../domain/vehicle_details.dart';
import '../domain/vehicle_validation.dart';
import 'vehicle_labels.dart';

/// The answers of the vehicle form, shared by S-06 Vehicle details and
/// S-32 Edit vehicle.
class VehicleFormController extends ChangeNotifier {
  VehicleFormController() {
    for (final c in [odometer, nickname, plate, vin]) {
      c.addListener(notifyListeners);
    }
    odometerFocus.addListener(() {
      if (!odometerFocus.hasFocus) update(() => odometerTouched = true);
    });
  }

  final odometer = TextEditingController();
  final nickname = TextEditingController();
  final plate = TextEditingController();
  final vin = TextEditingController();
  final odometerFocus = FocusNode();
  final vinFocus = FocusNode();

  FuelType? fuel;
  PaintColor paint = PaintColor.fallback;
  BodyType body = BodyType.sedan;
  int? year;
  DateTime? purchaseDate;
  bool moreOpen = false;
  bool odometerTouched = false;

  /// Changes a value and redraws the form.
  void update(VoidCallback change) {
    change();
    notifyListeners();
  }

  /// Fills the form from saved answers. "More details" opens when any of
  /// them is set.
  void fill(VehicleDetails details, DistanceUnit unit) {
    fuel = details.fuelType;
    paint = details.paint;
    body = details.bodyType;
    odometer.text = GroupedNumberFormatter()
        .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: '${fromKilometres(details.odometerKm, unit)}'))
        .text;
    nickname.text = details.nickname ?? '';
    plate.text = details.licencePlate ?? '';
    vin.text = details.vin ?? '';
    year = details.year;
    purchaseDate = details.purchaseDate;
    moreOpen = [
      details.nickname,
      details.licencePlate,
      details.vin,
      details.year,
      details.purchaseDate,
    ].any((v) => v != null);
    notifyListeners();
  }

  bool isValid(DistanceUnit unit) =>
      fuel != null && checkOdometer(odometer.text, unit) == null && checkVin(vin.text) != VinIssue.invalidCharacters;

  /// The answers; call only when [isValid].
  VehicleDetails toDetails(DistanceUnit unit) {
    String? optional(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    return VehicleDetails(
      fuelType: fuel!,
      odometerKm: toKilometres(parseWholeNumber(odometer.text)!, unit),
      paint: paint,
      bodyType: body,
      nickname: optional(nickname),
      year: year,
      licencePlate: optional(plate),
      vin: optional(vin),
      purchaseDate: purchaseDate,
    );
  }

  /// Opens "More details" and puts the cursor in the VIN field.
  void focusVin() {
    update(() => moreOpen = true);
    vinFocus.requestFocus();
  }

  @override
  void dispose() {
    for (final c in [odometer, nickname, plate, vin]) {
      c.dispose();
    }
    odometerFocus.dispose();
    vinFocus.dispose();
    super.dispose();
  }
}

/// The form's fields (spec S-06 items 4–6): fuel type and odometer,
/// appearance, and the optional "More details".
class VehicleFormFields extends StatelessWidget {
  const VehicleFormFields({
    super.key,
    required this.controller,
    required this.unit,
    required this.today,
    this.odometerError,
  });

  final VehicleFormController controller;
  final DistanceUnit unit;
  final DateTime today;

  /// An extra odometer error from the caller (S-32: lower than the last
  /// reading).
  final String? odometerError;

  Future<void> _pickYear(BuildContext context) async {
    final choice = await showYearPicker(context: context, selected: controller.year);
    if (choice != null) controller.update(() => controller.year = choice.year);
  }

  Future<void> _pickPurchaseDate(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final choice = await showAppDatePicker(
      context: context,
      title: l10n.purchaseDateLabel,
      initial: controller.purchaseDate,
      lastDate: DateUtils.dateOnly(today),
      today: today,
    );
    if (choice != null) controller.update(() => controller.purchaseDate = choice.date);
  }

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: controller, builder: (context, _) => _build(context));

  Widget _build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final language = Localizations.localeOf(context).languageCode;
    final c = controller;

    final odometerIssue = checkOdometer(c.odometer.text, unit);
    final showOdometerIssue = odometerIssue != null && (c.odometerTouched || odometerIssue != OdometerIssue.missing);
    final vinIssue = checkVin(c.vin.text);
    final dateText = c.purchaseDate == null ? '' : AppFormatters(languageCode: language).mediumDate(c.purchaseDate!);

    Widget label(String value) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Semantics(header: true, child: Text(value, style: text.label)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Required (spec S-06 item 4).
        label(l10n.fuelTypeLabel),
        AppSegmentedControl<FuelType>(
          semanticPrefix: l10n.fuelTypeLabel,
          selected: c.fuel,
          onChanged: (fuel) => c.update(() => c.fuel = fuel),
          segments: [for (final fuel in FuelType.values) (fuel, fuelTypeLabel(l10n, fuel))],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(l10n.fuelTypeHelper, style: text.caption.copyWith(color: colors.textTertiary)),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          controller: c.odometer,
          focusNode: c.odometerFocus,
          label: l10n.odometerLabel,
          suffixText: distanceUnitLabel(l10n, unit),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [GroupedNumberFormatter()],
          valueStyle: AppTextStyles.tabular(text.body),
          helper: l10n.odometerHelper,
          error: showOdometerIssue
              ? switch (odometerIssue) {
                  OdometerIssue.missing => l10n.odometerMissing,
                  OdometerIssue.notANumber => l10n.odometerNotNumber,
                  OdometerIssue.tooHigh => l10n.odometerTooHigh,
                }
              : odometerError,
        ),
        const SizedBox(height: AppSpacing.xxl),

        // Appearance (spec S-06 item 5).
        Semantics(header: true, child: Text(l10n.appearanceTitle, style: text.titleM)),
        const SizedBox(height: AppSpacing.md),
        label(l10n.paintColorLabel),
        PaintSwatches(selected: c.paint, onSelected: (paint) => c.update(() => c.paint = paint)),
        const SizedBox(height: AppSpacing.md),
        label(l10n.bodyTypeLabel),
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            for (final type in BodyType.values)
              AppChoiceChip(
                label: bodyTypeLabel(l10n, type),
                selected: c.body == type,
                onTap: () => c.update(() => c.body = type),
                leading: SizedBox(
                  width: 30,
                  child: CarIllustration(
                    bodyType: type,
                    paint: c.body == type ? colors.textOnLight : PaintColor.silver.color,
                    showReflection: false,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        // More details, optional (spec S-06 item 6).
        _MoreDetailsHeader(open: c.moreOpen, onTap: () => c.update(() => c.moreOpen = !c.moreOpen)),
        AnimatedSize(
          duration: AppMotion.standard,
          curve: AppMotion.standardCurve,
          alignment: Alignment.topCenter,
          child: !c.moreOpen
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        controller: c.nickname,
                        label: l10n.nicknameLabel,
                        maxLength: 40,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Picker fields: read-only, rebuilt when the value changes.
                      AppTextField(
                        key: ValueKey(('year', c.year)),
                        initialValue: c.year?.toString() ?? '',
                        label: l10n.yearLabel,
                        readOnly: true,
                        onTap: () => _pickYear(context),
                        trailingIcon: Icons.expand_more,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        controller: c.plate,
                        label: l10n.plateLabel,
                        maxLength: 20,
                        textDirection: TextDirection.ltr,
                        inputFormatters: [UpperAlphanumericFormatter(allowSpaces: true)],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        controller: c.vin,
                        focusNode: c.vinFocus,
                        label: l10n.vinLabel,
                        maxLength: 17,
                        textDirection: TextDirection.ltr,
                        inputFormatters: [UpperAlphanumericFormatter()],
                        valueStyle: const TextStyle(
                          fontFamily: AppFonts.inter,
                          fontFeatures: [FontFeature.tabularFigures(), FontFeature('zero')],
                          letterSpacing: 1,
                        ),
                        error: vinIssue == VinIssue.invalidCharacters ? l10n.vinInvalid : null,
                        warning: vinIssue == VinIssue.unusualLength ? l10n.vinLengthWarning : null,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        key: ValueKey(('purchase', c.purchaseDate)),
                        initialValue: dateText,
                        label: l10n.purchaseDateLabel,
                        readOnly: true,
                        onTap: () => _pickPurchaseDate(context),
                        trailingIcon: Icons.calendar_today_outlined,
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// "Add nickname, year, VIN and more" with a chevron (spec S-06 item 6).
class _MoreDetailsHeader extends StatelessWidget {
  const _MoreDetailsHeader({required this.open, required this.onTap});

  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Semantics(
      button: true,
      expanded: open,
      label: '${l10n.moreDetailsTitle}, ${l10n.moreDetailsOptional}',
      excludeSemantics: true,
      child: Material(
        color: colors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.row),
          side: BorderSide(color: colors.borderSubtle),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.row),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l10n.moreDetailsTitle, style: context.text.titleM),
                        Text(
                          l10n.moreDetailsOptional,
                          style: context.text.caption.copyWith(color: colors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: AppMotion.standard,
                    child: Icon(Icons.expand_more, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
