import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/toothbrush_state.dart';
import 'services/notification_service.dart';
import 'ui/screens/main_shell.dart';
import 'ui/theme/xclean_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  runApp(const XCleanApp());
}

class XCleanApp extends StatelessWidget {
  const XCleanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ToothbrushState(),
      child: MaterialApp(
        title: 'XClean',
        debugShowCheckedModeBanner: false,
        theme: XCleanTheme.darkTheme,
        darkTheme: XCleanTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const MainShell(),
      ),
    );
  }
}
