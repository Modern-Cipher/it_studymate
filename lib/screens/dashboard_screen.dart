import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../models/task.dart';
import '../state/auth_provider.dart';
import '../state/task_provider.dart';
import '../theme/app_colors.dart';
import '../utils/app_format.dart';
import '../widgets/app_card.dart';
import '../widgets/app_feedback.dart';
import '../widgets/task_tile.dart';
import 'tasks/task_form_sheet.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onOpenTasks});

  final VoidCallback onOpenTasks;

  @override
  Widget build(BuildContext context) {
    final AppUser? user = context.watch<AuthProvider>().user;
    final TaskProvider tasks = context.watch<TaskProvider>();
    if (user == null) return const SizedBox.shrink();
    final List<Task> today = tasks.todayTasks;
    final List<Task> overdue = tasks.overdueTasks;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 130),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${AppDate.greeting()},',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  user.initials,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[AppColors.primary, AppColors.primaryDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 66,
                  height: 66,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      CircularProgressIndicator(
                        value: tasks.completionRate,
                        strokeWidth: 7,
                        backgroundColor: Colors.white.withValues(alpha: 0.22),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                      Text(
                        AppFormat.percent(tasks.completionRate),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${tasks.doneCount} of ${tasks.totalCount} tasks done',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Study time today: ${AppFormat.duration(tasks.todaySeconds)}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => context.go('/home'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.add,
                                size: 16,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Quick add task',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _MetricCard(
                  label: 'Today',
                  value: '${today.length}',
                  icon: Icons.today_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  label: 'Overdue',
                  value: '${overdue.length}',
                  icon: Icons.warning_amber_outlined,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  label: 'This week',
                  value: AppFormat.duration(tasks.weekSeconds),
                  icon: Icons.insights_outlined,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SectionHeader(
            title: "Today's tasks",
            actionLabel: 'See all',
            onAction: onOpenTasks,
          ),
          const SizedBox(height: 12),
          if (tasks.loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: AppLoading(label: 'Loading your tasks'),
            )
          else if (today.isEmpty)
            const AppEmptyState(
              icon: Icons.task_alt,
              title: 'No tasks for today',
              message: 'Add a task and your progress will start counting here.',
            )
          else
            ...today.map(
              (Task task) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TaskTile(
                  task: task,
                  onTap: () => showTaskFormSheet(context, task: task),
                  onToggle: () => context.read<TaskProvider>().toggle(task),
                ),
              ),
            ),
          if (overdue.isNotEmpty) ...<Widget>[
            const SizedBox(height: 24),
            const SectionHeader(title: 'Overdue'),
            const SizedBox(height: 12),
            ...overdue.map(
              (Task task) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TaskTile(
                  task: task,
                  onTap: () => showTaskFormSheet(context, task: task),
                  onToggle: () => context.read<TaskProvider>().toggle(task),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
