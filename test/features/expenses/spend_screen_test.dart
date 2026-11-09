import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tdc_garage/core/format/app_formatters.dart';
import 'package:tdc_garage/core/widgets/stat_card.dart';
import 'package:tdc_garage/features/expenses/domain/spend_summary.dart';
import 'package:tdc_garage/features/expenses/presentation/spend_screen.dart';
import 'package:tdc_garage/features/garage/application/current_vehicle_controller.dart';
import 'package:tdc_garage/features/garage/presentation/dashboard_screen.dart';
import 'package:tdc_garage/features/privacy/application/consent_providers.dart';
import 'package:tdc_garage/features/service_history/application/service_history_providers.dart';
import 'package:tdc_garage/features/service_history/data/service_record_repository.dart';
import 'package:tdc_garage/features/service_history/domain/service_record.dart';
import 'package:tdc_garage/features/service_history/presentation/widgets/service_record_row.dart';
import 'package:tdc_garage/features/session/data/mock_session_repository.dart';
import 'package:tdc_garage/features/settings/application/locale_controller.dart';
import 'package:tdc_garage/features/settings/application/preferences_providers.dart';
import 'package:tdc_garage/features/settings/data/preferences_repository.dart';
import 'package:tdc_garage/features/settings/domain/regional_preferences.dart';
import 'package:tdc_garage/features/vehicles/application/garage_providers.dart';
import 'package:tdc_garage/features/vehicles/data/garage_repository.dart';

import 'package:tdc_garage/features/service_history/presentation/service_record_screen.dart';

import 'package:tdc_garage/features/service_history/presentation/log_service_screen.dart';

import 'package:tdc_garage/features/settings/presentation/region/currency_screen.dart';

import '../../helpers/test_app.dart';

final _now = DateTime(2026, 11, 7, 10);
final _records = MockServiceRecordRepository.sampleRecordsAt(_now);

class _FixedLocale extends LocaleController {
  _FixedLocale(this.locale);

  final Locale locale;

  @override
  Locale? build() => locale;
}

List<ServiceRecord> _of(String vehicleId) => _records.where((r) => r.vehicleId == vehicleId).toList();

/// Launches the sample garage on [vehicle] and opens S-19 (unless
/// [open] is false).
Future<void> _launch(
  WidgetTester tester, {
  String vehicle = 'veh-camry',
  Size? screen,
  String? language,
  List<ServiceRecord>? records,
  bool open = true,
}) async {
  screen == null ? usePhoneScreen(tester) : useScreen(tester, screen);
  await tester.pumpWidget(
    buildTestApp(
      MockSessionRepository(scenario: 'returning'),
      overrides: [
        garageRepositoryProvider.overrideWithValue(MockGarageRepository.forScenario('returning', now: _now)),
        serviceRecordRepositoryProvider.overrideWithValue(MockServiceRecordRepository(records ?? _records)),
        clockProvider.overrideWithValue(() => _now),
        preferencesRepositoryProvider.overrideWithValue(
          MockPreferencesRepository(const RegionalPreferences(countryCode: 'SA', currency: 'SAR')),
        ),
        if (language != null) localeControllerProvider.overrideWith(() => _FixedLocale(Locale(language))),
      ],
    ),
  );
  await finishLaunch(tester);
  if (vehicle != 'veh-camry') {
    final container = ProviderScope.containerOf(tester.element(find.byType(DashboardScreen)));
    await container.read(currentVehicleProvider.notifier).select(vehicle);
    await tester.pumpAndSettle();
  }
  if (open) {
    GoRouter.of(tester.element(find.byType(DashboardScreen))).push('/garage/spend');
    await tester.pumpAndSettle();
    expect(find.byType(SpendScreen), findsOneWidget);
  }
}

/// The total on the Spending screen (ChromeText may draw more than one
/// layer, and the dashboard card underneath shows the same amount).
Finder _total(String text) => find.descendant(of: find.byType(SpendScreen), matching: find.text(text));

List<ServiceRecordRow> _rows(WidgetTester tester) =>
    tester.widgetList<ServiceRecordRow>(find.byType(ServiceRecordRow)).toList();

