import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models/subject.dart';
import '../../models/task.dart';
import '../../state/auth_provider.dart';
import '../../state/subject_provider.dart';
import '../../state/task_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_format.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';

Future<void> showTaskFormSheet(BuildContext context, {Task? task}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _TaskFormSheet(task: task),
    ),
  );
}

class _TaskFormSheet extends StatefulWidget {
  const _TaskFormSheet({this.task});

  final Task? task;

  @override
  State<_TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<_TaskFormSheet> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _note = TextEditingController();
  late DateTime _dueDate;
  late TaskPriority _priority;
  int? _subjectId;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final Task? existing = widget.task;
    _title.text = existing?.title ?? '';
    _note.text = existing?.note ?? '';
    _dueDate =
        existing?.dueDate ?? DateTime.now().add(const Duration(hours: 2));
    _priority = existing?.priority ?? TaskPriority.medium;
    _subjectId = existing?.subjectId;
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _dueDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _dueDate.hour,
        _dueDate.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _dueDate = DateTime(
        _dueDate.year,
        _dueDate.month,
        _dueDate.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _save() async {
    final int? userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'Task title is required.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final TaskProvider tasks = context.read<TaskProvider>();
    final Task? existing = widget.task;
    if (existing == null) {
      await tasks.addTask(
        Task(
          userId: userId,
          subjectId: _subjectId,
          title: _title.text.trim(),
          note: _note.text.trim(),
          dueDate: _dueDate,
          priority: _priority,
        ),
      );
    } else {
      await tasks.updateTask(
        existing.copyWith(
          subjectId: _subjectId,
          clearSubject: _subjectId == null,
          title: _title.text.trim(),
          note: _note.text.trim(),
          dueDate: _dueDate,
          priority: _priority,
        ),
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final Task? existing = widget.task;
    if (existing == null) return;
    final TaskProvider tasks = context.read<TaskProvider>();
    await tasks.remove(existing);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final List<Subject> subjects = context.watch<SubjectProvider>().subjects;
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
            Text(
              widget.task == null ? 'New task' : 'Edit task',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Task title',
              controller: _title,
              hint: 'Finish capstone chapter 2',
              prefixIcon: Icons.task_alt,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            const Text(
              'Subject',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _SubjectChip(
                  label: 'General',
                  color: AppColors.textMuted,
                  selected: _subjectId == null,
                  onTap: () => setState(() => _subjectId = null),
                ),
                ...subjects.map(
                  (Subject subject) => _SubjectChip(
                    label: subject.code,
                    color: hexColor(subject.color),
                    selected: _subjectId == subject.id,
                    onTap: () => setState(() => _subjectId = subject.id),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Priority',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: TaskPriority.values.map((TaskPriority priority) {
                final bool selected = _priority == priority;
                return GestureDetector(
                  onTap: () => setState(() => _priority = priority),
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
                      priority.label,
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
              }).toList(),
            ),
            const SizedBox(height: 18),
            const Text(
              'Due',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    onTap: _pickDate,
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          AppDate.shortDate(_dueDate),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    onTap: _pickTime,
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.schedule,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          AppDate.time(_dueDate),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Notes',
              controller: _note,
              hint: 'Optional details',
              maxLines: 3,
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(fontSize: 13, color: AppColors.danger),
              ),
            ],
            const SizedBox(height: 22),
            AppButton(
              label: widget.task == null ? 'Add task' : 'Save changes',
              onPressed: _save,
              loading: _saving,
            ),
            if (widget.task != null) ...<Widget>[
              const SizedBox(height: 10),
              AppButton(
                label: 'Delete task',
                variant: AppButtonVariant.outline,
                icon: Icons.delete_outline,
                onPressed: _delete,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SubjectChip extends StatelessWidget {
  const _SubjectChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
