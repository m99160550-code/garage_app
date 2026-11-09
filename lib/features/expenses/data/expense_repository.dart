import '../../service_history/data/service_record_repository.dart';
import '../domain/spend_summary.dart';

/// Spend totals (architecture `v_vehicle_spend_year`). Screens only depend
/// on this interface.
abstract interface class ExpenseRepository {
  Future<SpendSummary> spend(String vehicleId, {required int year, required String currency});

  /// Years to offer in the year selector, oldest first.
  Future<List<int>> years(String vehicleId, {required int currentYear});
}

/// Totals worked out from the local service records, so the dashboard
/// card always equals the records behind it (BR-EXP-01). v1.1 adds fuel
/// and other expenses here.
class LocalExpenseRepository implements ExpenseRepository {
  const LocalExpenseRepository(this._records);

  final ServiceRecordRepository _records;

  @override
  Future<SpendSummary> spend(String vehicleId, {required int year, required String currency}) async =>
      summariseSpend(await _records.records(vehicleId), year: year, currency: currency);

  @override
  Future<List<int>> years(String vehicleId, {required int currentYear}) async =>
      spendYears(await _records.records(vehicleId), currentYear: currentYear);
}
