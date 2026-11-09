import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// The frame of a setting screen (S-25 to S-27): a title with back, or,
/// [embedded] in the iPad landscape detail pane, the title alone. Content
/// is at most 600 pt wide.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.title, required this.body, this.embedded = false});

  final String title;
  final Widget body;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        title: Text(title, style: context.text.titleM),
        centerTitle: true,
        automaticallyImplyLeading: !embedded,
        backgroundColor: colors.bgBase,
        surfaceTintColor: Colors.transparent,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: body),
      ),
    );
  }
}
