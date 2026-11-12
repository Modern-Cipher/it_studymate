import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/subject.dart';
import '../state/auth_provider.dart';
import '../state/subject_provider.dart';
import '../theme/app_colors.dart';
import '../utils/app_format.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_text_field.dart';

const List<String> subjectHexPalette = <String>[
  '#2563EB',
  '#14B8A6',
  '#8B5CF6',
  '#F59E0B',
  '#EF4444',
  '#0EA5E9',
];

Future<void> showSubjectFormSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: const _SubjectFormSheet(),
    ),
  );
}

class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Subject> subjects = context.watch<SubjectProvider>().subjects;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              'Subjects',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Text(
              '${subjects.length} enrolled subjects',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: subjects.isEmpty
                ? AppEmptyState(
                    icon: Icons.menu_book_outlined,
                    title: 'No subjects yet',
                    message:
                        'Add your subjects so tasks can be grouped and color coded.',
                    actionLabel: 'Add subject',
                    onAction: () => showSubjectFormSheet(context),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 130),
                    itemCount: subjects.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (BuildContext context, int index) {
                      final Subject subject = subjects[index];
                      final Color color = hexColor(subject.color);
                      return AppCard(
                        onTap: () => _confirmDelete(context, subject),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                subject.code.split(' ').first,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    subject.code,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    subject.name,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${subject.units} units',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Subject subject) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text('Remove subject'),
        content: Text(
          'Remove ${subject.code}? Tasks linked to it will become general tasks.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<SubjectProvider>().remove(subject);
  }
}

class _SubjectFormSheet extends StatefulWidget {
  const _SubjectFormSheet();

  @override
  State<_SubjectFormSheet> createState() => _SubjectFormSheetState();
}

class _SubjectFormSheetState extends State<_SubjectFormSheet> {
  final TextEditingController _code = TextEditingController();
  final TextEditingController _name = TextEditingController();
  int _units = 3;
  int _colorIndex = 0;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final int? userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    if (_code.text.trim().isEmpty || _name.text.trim().isEmpty) {
      setState(() => _error = 'Subject code and name are required.');
      return;
    }
    final SubjectProvider subjects = context.read<SubjectProvider>();
    await subjects.add(
      Subject(
        userId: userId,
        code: _code.text.trim().toUpperCase(),
        name: _name.text.trim(),
        units: _units,
        color: subjectHexPalette[_colorIndex],
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'New subject',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Subject code',
              controller: _code,
              hint: 'CS 302',
              prefixIcon: Icons.tag,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Subject name',
              controller: _name,
              hint: 'Data Structures and Algorithms',
              prefixIcon: Icons.menu_book_outlined,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (String value) => _save(),
            ),
            const SizedBox(height: 18),
            const Text(
              'Units',
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
                final int units = index + 1;
                final bool selected = _units == units;
                return GestureDetector(
                  onTap: () => setState(() => _units = units),
                  child: Container(
                    width: 44,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Text(
                      '$units',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
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
            const Text(
              'Color tag',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              children: List<Widget>.generate(
                subjectHexPalette.length,
                (int index) {
                  final Color color = hexColor(subjectHexPalette[index]);
                  final bool selected = _colorIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _colorIndex = index),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? AppColors.textPrimary : Colors.white,
                          width: selected ? 3 : 2,
                        ),
                      ),
                      child: selected
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  );
                },
              ),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(fontSize: 13, color: AppColors.danger),
              ),
            ],
            const SizedBox(height: 22),
            AppButton(label: 'Add subject', onPressed: _save),
          ],
        ),
      ),
    );
  }
}
