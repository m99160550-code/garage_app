import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/layout/window_class.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../application/brand_selection_controller.dart';
import 'widgets/brand_hero.dart';
import 'widgets/brand_panel.dart';

/// S-04 Brand selection (UI/UX spec S-04, reference screen 1).
///
/// * Phones: chrome hero with a frosted sheet that snaps between 52% and
///   92% of the screen. Tabs are pinned at the bottom of the sheet.
/// * Tablets portrait: same, with the sheet as a centred 640 pt panel.
/// * Tablets landscape: hero on the start half, brand panel on the end half.
/// * [addingVehicle]: opened from "Add vehicle", so it shows a close button,
///   no step dots, and asks before discarding a chosen brand.
/// * [editing]: opened from S-32 Edit vehicle. Continue goes on to S-05 in
///   edit mode, which returns to the edit screen; closing changes nothing.
class BrandSelectionScreen extends ConsumerStatefulWidget {
  const BrandSelectionScreen({super.key, this.addingVehicle = false, this.editing = false});

  final bool addingVehicle;
  final bool editing;

  @override
  ConsumerState<BrandSelectionScreen> createState() => _BrandSelectionScreenState();
}

class _BrandSelectionScreenState extends ConsumerState<BrandSelectionScreen> {
  final _sheet = DraggableScrollableController();
  bool _saving = false;

  static const _snapTop = 0.92;

  @override
  void dispose() {
    _sheet.dispose();
    super.dispose();
  }

  BrandSelectionController get _controller => ref.read(brandSelectionControllerProvider.notifier);

  void _expandSheet() {
    if (_sheet.isAttached) {
      _sheet.animateTo(_snapTop, duration: AppMotion.standard, curve: AppMotion.standardCurve);
    }
  }

  Future<void> _continue() async {
    setState(() => _saving = true);
    try {
      await _controller.submit(addingVehicle: widget.addingVehicle || widget.editing);
      if (!mounted) return;
      if (widget.editing) {
        // A new brand needs a model: S-05 takes this screen's place.
        context.pushReplacement('${AppRoutes.setupModel}?edit=1');
        return;
      }
      await context.push(widget.addingVehicle ? '${AppRoutes.setupModel}?add=1' : AppRoutes.setupModel);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _close(BrandSelectionState state) async {
    final hasChoice = !widget.editing && (state.selectedBrand != null || state.otherSelected);
    if (hasChoice) {
      final l10n = AppLocalizations.of(context);
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.discardVehicleTitle),
          content: Text(l10n.discardVehicleBody),
          actions: [
            AppButton.text(label: l10n.actionKeepEditing, onPressed: () => Navigator.pop(context, false)),
            AppButton.destructiveText(label: l10n.actionDiscard, onPressed: () => Navigator.pop(context, true)),
          ],
        ),
      );
      if (discard != true) return;
    }
    if (mounted) context.pop();
  }

  BrandPanelActions _actions(BrandSelectionState state) => BrandPanelActions(
    onQuery: _controller.setQuery,
    onTab: _controller.setTab,
    onToggleBrand: _controller.toggleBrand,
    onToggleOther: () => _controller.toggleOther(),
    onAddAsOther: (name) => _controller.toggleOther(prefill: name),
    onOtherName: _controller.setOtherName,
    onContinue: _continue,
    onSearchExpanded: _expandSheet,
  );

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(brandSelectionControllerProvider);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bgBase,
      body: asyncState.when(
        loading: () => const DelayedSkeleton(),
        error: (_, _) => Center(
          child: AppButton.secondary(
            label: AppLocalizations.of(context).actionRetry,
            onPressed: () => ref.invalidate(brandSelectionControllerProvider),
            expand: false,
          ),
        ),
        data: (state) => switch (WindowClass.of(context)) {
          WindowClass.expanded => _buildSplit(state),
          WindowClass.medium => _buildWithSheet(state, panelMaxWidth: 640, snapLow: 0.6),
          WindowClass.compact => _buildWithSheet(state, panelMaxWidth: double.infinity, snapLow: 0.52),
        },
      ),
    );
  }

  /// At the largest text sizes, the title is hidden and the sheet opens at
  /// its top snap (spec S-04 Accessibility).
  bool get _largeText => MediaQuery.textScalerOf(context).scale(16) / 16 > 1.5;

  Widget _buildWithSheet(BrandSelectionState state, {required double panelMaxWidth, required double snapLow}) {
    final onClose = widget.addingVehicle || widget.editing ? () => _close(state) : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        return Stack(
          children: [
            // Hero dims to 40% as the sheet rises to its top snap.
            Positioned.fill(
              child: ListenableBuilder(
                listenable: _sheet,
                builder: (context, child) {
                  final size = _sheet.isAttached ? _sheet.size : snapLow;
                  final t = ((size - snapLow) / (_snapTop - snapLow)).clamp(0.0, 1.0);
                  return Opacity(opacity: 1 - 0.6 * t, child: child);
                },
                child: Align(
                  alignment: Alignment.topCenter,
                  child: BrandHero(onClose: onClose, showTitle: !_largeText),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: panelMaxWidth),
                child: DraggableScrollableSheet(
                  controller: _sheet,
                  initialChildSize: _largeText ? _snapTop : snapLow,
                  minChildSize: snapLow,
                  maxChildSize: _snapTop,
                  snap: true,
                  snapSizes: [snapLow, _snapTop],
                  builder: (context, scrollController) => BrandPanelSurface(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
                    child: SafeArea(
                      top: false,
                      child: BrandPanel(
                        state: state,
                        actions: _actions(state),
                        saving: _saving,
                        scrollController: scrollController,
                        dragHandle: _DragHandle(
                          controller: _sheet,
                          availableHeight: height,
                          snaps: [snapLow, _snapTop],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Tablet landscape: hero on the start half, panel on the end half.
  Widget _buildSplit(BrandSelectionState state) {
    final onClose = widget.addingVehicle || widget.editing ? () => _close(state) : null;
    return Row(
      children: [
        Expanded(
          child: BrandHero(onClose: onClose, showTitle: !_largeText),
        ),
        Expanded(
          child: BrandPanelSurface(
            borderRadius: const BorderRadiusDirectional.horizontal(start: Radius.circular(AppRadii.sheet)),
            child: SafeArea(
              child: BrandPanel(state: state, actions: _actions(state), saving: _saving, tabsOnTop: true, columns: 2),
            ),
          ),
        ),
      ],
    );
  }
}

/// Drag handle (36 × 4 pt) with a 44 pt tall drag area. Dragging moves the
/// sheet; releasing snaps to the nearest stop.
class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.controller, required this.availableHeight, required this.snaps});

  final DraggableScrollableController controller;
  final double availableHeight;
  final List<double> snaps;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (details) {
        if (!controller.isAttached) return;
        final next = controller.size - details.delta.dy / availableHeight;
        controller.jumpTo(next.clamp(snaps.first, snaps.last));
      },
      onVerticalDragEnd: (_) {
        if (!controller.isAttached) return;
        final nearest = snaps.reduce((a, b) => (controller.size - a).abs() < (controller.size - b).abs() ? a : b);
        controller.animateTo(nearest, duration: AppMotion.standard, curve: AppMotion.standardCurve);
      },
      child: SizedBox(
        height: 28,
        width: double.infinity,
        child: Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: context.colors.borderStrong,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
          ),
        ),
      ),
    );
  }
}
