import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import 'app_nav_destination.dart';

/// Navigation rail on tablets (UI/UX spec 2.2): 88 pt on the start edge,
/// `bg.sheet`, icon above label, 56 pt per item, the selected item in a
/// `surface.raised` pill. "Add" is a 56 pt round primary button at the top.
class AppNavRail extends StatelessWidget {
  const AppNavRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.addLabel,
    required this.onAdd,
  });

  static const width = 88.0;

  final List<AppNavDestination> destinations;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;
  final String addLabel;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: colors.bgSheet,
        border: BorderDirectional(end: BorderSide(color: colors.borderSubtle)),
      ),
      child: SafeArea(
        right: false,
        left: false,
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            Tooltip(
              message: addLabel,
              child: Semantics(
                button: true,
                label: addLabel,
                excludeSemantics: true,
                child: Material(
                  color: colors.buttonPrimaryBg,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onAdd,
                    child: SizedBox.square(dimension: 56, child: Icon(Icons.add, color: colors.textOnLight)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            for (var i = 0; i < destinations.length; i++)
              _RailItem(destination: destinations[i], selected: i == selectedIndex, onTap: () => onSelected(i)),
          ],
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({required this.destination, required this.selected, required this.onTap});

  final AppNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = selected ? colors.textPrimary : colors.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.row),
          child: SizedBox(
            width: 72,
            height: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: AppMotion.standard,
                  width: 56,
                  height: 32,
                  decoration: BoxDecoration(
                    color: selected ? colors.surfaceRaised : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Icon(selected ? destination.selectedIcon : destination.icon, color: color),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(destination.label, style: context.text.caption.copyWith(color: color), maxLines: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
