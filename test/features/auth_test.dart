import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connect_puzzle_game/data/cloud_repository.dart';
import 'package:connect_puzzle_game/features/auth/auth_screen.dart';
import 'package:connect_puzzle_game/features/auth/auth_service.dart';
import 'package:connect_puzzle_game/features/auth/auth_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthState Model Tests', () {
    test('AuthUser equality and copyWith', () {
      const u1 = AuthUser(
        id: '123',
        name: 'Player One',
        avatarUrl: 'https://pic.jpg',
        jwt: 'jwt_abc',
      );
      const u2 = AuthUser(id: '123', name: 'Player One', jwt: 'jwt_abc');

      expect(u1, equals(u2));
      expect(u1.hashCode, equals(u2.hashCode));

      final u3 = u1.copyWith(name: 'Updated Name');
      expect(u3.name, 'Updated Name');
      expect(u3.id, '123');
    });

    test('AuthState flags', () {
      const initial = AuthInitial();
      expect(initial.isAuthenticated, isFalse);
      expect(initial.isGuest, isFalse);
      expect(initial.hasChosenMode, isFalse);

      const guest = AuthGuest();
      expect(guest.isAuthenticated, isFalse);
      expect(guest.isGuest, isTrue);
      expect(guest.hasChosenMode, isTrue);

      const auth = AuthAuthenticated(
        AuthUser(id: '1', name: 'User', jwt: 'tok'),
      );
      expect(auth.isAuthenticated, isTrue);
      expect(auth.isGuest, isFalse);
      expect(auth.hasChosenMode, isTrue);
    });
  });

  group('AuthService Session & Guest Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('restoreSession restores guest mode when flag is set', () async {
      SharedPreferences.setMockInitialValues({'auth_is_guest': true});
      final authService = AuthService(cloudRepository: CloudRepository());

      await authService.restoreSession();

      expect(authService.state, isA<AuthGuest>());
    });

    test(
      'restoreSession restores authenticated user when token exists',
      () async {
        SharedPreferences.setMockInitialValues({
          'auth_jwt': 'saved_jwt',
          'auth_user_id': 'u456',
          'auth_user_name': 'Saved User',
          'auth_avatar_url': 'https://example.com/avatar.png',
        });
        final authService = AuthService(cloudRepository: CloudRepository());

        await authService.restoreSession();

        expect(authService.state, isA<AuthAuthenticated>());
        final user = (authService.state as AuthAuthenticated).user;
        expect(user.id, 'u456');
        expect(user.name, 'Saved User');
        expect(user.jwt, 'saved_jwt');
        expect(user.avatarUrl, 'https://example.com/avatar.png');
      },
    );

    test('restoreSession defaults to unauthenticated when empty', () async {
      final authService = AuthService(cloudRepository: CloudRepository());
      await authService.restoreSession();
      expect(authService.state, isA<AuthUnauthenticated>());
    });

    test('continueAsGuest sets state and persists flag', () async {
      final authService = AuthService(cloudRepository: CloudRepository());
      await authService.continueAsGuest();

      expect(authService.state, isA<AuthGuest>());
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('auth_is_guest'), isTrue);
    });

    test('signOut clears persisted keys and updates state', () async {
      SharedPreferences.setMockInitialValues({
        'auth_jwt': 'saved_jwt',
        'auth_user_id': 'u456',
        'auth_user_name': 'Saved User',
        'auth_is_guest': true,
      });

      final authService = AuthService(cloudRepository: CloudRepository());
      await authService.signOut();

      expect(authService.state, isA<AuthUnauthenticated>());
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_jwt'), isNull);
      expect(prefs.getString('auth_user_id'), isNull);
      expect(prefs.getBool('auth_is_guest'), isNull);
    });
  });

  group('AuthScreen Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Renders AuthScreen with Facebook and Guest options', (
      WidgetTester tester,
    ) async {
      final authService = AuthService(cloudRepository: CloudRepository());
      var guestTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(
            authService: authService,
            onContinueAsGuest: () {
              guestTapped = true;
            },
          ),
        ),
      );

      expect(find.text('Loopline'), findsOneWidget);
      expect(find.text('Cloud Account'), findsOneWidget);
      expect(find.text('Continue with Facebook'), findsOneWidget);
      expect(find.text('Play as Guest'), findsOneWidget);
      expect(find.text('Continue as Guest'), findsOneWidget);

      await tester.ensureVisible(find.text('Continue as Guest'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue as Guest'));
      await tester.pumpAndSettle();

      expect(guestTapped, isTrue);
    });
  });
}
