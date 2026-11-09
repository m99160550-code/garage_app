import '../domain/account.dart';

/// The signed-in account and sync (Supabase Auth and the sync engine
/// later). Screens only depend on this interface.
abstract interface class AccountRepository {
  Future<AccountState> load();

  /// Sends waiting changes (BR-USR-04 "Sync now").
  Future<void> syncNow();

  /// Back to Guest. Waiting changes are dropped ("Discard and sign out").
  Future<void> signOut();

  Future<void> resendVerificationEmail();

  /// Records a successful sign-in (S-28) or re-authentication (S-30).
  Future<void> signedIn(OwnerAccount account);

  /// Deletes the account and its data on the server (FR-USR-06,
  /// BR-USR-05): live systems within 24 hours, backups within 30 days
  /// (NFR-SEC-09). `false` without a connection; nothing changes then.
  Future<bool> deleteAccount();
}

/// In-memory account for development, picked with `MOCK_ACCOUNT`.
class MockAccountRepository implements AccountRepository {
  MockAccountRepository([this._state = const GuestAccount()]);

  factory MockAccountRepository.fromConfig(String config, {required DateTime now}) {
    // Signed in yesterday: deleting the account asks to sign in again.
    OwnerAccount owner(SyncState sync, {bool verified = true}) => OwnerAccount(
      name: 'Sara Al-Amri',
      email: 'sara@example.com',
      emailVerified: verified,
      sync: sync,
      signedInAt: now.subtract(const Duration(days: 1)),
    );
    final syncedAt = now.subtract(const Duration(minutes: 2));
    return MockAccountRepository(switch (config) {
      'owner' => owner(Synced(syncedAt)),
      'ownerUnverified' => owner(Synced(syncedAt), verified: false),
      'ownerPending' => owner(const SyncPending(3)),
      'ownerSyncing' => owner(const SyncInProgress(3)),
      'ownerOffline' => owner(const SyncOffline(pending: 1)),
      _ => const GuestAccount(),
    });
  }

  AccountState _state;
  int verificationEmails = 0;

  /// Simulates no connection for [deleteAccount].
  bool online = true;
  bool deleted = false;

  @override
  Future<AccountState> load() async => _state;

  @override
  Future<void> syncNow() async {
    if (_state case final OwnerAccount owner) {
      _state = owner.copyWith(sync: Synced(DateTime.now()));
    }
  }

  @override
  Future<void> signOut() async => _state = const GuestAccount();

  @override
  Future<void> resendVerificationEmail() async => verificationEmails++;

  @override
  Future<void> signedIn(OwnerAccount account) async => _state = account;

  @override
  Future<bool> deleteAccount() async {
    if (!online) return false;
    deleted = true;
    _state = const GuestAccount();
    return true;
  }
}
