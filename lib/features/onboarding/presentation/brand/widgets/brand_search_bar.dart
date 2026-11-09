import 'package:flutter/material.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/widgets/app_search_field.dart';

/// The brand search (spec S-04 item 5a): a small centred pill
/// ("Search brand…", 200 × 40) that expands to a full-width 48 pt field
/// and opens the keyboard. It collapses again when it loses focus empty.
class BrandSearchBar extends StatefulWidget {
  const BrandSearchBar({
    super.key,
    required this.query,
    required this.onChanged,
    this.onExpanded,
    this.alwaysExpanded = false,
  });

  final String query;
  final ValueChanged<String> onChanged;

  /// Called when the pill expands, so the sheet can move to its top snap.
  final VoidCallback? onExpanded;

  /// Tablets in landscape always show the full field.
  final bool alwaysExpanded;

  @override
  State<BrandSearchBar> createState() => _BrandSearchBarState();
}

class _BrandSearchBarState extends State<BrandSearchBar> {
  final _focusNode = FocusNode();
  late final _controller = TextEditingController(text: widget.query);
  late bool _expanded = widget.alwaysExpanded || widget.query.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _controller.text.isEmpty && !widget.alwaysExpanded) {
        setState(() => _expanded = false);
      }
    });
  }

  @override
  void didUpdateWidget(BrandSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // "Clear search" in the empty state clears from outside.
    if (widget.query != _controller.text) _controller.text = widget.query;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _expand() {
    setState(() => _expanded = true);
    widget.onExpanded?.call();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return AnimatedSwitcher(
      duration: AppMotion.standard,
      child: _expanded
          ? AppSearchField(
              key: const ValueKey('field'),
              controller: _controller,
              focusNode: _focusNode,
              hint: l10n.brandSearchHint,
              clearLabel: l10n.actionClearSearch,
              onChanged: widget.onChanged,
            )
          : Center(
              key: const ValueKey('pill'),
              child: Semantics(
                button: true,
                label: l10n.brandSearchHint,
                excludeSemantics: true,
                child: Material(
                  color: colors.surfaceCard,
                  shape: StadiumBorder(side: BorderSide(color: colors.borderSubtle)),
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: _expand,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 200, minHeight: AppSpacing.minTouchTarget),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search, size: 18, color: colors.textSecondary),
                            const SizedBox(width: AppSpacing.xs),
                            Flexible(
                              child: Text(
                                l10n.brandSearchHint,
                                style: context.text.bodyS.copyWith(color: colors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
