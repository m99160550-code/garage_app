import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_skeleton.dart';
import '../../../core/format/app_formatters.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/status_badge.dart';
import '../../maintenance/presentation/item_visuals.dart';
import '../application/record_detail.dart';
import '../domain/service_record.dart';
import 'widgets/service_record_row.dart';

/// "Engine oil", "Engine oil and Oil filter", "A, B and C".
String joinWithAnd(AppLocalizations l10n, List<String> names, String languageCode) {
  if (names.length < 2) return names.join();
  final head = names.sublist(0, names.length - 1).join(languageCode == 'ar' ? '، ' : ', ');
  return l10n.listAnd(head, names.last);
}

/// S-21 Service record detail (UI/UX spec S-21, FR-SVC-05, FR-SVC-06):
/// the date and type, the facts, the items covered (each opens S-15),
/// notes and when it was added. "Edit" opens S-22; the overflow menu
/// deletes it, with Undo.
///
/// [sideSheet]: shown beside the list on iPad portrait (a close button
/// instead of back). [embedded]: the iPad landscape detail pane (no back
/// or close; stays on screen after a delete).
class ServiceRecordScreen extends ConsumerStatefulWidget {
  const ServiceRecordScreen({super.key, required this.recordId, this.sideSheet = false, this.embedded = false});

  final String recordId;
  final bool sideSheet;
  final bool embedded;

  /// Content never gets wider than this (spec 2.3).
  static const maxContentWidth = 720.0;

  @override
  ConsumerState<ServiceRecordScreen> createState() => _ServiceRecordScreenState();
}

