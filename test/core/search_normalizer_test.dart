import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_garage/core/text/search_normalizer.dart';

void main() {
  group('SearchNormalizer.matches (BR-VEH-10)', () {
    test('empty query matches everything', () {
      expect(SearchNormalizer.matches('', ['Egypt']), isTrue);
      expect(SearchNormalizer.matches('   ', ['Egypt']), isTrue);
    });

    test('ignores case and matches from the start of a word', () {
      expect(SearchNormalizer.matches('egy', ['Egypt']), isTrue);
      expect(SearchNormalizer.matches('arab', ['United Arab Emirates']), isTrue);
      expect(SearchNormalizer.matches('gypt', ['Egypt']), isFalse);
    });

    test('ignores Latin accents', () {
      expect(SearchNormalizer.matches('turkiye', ['Türkiye']), isTrue);
    });

    test('treats Arabic letter variants as equal', () {
      // إ / ا
      expect(SearchNormalizer.matches('الامارات', ['الإمارات']), isTrue);
      // ة / ه and ى / ي
      expect(SearchNormalizer.matches('السعوديه', ['السعودية']), isTrue);
      expect(SearchNormalizer.matches('موسي', ['موسى']), isTrue);
    });

    test('ignores Arabic diacritics', () {
      expect(SearchNormalizer.matches('عمان', ['عُمان']), isTrue);
    });

    test('the Arabic article ال is optional at the start of a word', () {
      expect(SearchNormalizer.matches('امارات', ['الإمارات']), isTrue);
      expect(SearchNormalizer.matches('كويت', ['الكويت']), isTrue);
    });

    test('matches any of the candidate names and aliases', () {
      expect(SearchNormalizer.matches('uae', ['United Arab Emirates', 'الإمارات', 'UAE']), isTrue);
      expect(SearchNormalizer.matches('مصر', ['Egypt', 'مصر']), isTrue);
    });

    test('hyphens count as word breaks', () {
      expect(SearchNormalizer.matches('benz', ['Mercedes-Benz']), isTrue);
    });
  });
}
