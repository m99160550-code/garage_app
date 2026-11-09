import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/mock_config.dart';
import '../data/app_version_repository.dart';

/// Swap for the API-backed check later.
final appVersionRepositoryProvider = Provider<AppVersionRepository>(
  (ref) => const MockAppVersionRepository(supported: !MockConfig.updateRequired),
);

final storeLauncherProvider = Provider<StoreLauncher>((ref) => StoreLauncher());

/// Whether the app must be updated before it can be used (spec S-34
/// "Update required"). Checked at launch; the API client also calls
/// [require] when any request answers 426.
class UpdateGate extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async => !await ref.watch(appVersionRepositoryProvider).isSupported();

  void require() => state = const AsyncData(true);
}

final updateRequiredProvider = AsyncNotifierProvider<UpdateGate, bool>(UpdateGate.new);
