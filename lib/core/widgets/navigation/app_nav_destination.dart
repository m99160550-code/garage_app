import 'package:flutter/widgets.dart';

/// One item of the main navigation (UI/UX spec 2.2).
class AppNavDestination {
  const AppNavDestination({required this.label, required this.icon, required this.selectedIcon});

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
