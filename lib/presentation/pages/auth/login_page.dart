import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/services/biometric_service.dart';
import '../../../di/di.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../router/app_router.dart';
import '../../../data/models/user/user_model.dart';
import '../../../utils/extensions.dart';
import '../../../utils/validators.dart';
import 'package:permission_handler/permission_handler.dart';

@RoutePage()
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, @QueryParam('expired') this.expired = false});
  final bool expired;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _emailKey = GlobalKey();
  final _passwordKey = GlobalKey();
  bool _obscure = true;
  bool _autoValidate = false;
  bool _emailTouched = false; // triggers email validation on blur

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<double> _slideUp;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideUp = Tween<double>(
      begin: 24,
      end: 0,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();

    // Validate the email field as soon as the user moves away from it.
    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus && !_emailTouched) {
        setState(() => _emailTouched = true);
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _scrollController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _autoValidate = true);
    if (!(_formKey.currentState?.validate() ?? false)) {
      await _scrollToFirstError();
      return;
    }
    if (!mounted) return;
    context.read<AuthBloc>().add(
      AuthLoginRequested(
        request: LoginRequest(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        ),
      ),
    );
  }

  Future<void> _scrollToFirstError() async {
    for (final (key, focus) in [
      (_emailKey, _emailFocus),
      (_passwordKey, _passwordFocus),
    ]) {
      final ctx = key.currentContext;
      if (ctx == null) continue;
      final st = ctx.findAncestorStateOfType<FormFieldState>();
      if (st != null && st.hasError) {
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          alignment: 0.2,
        );
        if (!mounted) return;
        FocusScope.of(context).requestFocus(focus);
        return;
      }
    }
  }

  Future<void> _offerBiometricOptIn() async {
    final bio = getIt<BiometricService>();
    final isAvailable = await bio.isAvailable();
    final isAlready = await bio.isBiometricEnabled();
    if (!isAvailable || isAlready || !mounted) return;

    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _BiometricOptInSheet(
        onAccept: () => Navigator.of(context).pop(true),
        onDecline: () => Navigator.of(context).pop(false),
      ),
    );

    if (accepted == true) {
      final success = await bio.authenticate(
        reason: 'Verify biometric to enable unlock',
      );
      if (success && mounted) {
        context.read<AuthBloc>().add(
          const AuthSetBiometricEnabled(enabled: true),
        );
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      await Permission.locationWhenInUse.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) async {
          if (state is AuthAuthenticated) {
            final router = context.router;
            await _offerBiometricOptIn();
            await _requestLocationPermission();
            if (!mounted) return;
            router.replaceAll([const HomeRoute()]);
          } else if (state is AuthFailure) {
            context.showErrorSnackBar(state.message);
          }
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Gradient hero header ─────────────────────────────────
              Container(
                height: 260,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF0D1B2A), const Color(0xFF1B2838)]
                        : [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withAlpha(60),
                            ),
                          ),
                          child: const Icon(
                            Icons.construction_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sign in to continue field service management',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withAlpha(200),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Form ─────────────────────────────────────────────────
              FadeTransition(
                opacity: _fadeIn,
                child: AnimatedBuilder(
                  animation: _slideUp,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, _slideUp.value),
                    child: child,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: _autoValidate
                          ? AutovalidateMode.onUserInteraction
                          : AutovalidateMode.disabled,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Session expired banner
                          if (widget.expired) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: cs.errorContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    color: cs.onErrorContainer,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Your session has expired. Please sign in again.',
                                      style: TextStyle(
                                        color: cs.onErrorContainer,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Email
                          TextFormField(
                            key: _emailKey,
                            controller: _emailCtrl,
                            focusNode: _emailFocus,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => FocusScope.of(
                              context,
                            ).requestFocus(_passwordFocus),
                            // Validate immediately once the field has been blurred at least once.
                            autovalidateMode: _emailTouched
                                ? AutovalidateMode.always
                                : AutovalidateMode.disabled,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'you@example.com',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: cs.outline.withAlpha(80),
                                ),
                              ),
                              filled: true,
                              fillColor: cs.surfaceContainerLowest,
                            ),
                            validator: AppValidators.validateEmail,
                          ),
                          const SizedBox(height: 16),

                          // Password
                          TextFormField(
                            key: _passwordKey,
                            controller: _passwordCtrl,
                            focusNode: _passwordFocus,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: cs.outline.withAlpha(80),
                                ),
                              ),
                              filled: true,
                              fillColor: cs.surfaceContainerLowest,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: AppValidators.validatePassword,
                          ),
                          const SizedBox(height: 28),

                          // Submit
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              return SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: FilledButton(
                                  onPressed: state is AuthLoading
                                      ? null
                                      : _submit,
                                  style: FilledButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: state is AuthLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Sign In',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              onPressed: () =>
                                  context.router.push(const RegisterRoute()),
                              child: RichText(
                                text: TextSpan(
                                  text: "Don't have an account? ",
                                  style: TextStyle(color: cs.onSurfaceVariant),
                                  children: [
                                    TextSpan(
                                      text: 'Register',
                                      style: TextStyle(
                                        color: cs.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Biometric opt-in bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _BiometricOptInSheet extends StatelessWidget {
  const _BiometricOptInSheet({required this.onAccept, required this.onDecline});
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.fingerprint_rounded, size: 42, color: cs.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Enable Biometric Unlock',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Use Face ID or fingerprint to unlock FSM next time — no password needed.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: onAccept,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Enable', style: TextStyle(fontSize: 15)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: onDecline,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Not Now', style: TextStyle(fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
