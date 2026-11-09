import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tdc_garage/core/widgets/app_text_field.dart';
import 'package:tdc_garage/features/add_menu/presentation/add_menu_sheet.dart';
import 'package:tdc_garage/features/garage/presentation/dashboard_screen.dart';
import 'package:tdc_garage/features/mileage/presentation/update_mileage_sheet.dart';
import 'package:tdc_garage/features/onboarding/presentation/brand/brand_selection_screen.dart';
import 'package:tdc_garage/features/privacy/application/consent_providers.dart';
import 'package:tdc_garage/features/service_history/application/service_history_providers.dart';
import 'package:tdc_garage/features/service_history/data/service_record_repository.dart';
import 'package:tdc_garage/features/service_history/presentation/log_service_screen.dart';
import 'package:tdc_garage/features/session/data/mock_session_repository.dart';
import 'package:tdc_garage/features/settings/application/locale_controller.dart';
import 'package:tdc_garage/features/settings/application/preferences_providers.dart';
import 'package:tdc_garage/features/settings/data/preferences_repository.dart';
import 'package:tdc_garage/features/settings/domain/regional_preferences.dart';
import 'package:tdc_garage/features/vehicles/application/garage_providers.dart';
import 'package:tdc_garage/features/vehicles/data/garage_repository.dart';
import 'package:tdc_garage/features/vehicles/domain/vehicle.dart';

import '../../helpers/test_app.dart';

final _now = DateTime(2026, 11, 7, 10);

class _FixedLocale extends LocaleController {
  _FixedLocale(this.locale);

  final Locale locale;

  @override
  Locale? build() => locale;
}

/// A garage of [count] copies of the sample Camry.
MockGarageRepository _copies(int count) {
  final camry = MockGarageRepository.sampleVehiclesAt(_now).first;
  return MockGarageRepository([
    for (var i = 0; i < count; i++)
      Vehicle(
        id: i == 0 ? camry.id : 'veh-$i',
        brandId: camry.brandId,
        modelId: camry.modelId,
        nickname: i == 0 ? camry.nickname : 'Car $i',
        fuelType: camry.fuelType,
        bodyType: camry.bodyType,
        odometerKm: camry.odometerKm,
        odometerUpdatedAt: camry.odometerUpdatedAt,
      ),
  ]);
}

/// Launches the app and taps "Add" in the floating bar (or the rail).
Future<void> _openAdd(WidgetTester tester, {MockGarageRepository? garage, Size? screen, String? language}) async {
  useScreen(tester, screen ?? const Size(390, 1000));
  await tester.pumpWidget(
    buildTestApp(
      MockSessionRepository(scenario: 'returning'),
      overrides: [
        garageRepositoryProvider.overrideWithValue(garage ?? MockGarageRepository.forScenario('returning', now: _now)),
        serviceRecordRepositoryProvider.overrideWithValue(
          MockServiceRecordRepository.forScenario('returning', now: _now),
        ),
        clockProvider.overrideWithValue(() => _now),
        preferencesRepositoryProvider.overrideWithValue(
          MockPreferencesRepository(const RegionalPreferences(countryCode: 'SA', currency: 'SAR')),
        ),
        if (language != null) localeControllerProvider.overrideWith(() => _FixedLocale(Locale(language))),
      ],
    ),
  );
  await finishLaunch(tester);
  await tester.tap(find.bySemanticsLabel(language == 'ar' ? 'إضافة' : 'Add').first);
  await tester.pumpAndSettle();
  expect(find.byType(AddMenuSheet), findsOneWidget);
}

Finder _inMenu(Finder finder) => find.descendant(of: find.byType(AddMenuSheet), matching: finder);

