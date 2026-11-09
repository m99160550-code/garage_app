import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../layout/window_class.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Opens a sheet the way the design system describes (UI/UX spec 1.7, 2.4):
///
/// * Phones: a modal bottom sheet, radius 32, frosted `bg.sheet` with a
///   drag handle, over a 50% black scrim. Swipe down or tap the scrim to
///   close.
/// * Tablets: a centred modal, at most [tabletMaxWidth] × [tabletMaxHeight].
///
/// With [fitContent], the sheet is as tall as its content (for example
/// S-08, about 420 pt), up to [heightFactor] of the screen. The content
/// must then use `MainAxisSize.min` and scroll inside a `Flexible`.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double heightFactor = 0.92,
  bool fitContent = false,
  double tabletMaxWidth = 560,
  double tabletMaxHeight = 640,
}) {
  final colors = context.colors;
  if (!WindowClass.of(context).isCompact) {
    return showDialog<T>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Dialog(
        backgroundColor: colors.bgSheet,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppSpacing.xl),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sheet)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: tabletMaxWidth, maxHeight: tabletMaxHeight),
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: fitContent
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [Flexible(child: builder(context))],
                  )
                : builder(context),
          ),
        ),
      ),
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    // Above the floating navigation bar, which sheets hide (spec 2.2).
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (context) {
      if (!fitContent) {
        return FractionallySizedBox(
          heightFactor: heightFactor,
          child: _FrostedSheet(child: builder(context)),
        );
      }
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * heightFactor),
        child: _FrostedSheet(fitContent: true, child: builder(context)),
      );
    },
  );
}

class _FrostedSheet extends StatelessWidget {
  const _FrostedSheet({required this.child, this.fitContent = false});

  final Widget child;
  final bool fitContent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: ColoredBox(
          color: colors.bgSheet.withValues(alpha: 0.88),
          child: Column(
            mainAxisSize: fitContent ? MainAxisSize.min : MainAxisSize.max,
            children: [
              const SizedBox(height: AppSpacing.xs),
              ExcludeSemantics(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.borderStrong,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (fitContent) Flexible(child: SafeArea(top: false, child: child)) else Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
