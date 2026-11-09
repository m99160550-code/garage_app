import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/mock_config.dart';
import '../data/help_repository.dart';
import '../data/support_mailer.dart';
import '../domain/help_article.dart';

/// Swap for the help-centre repository later.
final helpRepositoryProvider = Provider<HelpRepository>((ref) => MockHelpRepository(online: !MockConfig.helpOffline));

final helpContentProvider = FutureProvider.autoDispose<HelpContent>((ref) => ref.watch(helpRepositoryProvider).load());

/// Swap for a mail-launcher implementation later.
final supportMailerProvider = Provider<SupportMailer>((ref) => MockSupportMailer());
