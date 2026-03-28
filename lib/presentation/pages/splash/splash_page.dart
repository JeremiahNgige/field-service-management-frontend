import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../router/app_router.dart';
import '../../../utils/extensions.dart';

@RoutePage()
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<double> _slideUp;
  late final Animation<double> _pulse;

  bool _showBiometricButton = false;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideUp = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _animCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthBloc>().add(const AuthCheckBiometricStatus());
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _navigateToHome() => context.router.replaceAll([const HomeRoute()]);
  void _navigateToLogin() => context.router.replaceAll([LoginRoute()]);
  void _triggerBiometric() =>
      context.read<AuthBloc>().add(const AuthBiometricUnlockRequested());

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: _handleStateChange,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF0D1B2A),
                      const Color(0xFF1B2838),
                      const Color(0xFF0F2044),
                    ]
                  : [
                      const Color(0xFF1565C0),
                      const Color(0xFF1E88E5),
                      const Color(0xFF42A5F5),
                    ],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: AnimatedBuilder(
                animation: _slideUp,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _slideUp.value),
                  child: child,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Logo ───────────────────────────────────────
                        ScaleTransition(
                          scale: _pulse,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: Colors.white.withAlpha(60),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(40),
                                  blurRadius: 32,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.construction_rounded,
                              size: 58,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        Text(
                          'FSM Field Service',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Field service, managed.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.white.withAlpha(180),
                                letterSpacing: 0.3,
                              ),
                        ),
                        const SizedBox(height: 56),

                        // ── Biometric / loading ─────────────────────────
                        if (_showBiometricButton) ...[
                          _BiometricUnlockButton(onTap: _triggerBiometric),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: _navigateToLogin,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white.withAlpha(200),
                            ),
                            child: const Text('Use Password Instead'),
                          ),
                        ] else ...[
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white.withAlpha(200),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleStateChange(BuildContext context, AuthState state) {
    if (state is AuthBiometricStatus) {
      final canUnlock = state.hasToken && state.isAvailable && state.isEnabled;
      if (!state.hasToken) {
        _navigateToLogin();
        return;
      }
      if (canUnlock) {
        setState(() => _showBiometricButton = true);
        _triggerBiometric();
      } else {
        _navigateToLogin();
      }
    } else if (state is AuthAuthenticated) {
      _navigateToHome();
    } else if (state is AuthFailure) {
      setState(() => _showBiometricButton = true);
      context.showErrorSnackBar(state.message);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Biometric button
// ─────────────────────────────────────────────────────────────────────────────

class _BiometricUnlockButton extends StatelessWidget {
  const _BiometricUnlockButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return Column(
          children: [
            GestureDetector(
              onTap: isLoading ? null : onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(isLoading ? 40 : 30),
                  border: Border.all(
                    color: Colors.white.withAlpha(isLoading ? 60 : 150),
                    width: 2,
                  ),
                  boxShadow: isLoading
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withAlpha(30),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.fingerprint_rounded,
                        size: 42,
                        color: Colors.white,
                      ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isLoading ? 'Verifying…' : 'Tap to unlock',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
            ),
          ],
        );
      },
    );
  }
}
