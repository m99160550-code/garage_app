import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/mock_config.dart';
import '../../privacy/application/consent_providers.dart';
import '../data/account_repository.dart';
import '../data/auth_repository.dart';
import '../domain/account.dart';

/// Swap for the Supabase-backed repository later.
final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => MockAccountRepository.fromConfig(MockConfig.account, now: ref.read(clockProvider)()),
);

/// The account as screens show it. Actions refresh it.
final accountProvider = FutureProvider<AccountState>((ref) => ref.watch(accountRepositoryProvider).load());

/// Sign out (BR-USR-04) and the other account actions on S-24.
class AccountActions {
  AccountActions(this._ref);

  final Ref _ref;

  AccountRepository get _repository => _ref.read(accountRepositoryProvider);

  /// [syncFirst]: "Sync now" sends the waiting changes, then signs out.
  /// Otherwise they are discarded.
  Future<void> signOut({required bool syncFirst}) async {
    if (syncFirst) await _repository.syncNow();
    await _repository.signOut();
    _ref.invalidate(accountProvider);
  }

  Future<void> resendVerificationEmail() => _repository.resendVerificationEmail();

  /// Stores the signed-in account and refreshes the screens that show it.
  Future<void> signedIn(OwnerAccount account) async {
    await _repository.signedIn(account.copyWith(signedInAt: _ref.read(clockProvider)()));
    _ref.invalidate(accountProvider);
  }
}

final accountActionsProvider = Provider<AccountActions>(AccountActions.new);

/// Swap for the Supabase Auth repository later.
final authRepositoryProvider = Provider<AuthRepository>((ref) => MockAuthRepository());

/// Opens the phone's mail app (S-28 E4). A mock until a launcher plugin is
/// added.
class MailLauncher {
  int opened = 0;

  Future<void> openMailApp() async => opened++;
}

final mailLauncherProvider = Provider<MailLauncher>((ref) => MailLauncher());

/// Where to go after signing in (spec S-28 "After success").
enum AfterSignIn {
  /// Upload this device's garage to the new account (S-29).
  upload,

  /// An existing account and a garage on this device: merge or discard
  /// (S-29, FR-USR-15).
  mergeOrDiscard,

  /// Back to where the user came from.
  back,
}

/// Records a successful sign-in and decides the next step.
AfterSignIn afterSignIn({required bool isNewAccount, required bool hasDeviceData}) {
  if (!hasDeviceData) return AfterSignIn.back;
  // A new account takes the device's garage (FR-USR-14).
  if (isNewAccount) return AfterSignIn.upload;
  return AfterSignIn.mergeOrDiscard;
}
