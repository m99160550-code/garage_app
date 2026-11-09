import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_skeleton.dart';
import '../../../core/format/app_formatters.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_banner.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../privacy/application/consent_providers.dart';
import '../application/account_providers.dart';
import '../application/erase_controller.dart';
import '../domain/account.dart';
import '../domain/auth.dart';
import '../domain/erase.dart';
import 'widgets/google_mark.dart';

/// S-30 Delete account / Erase all data (UI/UX spec S-30, FR-USR-06,
/// FR-USR-16, NFR-SEC-09).
///
/// * Owner: "Delete account". If the last sign-in was more than 5 minutes
///   ago, the user first signs in again (Apple, Google or password).
/// * Guest: "Erase all data", for this phone only.
///
/// Both explain what happens and need a typed word (DELETE or ERASE, «حذف»
/// or «مسح» in Arabic) before the red button works. Afterwards the app
/// starts over at S-01 → S-02.
class EraseScreen extends ConsumerStatefulWidget {
  const EraseScreen({super.key});

  static const maxWidth = 440.0;

  @override
  ConsumerState<EraseScreen> createState() => _EraseScreenState();
}

class _EraseScreenState extends ConsumerState<EraseScreen> {
  final _confirmation = TextEditingController();
  final _password = TextEditingController();
  bool _reauthenticated = false;
  bool _obscure = true;
  bool _busy = false;

  /// Shown in a banner when there's no connection.
  String? _offlineMessage;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _confirmation.addListener(() => setState(() {}));
    _password.addListener(() => setState(() => _passwordError = null));
  }

  @override
  void dispose() {
    _confirmation.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() task) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await task();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Re-authentication: the account stays the same; only its sign-in time
  /// is renewed.
  Future<void> _reauthenticate(OwnerAccount owner, Future<AuthOutcome> Function() attempt) => _run(() async {
    final l10n = AppLocalizations.of(context);
    final outcome = await attempt();
    if (!mounted) return;
    switch (outcome) {
      case AuthSucceeded():
        await ref.read(accountActionsProvider).signedIn(owner);
        if (mounted) setState(() => _reauthenticated = true);
      case WrongPassword():
        setState(() => _passwordError = l10n.authWrongPassword);
      case TooManyAttempts():
        setState(() => _passwordError = l10n.authTooMany);
      case NoConnection():
        setState(() => _offlineMessage = l10n.authOffline);
      case AuthCancelled():
        break;
    }
  });

  Future<void> _erase(EraseKind kind) => _run(() async {
    final eraser = ref.read(dataEraserProvider);
    final router = GoRouter.of(context);
    final offline = AppLocalizations.of(context).eraseOffline;
    if (kind == EraseKind.deleteAccount) {
      if (await eraser.deleteAccount() == EraseOutcome.offline) {
        if (mounted) setState(() => _offlineMessage = offline);
        return;
      }
    } else {
      await eraser.eraseDevice();
    }
    // A fresh start: S-01, then the intro (S-02).
    router.go(AppRoutes.launch);
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final account = ref.watch(accountProvider).value;
    final now = ref.watch(clockProvider)();

    final Widget content;
    if (account == null) {
      content = const Padding(padding: EdgeInsets.all(AppSpacing.xxl), child: DelayedSkeleton());
    } else if (account case final OwnerAccount owner
        when !_reauthenticated && needsReauthentication(owner.signedInAt, now: now)) {
      content = _ReauthStep(
        owner: owner,
        password: _password,
        obscure: _obscure,
        passwordError: _passwordError,
        busy: _busy,
        onToggleObscure: () => setState(() => _obscure = !_obscure),
        onApple: () => _reauthenticate(owner, ref.read(authRepositoryProvider).signInWithApple),
        onGoogle: () => _reauthenticate(owner, ref.read(authRepositoryProvider).signInWithGoogle),
        onPassword: () =>
            _reauthenticate(owner, () => ref.read(authRepositoryProvider).signIn(owner.email, _password.text)),
      );
    } else {
      content = _ConfirmStep(
        kind: account is OwnerAccount ? EraseKind.deleteAccount : EraseKind.eraseDevice,
        controller: _confirmation,
        busy: _busy,
        onErase: _erase,
      );
    }

    return Scaffold(
      backgroundColor: colors.bgSheet,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: l10n.actionClose,
          icon: const Icon(Icons.close),
          onPressed: _busy ? null : () => context.pop(),
        ),
        backgroundColor: colors.bgSheet,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: EraseScreen.maxWidth),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenMargin,
                AppSpacing.xs,
                AppSpacing.screenMargin,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_offlineMessage case final message?) ...[
                    OfflineBanner(reason: message),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  content,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Step 1 for Owners whose sign-in is older than 5 minutes.
class _ReauthStep extends StatelessWidget {
  const _ReauthStep({
    required this.owner,
    required this.password,
    required this.obscure,
    required this.passwordError,
    required this.busy,
    required this.onToggleObscure,
    required this.onApple,
    required this.onGoogle,
    required this.onPassword,
  });

  final OwnerAccount owner;
  final TextEditingController password;
  final bool obscure;
  final String? passwordError;
  final bool busy;
  final VoidCallback onToggleObscure;
  final VoidCallback onApple;
  final VoidCallback onGoogle;
  final VoidCallback onPassword;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text(l10n.reauthTitle, style: text.titleL)),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.reauthBody, style: text.body.copyWith(color: colors.textSecondary)),
        const SizedBox(height: AppSpacing.xxs),
        Text(l10n.reauthAccount(ltrValue(owner.email)), style: text.bodyS.copyWith(color: colors.textSecondary)),
        const SizedBox(height: AppSpacing.xl),
        AppButton(label: l10n.authApple, icon: Icons.apple, isLoading: busy, onPressed: onApple),
        const SizedBox(height: AppSpacing.sm),
        AppButton.secondary(label: l10n.authGoogle, leading: const GoogleMark(), onPressed: busy ? null : onGoogle),
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.reauthOr,
          style: text.label.copyWith(color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: l10n.authPasswordLabel,
          controller: password,
          obscureText: obscure,
          autofillHints: const [AutofillHints.password],
          error: passwordError,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => password.text.isEmpty ? null : onPassword(),
          trailing: IconButton(
            tooltip: obscure ? l10n.authShowPassword : l10n.authHidePassword,
            icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            onPressed: onToggleObscure,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton.secondary(label: l10n.reauthConfirm, onPressed: password.text.isEmpty || busy ? null : onPassword),
      ],
    );
  }
}

