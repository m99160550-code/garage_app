import 'package:intl/intl.dart';

import '../text/digits.dart';

/// Digit style setting (FR-SET-13). Western is the default.
enum DigitStyle { western, arabicIndic }

/// Number and money formatting shared by every screen.
///
/// Rules from the design spec 2.5 and BR-SET-05:
/// * Grouped thousands ("54,320").
/// * Arabic-Indic digits only when the user picks them, and never for
///   VINs, plates or odometer readings (use [formatOdometer] for those).
/// * English money: code before the amount ("SAR 420").
///   Arabic money: amount, then the Arabic symbol ("420 ر.س").
class AppFormatters {
  const AppFormatters({required this.languageCode, this.digits});

  final String languageCode;

  /// `null` follows the user's setting ([appDigits]).
  final DigitStyle? digits;

  /// The user's digit setting (FR-SET-13), set by the app root from the
  /// saved preferences. Formatters created without [digits] follow it.
  static DigitStyle appDigits = DigitStyle.western;

  bool get _isArabic => languageCode == 'ar';

  static const _arabicIndic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

  /// Arabic symbols for the region's currencies. Others fall back to the code.
  static const _arabicCurrencySymbols = {
    'SAR': 'ر.س',
    'AED': 'د.إ',
    'EGP': 'ج.م',
    'KWD': 'د.ك',
    'QAR': 'ر.ق',
    'BHD': 'د.ب',
    'OMR': 'ر.ع',
    'JOD': 'د.أ',
    'USD': r'$',
  };

  String _applyDigits(String value) {
    if ((digits ?? appDigits) == DigitStyle.western) return value;
    final buffer = StringBuffer();
    for (final unit in value.codeUnits) {
      final char = String.fromCharCode(unit);
      final digit = int.tryParse(char);
      buffer.write(digit == null ? char : _arabicIndic[digit]);
    }
    return buffer.toString();
  }

  /// "54,320". Uses the digit setting.
  String integer(int value) => _applyDigits(NumberFormat.decimalPattern('en').format(value));

  /// Odometer values always use Western digits (BR-SET-05).
  String formatOdometer(int value) => NumberFormat.decimalPattern('en').format(value);

  /// "27 Nov" / "27 نوفمبر": day and month in the UI language, Gregorian
  /// (NFR-LOC-04), with Western digits unless the user picked Arabic-Indic.
  String shortDate(DateTime date) => _applyDigits(toWesternDigits(DateFormat.MMMd(languageCode).format(date)));

  /// "27 Nov 2026", for date fields.
  String mediumDate(DateTime date) => _applyDigits(toWesternDigits(DateFormat.yMMMd(languageCode).format(date)));

  /// "Tue, Nov 17" (S-18).
  String weekdayDate(DateTime date) => _applyDigits(toWesternDigits(DateFormat.MMMEd(languageCode).format(date)));

  /// "Nov 5, 2026, 10:24": a date and a 24-hour time (S-21 footer).
  String dateTime(DateTime value) =>
      '${mediumDate(value)}${_isArabic ? '، ' : ', '}${_applyDigits(DateFormat.Hm('en').format(value))}';

  /// "Nov" / "نوفمبر", for the date block of record rows.
  String monthShort(DateTime date) => DateFormat.MMM(languageCode).format(date);

  /// "November 2026", for month headings.
  String monthYear(DateTime date) => _applyDigits(toWesternDigits(DateFormat.yMMMM(languageCode).format(date)));

  /// Decimal places by currency (BR-EXP-04). Others use 2.
  static const _minorUnits = {'JPY': 0, 'KWD': 3, 'BHD': 3, 'OMR': 3, 'JOD': 3};

  static int minorUnitsOf(String currencyCode) => _minorUnits[currencyCode] ?? 2;

  /// Money stored in the smallest unit (AD-07): "SAR 350", "SAR 349.50",
  /// "KWD 12.500". Decimals show only when the amount has a fraction, and
  /// then with the currency's own number of places (BR-EXP-04).
  String money(int amountMinor, String currencyCode) {
    final places = minorUnitsOf(currencyCode);
    final factor = [1, 10, 100, 1000, 10000][places];
    final whole = amountMinor ~/ factor;
    final fraction = amountMinor % factor;
    final number = fraction == 0
        ? integer(whole)
        : _applyDigits(
            NumberFormat.decimalPatternDigits(locale: 'en', decimalDigits: places).format(amountMinor / factor),
          );
    if (!_isArabic) return '$currencyCode\u00A0$number';
    final symbol = _arabicCurrencySymbols[currencyCode] ?? currencyCode;
    return '$number\u00A0$symbol';
  }

  /// Whole-unit money for summary cards, for example "SAR 420".
  String moneyWhole(int amount, String currencyCode) {
    final number = integer(amount);
    if (!_isArabic) return '$currencyCode $number';
    final symbol = _arabicCurrencySymbols[currencyCode] ?? currencyCode;
    return '$number $symbol';
  }
}

/// Keeps a signed value such as "−15" in one left-to-right piece inside
/// Arabic text. Uses LRM marks (U+200E) rather than isolates, which some
/// renderers (Flutter web) ignore, leaving "15−".
String ltrValue(String value) => '\u200E$value\u200E';