class _ServiceRecordScreenState extends ConsumerState<ServiceRecordScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final detail = ref.watch(recordDetailProvider(widget.recordId));
    final data = detail.value;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: !widget.embedded && !widget.sideSheet,
        leading: widget.sideSheet ? CloseButton(onPressed: () => context.pop()) : null,
        actions: [
          if (data != null) ...[
            AppButton.text(
              label: l10n.actionEdit,
              onPressed: () => context.push(AppRoutes.logService(recordId: data.record.id)),
            ),
            PopupMenuButton<String>(
              tooltip: l10n.actionMoreOptions,
              icon: Icon(Icons.more_horiz, color: colors.textPrimary),
              color: colors.surfaceRaised,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.row)),
              onSelected: (_) => _delete(data),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Text(l10n.actionDelete, style: TextStyle(color: colors.destructiveText)),
                ),
              ],
            ),
          ],
        ],
      ),
      body: switch (detail) {
        AsyncData(value: null) => Center(child: Text(l10n.recordGone, style: context.text.body)),
        AsyncData(value: final RecordDetail data) => Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: ServiceRecordScreen.maxContentWidth),
            child: _content(data),
          ),
        ),
        _ => const DelayedSkeleton(),
      },
    );
  }

  Widget _content(RecordDetail data) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final language = Localizations.localeOf(context).languageCode;
    final format = AppFormatters(languageCode: language);
    final record = data.record;
    // Inside the History tab, items open there too (spec S-21 item 4).
    final inHistory = GoRouterState.of(context).uri.path.startsWith(AppRoutes.history);

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenMargin, 0, AppSpacing.screenMargin, AppSpacing.xxl),
      children: [
        // 2. Header: the date and the type badge.
        Semantics(header: true, child: Text(format.mediumDate(record.date), style: text.titleL)),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: StatusBadge(label: serviceTypeLabel(l10n, record.type), icon: _typeIcon(record.type)),
        ),
        const SizedBox(height: AppSpacing.lg),
        // 3. Facts.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Column(
            children: [
              _Fact(
                label: l10n.recordFactOdometer,
                value: record.odometerKm == null ? '—' : scheduleDistance(l10n, record.odometerKm!, data.unit),
              ),
              _Fact(
                label: l10n.recordFactCost,
                value: record.hasCost ? format.money(record.costMinor!, record.currency!) : '—',
              ),
              _Fact(label: l10n.recordFactShop, value: (record.shopName?.isNotEmpty ?? false) ? record.shopName! : '—'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        // 4. Items covered (each opens S-15).
        Semantics(header: true, child: Text(l10n.recordItemsTitle, style: text.titleM)),
        const SizedBox(height: AppSpacing.xs),
        if (record.itemCodes.isEmpty)
          Text(l10n.recordNoItems, style: text.bodyS.copyWith(color: colors.textSecondary))
        else
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xxs,
            children: [
              for (final code in record.itemCodes)
                _ItemChip(
                  code: code,
                  name: switch (data.itemNames[code]) {
                    (final en, final ar) => language == 'ar' ? ar : en,
                    null => code,
                  },
                  onTap: () => context.push(inHistory ? AppRoutes.historyItem(code) : AppRoutes.garageItem(code)),
                ),
            ],
          ),
        const SizedBox(height: AppSpacing.xl),
        // 5. Notes.
        Semantics(header: true, child: Text(l10n.recordNotesTitle, style: text.titleM)),
        const SizedBox(height: AppSpacing.xs),
        if (record.notes?.trim().isNotEmpty ?? false)
          Text(record.notes!, style: text.body)
        else
          Text(l10n.recordNoNotes, style: text.body.copyWith(color: colors.textTertiary)),
        const SizedBox(height: AppSpacing.xl),
        // 7. When it was added.
        Text(
          l10n.recordAdded(format.dateTime(record.createdAt)),
          style: text.caption.copyWith(color: colors.textTertiary),
        ),
      ],
    );
  }

  static IconData _typeIcon(ServiceType type) => switch (type) {
    ServiceType.maintenance => Icons.build_outlined,
    ServiceType.repair => Icons.handyman_outlined,
    ServiceType.inspection => Icons.fact_check_outlined,
    ServiceType.other => Icons.more_horiz,
  };

  /// "Delete this service?" naming the items that go back (BR-SVC-04),
  /// then a toast with Undo (8 s).
  Future<void> _delete(RecordDetail data) async {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final names = [for (final item in data.itemsSetByRecord) item.name(language)];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.recordDeleteTitle),
        content: Text(
          names.isEmpty ? l10n.recordDeleteBodyNone : l10n.recordDeleteBodyItems(joinWithAnd(l10n, names, language)),
        ),
        actions: [
          AppButton.text(label: l10n.actionCancel, onPressed: () => Navigator.pop(context, false)),
          AppButton.destructiveText(label: l10n.actionDelete, onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Read before the await: this screen may be gone when Undo is tapped.
    final actions = ref.read(serviceRecordActionsProvider);
    final deleted = await actions.delete(data.record);
    if (!mounted) return;
    showAppToast(context, l10n.recordDeleted, actionLabel: l10n.actionUndo, onAction: () => actions.undo(deleted));
    if (!widget.embedded) context.pop();
  }
}

/// One fact: label at the start, value at the end.
class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return Semantics(
      container: true,
      label: '$label, $value',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(label, style: text.bodyS.copyWith(color: context.colors.textTertiary)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              flex: 2,
              child: Text(value, style: text.body, textAlign: TextAlign.end),
            ),
          ],
        ),
      ),
    );
  }
}

/// A covered item: its icon, name and a chevron; opens S-15.
class _ItemChip extends StatelessWidget {
  const _ItemChip({required this.code, required this.name, required this.onTap});

  final String code;
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).recordItemSemantic(name),
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
        child: Center(
          widthFactor: 1,
          child: Material(
            color: colors.surfaceCard,
            shape: StadiumBorder(side: BorderSide(color: colors.borderSubtle)),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 40),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.sm, 0, AppSpacing.xs, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(scheduleItemIcon(code), size: 18, color: colors.textSecondary),
                      const SizedBox(width: AppSpacing.xxs),
                      Flexible(child: Text(name, style: context.text.label)),
                      Icon(Icons.chevron_right, size: 18, color: colors.textTertiary),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
