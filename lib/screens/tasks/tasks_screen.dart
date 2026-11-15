import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models/task.dart';
import '../../state/task_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/task_tile.dart';
import 'task_form_sheet.dart';

enum TaskFilter { all, today, upcoming, done }

enum TaskSort { dueDate, priority, title, added }

extension TaskSortLabel on TaskSort {
  String get label => switch (this) {
    TaskSort.dueDate => 'Due date',
    TaskSort.priority => 'Priority high-low',
    TaskSort.title => 'Title A-Z',
    TaskSort.added => 'Recently added',
  };

  IconData get icon => switch (this) {
    TaskSort.dueDate => Icons.event_outlined,
    TaskSort.priority => Icons.flag_outlined,
    TaskSort.title => Icons.sort_by_alpha,
    TaskSort.added => Icons.schedule,
  };
}

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TextEditingController _search = TextEditingController();
  TaskFilter _filter = TaskFilter.all;
  TaskSort _sort = TaskSort.dueDate;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Task> _byFilter(TaskProvider provider) {
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

  List<Task> _visible(TaskProvider provider) {
    final String query = _search.text.trim().toLowerCase();
    final List<Task> items = _byFilter(provider).where((Task task) {
      if (query.isEmpty) return true;
      return '${task.title} ${task.subjectCode ?? ''} ${task.priority.label}'
          .toLowerCase()
          .contains(query);
    }).toList();
    switch (_sort) {
      case TaskSort.dueDate:
        items.sort(
          (Task a, Task b) => a.dueDate.compareTo(b.dueDate),
        );
      case TaskSort.priority:
        items.sort((Task a, Task b) {
          final int byPriority = b.priority.index.compareTo(a.priority.index);
          if (byPriority != 0) return byPriority;
          return a.dueDate.compareTo(b.dueDate);
        });
      case TaskSort.title:
        items.sort(
          (Task a, Task b) =>
              a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      case TaskSort.added:
        items.sort(
          (Task a, Task b) => b.createdAt.compareTo(a.createdAt),
        );
    }
    return items;
  }

  Future<void> _openSortSheet() async {
    final TaskSort? picked = await showModalBottomSheet<TaskSort>(
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
            ...TaskSort.values.map(
              (TaskSort option) => ListTile(
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
    final TaskProvider tasks = context.watch<TaskProvider>();
    final List<Task> visible = _visible(tasks);
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Text(
              '${tasks.openTasks.length} open · ${tasks.completedTasks.length} completed · ${visible.length} shown',
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
                  hintText: 'Search task, subject, or priority',
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
                  if (_search.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _search.clear();
                        setState(() {});
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
            child: tasks.loading
                ? const AppLoading(label: 'Loading tasks')
                : tasks.tasks.isEmpty
                ? const AppEmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'No tasks yet',
                    message:
                        'Use the + button to add your first task and start tracking deadlines.',
                  )
                : visible.isEmpty
                ? const AppEmptyState(
                    icon: Icons.search_off,
                    title: 'No matches',
                    message:
                        'No task matches that keyword or filter. Try another search or switch the filter.',
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
