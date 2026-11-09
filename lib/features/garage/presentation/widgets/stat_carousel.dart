import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/stat_card.dart';
import 'dashboard_stats.dart';

/// The stat carousel on phones (spec S-09 item 5): 148 × 168 cards that
/// snap, opening on Next service. The focused card is raised; side cards
/// are smaller and dimmed, partly off-screen. In Arabic it runs right to
/// left, so Mileage is on the right.
///
/// Screen readers hear it as an adjustable control ("Stat cards, Next
/// service, 2 of 3"), and each card is also a button.
class StatCarousel extends StatefulWidget {
  const StatCarousel({super.key, required this.stats, this.initialIndex = 1});

  static const cardWidth = 148.0;
  static const cardHeight = 168.0;
  static const gap = 12.0;

  final List<DashboardStat> stats;
  final int initialIndex;

  @override
  State<StatCarousel> createState() => _StatCarouselState();
}

class _StatCarouselState extends State<StatCarousel> {
  PageController? _controller;
  double? _viewportWidth;
  late int _index = widget.initialIndex;

  PageController _controllerFor(double width) {
    if (_controller != null && _viewportWidth == width) return _controller!;
    _controller?.dispose();
    _viewportWidth = width;
    return _controller = PageController(
      initialPage: _index,
      viewportFraction: (StatCarousel.cardWidth + StatCarousel.gap) / width,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index >= widget.stats.length) return;
    _controller?.animateToPage(index, duration: AppMotion.standard, curve: AppMotion.standardCurve);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stats = widget.stats;
    String valueFor(int i) => '${stats[i].label}, ${l10n.positionOf(i + 1, stats.length)}';

    return Semantics(
      container: true,
      label: l10n.statCarouselLabel,
      value: valueFor(_index),
      increasedValue: _index + 1 < stats.length ? valueFor(_index + 1) : null,
      decreasedValue: _index > 0 ? valueFor(_index - 1) : null,
      hint: l10n.statCarouselHint,
      onIncrease: _index + 1 < stats.length ? () => _goTo(_index + 1) : null,
      onDecrease: _index > 0 ? () => _goTo(_index - 1) : null,
      child: SizedBox(
        height: StatCarousel.cardHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final controller = _controllerFor(constraints.maxWidth);
            return PageView.builder(
              controller: controller,
              clipBehavior: Clip.none,
              itemCount: stats.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  final page = controller.hasClients && controller.position.haveDimensions
                      ? controller.page ?? _index.toDouble()
                      : _index.toDouble();
                  final distance = (page - i).abs().clamp(0.0, 1.0);
                  final stat = stats[i];
                  return Center(
                    child: Opacity(
                      opacity: 1 - 0.4 * distance,
                      child: Transform.scale(
                        scale: 1 - 0.1 * distance,
                        child: StatCard(
                          label: stat.label,
                          sublabel: stat.sublabel,
                          value: stat.value,
                          unit: stat.unit,
                          footer: stat.footer,
                          valueColor: stat.valueColor,
                          sublabelIcon: stat.sublabelIcon,
                          semanticLabel: stat.semanticLabel,
                          focused: distance < 0.5,
                          // A side card scrolls into focus first.
                          onTap: i == _index ? stat.onTap : () => _goTo(i),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
