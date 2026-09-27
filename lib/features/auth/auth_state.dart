// lib/features/auth/auth_state.dart
//
// Immutable sealed union representing all possible authentication states.
// Use a switch expression on this type wherever the UI needs to branch.

import 'package:flutter/foundation.dart';

/// A user profile returned after successful Facebook login.
@immutable
class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.jwt,
  });

  /// Stable Facebook user ID used as the primary key in our D1 database.
  final String id;
  final String name;
  final String? avatarUrl;

  /// Short-lived JWT issued by the Cloudflare Worker (24 h TTL).
  final String jwt;

  AuthUser copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? jwt,
  }) {
    return AuthUser(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      jwt: jwt ?? this.jwt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          jwt == other.jwt;

  @override
  int get hashCode => Object.hash(id, jwt);
}

/// Sealed base class for the authentication state machine.
@immutable
sealed class AuthState {
  const AuthState();

  bool get isAuthenticated => this is AuthAuthenticated;
  bool get isGuest => this is AuthGuest;
  bool get hasChosenMode => this is AuthAuthenticated || this is AuthGuest;
}

/// Initial state — no sign-in attempt has been made yet.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// A sign-in flow is in progress (showing a loading indicator).
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// The user is signed in with Facebook and has a valid JWT.
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final AuthUser user;
}

/// The user chose to play as a guest. Progress is saved locally on the device only.
final class AuthGuest extends AuthState {
  const AuthGuest();
}

/// The user explicitly signed out or has not yet chosen an account mode.
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// An error occurred during sign-in (e.g. network failure, token rejection).
final class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
}
