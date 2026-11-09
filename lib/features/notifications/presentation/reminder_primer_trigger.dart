import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/app_routes.dart';
import '../application/reminder_primer_service.dart';
import 'reminders_primer_sheet.dart';

/// Wraps the dashboard. When it opens with a newly saved vehicle
/// ([arrival]), the S-08 primer appears 800 ms after the dashboard settles,
/// if permission hasn't been asked yet and a reminder exists (spec S-07
/// "After save", FR-USR-08).
class ReminderPrimerTrigger extends ConsumerStatefulWidget {
  const ReminderPrimerTrigger({super.key, required this.arrival, required this.child, this.settleTime = Duration.zero});

  /// How long after the dashboard settles the primer appears.
  static const delay = Duration(milliseconds: 800);

  final DashboardArrival? arrival;
  final Widget child;

  /// How long the dashboard's own arrival animation runs.
  final Duration settleTime;

  @override
  ConsumerState<ReminderPrimerTrigger> createState() => _ReminderPrimerTriggerState();
}

class _ReminderPrimerTriggerState extends ConsumerState<ReminderPrimerTrigger> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final arrival = widget.arrival;
    if (arrival == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Wait for the page transition and the arrival animation, then the
      // spec's 800 ms.
      final transition = ModalRoute.of(context)?.transitionDuration ?? Duration.zero;
      // They run at the same time, so wait for the longer one.
      final settle = transition > widget.settleTime ? transition : widget.settleTime;
      _timer = Timer(settle + ReminderPrimerTrigger.delay, () => _offer(arrival.vehicleId));
    });
  }

  Future<void> _offer(String vehicleId) async {
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    final language = Localizations.localeOf(context).languageCode;
    final offer = await ref.read(reminderPrimerServiceProvider).offerAfterSetup(vehicleId, language);
    if (offer == null || !mounted) return;
    await showRemindersPrimer(context, ref, offer);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
