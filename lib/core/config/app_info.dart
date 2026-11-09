/// The app's name and version for the Profile footer (FR-SET-05). Keep in
/// step with `version:` in pubspec.yaml (the build pipeline will inject it
/// later).
abstract final class AppInfo {
  static const name = 'TDC-mena Garage';
  static const version = '0.1.0';
  static const build = '1';
}

/// Support and legal addresses (FR-SET-05, NFR-SUP-06). The support
/// address is a shared role address on TDC-mena's own domain, never a
/// personal inbox. Placeholders until the domain is confirmed.
abstract final class SupportInfo {
  static const email = 'support@tdc-mena.com';
  static const helpCentre = 'https://tdc-mena.com/garage/help';
  static const privacyPolicy = 'https://tdc-mena.com/garage/privacy';
  static const terms = 'https://tdc-mena.com/garage/terms';
}
