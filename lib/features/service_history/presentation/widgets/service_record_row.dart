import 'package:flutter/material.dart';

import '../../../../core/format/app_formatters.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../maintenance/presentation/item_visuals.dart';
import '../../../settings/domain/distance_unit.dart';
import '../../domain/service_record.dart';

/// "Maintenance", "Repair", "Inspection", "Other".
String serviceTypeLabel(AppLocalizations l10n, ServiceType type) => switch (type) {
  ServiceType.maintenance => l10n.serviceTypeMaintenance,
  ServiceType.repair => l10n.serviceTypeRepair,
  ServiceType.inspection => l10n.serviceTypeInspection,
  ServiceType.other => l10n.serviceTypeOther,
};

/// A record's title (spec S-20 item 4): the covered items ("Engine oil,
/// Oil filter"), or the service type when it covers none.
String serviceRecordTitle(
  AppLocalizations l10n,
  ServiceRecord record, {
  required Map<String, (String, String)> itemNames,
  required String languageCode,
}) {
  final names = [
    for (final code in record.itemCodes)
      if (itemNames[code] case (final en, final ar)) languageCode == 'ar' ? ar : en,
  ];
  return names.isEmpty ? serviceTypeLabel(l10n, record.type) : names.join(languageCode == 'ar' ? '، ' : ', ');
}

/// One service record (spec S-20 item 4, also used by S-19): a date block,
/// the title, "Shop · 54,900 km", and the cost in the record's own
/// currency (BR-EXP-05) or "—". With [excluded], the cost is dimmed and a
/// "Not in total" note explains why (BR-EXP-03).
class ServiceRecordRow extends StatelessWidget {
  const ServiceRecordRow({
    super.key,
    required this.record,
    required this.title,
    required this.unit,
    required this.onTap,
    this.excluded = false,
  });

  final ServiceRecord record;
  final String title;
  final DistanceUnit unit;
  final VoidCallback onTap;
  final bool excluded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final language = Localizations.localeOf(context).languageCode;
    final format = AppFormatters(languageCode: language);

    final detail =
        [
              if (record.shopName case final shop? when shop.isNotEmpty) shop,
              if (record.odometerKm case final km?) scheduleDistance(l10n, km, unit),
            ]
            // In Arabic each part starts with an RLM so a Latin shop name can't
            // pull "كم" away from its number.
            .map((part) => language == 'ar' ? '\u200F$part' : part)
            .join(' · ');
    final cost = record.hasCost ? format.money(record.costMinor!, record.currency!) : '—';

    return Semantics(
      button: true,
      label: l10n.serviceRecordSemantic(
        format.mediumDate(record.date),
        title,
        detail,
        excluded ? '$cost, ${l10n.spendNotInTotal}' : cost,
      ),
      excludeSemantics: true,
      child: Material(
        color: colors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.row),
          side: BorderSide(color: colors.borderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 80),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  // Date block, 48 × 48.
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.surfaceRaised,
                      borderRadius: BorderRadius.circular(AppRadii.input),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(format.integer(record.date.day), style: text.titleM.copyWith(height: 1.1)),
                        FittedBox(
                          child: Text(
                            format.monthShort(record.date),
                            style: text.caption.copyWith(color: colors.textSecondary, height: 1.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, style: text.titleM, maxLines: 2, overflow: TextOverflow.ellipsis),
                        if (detail.isNotEmpty) Text(detail, style: text.bodyS.copyWith(color: colors.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cost,
                        style: text.titleM.copyWith(
                          color: excluded ? colors.textTertiary : colors.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (excluded)
                        Text(l10n.spendNotInTotal, style: text.caption.copyWith(color: colors.textTertiary)),
                    ],
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
