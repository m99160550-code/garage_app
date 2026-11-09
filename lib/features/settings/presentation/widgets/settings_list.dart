import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';

/// An inset grouped section (UI/UX spec S-24): an overline header, then a
/// `surface.card` group with radius 18 and dividers between rows.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.title, required this.children, this.footer});

  /// The heading above the group; `null` for none.
  final String? title;
  final List<Widget> children;

  /// A caption under the group, for example the support promise.
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final language = Localizations.localeOf(context).languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title case final title?)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: AppSpacing.md, bottom: AppSpacing.xs),
            child: Semantics(
              header: true,
              child: Text(
                language == 'ar' ? title : title.toUpperCase(),
                style: text.overline.copyWith(color: colors.textTertiary),
              ),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: BorderRadius.circular(AppRadii.row),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.row),
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) Divider(height: 1, indent: AppSpacing.md, color: colors.borderSubtle),
                  children[i],
                ],
              ],
            ),
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0),
            child: Text(footer!, style: text.caption.copyWith(color: colors.textTertiary)),
          ),
      ],
    );
  }
}

/// A 56 pt row: title, optional value at the end, and a chevron. With
/// [destructive] the title is red and there is no chevron. [selected]
/// marks the row shown in the iPad detail pane.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.title,
    required this.onTap,
    this.value,
    this.icon,
    this.destructive = false,
    this.selected = false,
    this.external = false,
  });

  final String title;
  final String? value;
  final IconData? icon;
  final VoidCallback onTap;
  final bool destructive;
  final bool selected;

  /// Opens outside this screen (a web page): an arrow instead of a chevron.
  final bool external;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: value == null ? title : '$title, $value',
      excludeSemantics: true,
      child: Material(
        color: selected ? colors.surfaceRaised : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 22, color: destructive ? colors.destructiveText : colors.textSecondary),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: text.body.copyWith(color: destructive ? colors.destructiveText : colors.textPrimary),
                    ),
                  ),
                  if (value != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    // The value sits at the end and takes at most half the row.
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.45),
                      child: Text(
                        value!,
                        style: text.body.copyWith(color: colors.textSecondary),
                        textAlign: TextAlign.end,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (!destructive) ...[
                    const SizedBox(width: AppSpacing.xxs),
                    Icon(
                      external ? Icons.open_in_new : Icons.chevron_right,
                      size: external ? 18 : 24,
                      color: colors.textTertiary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A row with a switch and an optional subline ("Usage analytics").
class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subline,
    this.icon,
  });

  final String title;
  final String? subline;
  final IconData? icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    return MergeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.md, AppSpacing.xs, AppSpacing.sm, AppSpacing.xs),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 22, color: colors.textSecondary),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: text.body),
                    if (subline != null) Text(subline!, style: text.bodyS.copyWith(color: colors.textSecondary)),
                  ],
                ),
              ),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}
