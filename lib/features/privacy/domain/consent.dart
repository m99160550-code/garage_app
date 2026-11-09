import 'package:flutter/foundation.dart';

enum ConsentPurpose { analytics, diagnostics }

/// One consent decision, only ever added (architecture `consent_records`).
@immutable
class ConsentRecord {
  const ConsentRecord({
    required this.purpose,
    required this.granted,
    required this.regionCode,
    required this.policyVersion,
    required this.recordedAt,
  });

  final ConsentPurpose purpose;
  final bool granted;

  /// Device region when the decision was made.
  final String? regionCode;
  final String policyVersion;
  final DateTime recordedAt;
}

/// Privacy policy version shown with the consent request.
const currentPolicyVersion = '2026-11';

/// Regions where analytics needs opt-in consent (D25, BR-PRV-01): the EU,
/// the rest of the EEA (A-06), the UK and Switzerland.
const _consentRegions = {
  'AT', 'BE', 'BG', 'HR', 'CY', 'CZ', 'DK', 'EE', 'FI', 'FR', 'DE', 'GR', //
  'HU', 'IE', 'IT', 'LV', 'LT', 'LU', 'MT', 'NL', 'PL', 'PT', 'RO', 'SK', //
  'SI', 'ES', 'SE', 'IS', 'LI', 'NO', 'GB', 'CH',
};

/// Consent follows the device region, never the chosen country, and an
/// unknown region is asked too (BR-PRV-01, BR-PRV-03, BR-SET-06).
bool analyticsConsentRequired(String? deviceRegion) =>
    deviceRegion == null || _consentRegions.contains(deviceRegion.toUpperCase());
