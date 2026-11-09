import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_garage/features/vehicles/application/vehicle_draft_controller.dart';
import 'package:tdc_garage/features/vehicles/domain/body_type.dart';
import 'package:tdc_garage/features/vehicles/domain/fuel_type.dart';
import 'package:tdc_garage/features/vehicles/domain/paint_color.dart';
import 'package:tdc_garage/features/vehicles/domain/vehicle_details.dart';

void main() {
  late ProviderContainer container;
  VehicleDraftController draft() => container.read(vehicleDraftProvider.notifier);

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('choosing a model keeps the brand', () {
    draft().setBrand(brandId: 'toyota');
    draft().setModel(modelId: 'toyota-camry', bodyType: BodyType.sedan);
    final state = container.read(vehicleDraftProvider);
    expect(state.brandId, 'toyota');
    expect(state.modelId, 'toyota-camry');
    expect(state.hasModel, isTrue);
  });

  test('choosing the same brand again keeps the model', () {
    draft().setBrand(brandId: 'toyota');
    draft().setModel(modelId: 'toyota-camry', bodyType: BodyType.sedan);
    draft().setBrand(brandId: 'toyota');
    expect(container.read(vehicleDraftProvider).modelId, 'toyota-camry');
  });

  test('choosing a different brand clears the model', () {
    draft().setBrand(brandId: 'toyota');
    draft().setModel(modelId: 'toyota-camry', bodyType: BodyType.sedan);
    draft().setBrand(brandId: 'kia');
    final state = container.read(vehicleDraftProvider);
    expect(state.brandId, 'kia');
    expect(state.modelId, isNull);
    expect(state.bodyType, isNull);
  });

  test('a typed model needs a name and a body type', () {
    draft().setBrand(otherName: 'Proton');
    draft().setModel(otherName: '  Saga ', bodyType: BodyType.sedan);
    final state = container.read(vehicleDraftProvider);
    expect(state.modelOtherName, 'Saga');
    expect(state.hasModel, isTrue);
  });

  test('changing the model keeps S-06 answers but takes the new body type', () {
    draft().setBrand(brandId: 'toyota');
    draft().setModel(modelId: 'toyota-camry', bodyType: BodyType.sedan);
    draft().setDetails(
      const VehicleDetails(
        fuelType: FuelType.hybrid,
        odometerKm: 54320,
        paint: PaintColor.racingRed,
        bodyType: BodyType.sedan,
        nickname: 'Daily',
      ),
    );
    draft().setModel(modelId: 'toyota-hilux', bodyType: BodyType.pickup);
    final details = container.read(vehicleDraftProvider).details!;
    expect(details.odometerKm, 54320);
    expect(details.nickname, 'Daily');
    expect(details.bodyType, BodyType.pickup);
  });
}
