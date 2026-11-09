import 'package:flutter/material.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../../../core/widgets/monogram_tile.dart';

/// "Other brand", always the last row (FR-VEH-04). When chosen it opens a
/// "Brand name" field (max 60 characters) inside the same card.
class OtherBrandRow extends StatefulWidget {
  const OtherBrandRow({
    super.key,
    required this.selected,
    required this.name,
    required this.onTap,
    required this.onNameChanged,
  });

  final bool selected;
  final String name;
  final VoidCallback onTap;
  final ValueChanged<String> onNameChanged;

  @override
  State<OtherBrandRow> createState() => _OtherBrandRowState();
}

class _OtherBrandRowState extends State<OtherBrandRow> {
  late final _controller = TextEditingController(text: widget.name);

  @override
  void didUpdateWidget(OtherBrandRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // "Add 'BYDD' as other brand" prefills the name from outside.
    if (widget.name != _controller.text) _controller.text = widget.name;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final radius = BorderRadius.circular(AppRadii.row);

    return AnimatedContainer(
      duration: AppMotion.standard,
      decoration: BoxDecoration(
        color: widget.selected ? colors.surfaceRaised : colors.surfaceCard,
        borderRadius: radius,
        border: Border.all(color: widget.selected ? colors.borderStrong : colors.borderSubtle),
      ),
      child: AnimatedSize(
        duration: AppMotion.standard,
        curve: AppMotion.standardCurve,
        alignment: Alignment.topCenter,
        child: Column(
          children: [
            Semantics(
              button: true,
              selected: widget.selected,
              label: '${l10n.brandOther}, ${l10n.brandOtherHint}',
              excludeSemantics: true,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: radius,
                  onTap: widget.onTap,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 64),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      child: Row(
                        children: [
                          const MonogramTile.add(),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(l10n.brandOther, style: text.titleM),
                                Text(l10n.brandOtherHint, style: text.bodyS.copyWith(color: colors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.selected)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                child: AppTextField(
                  controller: _controller,
                  label: l10n.brandOtherFieldLabel,
                  maxLength: 60,
                  autofocus: widget.name.isEmpty,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  onChanged: widget.onNameChanged,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
