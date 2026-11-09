import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Converts Arabic-Indic (٠-٩) and Eastern Arabic-Indic (۰-۹) digits to
/// Western digits, so numbers typed on an Arabic keyboard are understood.
String toWesternDigits(String input) {
  final buffer = StringBuffer();
  for (final unit in input.codeUnits) {
    if (unit >= 0x0660 && unit <= 0x0669) {
      buffer.writeCharCode(0x30 + unit - 0x0660);
    } else if (unit >= 0x06F0 && unit <= 0x06F9) {
      buffer.writeCharCode(0x30 + unit - 0x06F0);
    } else {
      buffer.writeCharCode(unit);
    }
  }
  return buffer.toString();
}

/// Parses a whole number typed by the user, ignoring thousands separators
/// and spaces. Returns `null` if it isn't a whole number.
int? parseWholeNumber(String input) {
  final cleaned = toWesternDigits(input).replaceAll(RegExp(r'[,\s٬.]'), '');
  if (cleaned.isEmpty || !RegExp(r'^\d+$').hasMatch(cleaned)) return null;
  return int.tryParse(cleaned);
}

/// Keeps a whole number grouped while typing ("54,320"), in Western digits
/// (odometer values always use Western digits, BR-SET-05).
class GroupedNumberFormatter extends TextInputFormatter {
  GroupedNumberFormatter({this.maxDigits = 9});

  final int maxDigits;
  static final _format = NumberFormat.decimalPattern('en');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = toWesternDigits(newValue.text).replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final limited = digits.length > maxDigits ? digits.substring(0, maxDigits) : digits;
    final formatted = _format.format(int.parse(limited));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Uppercases and keeps only letters and digits (VINs, plates).
class UpperAlphanumericFormatter extends TextInputFormatter {
  UpperAlphanumericFormatter({this.allowSpaces = false});

  final bool allowSpaces;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final pattern = allowSpaces ? RegExp(r'[^A-Z0-9 ]') : RegExp(r'[^A-Z0-9]');
    final text = toWesternDigits(newValue.text).toUpperCase().replaceAll(pattern, '');
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
