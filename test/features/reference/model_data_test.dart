import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_garage/features/reference/data/mock_reference_repository.dart';

void main() {
  const repository = MockReferenceRepository();

  test('every brand with models loaded has 3 or 4 models (FR-REF-01)', () async {
    for (final brand in await repository.brands()) {
      final models = await repository.models(brand.id);
      if (brand.modelsLoaded) {
        expect(models.length, inInclusiveRange(3, 4), reason: brand.id);
      } else {
        expect(models, isEmpty, reason: '${brand.id} is phase 2 data');
      }
    }
  });

  test('every model has both names and belongs to its brand', () async {
    for (final brand in await repository.brands()) {
      for (final model in await repository.models(brand.id)) {
        expect(model.nameEn.trim(), isNotEmpty, reason: model.id);
        expect(model.nameAr.trim(), isNotEmpty, reason: model.id);
        expect(model.brandId, brand.id);
        expect(model.id, startsWith('${brand.id}-'));
      }
    }
  });

  test('model ids are unique', () async {
    final ids = <String>[];
    for (final brand in await repository.brands()) {
      ids.addAll((await repository.models(brand.id)).map((m) => m.id));
    }
    expect(ids.toSet(), hasLength(ids.length));
  });
}
