import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../state/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _username;
  late final TextEditingController _email;
  late final TextEditingController _course;
  late final TextEditingController _section;
  final TextEditingController _currentPassword = TextEditingController();
  late int _yearLevel;
  String? _error;

  @override
  void initState() {
    super.initState();
    final AppUser user = widget.user;
    _firstName = TextEditingController(text: user.firstName);
    _lastName = TextEditingController(text: user.lastName);
    _username = TextEditingController(text: user.username);
    _email = TextEditingController(text: user.email);
    _course = TextEditingController(text: user.course);
    _section = TextEditingController(text: user.section);
    _yearLevel = user.yearLevel;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _username.dispose();
    _email.dispose();
    _course.dispose();
    _section.dispose();
    _currentPassword.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final AuthProvider auth = context.read<AuthProvider>();
    setState(() => _error = null);
    final String? failure = await auth.updateProfile(
      firstName: _firstName.text,
      lastName: _lastName.text,
      username: _username.text,
      email: _email.text,
      course: _course.text,
      yearLevel: _yearLevel,
      section: _section.text,
      currentPassword: _currentPassword.text,
    );
    if (!mounted) return;
    if (failure != null) {
      setState(() => _error = failure);
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bool busy = context.watch<AuthProvider>().busy;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.textPrimary,
        title: const Text(
          'Edit profile',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: AppTextField(
                      label: 'First name',
                      controller: _firstName,
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
              const SizedBox(height: 16),
              AppTextField(
                label: 'Email',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.alternate_email,
                textInputAction: TextInputAction.next,
                validator: Validators.emailError,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Course',
                controller: _course,
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
                        color: selected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? AppColors.primary : AppColors.border,
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
                prefixIcon: Icons.groups_outlined,
                textInputAction: TextInputAction.next,
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Section is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 22),
              const Text(
                'Confirm with your current password',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              AppTextField(
                label: 'Current password',
                controller: _currentPassword,
                hint: 'Required to save changes',
                obscure: true,
                prefixIcon: Icons.lock_outline,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (String value) => _save(),
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.danger,
                  ),
                ),
              ],
              const SizedBox(height: 22),
              AppButton(
                label: 'Save changes',
                onPressed: _save,
                loading: busy,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