void main() {
  group('spend rules (FR-EXP-01, BR-EXP-01, BR-EXP-03)', () {
    test('Camry 2026: three SAR services, newest first, no other currencies', () {
      final spend = summariseSpend(_of('veh-camry'), year: 2026, currency: 'SAR');
      expect(spend.totalMinor, 42000);
      expect(spend.serviceCount, 3);
      expect(spend.records.map((r) => r.id), ['rec-camry-4', 'rec-camry-3', 'rec-camry-2']);
      expect(spend.hasOtherCurrencies, isFalse);
    });

    test('records without a cost are not listed', () {
      final spend = summariseSpend(_of('veh-camry'), year: 2026, currency: 'SAR');
      expect(spend.records.any((r) => r.id == 'rec-camry-5'), isFalse);
    });

    test('Patrol 2026: the AED record is listed but not added (no conversion)', () {
      final spend = summariseSpend(_of('veh-patrol'), year: 2026, currency: 'SAR');
      expect(spend.totalMinor, 115000);
      expect(spend.serviceCount, 2);
      expect(spend.records, hasLength(3));
      expect(spend.hasOtherCurrencies, isTrue);
      expect(spend.isIncluded(spend.records.last), isFalse);
    });

    test('another active currency only adds that currency', () {
      final spend = summariseSpend(_of('veh-patrol'), year: 2026, currency: 'AED');
      expect((spend.totalMinor, spend.serviceCount, spend.hasOtherCurrencies), (60000, 1, true));
    });

    test('years run from the first year with a cost to this year, never later', () {
      expect(spendYears(_of('veh-camry'), currentYear: 2026), [2025, 2026]);
      expect(spendYears(const [], currentYear: 2026), [2026]);
      final future = ServiceRecord(
        id: 'f',
        vehicleId: 'v',
        date: DateTime(2027, 1, 1),
        type: ServiceType.other,
        costMinor: 100,
        currency: 'SAR',
        createdAt: _now,
      );
      expect(spendYears([future], currentYear: 2026), [2026]);
    });

    test('money uses each currency\'s decimals (BR-EXP-04)', () {
      const en = AppFormatters(languageCode: 'en');
      expect(en.money(35000, 'SAR'), 'SAR\u00A0350');
      expect(en.money(34950, 'SAR'), 'SAR\u00A0349.50');
      expect(en.money(12500, 'KWD'), 'KWD\u00A012.500');
      expect(en.money(1200, 'JPY'), 'JPY\u00A01,200');
      expect(const AppFormatters(languageCode: 'ar').money(35000, 'SAR'), '350\u00A0ر.س');
    });
  });

  group('S-19 Spending', () {
    testWidgets('the This year card opens Spending with the total and records', (tester) async {
      await _launch(tester, screen: const Size(1024, 768), open: false);
      await tester.tap(find.byWidgetPredicate((w) => w is StatCard && w.label == 'This year'));
      await tester.pumpAndSettle();

      expect(find.byType(SpendScreen), findsOneWidget);
      expect(find.text('Spending'), findsOneWidget);
      expect(find.text('2026'), findsOneWidget);
      expect(_total('SAR\u00A0420'), findsWidgets);
      expect(find.text('3 services in 2026'), findsOneWidget);
      expect(_rows(tester).map((r) => r.record.id), ['rec-camry-4', 'rec-camry-3', 'rec-camry-2']);
      expect(find.text('Tires and rotation'), findsWidgets);
      expect(find.text('Repair'), findsOneWidget, reason: 'a record without items shows its type');
      expect(find.textContaining('Bridgestone Olaya · 52,100'), findsOneWidget);
      // The card on the dashboard equals the screen's total (BR-EXP-01).
      expect(tester.takeException(), isNull);
    });

    testWidgets('the year selector goes back to 2025 and stops there', (tester) async {
      await _launch(tester);
      final next = find.byTooltip('Next year');
      final previous = find.byTooltip('Previous year');
      expect(
        tester
            .widget<IconButton>(find.ancestor(of: find.byIcon(Icons.chevron_right), matching: find.byType(IconButton)))
            .onPressed,
        isNull,
      );

      await tester.tap(previous);
      await tester.pumpAndSettle();
      expect(find.text('2025'), findsOneWidget);
      expect(find.text('SAR\u00A0350'), findsWidgets);
      expect(find.text('Engine oil, Oil filter'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(find.ancestor(of: find.byIcon(Icons.chevron_left), matching: find.byType(IconButton)))
            .onPressed,
        isNull,
      );

      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(find.text('2026'), findsOneWidget);
    });

    testWidgets('other currencies: banner, "Not in total" and Change currency', (tester) async {
      await _launch(tester, vehicle: 'veh-patrol');

      expect(_total('SAR\u00A01,150'), findsWidgets);
      expect(find.text('2 services in 2026'), findsOneWidget);
      expect(find.text("Records in other currencies aren't included."), findsOneWidget);
      await tester.scrollUntilVisible(find.text('AED\u00A0600'), 200);
      expect(find.text('Not in total'), findsOneWidget);
    });

    testWidgets('Change currency opens the currency setting (S-25)', (tester) async {
      await _launch(tester, vehicle: 'veh-patrol');
      await tester.tap(find.text('Change currency'));
      await tester.pumpAndSettle();
      expect(find.byType(CurrencyScreen), findsOneWidget);
    });

    testWidgets('a record opens S-21', (tester) async {
      await _launch(tester);
      await tester.tap(find.byType(ServiceRecordRow).first);
      await tester.pumpAndSettle();
      expect(find.byType(ServiceRecordScreen), findsOneWidget);
      expect(GoRouterState.of(tester.element(find.byType(ServiceRecordScreen))).uri.path, '/garage/record/rec-camry-4');
    });

    testWidgets('empty: "No costs logged in 2026" and Log service', (tester) async {
      await _launch(tester, records: const []);
      expect(_total('SAR\u00A00'), findsWidgets);
      expect(find.text('No costs logged in 2026'), findsOneWidget);
      expect(find.byTooltip('Previous year'), findsOneWidget);
      await tester.tap(find.text('Log service'));
      await tester.pumpAndSettle();
      expect(find.byType(LogServiceScreen), findsOneWidget);
    });

    testWidgets('Arabic: translated, amounts with the symbol after, no overflow', (tester) async {
      await _launch(tester, vehicle: 'veh-patrol', language: 'ar');
      expect(find.text('المصروفات'), findsOneWidget);
      expect(_total('1,150\u00A0ر.س'), findsWidgets);
      expect(find.text('صيانتان في 2026'), findsOneWidget);
      expect(find.text('السجلات بعملات أخرى غير مشمولة.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tablet: content at most 720 wide', (tester) async {
      await _launch(tester, screen: const Size(1366, 1024));
      expect(tester.getSize(find.byType(ServiceRecordRow).first).width, lessThanOrEqualTo(720));
      expect(tester.takeException(), isNull);
    });

    testWidgets('meets tap-target and contrast guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await _launch(tester, vehicle: 'veh-patrol', screen: const Size(390, 1600));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });
}
