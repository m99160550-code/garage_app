import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/mock_config.dart';
import '../data/mock_session_repository.dart';
import '../data/session_repository.dart';
import '../domain/app_session.dart';

/// Swap this override for the Drift-backed repository later.
final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => MockSessionRepository(
    scenario: MockConfig.scenario,
    latency: const Duration(milliseconds: MockConfig.launchLatencyMs),
  ),
);

final appSessionProvider = FutureProvider<AppSession>((ref) => ref.watch(sessionRepositoryProvider).load());
