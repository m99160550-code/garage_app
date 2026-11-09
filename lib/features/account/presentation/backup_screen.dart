import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_skeleton.dart';
import '../../../core/format/app_formatters.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_toast.dart';
import '../../vehicles/domain/vehicle.dart';
import '../application/backup_controller.dart';
import '../domain/backup.dart';
import 'widgets/upload_ring.dart';

/// Where S-29 starts after sign-in (S-28 "After success").
enum BackupStep { upload, merge }

enum _Phase { upload, choose, duplicates }

/// S-29 Back up your garage, steps 2 and 3 (UI/UX spec S-29, UC-05,
/// FR-USR-14, FR-USR-15, BR-USR-08):
///
/// * Upload: a 120 pt ring with the percentage. It can't be closed while
///   it runs; a lost connection pauses it, repeated failures offer Retry.
/// * Merge or discard, when the account already has a garage. Merge is
///   recommended; discard needs the word DISCARD typed. Over the account
///   limit, the user picks which vehicles to bring. After a merge, cars
///   with the same VIN are pointed out.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key, this.step = BackupStep.upload});

  final BackupStep step;

  static const maxWidth = 440.0;

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  late _Phase _phase = widget.step == BackupStep.merge ? _Phase.choose : _Phase.upload;
  UploadState _upload = const Uploading(0);
  StreamSubscription<UploadState>? _subscription;

  bool _merge = true;
  Set<String>? _bring;
  bool _busy = false;

  /// The data before the merge, for the duplicate names.
  BackupData? _beforeMerge;
  List<(Vehicle, Vehicle)> _duplicates = const [];

  @override
  void initState() {
    super.initState();
    if (_phase == _Phase.upload) _startUpload();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _startUpload() {
    _subscription?.cancel();
    setState(() {
      _phase = _Phase.upload;
      _upload = const Uploading(0);
    });
    _subscription = ref.read(backupActionsProvider).upload().listen((state) {
      if (mounted) setState(() => _upload = state);
    });
  }

  /// Leaving is blocked while the upload runs (spec S-29 step 2).
  bool get _canLeave => _phase != _Phase.upload || _upload is UploadFailed || _upload is UploadDone;

  void _leave() {
    if (_upload is UploadDone) {
      context.go(AppRoutes.profile);
    } else {
      context.pop();
    }
  }

  Future<void> _continue(BackupData data) async {
    if (_merge) {
      setState(() => _busy = true);
      final bring = data.overLimit
          ? _bring ?? {for (final v in data.device) v.id}
          : {for (final v in data.device) v.id};
      await ref.read(backupActionsProvider).merge(data, bring: bring);
      if (!mounted) return;
      final duplicates = duplicatesByVin([...data.device.where((v) => bring.contains(v.id))], data.account);
      setState(() => _busy = false);
      if (duplicates.isEmpty) {
        _startUpload();
      } else {
        setState(() {
          _beforeMerge = data;
          _duplicates = duplicates;
          _phase = _Phase.duplicates;
        });
      }
    } else {
      await _confirmDiscard(data);
    }
  }

  Future<void> _confirmDiscard(BackupData data) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(context: context, builder: (_) => const _DiscardDialog());
    if (!(confirmed ?? false) || !mounted) return;
    setState(() => _busy = true);
    await ref.read(backupActionsProvider).discard(data);
    if (!mounted) return;
    showAppToast(context, l10n.discardDone);
    context.go(AppRoutes.garage);
  }

  Future<void> _removeDuplicate(Vehicle device) async {
    await ref.read(backupActionsProvider).removeVehicle(device.id);
    if (!mounted) return;
    setState(() => _duplicates = [..._duplicates.where((pair) => pair.$1.id != device.id)]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final language = Localizations.localeOf(context).languageCode;
    final data = ref.watch(backupDataProvider(language)).value;

    return PopScope(
      canPop: _canLeave && _upload is! UploadDone,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _canLeave) _leave();
      },
      child: Scaffold(
        backgroundColor: colors.bgSheet,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: _canLeave
              ? IconButton(tooltip: l10n.actionClose, icon: const Icon(Icons.close), onPressed: _leave)
              : null,
          backgroundColor: colors.bgSheet,
          surfaceTintColor: Colors.transparent,
        ),
        body: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: BackupScreen.maxWidth),
              child: data == null
                  ? const DelayedSkeleton()
                  : switch (_phase) {
                      _Phase.upload => _UploadView(
                        state: _upload,
                        data: data,
                        onRetry: _startUpload,
                        // Contact is in the Profile tab, under this screen: go there.
                        onContact: () => context.go(AppRoutes.profileContact),
                        onDone: _leave,
                      ),
                      _Phase.choose => _ChooseView(
                        data: data,
                        merge: _merge,
                        bring: _bring ?? {for (final v in data.device) v.id},
                        busy: _busy,
                        onChoose: (merge) => setState(() => _merge = merge),
                        onBring: (bring) => setState(() => _bring = bring),
                        onContinue: () => _continue(data),
                      ),
                      _Phase.duplicates => _DuplicatesView(
                        data: _beforeMerge ?? data,
                        pairs: _duplicates,
                        onRemove: _removeDuplicate,
                        onContinue: _startUpload,
                      ),
                    },
            ),
          ),
        ),
      ),
    );
  }
}

