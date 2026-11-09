import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/item_due.dart';
import '../../domain/severity.dart';
import '../item_visuals.dart';

/// One schedule item (spec S-14 item 5): icon tile, name with a
/// "Critical" marker, the due line, the interval progress bar, the status
/// badge and a chevron. Not applicable rows are dimmed.
///
/// With [highlight], the border pulses twice in `accent.primary` (an item
/// opened from a deep link).
class ScheduleItemRow extends StatefulWidget {
  const ScheduleItemRow({
    super.key,
    required this.due,
    required this.name,
    required this.dueText,
    required this.progress,
    required this.onTap,
    this.selected = false,
    this.highlight = false,
    this.compact = false,
  });

  final ItemDue due;
  final String name;
  final String dueText;

  /// 0–1, or `null` to hide the bar (Unknown, Not applicable).
  final double? progress;
  final VoidCallback onTap;

  /// Selected in the iPad master-detail layout.
  final bool selected;
  final bool highlight;

  /// 64 pt high (S-18 lists); pass no [progress] with it.
  final bool compact;

  @override
  State<ScheduleItemRow> createState() => _ScheduleItemRowState();
}

class _ScheduleItemRowState extends State<ScheduleItemRow> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

  @override
  void initState() {
    super.initState();
    if (widget.highlight) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
        for (var i = 0; i < 2 && mounted; i++) {
          await _pulse.forward(from: 0);
          if (mounted) await _pulse.reverse();
        }
      });
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final due = widget.due;
    final (badge, tone, icon) = scheduleStatusBadge(l10n, due);
    final notApplicable = due.status == ItemStatus.notApplicable;
    final critical = due.item.severity == Severity.critical;

    final row = Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.md, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: colors.surfaceRaised, borderRadius: BorderRadius.circular(12)),
            child: Icon(scheduleItemIcon(due.item.code), size: 22, color: colors.textPrimary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(widget.name, style: text.titleM),
                    if (critical) Text(l10n.scheduleCritical, style: text.caption.copyWith(color: colors.textTertiary)),
                  ],
                ),
                Text(widget.dueText, style: text.bodyS.copyWith(color: colors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            flex: 0,
            child: StatusBadge(label: badge, tone: tone, icon: icon),
          ),
          Icon(Icons.chevron_right, color: colors.textTertiary),
        ],
      ),
    );
    // The bar runs the full width of the row, lined up with the text.
    final content = widget.progress == null
        ? row
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              row,
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.md + 40 + AppSpacing.sm,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: IntervalBar(progress: widget.progress!, status: due.status, snoozed: due.snoozed),
              ),
            ],
          );

    return Semantics(
      button: true,
      selected: widget.selected,
      label: l10n.scheduleRowSemantic(
        [widget.name, if (critical) l10n.scheduleCritical].join(', '),
        widget.dueText,
        badge,
      ),
      excludeSemantics: true,
      child: Opacity(
        opacity: notApplicable ? 0.6 : 1,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) => Material(
            color: widget.selected ? colors.surfaceRaised : colors.surfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.row),
              side: BorderSide(
                color: Color.lerp(
                  widget.selected ? colors.borderStrong : colors.borderSubtle,
                  colors.accentPrimary,
                  _pulse.value,
                )!,
                width: 1 + _pulse.value,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
          child: InkWell(
            onTap: widget.onTap,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: widget.compact ? 64 : 84),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

/// How much of the interval is used (spec S-14): green until due soon,
/// then amber, and red with stripes once overdue (full).
class IntervalBar extends StatelessWidget {
  const IntervalBar({super.key, required this.progress, required this.status, required this.snoozed, this.height = 4});

  final double progress;
  final ItemStatus status;
  final bool snoozed;

  /// 4 pt in lists, 8 pt on the item detail.
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final overdue = status == ItemStatus.overdue;
    final color = switch (status) {
      ItemStatus.overdue => colors.danger,
      ItemStatus.dueSoon => snoozed ? colors.textTertiary : colors.warning,
      _ => colors.success,
    };
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: colors.surfacePressed),
              FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: overdue ? 1 : progress.clamp(0.02, 1.0),
                child: overdue
                    ? CustomPaint(
                        painter: _StripePainter(color: color, stripe: colors.dangerContainer),
                      )
                    : ColoredBox(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  _StripePainter({required this.color, required this.stripe});

  final Color color;
  final Color stripe;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = color);
    final paint = Paint()
      ..color = stripe
      ..strokeWidth = 2;
    for (var x = -size.height; x < size.width; x += 6) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height * math.sqrt1_2 * 2, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_StripePainter old) => old.color != color || old.stripe != stripe;
}
