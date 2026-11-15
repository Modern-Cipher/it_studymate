import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../state/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _current = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final AuthProvider auth = context.read<AuthProvider>();
    setState(() => _error = null);
    final String? failure = await auth.changePassword(
      currentPassword: _current.text,
      newPassword: _password.text,
      confirmPassword: _confirm.text,
    );
    if (!mounted) return;
    if (failure != null) {
      setState(() => _error = failure);
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Password updated.')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bool busy = context.watch<AuthProvider>().busy;
    final String password = _password.text;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.textPrimary,
        title: const Text(
          'Change password',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AppTextField(
                  label: 'Current password',
                  controller: _current,
                  hint: 'Your existing password',
                  obscure: true,
                  prefixIcon: Icons.lock_outline,
                  textInputAction: TextInputAction.next,
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Current password is required.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'New password',
                  controller: _password,
                  hint: 'At least 8 characters',
                  obscure: true,
                  prefixIcon: Icons.lock_reset,
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
                  label: 'Confirm new password',
                  controller: _confirm,
                  hint: 'Re-type the new password',
                  obscure: true,
                  prefixIcon: Icons.lock_reset,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (String value) => _save(),
                  validator: (String? value) =>
                      Validators.confirmError(value, _password.text),
                ),
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Icon(
                        Icons.error_outline,
                        size: 17,
                        color: AppColors.danger,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 22),
                AppButton(
                  label: 'Update password',
                  onPressed: _save,
                  loading: busy,
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