/// The scrolling body with the buttons pinned below it.
class _Layout extends StatelessWidget {
  const _Layout({required this.children, this.buttons = const [], this.centered = false});

  final List<Widget> children;
  final List<Widget> buttons;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: centered ? constraints.maxHeight : 0),
                child: Column(
                  mainAxisAlignment: centered ? MainAxisAlignment.center : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ),
        ),
        if (buttons.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenMargin,
              AppSpacing.xs,
              AppSpacing.screenMargin,
              AppSpacing.md,
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: buttons),
          ),
      ],
    );
  }
}

class _UploadView extends StatelessWidget {
  const _UploadView({
    required this.state,
    required this.data,
    required this.onRetry,
    required this.onContact,
    required this.onDone,
  });

  final UploadState state;
  final BackupData data;
  final VoidCallback onRetry;
  final VoidCallback onContact;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final formatter = AppFormatters(languageCode: Localizations.localeOf(context).languageCode);
    String percent(double progress) => l10n.backupPercent(formatter.integer((progress * 100).round()));

    Widget title(String value) => Semantics(
      header: true,
      liveRegion: true,
      child: Text(value, style: text.titleL, textAlign: TextAlign.center),
    );
    Widget body(String value) => Text(
      value,
      style: text.bodyS.copyWith(color: colors.textSecondary),
      textAlign: TextAlign.center,
    );

    return switch (state) {
      Uploading(:final progress) => _Layout(
        centered: true,
        children: [
          UploadRing(progress: progress, label: percent(progress)),
          const SizedBox(height: AppSpacing.xl),
          title(l10n.backupProgress(l10n.backupVehicles(data.device.length), l10n.backupRecords(data.records))),
        ],
      ),
      WaitingForConnection(:final progress) => _Layout(
        centered: true,
        children: [
          UploadRing(progress: progress, label: percent(progress), paused: true),
          const SizedBox(height: AppSpacing.xl),
          title(l10n.backupWaiting),
        ],
      ),
      UploadFailed() => _Layout(
        centered: true,
        buttons: [
          AppButton(label: l10n.actionRetry, onPressed: onRetry),
          const SizedBox(height: AppSpacing.xxs),
          Center(
            child: AppButton.text(label: l10n.profileContact, onPressed: onContact),
          ),
        ],
        children: [
          ExcludeSemantics(child: Icon(Icons.cloud_off_outlined, size: 56, color: colors.warning)),
          const SizedBox(height: AppSpacing.lg),
          title(l10n.backupFailedTitle),
          const SizedBox(height: AppSpacing.xs),
          body(l10n.backupFailedBody),
        ],
      ),
      UploadDone() => _Layout(
        centered: true,
        buttons: [AppButton(label: l10n.backupDone, onPressed: onDone)],
        children: [
          const UploadCheck(),
          const SizedBox(height: AppSpacing.xl),
          title(l10n.backupDoneTitle),
        ],
      ),
    };
  }
}

class _ChooseView extends StatelessWidget {
  const _ChooseView({
    required this.data,
    required this.merge,
    required this.bring,
    required this.busy,
    required this.onChoose,
    required this.onBring,
    required this.onContinue,
  });

  final BackupData data;
  final bool merge;
  final Set<String> bring;
  final bool busy;
  final ValueChanged<bool> onChoose;
  final ValueChanged<Set<String>> onBring;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final allowed = vehiclesThatFit(account: data.account.length);
    final picking = merge && data.overLimit;
    final fits = !picking || bring.length <= allowed;

