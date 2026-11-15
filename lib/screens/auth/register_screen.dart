import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../state/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();
  final TextEditingController _course = TextEditingController(
    text: 'BS Information Technology',
  );
  final TextEditingController _section = TextEditingController();
  int _yearLevel = 1;
  String? _error;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _course.dispose();
    _section.dispose();
    super.dispose();
  }

  Future<void> _showRecoveryCode(String code) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Save your recovery code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'This code is the only way to reset your password without a server. It will not be shown again.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                code,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('I saved my code'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final AuthProvider auth = context.read<AuthProvider>();
    setState(() => _error = null);
    final String? failure = await auth.register(
      firstName: _firstName.text,
      lastName: _lastName.text,
      username: _username.text,
      email: _email.text,
      password: _password.text,
      confirmPassword: _confirmPassword.text,
      course: _course.text,
      yearLevel: _yearLevel,
      section: _section.text,
    );
    if (!mounted) return;
    if (failure != null) {
      setState(() => _error = failure);
      return;
    }
    final String? code = auth.lastRecoveryCode;
    if (code != null) await _showRecoveryCode(code);
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final bool busy = context.watch<AuthProvider>().busy;
    final String password = _password.text;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                IconButton(
                  onPressed: () => context.go('/login'),
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create your account',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your account and study data are saved on this device.',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: AppTextField(
                        label: 'First name',
                        controller: _firstName,
                        hint: 'Juan',
                        textInputAction: TextInputAction.next,
                        validator: (String? value) =>
                            Validators.nameError(value, 'First name'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Last name',
                        controller: _lastName,
                        hint: 'Dela Cruz',
                        textInputAction: TextInputAction.next,
                        validator: (String? value) =>
                            Validators.nameError(value, 'Last name'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Username (optional)',
                  controller: _username,
                  hint: 'juan.dela',
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  validator: Validators.optionalUsernameError,
                ),
                const SizedBox(height: 6),
                const Text(
                  'If you add a username, you can sign in with it instead of your email.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Email',
                  controller: _email,
                  hint: 'you@school.edu',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.alternate_email,
                  textInputAction: TextInputAction.next,
                  validator: Validators.emailError,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Password',
                  controller: _password,
                  hint: 'At least 8 characters',
                  obscure: true,
                  prefixIcon: Icons.lock_outline,
                  textInputAction: TextInputAction.next,
                  onChanged: (String value) => setState(() {}),
                  validator: Validators.passwordError,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: <Widget>[
                    _Rule(
                      label: '8+ characters',
                      met: Validators.hasLength(password),
                    ),
                    _Rule(
                      label: 'Uppercase',
                      met: Validators.hasUppercase(password),
                    ),
                    _Rule(
                      label: 'Lowercase',
                      met: Validators.hasLowercase(password),
                    ),
                    _Rule(
                      label: 'Number',
                      met: Validators.hasDigit(password),
                    ),
                    _Rule(
                      label: 'Special char',
                      met: Validators.hasSpecial(password),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Confirm password',
                  controller: _confirmPassword,
                  hint: 'Re-type your password',
                  obscure: true,
                  prefixIcon: Icons.lock_reset,
                  textInputAction: TextInputAction.next,
                  validator: (String? value) =>
                      Validators.confirmError(value, _password.text),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Course',
                  controller: _course,
                  hint: 'BS Information Technology',
                  prefixIcon: Icons.menu_book_outlined,
                  textInputAction: TextInputAction.next,
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Course is required.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                const Text(
                  'Year level',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: List<Widget>.generate(5, (int index) {
                    final int level = index + 1;
                    final bool selected = _yearLevel == level;
                    return GestureDetector(
                      onTap: () => setState(() => _yearLevel = level),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          'Year $level',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 18),
                AppTextField(
                  label: 'Section',
                  controller: _section,
                  hint: 'IT-3A',
                  prefixIcon: Icons.groups_outlined,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (String value) => _submit(),
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Section is required.';
                    }
                    return null;
                  },
                ),
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
                const SizedBox(height: 22),
                AppButton(
                  label: 'Create account',
                  onPressed: _submit,
                  loading: busy,
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                    child: const Text('Already have an account? Sign in'),
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

class _Rule extends StatelessWidget {
  const _Rule({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          met ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 14,
          color: met ? AppColors.success : AppColors.textMuted,
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: met ? AppColors.success : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
