import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/consent_repository.dart';

final consentRepositoryProvider = Provider<ConsentRepository>((ref) => MockConsentRepository());

/// The clock, injectable so tests get fixed timestamps.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
