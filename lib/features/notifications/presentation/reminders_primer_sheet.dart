import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_toast.dart';
import '../application/reminder_primer_service.dart';
import '../domain/notification_permission.dart';
import 'widgets/notification_preview.dart';
import 'widgets/primer_illustration.dart';

/// Opens S-08 Reminders primer and handles the outcome (UI/UX spec S-08):
///
/// * Allowed: toast "Reminders are on".
/// * Not allowed, "Not now" or dismissed: the sheet closes quietly. The app
///   works normally and Profile offers "Enable reminders" (FR-NOT-06).
/// * Declined before: the main button opens the system Settings app.
Future<PrimerResult?> showRemindersPrimer(BuildContext context, WidgetRef ref, ReminderPrimerOffer offer) async {
  final l10n = AppLocalizations.of(context);
  final result = await showAppSheet<PrimerResult>(
    context: context,
    fitContent: true,
    builder: (_) => RemindersPrimerSheet(offer: offer),
  );
  if (result == null) await ref.read(reminderPrimerServiceProvider).dismiss();
  if (result == PrimerResult.granted && context.mounted) showAppToast(context, l10n.remindersOnToast);
  return result;
}

/// The sheet's content: illustration, explanation, an example notification
/// and the two buttons.
class RemindersPrimerSheet extends ConsumerStatefulWidget {
  const RemindersPrimerSheet({super.key, required this.offer});

  final ReminderPrimerOffer offer;

  @override
  ConsumerState<RemindersPrimerSheet> createState() => _RemindersPrimerSheetState();
}

class _RemindersPrimerSheetState extends ConsumerState<RemindersPrimerSheet> {
  bool _busy = false;

  Future<void> _turnOn() async {
    setState(() => _busy = true);
    final result = await ref.read(reminderPrimerServiceProvider).turnOn();
    if (mounted) Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final denied = widget.offer.permission == NotificationPermission.denied;

    // As tall as the content (about 420 pt), scrolling only when the text
    // is very large.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xs),
                const PrimerIllustration(),
                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  header: true,
                  child: Text(l10n.primerTitle, style: text.titleL, textAlign: TextAlign.center),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  denied ? '${l10n.primerBody} ${l10n.primerDeniedHint}' : l10n.primerBody,
                  style: text.bodyS.copyWith(color: colors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                NotificationPreview(
                  vehicleName: widget.offer.vehicleName,
                  itemName: widget.offer.itemName ?? l10n.primerPreviewFallbackItem,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xs, AppSpacing.xl, AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppButton(
                label: denied ? l10n.primerOpenSettings : l10n.primerTurnOn,
                isLoading: _busy,
                onPressed: _turnOn,
              ),
              const SizedBox(height: AppSpacing.xxs),
              AppButton.text(label: l10n.primerNotNow, onPressed: _busy ? null : () => Navigator.of(context).pop()),
            ],
          ),
        ),
      ],
    );
  }
}
