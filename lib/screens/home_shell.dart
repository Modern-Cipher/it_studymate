import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../state/auth_provider.dart';
import '../state/resource_provider.dart';
import '../state/subject_provider.dart';
import '../state/task_provider.dart';
import '../theme/app_colors.dart';
import 'dashboard_screen.dart';
import 'more_screen.dart';
import 'resources/resource_form_sheet.dart';
import 'resources/resources_screen.dart';
import 'subjects_screen.dart';
import 'tasks/task_form_sheet.dart';
import 'tasks/tasks_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final AppUser? user = context.read<AuthProvider>().user;
    if (user == null) {
      context.go('/login');
      return;
    }
    final SubjectProvider subjects = context.read<SubjectProvider>();
    final TaskProvider tasks = context.read<TaskProvider>();
    final ResourceProvider resources = context.read<ResourceProvider>();
    await subjects.load(user.id);
    await tasks.load(user.id);
    await resources.load(user.id);
  }

  void _openTasks() => setState(() => _index = 1);

  void _openAdd() {
    switch (_index) {
      case 2:
        showSubjectFormSheet(context);
        return;
      case 3:
        showResourceFormSheet(context);
        return;
      default:
        showTaskFormSheet(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      DashboardScreen(onOpenTasks: _openTasks),
      const TasksScreen(),
      const SubjectsScreen(),
      const ResourcesScreen(),
      const MoreScreen(),
    ];
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(index: _index, children: pages),
      floatingActionButton: _index <= 3
          ? FloatingActionButton(
              onPressed: _openAdd,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: _BottomNav(
        index: _index,
        onSelect: (int value) => setState(() => _index = value),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  static const List<IconData> _icons = <IconData>[
    Icons.space_dashboard_outlined,
    Icons.task_alt,
    Icons.menu_book_outlined,
    Icons.ondemand_video_outlined,
    Icons.more_horiz,
  ];

  static const List<String> _labels = <String>[
    'Home',
    'Tasks',
    'Subjects',
    'Learn',
    'More',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List<Widget>.generate(_icons.length, (int itemIndex) {
            final bool selected = index == itemIndex;
            return Expanded(
              child: InkWell(
                onTap: () => onSelect(itemIndex),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        _icons[itemIndex],
                        size: 22,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _labels[itemIndex],
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
