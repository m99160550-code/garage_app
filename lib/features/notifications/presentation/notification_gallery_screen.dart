import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/app_formatters.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_segmented_control.dart';
import '../../maintenance/domain/item_due.dart';
import '../../maintenance/domain/schedule_item.dart';
import '../../maintenance/domain/severity.dart';
import '../../settings/application/language_settings.dart';
import '../application/reminder_notifications.dart';
import '../domain/reminder_plan.dart';
import 'widgets/lock_screen_notification.dart';

/// The sample day of the gallery.
final _galleryDay = DateTime(2026, 11, 7);

ItemDue _due(String code, String en, String ar, Severity severity, ItemStatus status, int days) => ItemDue(
  item: ScheduleItem(
    id: 'sample-$code',
    vehicleId: 'veh-camry',
    code: code,
    nameEn: en,
    nameAr: ar,
    severity: severity,
    intervalMonths: 12,
  ),
  status: status,
  nextDueDate: _galleryDay.add(Duration(days: days)),
  overdueSince: status == ItemStatus.overdue ? _galleryDay.add(Duration(days: days)) : null,
);

/// The S-35 table: due soon, due tomorrow, overdue, a bundle and the
/// mileage nudge.
List<PlannedReminder> get sampleReminders {
  final oil = _due('engine_oil', 'Engine oil', 'زيت المحرك', Severity.major, ItemStatus.dueSoon, 7);
  final fluid = _due('brake_fluid', 'Brake fluid', 'زيت الفرامل', Severity.critical, ItemStatus.dueSoon, 1);
  final brakes = _due('brake_pads', 'Brake pads', 'تيل الفرامل', Severity.critical, ItemStatus.overdue, -3);
  ItemReminder at(ItemDue d) => itemReminderOn(d, _galleryDay)!;
  return [
    SingleItemReminder('veh-camry', _galleryDay, at(oil)),
    SingleItemReminder('veh-camry', _galleryDay, at(fluid)),
    SingleItemReminder('veh-camry', _galleryDay, at(brakes)),
    BundleReminder('veh-camry', _galleryDay, [at(brakes), at(fluid), at(oil)]),
    MileageNudge('veh-camry', _galleryDay, 34),
  ];
}

/// Design review for S-35 (development builds only): every reminder type
/// on a lock screen, built by the same code that schedules them, in the
/// app language and either digit style.
class NotificationGalleryScreen extends ConsumerStatefulWidget {
  const NotificationGalleryScreen({super.key});

  @override
  ConsumerState<NotificationGalleryScreen> createState() => _NotificationGalleryScreenState();
}

class _NotificationGalleryScreenState extends ConsumerState<NotificationGalleryScreen> {
  DigitStyle? _digits;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final language = Localizations.localeOf(context).languageCode;
    final digits = _digits ?? ref.watch(digitStyleProvider).value ?? DigitStyle.western;
    final numbers = AppFormatters(languageCode: language, digits: digits);
    final notifications = [
      for (final reminder in sampleReminders)
        buildNotification(
          reminder,
          l10n: l10n,
          languageCode: language,
          digits: digits,
          // A nickname stays as the user typed it.
          vehicleName: 'Family Camry',
          itemName: (r) => r.due.item.name(language),
        ),
    ];

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B2433), Color(0xFF0B0C0E)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const SizedBox(height: AppSpacing.lg),
              Text(
                ltrValue('${numbers.integer(9)}:${numbers.integer(0)}${numbers.integer(0)}'),
                style: text.displayHero.copyWith(color: colors.textPrimary, fontSize: 72),
                textAlign: TextAlign.center,
              ),
              Text(
                numbers.weekdayDate(_galleryDay),
                style: text.body.copyWith(color: colors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppSegmentedControl<DigitStyle>(
                semanticPrefix: 'Digits',
                selected: digits,
                onChanged: (d) => setState(() => _digits = d),
                // One unbroken run each, so bidi keeps the order in both directions.
                segments: [(DigitStyle.western, '0123'), (DigitStyle.arabicIndic, '٠١٢٣')],
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final n in notifications) ...[
                LockScreenNotification(notification: n),
                const SizedBox(height: AppSpacing.xs),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
