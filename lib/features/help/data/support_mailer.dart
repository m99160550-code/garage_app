/// Opens the phone's mail composer (a launcher plugin later). Screens only
/// depend on this interface.
abstract interface class SupportMailer {
  /// `false` when no mail app can open; the caller offers the address
  /// instead.
  Future<bool> compose({required String to, required String subject, required String body});
}

/// Records the email instead of opening a mail app. [available] `false`
/// simulates a phone without one.
class MockSupportMailer implements SupportMailer {
  MockSupportMailer({this.available = true});

  bool available;
  ({String to, String subject, String body})? last;

  @override
  Future<bool> compose({required String to, required String subject, required String body}) async {
    if (!available) return false;
    last = (to: to, subject: subject, body: body);
    return true;
  }
}