    return _Layout(
      buttons: [AppButton(label: l10n.actionContinue, isLoading: busy, onPressed: fits && !busy ? onContinue : null)],
      children: [
        Semantics(header: true, child: Text(l10n.mergeTitle, style: text.headline)),
        const SizedBox(height: AppSpacing.lg),
        _ChoiceCard(
          selected: merge,
          title: l10n.mergeOption,
          badge: l10n.mergeRecommended,
          body: l10n.mergeOptionBody(l10n.backupVehicles(data.device.length), l10n.backupVehicles(data.account.length)),
          onTap: () => onChoose(true),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ChoiceCard(
          selected: !merge,
          destructive: true,
          title: l10n.discardOption,
          body: l10n.discardOptionBody(l10n.backupVehicles(data.device.length)),
          onTap: () => onChoose(false),
        ),
        if (picking) ...[
          const SizedBox(height: AppSpacing.xl),
          Semantics(header: true, child: Text(l10n.limitTitle, style: text.titleM)),
          const SizedBox(height: AppSpacing.xxs),
          Text(l10n.limitBody, style: text.bodyS.copyWith(color: colors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            liveRegion: true,
            child: Text(
              l10n.limitCounter(allowed, data.device.length),
              style: text.label.copyWith(color: fits ? colors.textSecondary : colors.warning),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final v in data.device)
            CheckboxListTile(
              value: bring.contains(v.id),
              title: Text(data.nameOf(v), style: text.body),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (on) => onBring(on ?? false ? {...bring, v.id} : bring.difference({v.id})),
            ),
        ],
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

/// A radio card (spec S-29 step 3): the title, a line on what happens and
/// a ring that fills when selected. The destructive one is red.
class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.selected,
    required this.title,
    required this.body,
    required this.onTap,
    this.badge,
    this.destructive = false,
  });

  final bool selected;
  final String title;
  final String body;
  final String? badge;
  final bool destructive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final accent = destructive ? colors.destructiveText : colors.accentPrimary;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      container: true,
      label: [title, ?badge, body].join(', '),
      excludeSemantics: true,
      child: Material(
        color: colors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.row),
          side: BorderSide(color: selected ? accent : colors.borderSubtle, width: selected ? 2 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: selected ? accent : colors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xxs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(title, style: text.titleM.copyWith(color: destructive ? colors.destructiveText : null)),
                          if (badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.successContainer,
                                borderRadius: BorderRadius.circular(AppRadii.pill),
                              ),
                              child: Text(badge!, style: text.caption.copyWith(color: colors.onSuccessContainer)),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(body, style: text.bodyS.copyWith(color: colors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DuplicatesView extends StatelessWidget {
  const _DuplicatesView({required this.data, required this.pairs, required this.onRemove, required this.onContinue});

  final BackupData data;
  final List<(Vehicle, Vehicle)> pairs;
  final ValueChanged<Vehicle> onRemove;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    return _Layout(
      buttons: [AppButton(label: l10n.actionContinue, onPressed: onContinue)],
      children: [
        Semantics(header: true, child: Text(l10n.dupTitle, style: text.headline)),
        const SizedBox(height: AppSpacing.xxs),
        Text(l10n.dupBody, style: text.bodyS.copyWith(color: colors.textSecondary)),
        const SizedBox(height: AppSpacing.lg),
        for (final (device, account) in pairs)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
            decoration: BoxDecoration(
              color: colors.surfaceCard,
              borderRadius: BorderRadius.circular(AppRadii.row),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DuplicateLine(icon: Icons.smartphone, name: data.nameOf(device), where: l10n.dupOnPhone),
                const SizedBox(height: AppSpacing.sm),
                _DuplicateLine(icon: Icons.cloud_outlined, name: data.nameOf(account), where: l10n.dupInAccount),
                const SizedBox(height: AppSpacing.xs),
                Text(ltrValue('VIN ${device.vin}'), style: text.caption.copyWith(color: colors.textSecondary)),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AppButton.destructiveText(label: l10n.dupRemove, onPressed: () => onRemove(device)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// One side of a same-VIN pair: the name and where it is. Each name is
/// its own line so mixed Arabic and Latin names never run together.
class _DuplicateLine extends StatelessWidget {
  const _DuplicateLine({required this.icon, required this.name, required this.where});

  final IconData icon;
  final String name;
  final String where;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    return MergeSemantics(
      child: Row(
        children: [
          ExcludeSemantics(child: Icon(icon, size: 20, color: colors.textSecondary)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: text.titleM),
                Text(where, style: text.caption.copyWith(color: colors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Discard needs the word typed (spec S-29 step 3, a destructive choice).
class _DiscardDialog extends StatefulWidget {
  const _DiscardDialog();

  @override
  State<_DiscardDialog> createState() => _DiscardDialogState();
}

class _DiscardDialogState extends State<_DiscardDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final word = l10n.discardWord;
    final matches = _controller.text.trim().toUpperCase() == word.toUpperCase();
    return AlertDialog(
      title: Text(l10n.discardDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.discardDialogBody(word)),
          const SizedBox(height: AppSpacing.md),
          AppTextField(label: word, controller: _controller, onChanged: (_) => setState(() {})),
        ],
      ),
      actions: [
        AppButton.text(label: l10n.actionCancel, onPressed: () => Navigator.pop(context, false)),
        AppButton.destructiveText(
          label: l10n.discardConfirm,
          onPressed: matches ? () => Navigator.pop(context, true) : null,
        ),
      ],
    );
  }
}
