import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// TEMPORARY: stands in for screens that haven't been built yet, so every
/// route works while screens are delivered one at a time. Each use is
/// replaced by the real screen in its own step. Not localised on purpose.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.screenId, required this.title});

  final String screenId;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            if (GoRouter.of(context).canPop())
              const Align(alignment: AlignmentDirectional.topStart, child: BackButton()),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenMargin),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(screenId, style: context.text.overline.copyWith(color: context.colors.textTertiary)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(title, style: context.text.titleL, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Coming in a later step',
                      style: context.text.bodyS.copyWith(color: context.colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
