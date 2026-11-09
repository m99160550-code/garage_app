import 'package:flutter/material.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../../core/widgets/app_sheet.dart';

/// What the year sheet returns: a year, or `null` inside for "Clear".
class YearChoice {
  const YearChoice(this.year);

  final int? year;
}

/// Year picker (spec S-06 item 6): years from next year back to 1950,
/// newest first. Next year is included for new model years sold early.
Future<YearChoice?> showYearPicker({required BuildContext context, required int? selected}) {
  return showAppSheet<YearChoice>(
    context: context,
    heightFactor: 0.7,
    builder: (context) => _YearPicker(selected: selected),
  );
}

class _YearPicker extends StatefulWidget {
  const _YearPicker({required this.selected});

  final int? selected;

  @override
  State<_YearPicker> createState() => _YearPickerState();
}

class _YearPickerState extends State<_YearPicker> {
  static const _rowHeight = 56.0;
  late final List<int> _years = [for (var y = DateTime.now().year + 1; y >= 1950; y--) y];
  late final ScrollController _scroll = ScrollController(
    // Open with the selected year near the top.
    initialScrollOffset: widget.selected == null
        ? 0
        : ((_years.indexOf(widget.selected!) - 2).clamp(0, _years.length) * _rowHeight),
  );

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: AppSpacing.screenMargin, end: AppSpacing.xs),
          child: Row(
            children: [
              Expanded(
                child: Semantics(header: true, child: Text(l10n.yearLabel, style: context.text.titleL)),
              ),
              AppButton.text(label: l10n.dateClear, onPressed: () => Navigator.of(context).pop(const YearChoice(null))),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            itemExtent: _rowHeight,
            itemCount: _years.length,
            itemBuilder: (context, i) => AppListRow(
              card: false,
              minHeight: _rowHeight,
              // Years always use Western digits, like other codes.
              title: '${_years[i]}',
              selected: _years[i] == widget.selected,
              trailing: _years[i] == widget.selected ? Icon(Icons.check, color: context.colors.accentPrimary) : null,
              onTap: () => Navigator.of(context).pop(YearChoice(_years[i])),
            ),
          ),
        ),
      ],
    );
  }
}
