import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../domain/baseline_group.dart';

/// "Oil change or service", "Brakes", "Tires", "Battery" (spec S-07).
String baselineGroupLabel(AppLocalizations l10n, BaselineGroup group) => switch (group) {
  BaselineGroup.oilService => l10n.baselineOilService,
  BaselineGroup.brakes => l10n.baselineBrakes,
  BaselineGroup.tires => l10n.baselineTires,
  BaselineGroup.battery => l10n.baselineBattery,
};

/// Oil can, brake disc, tire, battery (spec S-07 item 4).
IconData baselineGroupIcon(BaselineGroup group) => switch (group) {
  BaselineGroup.oilService => Icons.oil_barrel_outlined,
  BaselineGroup.brakes => Icons.album_outlined,
  BaselineGroup.tires => Icons.tire_repair_outlined,
  BaselineGroup.battery => Icons.battery_charging_full_outlined,
};
