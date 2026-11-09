/// What S-30 removes (FR-USR-06, FR-USR-16).
enum EraseKind {
  /// Owner: the account and its data on every device (BR-USR-05).
  deleteAccount,

  /// Guest: everything on this phone, immediately (NFR-SEC-09).
  eraseDevice,
}

/// Deleting the account asks to sign in again when the last sign-in was
/// more than 5 minutes ago, or isn't known (spec S-30 item 5).
const reauthenticationWindow = Duration(minutes: 5);

bool needsReauthentication(DateTime? signedInAt, {required DateTime now}) =>
    signedInAt == null || now.difference(signedInAt) > reauthenticationWindow;

/// The typed confirmation matches the word, ignoring case and spaces
/// around it (spec S-30 item 3).
bool confirmationMatches(String typed, String word) => typed.trim().toUpperCase() == word.trim().toUpperCase();

/// How deleting the account ended.
enum EraseOutcome { done, offline }
