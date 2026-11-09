import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Text category tabs (UI/UX spec 1.7): 48 pt high, horizontally
/// scrollable with fades at both ends. The selected tab is `text.primary`
/// with a 2 pt underline the width of its text. The row follows reading
/// direction, so it runs right to left in Arabic.
class CategoryTabs extends StatefulWidget {
  const CategoryTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    required this.semanticLabelBuilder,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Spoken label per tab, for example "Popular, tab 1 of 6".
  final String Function(int index) semanticLabelBuilder;

  @override
  State<CategoryTabs> createState() => _CategoryTabsState();
}

class _CategoryTabsState extends State<CategoryTabs> {
  late final List<GlobalKey> _keys = List.generate(widget.labels.length, (_) => GlobalKey());

  @override
  void didUpdateWidget(CategoryTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      // Keep the selected tab in view (it may be off-screen on phones).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = _keys[widget.selectedIndex].currentContext;
        if (context != null && context.mounted) {
          Scrollable.ensureVisible(context, duration: AppMotion.standard, alignment: 0.5);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;

    final row = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
      child: Row(
        children: [
          for (var i = 0; i < widget.labels.length; i++)
            Semantics(
              key: _keys[i],
              button: true,
              selected: i == widget.selectedIndex,
              label: widget.semanticLabelBuilder(i),
              excludeSemantics: true,
              child: InkWell(
                onTap: () => widget.onSelected(i),
                borderRadius: BorderRadius.circular(AppRadii.input),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48, minWidth: AppSpacing.minTouchTarget),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: IntrinsicWidth(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: AppMotion.quick,
                            style: text.label.copyWith(
                              fontSize: 14,
                              color: i == widget.selectedIndex ? colors.textPrimary : colors.textSecondary,
                            ),
                            child: Text(widget.labels[i], textAlign: TextAlign.center, maxLines: 1),
                          ),
                          const SizedBox(height: 6),
                          AnimatedContainer(
                            duration: AppMotion.standard,
                            height: 2,
                            decoration: BoxDecoration(
                              color: i == widget.selectedIndex ? colors.textPrimary : Colors.transparent,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    // 24 pt fade at both ends (spec 1.7).
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        final fade = 24 / (bounds.width == 0 ? 1 : bounds.width);
        return LinearGradient(
          colors: const [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
          stops: [0, fade, 1 - fade, 1],
        ).createShader(bounds);
      },
      child: row,
    );
  }
}
