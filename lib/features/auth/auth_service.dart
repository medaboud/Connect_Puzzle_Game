// lib/features/auth/auth_service.dart
//
// Wraps flutter_facebook_auth and the Cloudflare Worker /auth/facebook endpoint.
// Persists the JWT to shared_preferences so the user stays logged in across sessions.

import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/cloud_repository.dart';
import 'auth_state.dart';

/// Manages Facebook sign-in / sign-out and exposes the current [AuthState].
///
/// Usage — listen for changes:
/// ```dart
/// authService.addListener(() {
///   final state = authService.state;
/// });
/// ```
class AuthService extends ChangeNotifier {
  AuthService({
    required CloudRepository cloudRepository,
    FacebookAuth? facebookAuth,
  }) : _cloud = cloudRepository,
       _facebookAuth = facebookAuth;

  final CloudRepository _cloud;
  final FacebookAuth? _facebookAuth;
  FacebookAuth get _fb => _facebookAuth ?? FacebookAuth.instance;

  AuthState _state = const AuthInitial();
  AuthState get state => _state;

  // SharedPreferences keys
  static const _keyJwt = 'auth_jwt';
  static const _keyUserId = 'auth_user_id';
  static const _keyUserName = 'auth_user_name';
  static const _keyAvatarUrl = 'auth_avatar_url';
  static const _keyIsGuest = 'auth_is_guest';

  // ── Lifecycle ──────────────────────────────────────────────

  /// Call once at app start to restore a previously saved session.
  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString(_keyJwt);
    final id = prefs.getString(_keyUserId);
    final name = prefs.getString(_keyUserName);

    if (jwt != null && id != null && name != null) {
      _setState(
        AuthAuthenticated(
          AuthUser(
            id: id,
            name: name,
            avatarUrl: prefs.getString(_keyAvatarUrl),
            jwt: jwt,
          ),
        ),
      );
    } else if (prefs.getBool(_keyIsGuest) == true) {
      _setState(const AuthGuest());
    } else {
      _setState(const AuthUnauthenticated());
    }
  }

  // ── Guest Mode ─────────────────────────────────────────────

  /// Allows the player to play locally without connecting a Facebook account.
  /// All puzzle progress, streaks, and statistics are saved locally on this device only.
  Future<void> continueAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsGuest, true);
    _setState(const AuthGuest());
  }

  // ── Sign in ────────────────────────────────────────────────

  /// Launches the native Facebook OAuth dialog, exchanges the token with the
  /// Cloudflare Worker, and persists the resulting JWT.
  Future<void> signInWithFacebook() async {
    final wasGuest = _state is AuthGuest;
    _setState(const AuthLoading());

    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      _setState(
        const AuthError(
          'Facebook login is supported on mobile devices. Please continue as Guest on desktop.',
        ),
      );
      return;
    }

    try {
      final result = await _fb.login(
        permissions: const ['public_profile', 'user_friends'],
      );

      switch (result.status) {
        case LoginStatus.success:
          final fbToken = result.accessToken?.tokenString;
          if (fbToken == null) {
            _setState(
              const AuthError(
                'Facebook login succeeded but no token was returned.',
              ),
            );
            return;
          }
          await _exchangeToken(fbToken);

        case LoginStatus.cancelled:
          _setState(wasGuest ? const AuthGuest() : const AuthUnauthenticated());

        case LoginStatus.failed:
          _setState(AuthError(result.message ?? 'Facebook login failed.'));

        case LoginStatus.operationInProgress:
          // Another login is already running — ignore.
          break;
      }
    } catch (e) {
      _setState(AuthError('Unexpected error: $e'));
    }
  }

  // ── Sign out ───────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      await _fb.logOut();
    } catch (_) {
      // Ignore native logout failure
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyJwt);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyAvatarUrl);
    await prefs.remove(_keyIsGuest);
    _setState(const AuthUnauthenticated());
  }

  void clearError() {
    if (_state is AuthError) {
      _setState(const AuthUnauthenticated());
    }
  }

  // ── Helpers ────────────────────────────────────────────────

  /// Sends the Facebook access token to the Worker and stores the resulting JWT.
  Future<void> _exchangeToken(String fbToken) async {
    try {
      final user = await _cloud.loginWithFacebook(fbToken);
      await _persistSession(user);
      _setState(AuthAuthenticated(user));

      // Sync friend list in the background (non-blocking)
      unawaited(_cloud.syncFriends(user.jwt, fbToken));
    } catch (e) {
      _setState(AuthError('Could not sign in: $e'));
    }
  }

  Future<void> _persistSession(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsGuest);
    await prefs.setString(_keyJwt, user.jwt);
    await prefs.setString(_keyUserId, user.id);
    await prefs.setString(_keyUserName, user.name);
    if (user.avatarUrl != null) {
      await prefs.setString(_keyAvatarUrl, user.avatarUrl!);
    }
  }

  void _setState(AuthState s) {
    _state = s;
    notifyListeners();
  }
}

/// Silences the unawaited-future lint for fire-and-forget calls.
void unawaited(Future<void> future) {
  future.ignore();
}
