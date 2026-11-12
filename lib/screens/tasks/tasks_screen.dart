import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models/task.dart';
import '../../state/task_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/task_tile.dart';
import 'task_form_sheet.dart';

enum TaskFilter { all, today, upcoming, done }

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  TaskFilter _filter = TaskFilter.all;

  List<Task> _filtered(TaskProvider provider) {
    switch (_filter) {
      case TaskFilter.today:
        return provider.todayTasks;
      case TaskFilter.upcoming:
        return provider.upcomingTasks;
      case TaskFilter.done:
        return provider.completedTasks;
      case TaskFilter.all:
        return provider.tasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final TaskProvider tasks = context.watch<TaskProvider>();
    final List<Task> visible = _filtered(tasks);
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              'Tasks',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '${tasks.openTasks.length} open · ${tasks.completedTasks.length} completed',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: TaskFilter.values.map((TaskFilter filter) {
                final bool selected = _filter == filter;
                final String label = switch (filter) {
                  TaskFilter.all => 'All',
                  TaskFilter.today => 'Today',
                  TaskFilter.upcoming => 'Upcoming',
                  TaskFilter.done => 'Done',
                };
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = filter),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(
                          color: selected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: tasks.loading
                ? const AppLoading(label: 'Loading tasks')
                : visible.isEmpty
                ? const AppEmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'Nothing here yet',
                    message:
                        'Use the + button to add a task for this filter.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 130),
                    itemCount: visible.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (BuildContext context, int index) {
                      final Task task = visible[index];
                      return TaskTile(
                        task: task,
                        onTap: () => showTaskFormSheet(context, task: task),
                        onToggle: () =>
                            context.read<TaskProvider>().toggle(task),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
