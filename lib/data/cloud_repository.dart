// lib/data/cloud_repository.dart
//
// All HTTPS communication with the Cloudflare Worker.
// The Worker base URL is set via the kWorkerBaseUrl constant below —
// update it once your Worker is deployed.

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../features/auth/auth_state.dart';
import 'leaderboard_entry.dart';

// ── Configuration ──────────────────────────────────────────────────────────

/// Deployed Cloudflare Worker API URL
const String kWorkerBaseUrl = 'https://loopline-api.m-aboud-engr.workers.dev';

// ── Exceptions ─────────────────────────────────────────────────────────────

class CloudException implements Exception {
  const CloudException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => 'CloudException($statusCode): $message';
}

// ── Repository ─────────────────────────────────────────────────────────────

/// Handles all communication with the Loopline Cloudflare Worker API.
///
/// Methods throw [CloudException] on non-2xx responses or network failures.
class CloudRepository {
  CloudRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // ── Auth ────────────────────────────────────────────────────────────────

  /// Exchange a Facebook user-access token for a Worker-issued JWT.
  /// Returns the authenticated [AuthUser] with the JWT embedded.
  Future<AuthUser> loginWithFacebook(String fbAccessToken) async {
    final response = await _post(
      '/auth/facebook',
      body: {'fb_access_token': fbAccessToken},
    );
    final data = _requireMap(response, 'auth/facebook');
    final user = _requireMap(data['user'], 'user');

    return AuthUser(
      id: user['id'] as String,
      name: user['name'] as String,
      avatarUrl: user['avatar_url'] as String?,
      jwt: data['jwt'] as String,
    );
  }

  // ── Completions ─────────────────────────────────────────────────────────

  /// Submit a completed puzzle solve to the Worker.
  ///
  /// Returns the number of points awarded, or null if the puzzle was already
  /// submitted (HTTP 409 — not treated as an error).
  Future<int?> submitCompletion({
    required String jwt,
    required String puzzleId,
    required String difficulty,
    required int timeSeconds,
    required int moveCount,
    required int hintsUsed,
  }) async {
    try {
      final response = await _post(
        '/completions',
        jwt: jwt,
        body: {
          'puzzle_id': puzzleId,
          'difficulty': difficulty,
          'time_seconds': timeSeconds,
          'move_count': moveCount,
          'hints_used': hintsUsed,
        },
      );
      final data = _requireMap(response, 'completions');
      return data['points_earned'] as int?;
    } on CloudException catch (e) {
      if (e.statusCode == 409) return null; // already submitted — not an error
      rethrow;
    }
  }

  // ── Leaderboard ─────────────────────────────────────────────────────────

  /// Fetch a page of the global leaderboard (50 entries per page).
  Future<List<LeaderboardEntry>> getGlobalLeaderboard({int page = 1}) async {
    final response = await _get('/leaderboard/global?page=$page');
    final data = _requireMap(response, 'leaderboard/global');
    final entries = data['entries'] as List<dynamic>? ?? [];
    return entries.map(_entryFromJson).toList();
  }

  /// Fetch the authenticated user's friends leaderboard.
  Future<List<LeaderboardEntry>> getFriendsLeaderboard(String jwt) async {
    final response = await _get('/leaderboard/friends', jwt: jwt);
    final data = _requireMap(response, 'leaderboard/friends');
    final entries = data['entries'] as List<dynamic>? ?? [];
    return entries.map(_entryFromJson).toList();
  }

  // ── Friends ─────────────────────────────────────────────────────────────

  /// Push the caller's Facebook friend list to the Worker so they appear
  /// on the friends leaderboard. Called silently in the background after login.
  Future<void> syncFriends(String jwt, String fbAccessToken) async {
    await _post(
      '/friends/sync',
      jwt: jwt,
      body: {'fb_access_token': fbAccessToken},
    );
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  Future<dynamic> _get(String path, {String? jwt}) async {
    final uri = Uri.parse('$kWorkerBaseUrl$path');
    final headers = _buildHeaders(jwt: jwt);
    try {
      final res = await _client.get(uri, headers: headers);
      return _decode(res);
    } catch (e) {
      if (e is CloudException) rethrow;
      throw CloudException('Network error: $e');
    }
  }

  Future<dynamic> _post(
    String path, {
    String? jwt,
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('$kWorkerBaseUrl$path');
    final headers = _buildHeaders(jwt: jwt)
      ..['Content-Type'] = 'application/json';
    try {
      final res = await _client.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      return _decode(res);
    } catch (e) {
      if (e is CloudException) rethrow;
      throw CloudException('Network error: $e');
    }
  }

  Map<String, String> _buildHeaders({String? jwt}) {
    final h = <String, String>{};
    if (jwt != null) h['Authorization'] = 'Bearer $jwt';
    return h;
  }

  dynamic _decode(http.Response res) {
    final body = utf8.decode(res.bodyBytes);
    final json = jsonDecode(body);
    if (res.statusCode >= 200 && res.statusCode < 300) return json;
    final message =
        (json is Map ? json['error'] as String? : null) ??
        'HTTP ${res.statusCode}';
    throw CloudException(message, statusCode: res.statusCode);
  }

  Map<String, dynamic> _requireMap(dynamic value, String context) {
    if (value is Map<String, dynamic>) return value;
    throw CloudException('Unexpected response shape from $context');
  }

  LeaderboardEntry _entryFromJson(dynamic json) {
    final m = json as Map<String, dynamic>;
    return LeaderboardEntry(
      rank: m['rank'] as int,
      userId: m['user_id'] as String,
      name: m['name'] as String,
      avatarUrl: m['avatar_url'] as String?,
      totalPoints: m['total_points'] as int,
      puzzlesSolved: m['puzzles_solved'] as int,
    );
  }
}
