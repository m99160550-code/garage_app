import '../domain/account.dart';
import '../domain/auth.dart';

/// Sign-in with Apple, Google or email (Supabase Auth later). Screens only
/// depend on this interface.
abstract interface class AuthRepository {
  Future<AuthOutcome> signInWithApple();
  Future<AuthOutcome> signInWithGoogle();

  /// Whether an account uses [email] (E1 → E2a or E2b). `null` without a
  /// connection.
  Future<bool?> accountExists(String email);

  /// Creates an email account; its address is not verified yet (FR-USR-02).
  Future<AuthOutcome> signUp(String email, String password);
  Future<AuthOutcome> signIn(String email, String password);

  /// Sends a reset link (FR-USR-03). `false` without a connection.
  Future<bool> sendPasswordReset(String email);
  Future<void> resendVerification(String email);
}

/// In-memory accounts for development: `sara@example.com` exists with the
/// password `password123`; Google signs in to it, Apple creates a new
/// account. Five wrong passwords lock the account (NFR-SEC-05).
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({this.online = true});

  /// Simulates no connection (UC-05 4a).
  bool online;

  final Map<String, String> _passwords = {'sara@example.com': 'password123'};
  final Map<String, int> _wrongTries = {};
  int resetLinks = 0;
  int verificationEmails = 0;

  static const _maxTries = 5;

  OwnerAccount _owner(String email, {String name = 'Sara Al-Amri', bool verified = true}) =>
      OwnerAccount(name: name, email: email, emailVerified: verified, sync: Synced(DateTime.now()));

  @override
  Future<AuthOutcome> signInWithApple() async => online
      ? AuthSucceeded(_owner('relay@privaterelay.appleid.com', name: ''), isNewAccount: true)
      : const NoConnection();

  @override
  Future<AuthOutcome> signInWithGoogle() async =>
      online ? AuthSucceeded(_owner('sara@example.com'), isNewAccount: false) : const NoConnection();

  @override
  Future<bool?> accountExists(String email) async => online ? _passwords.containsKey(email.trim().toLowerCase()) : null;

  @override
  Future<AuthOutcome> signUp(String email, String password) async {
    if (!online) return const NoConnection();
    _passwords[email.trim().toLowerCase()] = password;
    verificationEmails++;
    return AuthSucceeded(_owner(email.trim(), name: '', verified: false), isNewAccount: true);
  }

  @override
  Future<AuthOutcome> signIn(String email, String password) async {
    if (!online) return const NoConnection();
    final key = email.trim().toLowerCase();
    if ((_wrongTries[key] ?? 0) >= _maxTries) return const TooManyAttempts();
    if (_passwords[key] != password) {
      _wrongTries[key] = (_wrongTries[key] ?? 0) + 1;
      return (_wrongTries[key]! >= _maxTries) ? const TooManyAttempts() : const WrongPassword();
    }
    _wrongTries.remove(key);
    return AuthSucceeded(_owner(email.trim()), isNewAccount: false);
  }

  @override
  Future<bool> sendPasswordReset(String email) async {
    if (!online) return false;
    resetLinks++;
    return true;
  }

  @override
  Future<void> resendVerification(String email) async => verificationEmails++;
}
