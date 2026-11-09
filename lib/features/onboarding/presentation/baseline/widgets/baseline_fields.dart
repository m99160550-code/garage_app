import 'package:flutter/material.dart';

import '../../../../../core/format/app_formatters.dart';
import '../../../../../core/text/digits.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/app_text_field.dart';

/// A date field and a mileage field, side by side (50 % each), stacked when
/// the space is narrow, the text is large, or a field shows an error, so
/// labels and messages are never cut off (spec S-07 item 4).
class DateAndMileageFields extends StatelessWidget {
  const DateAndMileageFields({
    super.key,
    required this.dateLabel,
    required this.dateText,
    required this.onPickDate,
    required this.mileageLabel,
    required this.mileageController,
    required this.unitLabel,
    this.dateError,
    this.mileageError,
    this.mileageFocus,
    this.enabled = true,
    this.alwaysStacked = false,
  });

  final String dateLabel;

  /// The formatted date, or empty.
  final String dateText;
  final VoidCallback onPickDate;
  final String? dateError;

  final String mileageLabel;
  final TextEditingController mileageController;
  final FocusNode? mileageFocus;
  final String unitLabel;
  final String? mileageError;

  final bool enabled;

  /// Stack even when there is room, for longer labels such as
  /// "Delivery date" and "Starting mileage".
  final bool alwaysStacked;

  @override
  Widget build(BuildContext context) {
    final date = AppTextField(
      // Read-only picker field: rebuilt when the value changes.
      key: ValueKey(('date', dateLabel, dateText)),
      initialValue: dateText,
      label: dateLabel,
      readOnly: true,
      enabled: enabled,
      onTap: onPickDate,
      error: dateError,
      trailingIcon: Icons.calendar_today_outlined,
    );
    final mileage = AppTextField(
      controller: mileageController,
      focusNode: mileageFocus,
      label: mileageLabel,
      enabled: enabled,
      suffixText: unitLabel,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      inputFormatters: [GroupedNumberFormatter()],
      valueStyle: AppTextStyles.tabular(context.text.body),
      error: mileageError,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            alwaysStacked ||
            dateError != null ||
            mileageError != null ||
            constraints.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(16) > 22;
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              date,
              const SizedBox(height: AppSpacing.sm),
              mileage,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: date),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: mileage),
          ],
        );
      },
    );
  }
}

/// The date shown in a field, in the UI language (Gregorian, NFR-LOC-04).
String formatFieldDate(BuildContext context, DateTime? date) {
  if (date == null) return '';
  return AppFormatters(languageCode: Localizations.localeOf(context).languageCode).mediumDate(date);
}
