import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_garage/features/privacy/domain/consent.dart';

void main() {
  group('analyticsConsentRequired (BR-PRV-01, BR-PRV-03)', () {
    test('required in the EU, the rest of the EEA, the UK and Switzerland', () {
      for (final region in ['DE', 'FR', 'IE', 'NO', 'IS', 'GB', 'CH', 'de']) {
        expect(analyticsConsentRequired(region), isTrue, reason: region);
      }
    });

    test('not required in MENA or the US', () {
      for (final region in ['SA', 'AE', 'EG', 'KW', 'US', 'TR']) {
        expect(analyticsConsentRequired(region), isFalse, reason: region);
      }
    });

    test('an unknown region is asked', () {
      expect(analyticsConsentRequired(null), isTrue);
    });
  });
}
