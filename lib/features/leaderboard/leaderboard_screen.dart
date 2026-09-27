// lib/features/leaderboard/leaderboard_screen.dart
//
// Full leaderboard screen with Global / Friends tabs.
// Reads auth state to know whether to show the Friends tab or a sign-in prompt.

import 'package:flutter/material.dart';

import '../../data/cloud_repository.dart';
import '../../data/leaderboard_entry.dart';
import '../../features/auth/auth_service.dart';
import '../../features/auth/auth_state.dart';
import '../../widgets/leaderboard_tile.dart';
import 'leaderboard_controller.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({
    super.key,
    required this.authService,
    required this.cloudRepository,
  });

  final AuthService authService;
  final CloudRepository cloudRepository;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final LeaderboardController _controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controller = LeaderboardController(
      cloudRepository: widget.cloudRepository,
    );
    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(_onTabChanged);
    widget.authService.addListener(_onAuthChanged);

    // Initial load
    _loadCurrent();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    widget.authService.removeListener(_onAuthChanged);
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ── Listeners ──────────────────────────────────────────────

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final tab = _tabController.index == 0
        ? LeaderboardTab.global
        : LeaderboardTab.friends;
    _controller.switchTab(tab);
    _loadCurrent();
  }

  void _onAuthChanged() {
    if (_controller.activeTab == LeaderboardTab.friends) {
      _loadCurrent();
    }
  }

  // ── Data ───────────────────────────────────────────────────

  String? get _jwt {
    final s = widget.authService.state;
    return s is AuthAuthenticated ? s.user.jwt : null;
  }

  String? get _currentUserId {
    final s = widget.authService.state;
    return s is AuthAuthenticated ? s.user.id : null;
  }

  Future<void> _loadCurrent() async {
    await _controller.load(jwt: _jwt);
    if (mounted) setState(() {});
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'Friends'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Global tab ────────────────────────────────────
          _buildList(
            entries: _controller.globalEntries,
            status: _controller.status,
            errorMessage: _controller.errorMessage,
            currentUserId: _currentUserId,
            onLoadMore: _controller.hasMoreGlobal
                ? () async {
                    await _controller.loadMoreGlobal();
                    if (mounted) setState(() {});
                  }
                : null,
          ),

          // ── Friends tab ───────────────────────────────────
          _buildFriendsTab(cs, theme),
        ],
      ),
    );
  }

  Widget _buildFriendsTab(ColorScheme cs, ThemeData theme) {
    final isSignedIn = widget.authService.state is AuthAuthenticated;
    if (!isSignedIn) {
      return _buildSignInPrompt(cs, theme);
    }
    return _buildList(
      entries: _controller.friendsEntries,
      status: _controller.status,
      errorMessage: _controller.errorMessage,
      currentUserId: _currentUserId,
    );
  }

  Widget _buildSignInPrompt(ColorScheme cs, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: cs.primary),
            const SizedBox(height: 16),
            Text(
              'See how you rank among friends',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in with Facebook to compare scores with friends who also play Loopline.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => widget.authService.signInWithFacebook(),
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Facebook'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList({
    required List<LeaderboardEntry> entries,
    required LeaderboardStatus status,
    required String? errorMessage,
    required String? currentUserId,
    Future<void> Function()? onLoadMore,
  }) {
    if (status == LeaderboardStatus.loading && entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (status == LeaderboardStatus.error && entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48),
            const SizedBox(height: 12),
            Text(errorMessage ?? 'Could not load leaderboard'),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadCurrent, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (entries.isEmpty && status == LeaderboardStatus.loaded) {
      return const Center(child: Text('No entries yet — be the first!'));
    }

    return RefreshIndicator(
      onRefresh: _loadCurrent,
      child: ListView.builder(
        itemCount: entries.length + (onLoadMore != null ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == entries.length) {
            // Load more button
            return Padding(
              padding: const EdgeInsets.all(16),
              child: status == LeaderboardStatus.loading
                  ? const Center(child: CircularProgressIndicator())
                  : TextButton(
                      onPressed: onLoadMore,
                      child: const Text('Load more'),
                    ),
            );
          }
          final entry = entries[i];
          return LeaderboardTile(
            entry: entry,
            isCurrentUser: entry.userId == currentUserId,
          );
        },
      ),
    );
  }
}
