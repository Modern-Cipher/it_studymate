import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'router.dart';
import 'state/auth_provider.dart';
import 'state/resource_provider.dart';
import 'state/subject_provider.dart';
import 'state/task_provider.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<SubjectProvider>(create: (_) => SubjectProvider()),
        ChangeNotifierProvider<TaskProvider>(create: (_) => TaskProvider()),
        ChangeNotifierProvider<ResourceProvider>(create: (_) => ResourceProvider()),
      ],
      child: const StudyMateApp(),
    ),
  );
}

class StudyMateApp extends StatelessWidget {
  const StudyMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'IT StudyMate',
      theme: AppTheme.light,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
