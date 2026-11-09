import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/generated/app_localizations.dart';
import '../layout/window_class.dart';
import '../theme/app_tokens.dart';
import '../widgets/navigation/app_nav_destination.dart';
import '../widgets/navigation/app_nav_rail.dart';
import '../widgets/navigation/floating_nav_bar.dart';
import '../../features/add_menu/presentation/add_menu_sheet.dart';

/// The main tabs (UI/UX spec 2.2): Garage, History and Profile, each with
/// its own navigation stack, plus "Add", which opens the Add menu (S-23)
/// over the current tab instead of being a page.
///
/// Phones: the floating pill bar over the content. Tablets: a rail on the
/// start edge.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  /// Bar position of "Add": between History and Profile.
  static const _addIndex = 2;

  /// Branch order in the router: Garage, History, Profile.
  static int _branchFor(int barIndex) => barIndex < _addIndex ? barIndex : barIndex - 1;
  static int _barFor(int branch) => branch < _addIndex ? branch : branch + 1;

  void _openAdd(BuildContext context) => openAddMenu(context);

  /// Tapping the current tab again returns to its first screen.
  void _goBranch(int branch) => shell.goBranch(branch, initialLocation: branch == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tabs = [
      AppNavDestination(label: l10n.navGarage, icon: Icons.directions_car_outlined, selectedIcon: Icons.directions_car),
      AppNavDestination(label: l10n.navHistory, icon: Icons.history, selectedIcon: Icons.history),
      AppNavDestination(label: l10n.navProfile, icon: Icons.person_outline, selectedIcon: Icons.person),
    ];

    if (!WindowClass.of(context).isCompact) {
      return Scaffold(
        body: Row(
          children: [
            AppNavRail(
              destinations: tabs,
              selectedIndex: shell.currentIndex,
              onSelected: _goBranch,
              addLabel: l10n.navAdd,
              onAdd: () => _openAdd(context),
            ),
            Expanded(child: shell),
          ],
        ),
      );
    }

    final barItems = [
      ...tabs.take(_addIndex),
      AppNavDestination(label: l10n.navAdd, icon: Icons.add, selectedIcon: Icons.add),
      ...tabs.skip(_addIndex),
    ];
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: FloatingNavBarInset(height: FloatingNavBar.height + AppSpacing.xs, child: shell),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingNavBar(
              destinations: barItems,
              selectedIndex: _barFor(shell.currentIndex),
              onSelected: (i) => i == _addIndex ? _openAdd(context) : _goBranch(_branchFor(i)),
            ),
          ),
        ],
      ),
    );
  }
}
