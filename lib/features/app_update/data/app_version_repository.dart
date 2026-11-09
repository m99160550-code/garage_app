/// Asks the server whether this app version is still supported (the API
/// answers 426 Upgrade Required otherwise). Screens only depend on this
/// interface.
abstract interface class AppVersionRepository {
  Future<bool> isSupported();
}

/// Development stand-in: [supported] `false` shows S-34 "Update required".
class MockAppVersionRepository implements AppVersionRepository {
  const MockAppVersionRepository({this.supported = true});

  final bool supported;

  @override
  Future<bool> isSupported() async => supported;
}

/// Opens this app's page in the App Store or Google Play (a launcher
/// plugin later).
class StoreLauncher {
  int opened = 0;

  Future<void> openStorePage() async => opened++;
}
