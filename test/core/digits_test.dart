import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_garage/core/text/digits.dart';

TextEditingValue _type(TextInputFormatter formatter, String text) =>
    formatter.formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: text));

void main() {
  test('Arabic-Indic and Eastern Arabic-Indic digits become Western', () {
    expect(toWesternDigits('٥٤٣٢٠'), '54320');
    expect(toWesternDigits('۵۴۳۲۰'), '54320');
    expect(toWesternDigits('km 12'), 'km 12');
  });

  test('whole numbers ignore separators and reject anything else', () {
    expect(parseWholeNumber('54,320'), 54320);
    expect(parseWholeNumber('٥٤٬٣٢٠'), 54320);
    expect(parseWholeNumber(' 1 200 '), 1200);
    expect(parseWholeNumber(''), isNull);
    expect(parseWholeNumber('12a'), isNull);
  });

  test('the grouped formatter keeps thousands separators while typing', () {
    final formatter = GroupedNumberFormatter();
    expect(_type(formatter, '54320').text, '54,320');
    expect(_type(formatter, '٥٤٣٢٠').text, '54,320');
    expect(_type(formatter, '12ab3').text, '123');
    expect(_type(formatter, '').text, '');
    expect(_type(GroupedNumberFormatter(maxDigits: 3), '12345').text, '123');
  });

  test('VIN and plate formatter uppercases and drops other characters', () {
    expect(_type(UpperAlphanumericFormatter(), '4t1-c11 ak').text, '4T1C11AK');
    expect(_type(UpperAlphanumericFormatter(allowSpaces: true), 'abc 123!').text, 'ABC 123');
  });
}