Future<void> _pickVehicle(WidgetTester tester, String name) async {
  await tester.tap(_inMenu(find.textContaining('For:')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists the actions for the dashboard car, most frequent first', (tester) async {
    await _openAdd(tester);

    expect(_inMenu(find.text('For: Family Camry')), findsOneWidget);
    expect(find.bySemanticsLabel('Log service, Record work done on your car'), findsOneWidget);
    expect(find.bySemanticsLabel('Update mileage, Current: 54,320\u00A0km'), findsOneWidget);
    expect(find.bySemanticsLabel('Add vehicle, Add another car to your garage'), findsOneWidget);
    final titles = ['Log service', 'Update mileage', 'Add vehicle'];
    final ys = [for (final t in titles) tester.getTopLeft(_inMenu(find.text(t))).dy];
    expect(ys, orderedEquals([...ys]..sort()));
  });

  testWidgets('Log service opens S-22 for the chosen car (FR-ADD-02)', (tester) async {
    await _openAdd(tester);
    await _pickVehicle(tester, 'Nissan Patrol');
    expect(find.bySemanticsLabel('Update mileage, Current: 121,400\u00A0km'), findsOneWidget);

    await tester.tap(_inMenu(find.text('Log service')));
    await tester.pumpAndSettle();
    expect(find.byType(AddMenuSheet), findsNothing);
    expect(find.byType(LogServiceScreen), findsOneWidget);
    expect(find.text('For: Nissan Patrol'), findsOneWidget);
    final odometer = find.descendant(
      of: find.widgetWithText(AppTextField, 'Odometer'),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(odometer).controller.text, '121,400');
  });

  testWidgets('Update mileage opens S-12 for the chosen car', (tester) async {
    await _openAdd(tester);
    await _pickVehicle(tester, 'Nissan Patrol');
    await tester.tap(_inMenu(find.text('Update mileage')));
    await tester.pumpAndSettle();
    expect(find.byType(UpdateMileageSheet), findsOneWidget);
    expect(tester.widget<UpdateMileageSheet>(find.byType(UpdateMileageSheet)).vehicleId, 'veh-patrol');
  });

  testWidgets('Add vehicle opens the add-vehicle flow', (tester) async {
    await _openAdd(tester);
    await tester.tap(_inMenu(find.text('Add vehicle')));
    await tester.pumpAndSettle();
    expect(find.byType(BrandSelectionScreen), findsOneWidget);
    expect(GoRouterState.of(tester.element(find.byType(BrandSelectionScreen))).uri.toString(), '/setup/brand?add=1');
  });

  testWidgets('one car: no vehicle row', (tester) async {
    await _openAdd(tester, garage: _copies(1));
    expect(_inMenu(find.textContaining('For:')), findsNothing);
    expect(_inMenu(find.text('Log service')), findsOneWidget);
  });

  testWidgets('at the 25-car limit "Add vehicle" is disabled (BR-VEH-01)', (tester) async {
    await _openAdd(tester, garage: _copies(25));
    expect(find.bySemanticsLabel('Add vehicle, Limit reached. Contact support.'), findsOneWidget);
    await tester.tap(_inMenu(find.text('Add vehicle')));
    await tester.pumpAndSettle();
    expect(find.byType(AddMenuSheet), findsOneWidget);
  });

  testWidgets('swiping down or tapping the scrim closes it without acting', (tester) async {
    await _openAdd(tester);
    await tester.tapAt(const Offset(200, 40));
    await tester.pumpAndSettle();
    expect(find.byType(AddMenuSheet), findsNothing);
    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('tablet: a 360 pt popover next to the rail', (tester) async {
    await _openAdd(tester, screen: const Size(1024, 768));
    expect(find.byType(Dialog), findsNothing);
    final rect = tester.getRect(find.byType(AddMenuSheet));
    expect(rect.width, lessThanOrEqualTo(360));
    expect(rect.left, lessThan(200));
  });

  testWidgets('Arabic: translated, no overflow', (tester) async {
    await _openAdd(tester, language: 'ar');
    expect(_inMenu(find.text('سجّل الأعمال التي أُنجزت على سيارتك')), findsOneWidget);
    expect(_inMenu(find.text('أضف سيارة أخرى إلى الكراج')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('meets tap-target and contrast guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await _openAdd(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
