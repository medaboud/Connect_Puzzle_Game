import 'package:flutter/material.dart';
import '../../data/game_repository.dart';
import '../../data/user_preferences.dart';
import '../auth/auth_service.dart';
import '../auth/auth_state.dart';

class SettingsScreen extends StatefulWidget {
  final GameRepository repository;
  final ValueChanged<UserPreferences>? onPreferencesChanged;
  final AuthService? authService;

  const SettingsScreen({
    super.key,
    required this.repository,
    this.onPreferencesChanged,
    this.authService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserPreferences _preferences = const UserPreferences();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await widget.repository.loadPreferences();
    if (mounted) {
      setState(() {
        _preferences = prefs;
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePreferences(UserPreferences newPrefs) async {
    setState(() {
      _preferences = newPrefs;
    });
    await widget.repository.savePreferences(newPrefs);
    widget.onPreferencesChanged?.call(newPrefs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                children: [
                  if (widget.authService != null) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 8.0,
                      ),
                      child: Text(
                        'ACCOUNT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Card(
                      child: ListenableBuilder(
                        listenable: widget.authService!,
                        builder: (context, _) {
                          final state = widget.authService!.state;
                          if (state is AuthAuthenticated) {
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: state.user.avatarUrl != null
                                    ? NetworkImage(state.user.avatarUrl!)
                                    : null,
                                child: state.user.avatarUrl == null
                                    ? Text(
                                        state.user.name.isNotEmpty
                                            ? state.user.name[0].toUpperCase()
                                            : '?',
                                      )
                                    : null,
                              ),
                              title: Text(state.user.name),
                              subtitle: const Text(
                                'Signed in with Facebook (Cloud Sync)',
                              ),
                              trailing: TextButton(
                                onPressed: () async {
                                  Navigator.of(
                                    context,
                                  ).popUntil((route) => route.isFirst);
                                  await widget.authService!.signOut();
                                },
                                child: const Text('Sign Out'),
                              ),
                            );
                          }
                          return ListTile(
                            leading: const Icon(Icons.phone_android_rounded),
                            title: const Text('Playing as Guest'),
                            subtitle: const Text(
                              'Progress saved locally on this phone only',
                            ),
                            trailing: state is AuthLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : FilledButton.tonal(
                                    onPressed: () => widget.authService!
                                        .signInWithFacebook(),
                                    child: const Text('Connect'),
                                  ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      'GAMEPLAY & FEEDBACK',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Haptic Feedback'),
                          subtitle: const Text(
                            'Vibrate on moves and checkpoints',
                          ),
                          value: _preferences.hapticsEnabled,
                          onChanged: (val) {
                            _updatePreferences(
                              _preferences.copyWith(hapticsEnabled: val),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Tap to Extend'),
                          subtitle: const Text(
                            'Tap adjacent cells in addition to dragging',
                          ),
                          value: _preferences.tapToExtend,
                          onChanged: (val) {
                            _updatePreferences(
                              _preferences.copyWith(tapToExtend: val),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      'ACCESSIBILITY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Reduced Motion'),
                          subtitle: const Text(
                            'Disable subtle pulse and shake animations',
                          ),
                          value: _preferences.reducedMotion,
                          onChanged: (val) {
                            _updatePreferences(
                              _preferences.copyWith(reducedMotion: val),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      'ABOUT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.all_inclusive_rounded, size: 36),
                          SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Loopline',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Version 1.0.0 • Pure Flutter Engine',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
