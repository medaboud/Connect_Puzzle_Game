import 'package:flutter/material.dart';
import 'data/game_repository.dart';
import 'data/user_preferences.dart';
import 'features/home/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const repository = SharedPrefsGameRepository();
  final preferences = await repository.loadPreferences();

  runApp(LooplineApp(repository: repository, initialPreferences: preferences));
}

class LooplineApp extends StatefulWidget {
  final GameRepository repository;
  final UserPreferences initialPreferences;

  const LooplineApp({
    super.key,
    required this.repository,
    required this.initialPreferences,
  });

  @override
  State<LooplineApp> createState() => _LooplineAppState();
}

class _LooplineAppState extends State<LooplineApp> {
  late UserPreferences _preferences;

  @override
  void initState() {
    super.initState();
    _preferences = widget.initialPreferences;
  }

  ThemeMode get _themeMode {
    if (_preferences.isDarkMode == true) {
      return ThemeMode.dark;
    } else if (_preferences.isDarkMode == false) {
      return ThemeMode.light;
    }
    return ThemeMode.system;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loopline',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: HomeScreen(repository: widget.repository),
    );
  }
}
