// lib/features/leaderboard/leaderboard_controller.dart
//
// Fetches and caches Global and Friends leaderboard data.
// Extends ChangeNotifier so the UI can rebuild on state changes.

import 'package:flutter/foundation.dart';

import '../../data/cloud_repository.dart';
import '../../data/leaderboard_entry.dart';

enum LeaderboardTab { global, friends }

enum LeaderboardStatus { idle, loading, loaded, error }

class LeaderboardController extends ChangeNotifier {
  LeaderboardController({required CloudRepository cloudRepository})
    : _cloud = cloudRepository;

  final CloudRepository _cloud;

  // ── State ──────────────────────────────────────────────────

  LeaderboardTab _activeTab = LeaderboardTab.global;
  LeaderboardTab get activeTab => _activeTab;

  LeaderboardStatus _status = LeaderboardStatus.idle;
  LeaderboardStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<LeaderboardEntry> _globalEntries = [];
  List<LeaderboardEntry> get globalEntries => _globalEntries;

  List<LeaderboardEntry> _friendsEntries = [];
  List<LeaderboardEntry> get friendsEntries => _friendsEntries;

  List<LeaderboardEntry> get activeEntries =>
      _activeTab == LeaderboardTab.global ? _globalEntries : _friendsEntries;

  int _globalPage = 1;
  bool _hasMoreGlobal = true;
  bool get hasMoreGlobal => _hasMoreGlobal;

  // ── Actions ────────────────────────────────────────────────

  void switchTab(LeaderboardTab tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    notifyListeners();
  }

  /// Load (or reload) the currently active tab.
  Future<void> load({String? jwt}) async {
    _status = LeaderboardStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_activeTab == LeaderboardTab.global) {
        _globalPage = 1;
        _globalEntries = await _cloud.getGlobalLeaderboard(page: 1);
        _hasMoreGlobal = _globalEntries.length == 50;
      } else {
        if (jwt == null) {
          _friendsEntries = [];
          _status = LeaderboardStatus.loaded;
          notifyListeners();
          return;
        }
        _friendsEntries = await _cloud.getFriendsLeaderboard(jwt);
      }
      _status = LeaderboardStatus.loaded;
    } catch (e) {
      _status = LeaderboardStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// Append the next page of global results (pagination).
  Future<void> loadMoreGlobal() async {
    if (!_hasMoreGlobal || _status == LeaderboardStatus.loading) return;
    _status = LeaderboardStatus.loading;
    notifyListeners();

    try {
      _globalPage++;
      final next = await _cloud.getGlobalLeaderboard(page: _globalPage);
      _globalEntries = [..._globalEntries, ...next];
      _hasMoreGlobal = next.length == 50;
      _status = LeaderboardStatus.loaded;
    } catch (e) {
      _globalPage--; // revert so retry works
      _status = LeaderboardStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }
}
