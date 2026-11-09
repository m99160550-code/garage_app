import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import 'app_button.dart';
import 'app_sheet.dart';

/// What the date sheet returns: a date, or `null` inside for "Clear".
/// A dismissed sheet returns no choice at all.
class DateChoice {
  const DateChoice(this.date);

  final DateTime? date;
}

/// Calendar in a bottom sheet (UI/UX spec 1.7 "Date field"): Gregorian
/// only (BR-MNT-16), with "Today" and "Clear" shortcuts. Dates after
/// [lastDate] are disabled, for example future dates. [today] comes from
/// the app's clock (`clockProvider`) so "Today" matches the rest of the
/// app; it falls back to the device clock.
Future<DateChoice?> showAppDatePicker({
  required BuildContext context,
  required String title,
  DateTime? initial,
  DateTime? firstDate,
  DateTime? lastDate,
  bool allowClear = true,
  DateTime? today,
}) {
  final day = DateUtils.dateOnly(today ?? DateTime.now());
  final last = lastDate ?? DateTime(day.year + 30);
  final first = firstDate ?? DateTime(1950);
  return showAppSheet<DateChoice>(
    context: context,
    heightFactor: 0.7,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      var picked = initial ?? (day.isAfter(last) ? last : day);
      return StatefulBuilder(
        builder: (context, setState) => Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(start: AppSpacing.screenMargin, end: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(header: true, child: Text(title, style: context.text.titleL)),
                  ),
                  IconButton(
                    tooltip: l10n.actionClose,
                    icon: Icon(Icons.close, color: context.colors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: CalendarDatePicker(
                  initialDate: picked,
                  currentDate: day,
                  firstDate: first,
                  lastDate: last,
                  onDateChanged: (date) => setState(() => picked = date),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenMargin, 0, AppSpacing.screenMargin, AppSpacing.md),
              child: Row(
                children: [
                  AppButton.text(
                    label: l10n.dateToday,
                    onPressed: day.isAfter(last) ? null : () => Navigator.of(context).pop(DateChoice(day)),
                  ),
                  if (allowClear)
                    AppButton.text(
                      label: l10n.dateClear,
                      onPressed: () => Navigator.of(context).pop(const DateChoice(null)),
                    ),
                  const Spacer(),
                  AppButton(
                    label: l10n.dateDone,
                    expand: false,
                    onPressed: () => Navigator.of(context).pop(DateChoice(picked)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
