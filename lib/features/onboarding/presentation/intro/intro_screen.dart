import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/layout/window_class.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/page_dots.dart';
import '../../../session/application/session_providers.dart';
import '../../../settings/presentation/widgets/language_switch_button.dart';
import 'widgets/intro_illustrations.dart';

/// S-02 Intro (UI/UX spec S-02): three pages explaining the app.
///
/// * Next / swipe moves between pages. "Get started" or "Skip" marks the
///   intro as seen and opens S-03 Country.
/// * "I already have an account · Sign in" opens S-28.
/// * The language switch flips Arabic and English, including direction.
/// * With Reduce Motion on, pages cross-fade instead of sliding.
class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroPage {
  const _IntroPage({required this.title, required this.body, required this.illustration});

  final String title;
  final String body;
  final Widget illustration;
}

class _IntroScreenState extends ConsumerState<IntroScreen> with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  late final AnimationController _contentFade = AnimationController(vsync: this, value: 1, duration: AppMotion.quick);
  int _page = 0;
  bool _leaving = false;

  static const _pageCount = 3;

  bool get _isLast => _page == _pageCount - 1;

  @override
  void dispose() {
    _pageController.dispose();
    _contentFade.dispose();
    super.dispose();
  }

  List<_IntroPage> _pages(AppLocalizations l10n) => [
    _IntroPage(title: l10n.introPage1Title, body: l10n.introPage1Body, illustration: const IntroScoreIllustration()),
    _IntroPage(
      title: l10n.introPage2Title,
      body: l10n.introPage2Body,
      illustration: const IntroStatCardsIllustration(),
    ),
    _IntroPage(title: l10n.introPage3Title, body: l10n.introPage3Body, illustration: const IntroPrivateIllustration()),
  ];

  Future<void> _goTo(int page) async {
    if (MediaQuery.disableAnimationsOf(context)) {
      // Reduce Motion: fade out, swap the page, fade in (150 ms in total).
      await _contentFade.animateTo(0, duration: AppMotion.quick ~/ 2);
      _pageController.jumpToPage(page);
      await _contentFade.animateTo(1, duration: AppMotion.quick ~/ 2);
    } else {
      await _pageController.animateToPage(page, duration: AppMotion.emphasis, curve: AppMotion.emphasisCurve);
    }
  }

  void _next() => _isLast ? _finish() : _goTo(_page + 1);

  Future<void> _finish() async {
    if (_leaving) return;
    _leaving = true;
    await ref.read(sessionRepositoryProvider).markIntroCompleted();
    if (!mounted) return;
    await context.push(AppRoutes.setupCountry);
    _leaving = false;
  }

  void _signIn() => context.push(AppRoutes.signIn);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final windowClass = WindowClass.of(context);
    final pages = _pages(l10n);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(showSkip: !_isLast, onSkip: _finish, skipLabel: l10n.introSkip),
            Expanded(
              child: FadeTransition(
                opacity: _contentFade,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pageCount,
                  onPageChanged: (index) => setState(() => _page = index),
                  itemBuilder: (context, index) =>
                      _IntroPageView(page: pages[index], sideBySide: windowClass == WindowClass.expanded),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenMargin,
                AppSpacing.md,
                AppSpacing.screenMargin,
                AppSpacing.xs,
              ),
              child: Column(
                children: [
                  PageDots(count: _pageCount, index: _page, semanticLabel: l10n.introPageLabel(_page + 1, _pageCount)),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(label: _isLast ? l10n.introGetStarted : l10n.introNext, onPressed: _next),
                  const SizedBox(height: AppSpacing.xs),
                  AppButton.text(label: l10n.introSignIn, onPressed: _signIn),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 44 pt top bar: language switch at the start, Skip at the end.
/// Skip keeps its space on the last page so nothing jumps.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.showSkip, required this.onSkip, required this.skipLabel});

  final bool showSkip;
  final VoidCallback onSkip;
  final String skipLabel;

  @override
  Widget build(BuildContext context) {
    // Minimum height rather than fixed: at large text sizes the labels may
    // wrap, and both buttons shrink before they overflow.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget + AppSpacing.xxs),
        child: Row(
          children: [
            const Flexible(
              child: Align(alignment: AlignmentDirectional.centerStart, child: LanguageSwitchButton()),
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Visibility(
                  visible: showSkip,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: AppButton.text(label: skipLabel, onPressed: showSkip ? onSkip : null),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One intro page: illustration (55% of the screen height) above the text,
/// or side by side on wide tablets in landscape.
class _IntroPageView extends StatelessWidget {
  const _IntroPageView({required this.page, required this.sideBySide});

  final _IntroPage page;
  final bool sideBySide;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;

    final textBlock = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: Text(page.title, style: text.titleL, textAlign: TextAlign.center),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            page.body,
            style: text.body.copyWith(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    if (sideBySide) {
      return Row(
        children: [
          Expanded(child: page.illustration),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: textBlock),
              ),
            ),
          ),
        ],
      );
    }

    final screenHeight = MediaQuery.sizeOf(context).height;
    return LayoutBuilder(
      builder: (context, constraints) {
        // 55% of the screen, but always leave room for the text.
        final illustrationHeight = (screenHeight * 0.55).clamp(0.0, constraints.maxHeight * 0.68);
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                SizedBox(height: illustrationHeight, child: page.illustration),
                const SizedBox(height: AppSpacing.md),
                Expanded(child: SingleChildScrollView(child: textBlock)),
              ],
            ),
          ),
        );
      },
    );
  }
}
