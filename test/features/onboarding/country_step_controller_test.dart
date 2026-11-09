import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_garage/features/onboarding/application/country_step_controller.dart';
import 'package:tdc_garage/features/privacy/application/consent_providers.dart';
import 'package:tdc_garage/features/privacy/data/consent_repository.dart';
import 'package:tdc_garage/features/session/application/session_providers.dart';
import 'package:tdc_garage/features/session/data/mock_session_repository.dart';
import 'package:tdc_garage/features/session/domain/app_session.dart';
import 'package:tdc_garage/features/settings/application/preferences_providers.dart';
import 'package:tdc_garage/features/settings/data/preferences_repository.dart';
import 'package:tdc_garage/features/settings/domain/distance_unit.dart';

class _Harness {
  _Harness(String? region) {
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        deviceRegionProvider.overrideWithValue(region),
        preferencesRepositoryProvider.overrideWithValue(preferences),
        consentRepositoryProvider.overrideWithValue(consents),
        sessionRepositoryProvider.overrideWithValue(session),
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 11, 7, 9)),
      ],
    );
    // Keep the auto-dispose provider alive for the test.
    container.listen(countryStepControllerProvider, (_, _) {});
  }

  late final ProviderContainer container;
  final preferences = MockPreferencesRepository();
  final consents = MockConsentRepository();
  final session = MockSessionRepository(scenario: 'countryStep');

  Future<CountryStepState> load() => container.read(countryStepControllerProvider.future);
  CountryStepController get controller => container.read(countryStepControllerProvider.notifier);
  CountryStepState get state => container.read(countryStepControllerProvider).requireValue;
}

void main() {
  test('preselects the device region country and its presets', () async {
    final h = _Harness('SA');
    final state = await h.load();
    expect(state.selected?.code, 'SA');
    expect(state.preferences.currency, 'SAR');
    expect(state.preferences.distanceUnit, DistanceUnit.km);
    expect(state.consentRequired, isFalse);
    expect(state.canContinue, isTrue);
  });

  test('an unknown region selects nothing and asks for consent', () async {
    final h = _Harness(null);
    final state = await h.load();
    expect(state.selected, isNull);
    expect(state.preferences.currency, 'USD');
    expect(state.consentRequired, isTrue);
    expect(state.canContinue, isFalse);
  });

  test('consent follows the device region, not the chosen country', () async {
    final h = _Harness('DE');
    await h.load();
    final egypt = h.state.countries.firstWhere((c) => c.code == 'EG');
    h.controller.selectCountry(egypt);
    expect(h.state.consentRequired, isTrue);
    expect(h.state.preferences.currency, 'EGP');
  });

  test('submitting saves presets, consent and the next setup step', () async {
    final h = _Harness('GB');
    await h.load();
    h.controller.setAnalyticsAllowed(allowed: false);
    await h.controller.submit();

    final saved = await h.preferences.load();
    expect(saved.countryCode, 'GB');
    expect(saved.currency, 'GBP');
    expect(saved.distanceUnit, DistanceUnit.mi);
    expect(saved.analyticsEnabled, isFalse);

    expect(h.consents.records, hasLength(1));
    expect(h.consents.records.single.granted, isFalse);
    expect(h.consents.records.single.regionCode, 'GB');
    expect((await h.session.load()).setupDraftStep, SetupStep.brand);
  });

  test('outside consent regions nothing is recorded and analytics stays on', () async {
    final h = _Harness('AE');
    await h.load();
    await h.controller.submit();
    expect(h.consents.records, isEmpty);
    expect((await h.preferences.load()).analyticsEnabled, isTrue);
  });

  test('submit refuses to continue without a required consent choice', () async {
    final h = _Harness('FR');
    await h.load();
    expect(h.controller.submit, throwsStateError);
  });
}
