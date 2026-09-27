import 'package:flutter/material.dart';
import 'data/cloud_repository.dart';
import 'data/game_repository.dart';
import 'data/user_preferences.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/auth_state.dart';
import 'features/home/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const repository = SharedPrefsGameRepository();
  final preferences = await repository.loadPreferences();

  final cloudRepository = CloudRepository();
  final authService = AuthService(cloudRepository: cloudRepository);
  await authService.restoreSession();

  runApp(
    LooplineApp(
      repository: repository,
      initialPreferences: preferences,
      cloudRepository: cloudRepository,
      authService: authService,
    ),
  );
}

class LooplineApp extends StatefulWidget {
  final GameRepository repository;
  final UserPreferences initialPreferences;
  final CloudRepository? cloudRepository;
  final AuthService? authService;

  const LooplineApp({
    super.key,
    required this.repository,
    required this.initialPreferences,
    this.cloudRepository,
    this.authService,
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
      home: _RootRouter(
        repository: widget.repository,
        cloudRepository: widget.cloudRepository,
        authService: widget.authService,
      ),
    );
  }
}

class _RootRouter extends StatelessWidget {
  final GameRepository repository;
  final CloudRepository? cloudRepository;
  final AuthService? authService;

  const _RootRouter({
    required this.repository,
    this.cloudRepository,
    this.authService,
  });

  @override
  Widget build(BuildContext context) {
    final auth = authService;
    if (auth == null) {
      return HomeScreen(
        repository: repository,
        cloudRepository: cloudRepository,
      );
    }

    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        final state = auth.state;
        if (state is AuthAuthenticated || state is AuthGuest) {
          return HomeScreen(
            repository: repository,
            cloudRepository: cloudRepository,
            authService: auth,
          );
        }

        return AuthScreen(
          authService: auth,
          onContinueAsGuest: () {
            auth.continueAsGuest();
          },
        );
      },
    );
  }
}
