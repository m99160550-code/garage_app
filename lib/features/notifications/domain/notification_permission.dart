/// The system notification permission (FR-USR-08).
enum NotificationPermission {
  /// Never asked: the system prompt can still be shown.
  notDetermined,
  granted,

  /// Declined earlier: only the system Settings app can change it.
  denied,
}

/// What happened when the user tapped the primer's main button.
enum PrimerResult { granted, denied, openedSettings }
