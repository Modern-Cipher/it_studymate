import 'package:material_ui/material_ui.dart';

import '../models/task.dart';
import '../theme/app_colors.dart';
import '../utils/app_format.dart';
import 'app_card.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.task, this.onTap, this.onToggle});

  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final Color accent = task.subjectColor == null
        ? AppColors.textMuted
        : hexColor(task.subjectColor!);
    final bool overdue = task.isOverdue;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.isDone ? AppColors.success : Colors.transparent,
                border: Border.all(
                  color: task.isDone ? AppColors.success : AppColors.border,
                  width: 1.8,
                ),
              ),
              child: task.isDone
                  ? const Icon(Icons.check, size: 15, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: task.isDone
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    decoration: task.isDone
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      task.subjectCode ?? 'General',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.schedule,
                      size: 13,
                      color: overdue ? AppColors.danger : AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        AppDate.dueLabel(task.dueDate),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: overdue
                              ? AppColors.danger
                              : AppColors.textMuted,
                          fontWeight: overdue
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PriorityTag(priority: task.priority),
        ],
      ),
    );
  }
}

class PriorityTag extends StatelessWidget {
  const PriorityTag({super.key, required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (priority) {
      TaskPriority.high => AppColors.danger,
      TaskPriority.medium => AppColors.warning,
      TaskPriority.low => AppColors.textMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        priority.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
