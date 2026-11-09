import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../application/account_providers.dart';
import '../../domain/account.dart';

/// Sync indicator (spec S-34): for Owners with something to say, an icon
/// in the header. Spinning `sync` while sending, a count badge for
/// waiting changes, `cloud-off` when offline. [needsReview] adds an amber
/// dot (a mileage reading to check, BR-SYN-03). Nothing when everything
/// is synced, and nothing for Guests. Tapping it opens Profile, where the
/// account card says more.
class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key, this.needsReview = false});

  final bool needsReview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final account = ref.watch(accountProvider).value;
    if (account is! OwnerAccount) return const SizedBox.shrink();
    final sync = account.sync;
    if (sync is Synced && !needsReview) return const SizedBox.shrink();

    final (Widget icon, String label) = switch (sync) {
      SyncInProgress() => (_Spinning(child: Icon(Icons.sync, color: colors.accentPrimary)), l10n.syncSyncing),
      SyncPending(:final count) => (
        Badge(
          label: Text('$count'),
          backgroundColor: colors.accentPrimary,
          textColor: colors.textOnLight,
          child: Icon(Icons.cloud_upload_outlined, color: colors.textPrimary),
        ),
        l10n.syncPending(count),
      ),
      SyncOffline() => (Icon(Icons.cloud_off_outlined, color: colors.textSecondary), l10n.syncOffline),
      Synced() => (Icon(Icons.cloud_done_outlined, color: colors.textSecondary), l10n.syncNeedsReview),
    };
    final tooltip = needsReview && sync is! Synced ? '$label, ${l10n.syncNeedsReview}' : label;

    return IconButton(
      tooltip: tooltip,
      onPressed: () => context.go(AppRoutes.profile),
      icon: needsReview
          ? Badge(smallSize: 10, backgroundColor: colors.warning, alignment: AlignmentDirectional.topEnd, child: icon)
          : icon,
    );
  }
}

/// Turns once a second; still with Reduce Motion.
class _Spinning extends StatefulWidget {
  const _Spinning({required this.child});

  final Widget child;

  @override
  State<_Spinning> createState() => _SpinningState();
}

class _SpinningState extends State<_Spinning> with SingleTickerProviderStateMixin {
  late final AnimationController _turns = AnimationController(vsync: this, duration: const Duration(seconds: 1));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _turns.stop();
    } else if (!_turns.isAnimating) {
      unawaited(_turns.repeat());
    }
  }

  @override
  void dispose() {
    _turns.dispose();
    super.dispose();
  }

  // Counter-clockwise reads as "sync" in both directions; not mirrored.
  @override
  Widget build(BuildContext context) => RotationTransition(turns: ReverseAnimation(_turns), child: widget.child);
}
