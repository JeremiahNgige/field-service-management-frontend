import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../router/app_router.dart';
import '../../../data/models/user/user_model.dart';
import '../../../utils/extensions.dart';
import '../../../utils/validators.dart';

@RoutePage()
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _password2Ctrl = TextEditingController();

  final _usernameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _password2Focus = FocusNode();

  final _usernameKey = GlobalKey();
  final _emailKey = GlobalKey();
  final _phoneKey = GlobalKey();
  final _addressKey = GlobalKey();
  final _passwordKey = GlobalKey();
  final _password2Key = GlobalKey();

  bool _obscure = true;
  bool _obscure2 = true;
  bool _autoValidate = false;
  String _userType = 'technician'; // Default account role

  // Per-field touched flags — validation activates on first blur.
  bool _usernameTouched = false;
  bool _emailTouched = false;
  bool _phoneTouched = false;
  bool _addressTouched = false;
  bool _passwordTouched = false;
  bool _password2Touched = false;

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
    _slideUp = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );
    _animCtrl.forward();

    // Validate each field as soon as the user leaves it.
    void onBlur(FocusNode node, VoidCallback mark) {
      node.addListener(() {
        if (!node.hasFocus) mark();
      });
    }

    onBlur(_usernameFocus, () => setState(() => _usernameTouched = true));
    onBlur(_emailFocus, () => setState(() => _emailTouched = true));
    onBlur(_phoneFocus, () => setState(() => _phoneTouched = true));
    onBlur(_addressFocus, () => setState(() => _addressTouched = true));
    onBlur(_passwordFocus, () => setState(() => _passwordTouched = true));
    onBlur(_password2Focus, () => setState(() => _password2Touched = true));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _scrollController.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _passwordCtrl.dispose();
    _password2Ctrl.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _addressFocus.dispose();
    _passwordFocus.dispose();
    _password2Focus.dispose();
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
          AuthRegisterRequested(
            request: RegisterRequest(
              email: _emailCtrl.text.trim(),
              password: _passwordCtrl.text,
              password2: _password2Ctrl.text,
              phoneNumber: _phoneCtrl.text.trim(),
              address: _addressCtrl.text.trim(),
              username: _usernameCtrl.text.trim(),
              userType: _userType,
            ),
          ),
        );
  }

  Future<void> _scrollToFirstError() async {
    for (final (key, focus) in [
      (_usernameKey, _usernameFocus),
      (_emailKey, _emailFocus),
      (_phoneKey, _phoneFocus),
      (_addressKey, _addressFocus),
      (_passwordKey, _passwordFocus),
      (_password2Key, _password2Focus),
    ]) {
      final ctx = key.currentContext;
      if (ctx == null) continue;
      final st = ctx.findAncestorStateOfType<FormFieldState>();
      if (st != null && st.hasError) {
        await Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            alignment: 0.2);
        if (!mounted) return;
        FocusScope.of(context).requestFocus(focus);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            context.showSuccessSnackBar('Account created! Please sign in.');
            context.router.replaceAll([LoginRoute()]);
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
                height: 220,
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
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back button
                        IconButton(
                          onPressed: () => context.router.pop(),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withAlpha(30),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Join FSM to manage field service operations',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withAlpha(200),
                              ),
                            ),
                          ],
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
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: _autoValidate
                          ? AutovalidateMode.onUserInteraction
                          : AutovalidateMode.disabled,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel('Account Type'),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'technician',
                                  label: Text('Technician'),
                                  icon: Icon(Icons.handyman_rounded),
                                ),
                                ButtonSegment(
                                  value: 'customer',
                                  label: Text('Customer'),
                                  icon: Icon(Icons.person_rounded),
                                ),
                              ],
                              selected: {_userType},
                              onSelectionChanged: (Set<String> newSelection) {
                                setState(() {
                                  _userType = newSelection.first;
                                });
                              },
                              style: SegmentedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          _SectionLabel('Personal Information'),
                          const SizedBox(height: 12),

                          _buildField(
                            key: _usernameKey,
                            controller: _usernameCtrl,
                            focusNode: _usernameFocus,
                            nextFocus: _emailFocus,
                            label: 'Full Name',
                            hint: 'John Doe',
                            icon: Icons.person_outline_rounded,
                            cap: TextCapitalization.words,
                            validator: AppValidators.validateUsername,
                            cs: cs,
                            touched: _usernameTouched,
                          ),
                          const SizedBox(height: 14),

                          _buildField(
                            key: _emailKey,
                            controller: _emailCtrl,
                            focusNode: _emailFocus,
                            nextFocus: _phoneFocus,
                            label: 'Email',
                            hint: 'you@example.com',
                            icon: Icons.email_outlined,
                            inputType: TextInputType.emailAddress,
                            validator: AppValidators.validateEmail,
                            cs: cs,
                            touched: _emailTouched,
                          ),
                          const SizedBox(height: 14),

                          _buildField(
                            key: _phoneKey,
                            controller: _phoneCtrl,
                            focusNode: _phoneFocus,
                            nextFocus: _addressFocus,
                            label: 'Phone Number',
                            hint: '+1234567890',
                            icon: Icons.phone_outlined,
                            inputType: TextInputType.phone,
                            validator: AppValidators.validatePhone,
                            cs: cs,
                            touched: _phoneTouched,
                          ),
                          const SizedBox(height: 14),

                          _buildField(
                            key: _addressKey,
                            controller: _addressCtrl,
                            focusNode: _addressFocus,
                            nextFocus: _passwordFocus,
                            label: 'Address',
                            hint: '123 Main St, City',
                            icon: Icons.location_on_outlined,
                            cap: TextCapitalization.sentences,
                            validator: AppValidators.validateAddress,
                            cs: cs,
                            touched: _addressTouched,
                          ),
                          const SizedBox(height: 24),

                          _SectionLabel('Security'),
                          const SizedBox(height: 12),

                          // Password
                          TextFormField(
                            key: _passwordKey,
                            controller: _passwordCtrl,
                            focusNode: _passwordFocus,
                            obscureText: _obscure,
                            autovalidateMode: _passwordTouched
                                ? AutovalidateMode.always
                                : AutovalidateMode.disabled,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => FocusScope.of(context)
                                .requestFocus(_password2Focus),
                            decoration: _inputDeco(
                              cs: cs,
                              label: 'Password',
                              hint: 'Min. 8 characters',
                              icon: Icons.lock_outline,
                              suffix: IconButton(
                                icon: Icon(_obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: AppValidators.validatePassword,
                          ),
                          const SizedBox(height: 14),

                          // Confirm password
                          TextFormField(
                            key: _password2Key,
                            controller: _password2Ctrl,
                            focusNode: _password2Focus,
                            obscureText: _obscure2,
                            autovalidateMode: _password2Touched
                                ? AutovalidateMode.always
                                : AutovalidateMode.disabled,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: _inputDeco(
                              cs: cs,
                              label: 'Confirm Password',
                              icon: Icons.lock_outline,
                              suffix: IconButton(
                                icon: Icon(_obscure2
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined),
                                onPressed: () =>
                                    setState(() => _obscure2 = !_obscure2),
                              ),
                            ),
                            validator: (v) => AppValidators.validateConfirmPassword(v, _passwordCtrl.text),
                          ),
                          const SizedBox(height: 32),

                          // Submit
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              return SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: FilledButton(
                                  onPressed:
                                      state is AuthLoading ? null : _submit,
                                  style: FilledButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                  child: state is AuthLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white),
                                        )
                                      : const Text('Create Account',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600)),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              onPressed: () => context.router.pop(),
                              child: RichText(
                                text: TextSpan(
                                  text: 'Already have an account? ',
                                  style: TextStyle(color: cs.onSurfaceVariant),
                                  children: [
                                    TextSpan(
                                      text: 'Sign In',
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
                          const SizedBox(height: 20),
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

  InputDecoration _inputDeco({
    required ColorScheme cs,
    required String label,
    String? hint,
    required IconData icon,
    Widget? suffix,
  }) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outline.withAlpha(80)),
        ),
        filled: true,
        fillColor: cs.surfaceContainerLowest,
      );

  Widget _buildField({
    required GlobalKey key,
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    required String label,
    String? hint,
    required IconData icon,
    TextInputType? inputType,
    TextCapitalization cap = TextCapitalization.none,
    required String? Function(String?) validator,
    required ColorScheme cs,
    bool touched = false, // ← per-field blur-validation flag
  }) =>
      TextFormField(
        key: key,
        controller: controller,
        focusNode: focusNode,
        keyboardType: inputType,
        textCapitalization: cap,
        autovalidateMode:
            touched ? AutovalidateMode.always : AutovalidateMode.disabled,
        textInputAction:
            nextFocus != null ? TextInputAction.next : TextInputAction.done,
        onFieldSubmitted: (_) => nextFocus != null
            ? FocusScope.of(context).requestFocus(nextFocus)
            : _submit(),
        decoration: _inputDeco(cs: cs, label: label, hint: hint, icon: icon),
        validator: validator,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: section label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: cs.primary,
        letterSpacing: 1.2,
      ),
    );
  }
}
