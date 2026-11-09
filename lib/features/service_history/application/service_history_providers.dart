import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/mock_config.dart';
import '../../privacy/application/consent_providers.dart';
import '../data/service_record_repository.dart';

/// Swap for the Drift-backed repository later.
final serviceRecordRepositoryProvider = Provider<ServiceRecordRepository>(
  (ref) => MockServiceRecordRepository.forScenario(MockConfig.scenario, now: ref.read(clockProvider)()),
);
