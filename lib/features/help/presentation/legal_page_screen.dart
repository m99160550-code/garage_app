import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/app_formatters.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';

/// The privacy policy and terms open in the in-app browser (spec S-31
/// item 4). Until a browser plugin is added, this stand-in shows the
/// browser's frame (close, title, address) and which page would load.
class LegalPageScreen extends StatelessWidget {
  const LegalPageScreen({super.key, required this.title, required this.url});

  final String title;
  final String url;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final host = Uri.parse(url).host;
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(tooltip: l10n.actionClose, icon: const Icon(Icons.close), onPressed: () => context.pop()),
        centerTitle: true,
        backgroundColor: colors.bgSheet,
        surfaceTintColor: Colors.transparent,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: text.label),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 12, color: colors.textSecondary),
                const SizedBox(width: AppSpacing.xxs),
                Text(ltrValue(host), style: text.caption.copyWith(color: colors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(child: Icon(Icons.public, size: 48, color: colors.textTertiary)),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.legalLoadsFrom(ltrValue(url)),
                style: text.bodyS.copyWith(color: colors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
