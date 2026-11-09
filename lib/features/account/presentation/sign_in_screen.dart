import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_banner.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_mark.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_toast.dart';
import '../../vehicles/application/garage_providers.dart';
import '../application/account_providers.dart';
import '../domain/auth.dart';
import 'widgets/google_mark.dart';

/// The steps of S-28 (UI/UX spec S-28 "Email screens").
enum SignInStep { method, email, createPassword, enterPassword, reset, resetSent, verify }

/// S-28 Sign in / Sign up (UI/UX spec S-28, FR-USR-01 to FR-USR-03): Apple,
/// Google or email, with the email steps on the same screen. [fromBackup]
/// (opened from "Back up your garage") changes the title. After success the
/// user goes to the S-29 upload or merge step, or back.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key, this.fromBackup = false});

  final bool fromBackup;

  /// The content is a 440 pt card on tablets.
  static const maxWidth = 440.0;

  /// "Resend" waits this long after each email (spec S-28 E4).
  static const resendWait = 30;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  SignInStep _step = SignInStep.method;
  bool _obscure = true;
  bool _busy = false;
  bool _offline = false;
  bool _showEmailError = false;
  String? _passwordError;
  AuthSucceeded? _pending;
  int _resendSeconds = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _password.addListener(() => setState(() => _passwordError = null));
    _email.addListener(() => setState(() => _showEmailError = false));
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _go(SignInStep step) => setState(() {
    _step = step;
    _offline = false;
    _passwordError = null;
  });

  /// Back one step; on the first step the screen closes.
  void _back() => switch (_step) {
    SignInStep.method => context.pop(),
    SignInStep.email => _go(SignInStep.method),
    SignInStep.createPassword || SignInStep.enterPassword || SignInStep.reset => _go(SignInStep.email),
    SignInStep.resetSent => _go(SignInStep.enterPassword),
    SignInStep.verify => _route(_pending!),
  };

  Future<void> _run(Future<void> Function() task) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await task();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handle(AuthOutcome outcome) async {
    final l10n = AppLocalizations.of(context);
    switch (outcome) {
      case AuthSucceeded():
        await ref.read(accountActionsProvider).signedIn(outcome.account);
        if (!mounted) return;
        if (!outcome.account.emailVerified) {
          // Data stays on the device until the email is verified (FR-USR-02).
          _pending = outcome;
          _startResendWait();
          _go(SignInStep.verify);
        } else {
          await _route(outcome);
        }
      case WrongPassword():
        setState(() => _passwordError = l10n.authWrongPassword);
      case TooManyAttempts():
        setState(() => _passwordError = l10n.authTooMany);
      case NoConnection():
        setState(() => _offline = true);
      case AuthCancelled():
        break;
    }
  }

  /// "After success" (spec S-28): upload, merge or discard, or back.
  Future<void> _route(AuthSucceeded success) async {
    final l10n = AppLocalizations.of(context);
    final router = GoRouter.of(context);
    final hasDeviceData = (await ref.read(garageRepositoryProvider).vehicles()).isNotEmpty;
    if (!mounted) return;
    showAppToast(context, l10n.authSignedIn);
    router.pop();
    switch (afterSignIn(isNewAccount: success.isNewAccount, hasDeviceData: hasDeviceData)) {
      case AfterSignIn.upload:
        router.push(AppRoutes.accountBackupStep('upload'));
      case AfterSignIn.mergeOrDiscard:
        router.push(AppRoutes.accountBackupStep('merge'));
      case AfterSignIn.back:
        break;
    }
  }

  Future<void> _continueWithEmail() => _run(() async {
    if (!looksLikeEmail(_email.text)) {
      setState(() => _showEmailError = true);
      return;
    }
    final exists = await ref.read(authRepositoryProvider).accountExists(_email.text);
    if (!mounted) return;
    if (exists == null) {
      setState(() => _offline = true);
    } else {
      _password.clear();
      _go(exists ? SignInStep.enterPassword : SignInStep.createPassword);
    }
  });

  void _startResendWait() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = SignInScreen.resendWait);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _resendSeconds--);
      if (_resendSeconds <= 0) timer.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final first = _step == SignInStep.method;

    return PopScope(
      canPop: first,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: colors.bgSheet,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: first
              ? IconButton(tooltip: l10n.actionClose, icon: const Icon(Icons.close), onPressed: _back)
              : BackButton(onPressed: _back),
          backgroundColor: colors.bgSheet,
          surfaceTintColor: Colors.transparent,
        ),
        body: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: SignInScreen.maxWidth),
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
                    if (_offline) ...[OfflineBanner(reason: l10n.authOffline), const SizedBox(height: AppSpacing.lg)],
                    ..._stepContent(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _stepContent() {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final auth = ref.read(authRepositoryProvider);
    Widget title(String value) => Semantics(header: true, child: Text(value, style: text.titleL));
    Widget body(String value) => Text(value, style: text.body.copyWith(color: colors.textSecondary));
    const gap = SizedBox(height: AppSpacing.sm);

    Widget passwordField({required bool create}) => AppTextField(
      controller: _password,
      label: l10n.authPasswordLabel,
      obscureText: _obscure,
      autofillHints: [create ? AutofillHints.newPassword : AutofillHints.password],
      helper: create ? l10n.authPasswordHint : null,
      error: _passwordError,
      trailing: IconButton(
        tooltip: _obscure ? l10n.authShowPassword : l10n.authHidePassword,
        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );

    return switch (_step) {
      // Screen 1: the method.
      SignInStep.method => [
        const Center(child: AppMark(size: 48)),
        const SizedBox(height: AppSpacing.lg),
        title(widget.fromBackup ? l10n.authBackupTitle : l10n.authWelcomeTitle),
        gap,
        body(l10n.authBody),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: l10n.authApple,
          icon: Icons.apple,
          isLoading: _busy,
          onPressed: () => _run(() async => _handle(await auth.signInWithApple())),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton.secondary(
          label: l10n.authGoogle,
          leading: const GoogleMark(),
          onPressed: _busy ? null : () => _run(() async => _handle(await auth.signInWithGoogle())),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton.secondary(
          label: l10n.authEmail,
          icon: Icons.mail_outline,
          onPressed: _busy ? null : () => _go(SignInStep.email),
        ),
        const SizedBox(height: AppSpacing.lg),
        _LegalLine(),
      ],
      // E1: the email.
      SignInStep.email => [
        title(l10n.authEmailTitle),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          controller: _email,
          label: l10n.authEmailLabel,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.next,
          autofocus: true,
          error: _showEmailError ? l10n.authEmailInvalid : null,
          onSubmitted: (_) => _continueWithEmail(),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(label: l10n.actionContinue, isLoading: _busy, onPressed: _continueWithEmail),
      ],
      // E2a: a new account.
      SignInStep.createPassword => [
        title(l10n.authCreatePasswordTitle),
        gap,
        body(_email.text.trim()),
        const SizedBox(height: AppSpacing.lg),
        passwordField(create: true),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: l10n.authCreateAccount,
          isLoading: _busy,
          onPressed: _password.text.length < minPasswordLength
              ? null
              : () => _run(() async => _handle(await auth.signUp(_email.text, _password.text))),
        ),
      ],
      // E2b: an existing account.
      SignInStep.enterPassword => [
        title(l10n.authEnterPasswordTitle),
        gap,
        body(_email.text.trim()),
        const SizedBox(height: AppSpacing.lg),
        passwordField(create: false),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: l10n.authSignIn,
          isLoading: _busy,
          onPressed: _password.text.isEmpty
              ? null
              : () => _run(() async => _handle(await auth.signIn(_email.text, _password.text))),
        ),
        Center(
          child: AppButton.text(label: l10n.authForgot, onPressed: () => _go(SignInStep.reset)),
        ),
      ],
      // E3: reset.
      SignInStep.reset => [
        title(l10n.authResetTitle),
        gap,
        body(l10n.authResetBody(_email.text.trim())),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: l10n.authSendLink,
          isLoading: _busy,
          onPressed: () => _run(() async {
            final sent = await auth.sendPasswordReset(_email.text);
            if (!mounted) return;
            sent ? _go(SignInStep.resetSent) : setState(() => _offline = true);
          }),
        ),
      ],
      SignInStep.resetSent => [
        Icon(Icons.mark_email_read_outlined, size: 64, color: colors.success),
        const SizedBox(height: AppSpacing.lg),
        title(l10n.authResetSentTitle),
        gap,
        body(l10n.authResetSentBody),
        const SizedBox(height: AppSpacing.lg),
        AppButton.secondary(
          label: l10n.authOpenMail,
          icon: Icons.mail_outline,
          onPressed: ref.read(mailLauncherProvider).openMailApp,
        ),
      ],
      // E4: verify the email (after sign-up). The app keeps working.
      SignInStep.verify => [
        Icon(Icons.mark_email_unread_outlined, size: 64, color: colors.accentPrimary),
        const SizedBox(height: AppSpacing.lg),
        title(l10n.authVerifyTitle),
        gap,
        body(l10n.authVerifyBody(_pending?.account.email ?? _email.text.trim())),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: l10n.authOpenMail,
          icon: Icons.mail_outline,
          onPressed: ref.read(mailLauncherProvider).openMailApp,
        ),
        const SizedBox(height: AppSpacing.xs),
        AppButton.secondary(label: l10n.actionContinue, onPressed: () => _route(_pending!)),
        Center(
          child: AppButton.text(
            label: _resendSeconds > 0 ? l10n.authResendIn(_resendSeconds) : l10n.authResend,
            onPressed: _resendSeconds > 0
                ? null
                : () async {
                    await auth.resendVerification(_pending!.account.email);
                    if (!mounted) return;
                    showAppToast(context, l10n.authVerificationSent);
                    _startResendWait();
                  },
          ),
        ),
      ],
    };
  }
}

/// "By continuing you agree to the Terms and Privacy Policy.", then both
/// links as real (44 pt) buttons side by side.
class _LegalLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Text(
          l10n.authLegal,
          style: context.text.caption.copyWith(color: context.colors.textTertiary),
          textAlign: TextAlign.center,
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.xs,
          children: [
            AppButton.text(label: l10n.authTerms, onPressed: () => context.push(AppRoutes.terms)),
            AppButton.text(label: l10n.authPrivacy, onPressed: () => context.push(AppRoutes.privacyPolicy)),
          ],
        ),
      ],
    );
  }
}
