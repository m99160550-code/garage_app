import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/help_article.dart';

String helpCategoryLabel(AppLocalizations l10n, HelpCategory category) => switch (category) {
  HelpCategory.gettingStarted => l10n.helpCatGettingStarted,
  HelpCategory.healthScore => l10n.helpCatHealthScore,
  HelpCategory.reminders => l10n.helpCatReminders,
  HelpCategory.backupSync => l10n.helpCatBackup,
  HelpCategory.privacy => l10n.helpCatPrivacy,
};

IconData helpCategoryIcon(HelpCategory category) => switch (category) {
  HelpCategory.gettingStarted => Icons.flag_outlined,
  HelpCategory.healthScore => Icons.monitor_heart_outlined,
  HelpCategory.reminders => Icons.notifications_none,
  HelpCategory.backupSync => Icons.cloud_outlined,
  HelpCategory.privacy => Icons.lock_outline,
};