/// The explanation, the typed word and the red button (spec S-30 items
/// 1–4).
class _ConfirmStep extends StatelessWidget {
  const _ConfirmStep({required this.kind, required this.controller, required this.busy, required this.onErase});

  final EraseKind kind;
  final TextEditingController controller;
  final bool busy;
  final ValueChanged<EraseKind> onErase;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = context.text;
    final owner = kind == EraseKind.deleteAccount;
    final title = owner ? l10n.eraseDeleteTitle : l10n.eraseEraseTitle;
    final word = owner ? l10n.eraseDeleteWord : l10n.eraseEraseWord;
    final points = owner ? [l10n.eraseOwnerDevices, l10n.eraseOwnerBackups, l10n.eraseOwnerFinal] : [l10n.eraseGuest];
    final matches = confirmationMatches(controller.text, word);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text(title, style: text.titleL)),
        const SizedBox(height: AppSpacing.md),
        for (final point in points) _Point(point),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: l10n.eraseTypeToConfirm(word),
          controller: controller,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => matches && !busy ? onErase(kind) : null,
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton.destructive(label: title, isLoading: busy, onPressed: matches && !busy ? () => onErase(kind) : null),
      ],
    );
  }
}

/// One line of the explanation list, with a red bullet.
class _Point extends StatelessWidget {
  const _Point(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Icon(Icons.error_outline, size: 18, color: colors.danger),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: context.text.body)),
        ],
      ),
    );
  }
}
