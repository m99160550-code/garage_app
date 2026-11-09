import '../domain/consent.dart';

/// Stores consent decisions (locally, then synced as `POST /me/consents`).
abstract interface class ConsentRepository {
  Future<void> record(ConsentRecord record);
}

/// In-memory version used until the local database exists.
class MockConsentRepository implements ConsentRepository {
  final List<ConsentRecord> records = [];

  @override
  Future<void> record(ConsentRecord record) async => records.add(record);
}
