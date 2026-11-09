import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../service_history/application/service_history_providers.dart';
import '../data/expense_repository.dart';

/// Totals from the service records (local first).
final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => LocalExpenseRepository(ref.watch(serviceRecordRepositoryProvider)),
);
