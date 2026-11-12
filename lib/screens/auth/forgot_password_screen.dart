import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../state/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _code = TextEditingController();
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _section = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  int _step = 0;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _section.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final AuthProvider auth = context.read<AuthProvider>();
    setState(() => _error = null);
    if (_step == 0) {
      final String? failure = await auth.startReset(_email.text);
      if (!mounted) return;
      if (failure != null) {
        setState(() => _error = failure);
        return;
      }
      setState(() => _step = 1);
      return;
    }
    if (_step == 1) {
      final String? failure = auth.resetRequiresCode
          ? await auth.verifyResetCode(_code.text)
          : await auth.verifyResetIdentity(
              firstName: _firstName.text,
              lastName: _lastName.text,
              section: _section.text,
            );
      if (!mounted) return;
      if (failure != null) {
        setState(() => _error = failure);
        return;
      }
      setState(() => _step = 2);
      return;
    }
    final String? failure = await auth.resetPassword(
      password: _password.text,
      confirmPassword: _confirm.text,
    );
    if (!mounted) return;
    if (failure != null) {
      setState(() => _error = failure);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password updated. You can sign in now.')),
    );
    context.go('/login');
  }

  void _back() {
    if (_step == 0) {
      context.go('/login');
      return;
    }
    setState(() {
      _step = _step - 1;
      _error = null;
    });
  }

  String get _heading {
    switch (_step) {
      case 1:
        return context.read<AuthProvider>().resetRequiresCode
            ? 'Enter your recovery code'
            : 'Confirm your details';
      case 2:
        return 'Set a new password';
      default:
        return 'Reset your password';
    }
  }

  String get _subtitle {
    switch (_step) {
      case 1:
        return context.read<AuthProvider>().resetRequiresCode
            ? 'Use the 8-character code shown when you created your account.'
            : 'This account has no recovery code. Confirm the details you registered.';
      case 2:
        return 'Choose a password that meets all five requirements.';
      default:
        return 'Enter the email you registered to begin.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              IconButton(
                onPressed: _back,
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                _heading,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _subtitle,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              if (_step == 0)
                AppTextField(
                  label: 'Email',
                  controller: _email,
                  hint: 'you@school.edu',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.alternate_email,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (String value) => _next(),
                ),
              if (_step == 1 && auth.resetRequiresCode)
                AppTextField(
                  label: 'Recovery code',
                  controller: _code,
                  hint: 'XXXX-XXXX',
                  prefixIcon: Icons.key_outlined,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (String value) => _next(),
                ),
              if (_step == 1 && !auth.resetRequiresCode) ...<Widget>[
                AppTextField(
                  label: 'First name',
                  controller: _firstName,
                  hint: 'Juan',
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Last name',
                  controller: _lastName,
                  hint: 'Dela Cruz',
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Section',
                  controller: _section,
                  hint: 'IT-3A',
                  prefixIcon: Icons.groups_outlined,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (String value) => _next(),
                ),
              ],
              if (_step == 2) ...<Widget>[
                AppTextField(
                  label: 'New password',
                  controller: _password,
                  hint: 'At least 8 characters',
                  obscure: true,
                  prefixIcon: Icons.lock_outline,
                  textInputAction: TextInputAction.next,
                  onChanged: (String value) => setState(() {}),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Confirm new password',
                  controller: _confirm,
                  hint: 'Re-type your password',
                  obscure: true,
                  prefixIcon: Icons.lock_reset,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (String value) => _next(),
                ),
              ],
              if (_error != null) ...<Widget>[
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.error_outline,
                      size: 18,
                      color: AppColors.danger,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              AppButton(
                label: _step == 2 ? 'Update password' : 'Continue',
                onPressed: _next,
                loading: auth.busy,
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text('Back to sign in'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
