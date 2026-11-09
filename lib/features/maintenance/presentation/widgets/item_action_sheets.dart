import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_banner.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_choice_chip.dart';
import '../../../../core/widgets/app_sheet.dart';

/// Snooze sheet (spec S-15 item 5): 7, 14 or 30 days. For an overdue
/// item it explains that the score still counts it (BR-HLT-05). Returns
/// the number of days, or `null` when dismissed.
Future<int?> showSnoozeSheet(BuildContext context, {required bool overdue}) => showAppSheet<int>(
  context: context,
  fitContent: true,
  tabletMaxWidth: 420,
  builder: (_) => _SnoozeSheet(overdue: overdue),
);

class _SnoozeSheet extends StatefulWidget {
  const _SnoozeSheet({required this.overdue});

  final bool overdue;

  @override
  State<_SnoozeSheet> createState() => _SnoozeSheetState();
}

class _SnoozeSheetState extends State<_SnoozeSheet> {
  int _days = 7;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(l10n.itemSnoozeTitle, style: context.text.titleL)),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              for (final days in const [7, 14, 30])
                AppChoiceChip(
                  label: l10n.itemSnoozeDays(days),
                  selected: _days == days,
                  onTap: () => setState(() => _days = days),
                ),
            ],
          ),
          if (widget.overdue) ...[
            const SizedBox(height: AppSpacing.md),
            AppBanner(message: l10n.itemSnoozeOverdueNote, tone: BannerTone.warning),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppButton(label: l10n.itemSnooze, onPressed: () => Navigator.of(context).pop(_days)),
        ],
      ),
    );
  }
}

/// Reschedule sheet (spec S-15 item 5): a calendar from today on, the note
/// that it's for this cycle only (BR-MNT-06), and "Save".
Future<DateTime?> showRescheduleSheet(BuildContext context, {required DateTime today, required DateTime initial}) =>
    showAppSheet<DateTime>(
      context: context,
      heightFactor: 0.8,
      tabletMaxWidth: 420,
      builder: (_) => _RescheduleSheet(today: today, initial: initial),
    );

class _RescheduleSheet extends StatefulWidget {
  const _RescheduleSheet({required this.today, required this.initial});

  final DateTime today;
  final DateTime initial;

  @override
  State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<_RescheduleSheet> {
  late DateTime _date = widget.initial.isBefore(widget.today) ? widget.today : widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Semantics(header: true, child: Text(l10n.itemReschedule, style: context.text.titleL)),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: CalendarDatePicker(
              initialDate: _date,
              firstDate: widget.today,
              lastDate: DateTime(widget.today.year + 5, widget.today.month, widget.today.day),
              onDateChanged: (date) => setState(() => _date = date),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.itemRescheduleNote, style: context.text.bodyS.copyWith(color: context.colors.textSecondary)),
              const SizedBox(height: AppSpacing.md),
              AppButton(label: l10n.actionSave, onPressed: () => Navigator.of(context).pop(_date)),
            ],
          ),
        ),
      ],
    );
  }
}
