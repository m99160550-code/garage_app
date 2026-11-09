import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/template_repository.dart';

/// Swap for the repository backed by the cached reference data later.
final templateRepositoryProvider = Provider<TemplateRepository>((ref) => const MockTemplateRepository());
