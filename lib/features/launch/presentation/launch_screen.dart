import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_mark.dart';
import '../../session/application/session_providers.dart';
import '../application/launch_route.dart';

/// S-01 Launch screen (UI/UX spec S-01).
///
/// Shows the app mark while the session loads, for at least
/// [minimumDisplay], then hands over to the right first screen with a
/// 250 ms fade (the destination route's transition).
class LaunchScreen extends ConsumerStatefulWidget {
  const LaunchScreen({super.key});

  /// Avoids a flash when local data loads very fast (spec: at least 300 ms).
  static const minimumDisplay = Duration(milliseconds: 300);

  @override
  ConsumerState<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends ConsumerState<LaunchScreen> {
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final minimumDisplay = Future<void>.delayed(LaunchScreen.minimumDisplay);
    try {
      final session = await ref.read(appSessionProvider.future);
      await minimumDisplay;
      if (!mounted) return;
      context.go(resolveLaunchRoute(session), extra: const LaunchHandover());
    } catch (_) {
      await minimumDisplay;
      if (mounted) setState(() => _failed = true);
    }
  }

  void _retry() {
    setState(() => _failed = false);
    ref.invalidate(appSessionProvider);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;

    final brand = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppMark(size: 72),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.appName,
          style: text.titleM.copyWith(color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );

    return Scaffold(
      backgroundColor: colors.bgBase,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenMargin),
            child: AnimatedSwitcher(
              duration: AppMotion.standard,
              child: _failed
                  ? _LaunchError(key: const ValueKey('error'), brand: brand, onRetry: _retry)
                  : Semantics(
                      key: const ValueKey('loading'),
                      container: true,
                      liveRegion: true,
                      label: l10n.launchLoadingLabel,
                      child: ExcludeSemantics(child: brand),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown only if local data can't be read. Offers a retry.
class _LaunchError extends StatelessWidget {
  const _LaunchError({super.key, required this.brand, required this.onRetry});

  final Widget brand;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(child: brand),
          const SizedBox(height: AppSpacing.xxl),
          Semantics(
            liveRegion: true,
            header: true,
            child: Text(l10n.launchErrorTitle, style: text.titleL, textAlign: TextAlign.center),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.launchErrorBody,
            style: text.body.copyWith(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(label: l10n.actionRetry, onPressed: onRetry),
        ],
      ),
    );
  }
}
