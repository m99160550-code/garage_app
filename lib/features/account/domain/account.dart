import 'package:flutter/foundation.dart';

/// Whether this device's garage is backed up (FR-USR-12, FR-SET-01).
sealed class AccountState {
  const AccountState();
}

/// No account: the garage is only on this phone (BR-USR-07).
final class GuestAccount extends AccountState {
  const GuestAccount();
}

/// Signed in; the garage syncs to the account.
@immutable
final class OwnerAccount extends AccountState {
  const OwnerAccount({
    required this.name,
    required this.email,
    required this.sync,
    this.emailVerified = true,
    this.signedInAt,
  });

  final String name;
  final String email;
  final bool emailVerified;
  final SyncState sync;

  /// The last sign-in or re-authentication. Deleting the account asks to
  /// sign in again when it was more than 5 minutes ago (spec S-30).
  final DateTime? signedInAt;

  OwnerAccount copyWith({SyncState? sync, DateTime? signedInAt}) => OwnerAccount(
    name: name,
    email: email,
    emailVerified: emailVerified,
    sync: sync ?? this.sync,
    signedInAt: signedInAt ?? this.signedInAt,
  );

  /// The name, or the email for accounts without one (Apple relay, a new
  /// email account).
  String get displayName => name.trim().isEmpty ? email : name;

  /// "SA" from "Sara Al-Amri"; the email's first letter without a name.
  String get initials {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return email.isEmpty ? '?' : email[0].toUpperCase();
    final letters = words.length == 1 ? words.first.substring(0, 1) : '${words.first[0]}${words.last[0]}';
    return letters.toUpperCase();
  }
}

/// The sync line on the account card (spec S-24 item 1).
sealed class SyncState {
  const SyncState();
}

final class Synced extends SyncState {
  const Synced(this.at);

  final DateTime at;
}

/// Changes on this phone not yet sent (BR-USR-04 applies at sign-out).
final class SyncPending extends SyncState {
  const SyncPending(this.count);

  final int count;
}

/// Sending changes now: the spinning indicator (spec S-34).
final class SyncInProgress extends SyncState {
  const SyncInProgress(this.count);

  final int count;
}

final class SyncOffline extends SyncState {
  const SyncOffline({this.pending = 0});

  final int pending;
}

extension SyncPendingCount on SyncState {
  int get pendingChanges => switch (this) {
    SyncPending(:final count) => count,
    SyncInProgress(:final count) => count,
    SyncOffline(:final pending) => pending,
    Synced() => 0,
  };
}
