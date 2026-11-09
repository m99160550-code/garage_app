import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import 'app_nav_destination.dart';

/// The floating pill bar on phones (UI/UX spec 2.2): centred, 8 pt above
/// the home indicator, 56 pt high, `bg.sheet` at 88% with blur, a subtle
/// border and shadow. The selected item has a `surface.raised` inner pill
/// with a filled icon and label; the others show their label only.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({super.key, required this.destinations, required this.selectedIndex, required this.onSelected});

  /// Bar height, used by screens for their bottom clearance.
  static const height = 56.0;

  /// Scrollable content gets this bottom padding so it clears the bar.
  static const contentClearance = 96.0;

  final List<AppNavDestination> destinations;

  /// `null` when no tab is selected (never the case today).
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // The bar keeps its shape with large text: labels scale up to 1.3× and
    // then shrink to fit (like the system tab bar).
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(textScaler: media.textScaler.clamp(maxScaleFactor: 1.3)),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xs),
        child: Center(
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 24, offset: Offset(0, 8))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  constraints: const BoxConstraints(minHeight: height),
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: colors.bgSheet.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  // As wide as its items; shrinks to fit narrow screens.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < destinations.length; i++)
                          _Item(destination: destinations[i], selected: i == selectedIndex, onTap: () => onSelected(i)),
                      ],
                    ),
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

class _Item extends StatelessWidget {
  const _Item({required this.destination, required this.selected, required this.onTap});

  final AppNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = Text(
      destination.label,
      style: context.text.label.copyWith(color: selected ? colors.textPrimary : colors.textSecondary),
      maxLines: 1,
    );
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: AnimatedContainer(
          duration: AppMotion.standard,
          curve: AppMotion.standardCurve,
          constraints: const BoxConstraints(minWidth: 64, minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colors.surfaceRaised : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (selected) ...[
                Icon(destination.selectedIcon, size: 20, color: colors.textPrimary),
                const SizedBox(width: 6),
              ],
              label,
            ],
          ),
        ),
      ),
    );
  }
}

/// Tells widgets under the tab shell how much room the floating bar takes
/// at the bottom, so toasts float above it (spec 1.7 "Toast").
class FloatingNavBarInset extends InheritedWidget {
  const FloatingNavBarInset({super.key, required this.height, required super.child});

  final double height;

  static double of(BuildContext context) => context.getInheritedWidgetOfExactType<FloatingNavBarInset>()?.height ?? 0;

  @override
  bool updateShouldNotify(FloatingNavBarInset oldWidget) => height != oldWidget.height;
}
