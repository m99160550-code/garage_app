import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Skeleton (UI/UX spec 1.7, S-34): grey shapes in `surface.card` with a
/// 1.2 s `surface.raised` shimmer sweeping across. No shimmer with
/// Reduce Motion. Screen readers hear "Loading".
class SkeletonShimmer extends StatefulWidget {
  const SkeletonShimmer({super.key, required this.child, this.label});

  /// Shapes made of [SkeletonBox]es.
  final Widget child;

  /// What's loading, for screen readers; "Loading" by default.
  final String? label;

  static const period = Duration(milliseconds: 1200);

  @override
  State<SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<SkeletonShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(vsync: this, duration: SkeletonShimmer.period);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _sweep.stop();
    } else if (!_sweep.isAnimating) {
      unawaited(_sweep.repeat());
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final still = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: widget.label ?? AppLocalizations.of(context).loading,
      liveRegion: true,
      child: ExcludeSemantics(
        child: still
            ? widget.child
            : AnimatedBuilder(
                animation: _sweep,
                child: widget.child,
                builder: (context, child) {
                  final t = _sweep.value * 3 - 1; // -1 → 2 across the width.
                  return ShaderMask(
                    blendMode: BlendMode.srcATop,
                    shaderCallback: (bounds) => LinearGradient(
                      begin: Alignment(t - 1, 0),
                      end: Alignment(t + 1, 0),
                      colors: [colors.surfaceCard, colors.surfaceRaised, colors.surfaceCard],
                      stops: const [0.25, 0.5, 0.75],
                    ).createShader(bounds),
                    child: child,
                  );
                },
              ),
      ),
    );
  }
}

/// One grey shape of a skeleton.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, required this.height, this.radius = AppRadii.row});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(color: context.colors.surfaceCard, borderRadius: BorderRadius.circular(radius)),
  );
}

/// A list of [count] row-shaped skeletons, for list screens.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4, this.rowHeight = 64, this.label, this.padding});

  final int count;
  final double rowHeight;
  final String? label;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    physics: const NeverScrollableScrollPhysics(),
    padding: padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin, vertical: AppSpacing.md),
    child: SkeletonShimmer(
      label: label,
      child: Column(
        children: [
          for (var i = 0; i < count; i++) ...[SkeletonBox(height: rowHeight), const SizedBox(height: AppSpacing.xs)],
        ],
      ),
    ),
  );
}

/// Shows nothing for the first 300 ms, then [skeleton] (spec S-34:
/// skeletons only for loading over 300 ms, so fast loads don't flash).
class DelayedSkeleton extends StatefulWidget {
  const DelayedSkeleton({super.key, this.skeleton = const SkeletonList()});

  final Widget skeleton;

  static const delay = Duration(milliseconds: 300);

  @override
  State<DelayedSkeleton> createState() => _DelayedSkeletonState();
}

class _DelayedSkeletonState extends State<DelayedSkeleton> {
  Timer? _timer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(DelayedSkeleton.delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _visible ? widget.skeleton : const SizedBox.shrink();
}
