import 'package:apex_client/core/storage/token_storage.dart';
import 'package:apex_client/features/auth/data/auth_repository.dart';
import 'package:apex_client/features/profile/data/profile_repository.dart';
import 'package:apex_client/features/session/data/session_repository.dart';
import 'package:apex_client/features/session/presentation/splash_screen.dart';
import 'package:apex_client/features/session/session_controller.dart';
import 'package:apex_client/features/session/session_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _MemoryTokenStorage implements TokenStorage {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {}
}

class _StubAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _StubProfileRepository implements ProfileRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  testWidgets('SplashScreen does not notify router during first build',
      (tester) async {
    final sessionController = SessionController(
      sessionRepository: SessionRepository(
        tokenStorage: _MemoryTokenStorage(),
        authRepository: _StubAuthRepository(),
      ),
      profileRepository: _StubProfileRepository(),
    );
    addTearDown(sessionController.dispose);

    final router = GoRouter(
      initialLocation: '/',
      refreshListenable: sessionController,
      redirect: (context, state) {
        final sessionState = sessionController.state;
        if (sessionState is CheckingSession) {
          return state.matchedLocation == '/' ? null : '/';
        }
        if (state.matchedLocation == '/') {
          return '/slots';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => SplashScreen(
            sessionController: sessionController,
          ),
        ),
        GoRoute(
          path: '/slots',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Slots')),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(tester.takeException(), isNull);

    await tester.pump();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(sessionController.state, isA<GuestSession>());
    expect(find.text('Slots'), findsOneWidget);
  });
}
