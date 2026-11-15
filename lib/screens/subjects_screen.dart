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

enum SubjectSort { code, name, units }

extension SubjectSortLabel on SubjectSort {
  String get label => switch (this) {
    SubjectSort.code => 'Code A-Z',
    SubjectSort.name => 'Name A-Z',
    SubjectSort.units => 'Units high-low',
  };

  IconData get icon => switch (this) {
    SubjectSort.code => Icons.sort_by_alpha,
    SubjectSort.name => Icons.text_fields,
    SubjectSort.units => Icons.numbers,
  };
}

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

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final TextEditingController _search = TextEditingController();
  SubjectSort _sort = SubjectSort.code;
  int? _unitFilter;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Subject> _visible(List<Subject> subjects) {
    final String query = _search.text.trim().toLowerCase();
    final List<Subject> items = subjects.where((Subject subject) {
      if (_unitFilter != null && subject.units != _unitFilter) return false;
      if (query.isEmpty) return true;
      return '${subject.code} ${subject.name}'.toLowerCase().contains(query);
    }).toList();
    switch (_sort) {
      case SubjectSort.code:
        items.sort(
          (Subject a, Subject b) => a.code.toLowerCase().compareTo(
            b.code.toLowerCase(),
          ),
        );
      case SubjectSort.name:
        items.sort(
          (Subject a, Subject b) => a.name.toLowerCase().compareTo(
            b.name.toLowerCase(),
          ),
        );
      case SubjectSort.units:
        items.sort((Subject a, Subject b) => b.units.compareTo(a.units));
    }
    return items;
  }

  Future<void> _openSortSheet() async {
    final SubjectSort? picked = await showModalBottomSheet<SubjectSort>(
      context: context,
      builder: (BuildContext sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              'Sort by',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ...SubjectSort.values.map(
              (SubjectSort option) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  option.icon,
                  size: 20,
                  color: _sort == option
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
                title: Text(
                  option.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: _sort == option
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: _sort == option
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
                trailing: _sort == option
                    ? const Icon(
                        Icons.check_circle,
                        size: 20,
                        color: AppColors.primary,
                      )
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(option),
              ),
            ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _sort = picked);
  }

  @override
  Widget build(BuildContext context) {
    final List<Subject> subjects = context.watch<SubjectProvider>().subjects;
    final List<Subject> visible = _visible(subjects);
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
              '${subjects.length} enrolled · ${visible.length} shown',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _search,
                onChanged: (String value) => setState(() {}),
                textInputAction: TextInputAction.search,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search subject code or name',
                  hintStyle: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textMuted,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          },
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: <Widget>[
                _UnitChip(
                  label: 'All units',
                  selected: _unitFilter == null,
                  onTap: () => setState(() => _unitFilter = null),
                ),
                ...List<int>.generate(5, (int index) => index + 1).map(
                  (int unit) => _UnitChip(
                    label: '$unit units',
                    selected: _unitFilter == unit,
                    onTap: () => setState(() => _unitFilter = unit),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: _openSortSheet,
              child: Row(
                children: <Widget>[
                  Icon(_sort.icon, size: 15, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    _sort.label,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.expand_more,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const Spacer(),
                  if (_unitFilter != null || _search.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _search.clear();
                        setState(() => _unitFilter = null);
                      },
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
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
                : visible.isEmpty
                ? const AppEmptyState(
                    icon: Icons.search_off,
                    title: 'No matches',
                    message:
                        'No subject matches that keyword or unit filter. Try another search.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 130),
                    itemCount: visible.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (BuildContext context, int index) {
                      final Subject subject = visible[index];
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
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
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

class _UnitChip extends StatelessWidget {
  const _UnitChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
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
                          color: selected
                              ? AppColors.textPrimary
                              : Colors.white,
                          width: selected ? 3 : 2,
                        ),
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
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
