import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_screen.dart';
import '../features/booking/presentation/booking_details_screen.dart';
import '../features/booking/presentation/booking_form_screen.dart';
import '../features/booking/presentation/booking_list_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/session/presentation/splash_screen.dart';
import '../features/session/session_state.dart';
import '../features/slots/presentation/slot_details_screen.dart';
import '../features/slots/presentation/slot_list_screen.dart';
import 'app_scope.dart';

/// Protected locations require AuthenticatedSession (plan: SCR-004..007).
bool _isProtectedLocation(String location) {
  if (location.startsWith('/bookings') || location.startsWith('/profile')) {
    return true;
  }
  return location.startsWith('/slots/') && location.endsWith('/book');
}

GoRouter createAppRouter(AppDependencies dependencies) {
  final session = dependencies.sessionController;

  return GoRouter(
    initialLocation: '/',
    // Re-evaluates redirects when the session changes (auth gate, logout).
    refreshListenable: session,
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Ошибка')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            state.error?.toString() ?? 'Не удалось открыть экран',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
    redirect: (context, state) {
      final sessionState = session.state;
      final location = state.matchedLocation;

      if (sessionState is CheckingSession) {
        return location == '/' ? null : '/';
      }
      if (location == '/') {
        return '/slots';
      }

      // Auth gate with return intent.
      if (_isProtectedLocation(location) && sessionState is! AuthenticatedSession) {
        return Uri(
          path: '/auth',
          queryParameters: {'return': state.uri.toString()},
        ).toString();
      }

      // Return intent: leave auth flow once signed in.
      if (location == '/auth' && sessionState is AuthenticatedSession) {
        final returnTo = state.uri.queryParameters['return'];
        return (returnTo != null && returnTo.startsWith('/')) ? returnTo : '/slots';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => SplashScreen(
          sessionController: dependencies.sessionController,
        ),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => AuthScreen(
          returnTo: state.uri.queryParameters['return'],
        ),
      ),
      GoRoute(
        path: '/slots',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const SlotListScreen(),
        ),
        routes: [
          GoRoute(
            path: ':slotId',
            builder: (context, state) => SlotDetailsScreen(
              slotId: state.pathParameters['slotId']!,
            ),
            routes: [
              GoRoute(
                path: 'book',
                builder: (context, state) => BookingFormScreen(
                  slotId: state.pathParameters['slotId']!,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/bookings',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const BookingListScreen(),
        ),
        routes: [
          GoRoute(
            path: ':bookingId',
            builder: (context, state) => BookingDetailsScreen(
              bookingId: state.pathParameters['bookingId']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const ProfileScreen(),
        ),
      ),
    ],
  );
}

class ApexBottomNavigationBar extends StatelessWidget {
  const ApexBottomNavigationBar({
    required this.currentIndex,
    super.key,
  });

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go('/slots');
            return;
          case 1:
            context.go('/bookings');
            return;
          case 2:
            context.go('/profile');
            return;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.sports_motorsports_outlined),
          selectedIcon: Icon(Icons.sports_motorsports),
          label: 'Запись',
        ),
        NavigationDestination(
          icon: Icon(Icons.event_note_outlined),
          selectedIcon: Icon(Icons.event_note),
          label: 'Мои записи',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Профиль',
        ),
      ],
    );
  }
}
