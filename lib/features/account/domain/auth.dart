import 'account.dart';

/// How a sign-in attempt ended (FR-USR-01, NFR-SEC-05, UC-05 4a).
sealed class AuthOutcome {
  const AuthOutcome();
}

final class AuthSucceeded extends AuthOutcome {
  const AuthSucceeded(this.account, {required this.isNewAccount});

  final OwnerAccount account;

  /// A new account (sign-up) rather than an existing one: decides between
  /// uploading this device's garage and offering merge or discard (S-29).
  final bool isNewAccount;
}

final class WrongPassword extends AuthOutcome {
  const WrongPassword();
}

/// Too many wrong passwords: locked for a while (NFR-SEC-05).
final class TooManyAttempts extends AuthOutcome {
  const TooManyAttempts();
}

final class NoConnection extends AuthOutcome {
  const NoConnection();
}

/// The user closed the Apple or Google sheet.
final class AuthCancelled extends AuthOutcome {
  const AuthCancelled();
}

/// At least 8 characters (NFR-SEC-06).
const minPasswordLength = 8;

/// A plain shape check; the server has the final word.
bool looksLikeEmail(String value) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
