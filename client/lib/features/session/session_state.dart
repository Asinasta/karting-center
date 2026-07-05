import '../profile/domain/profile_models.dart';

sealed class SessionState {
  const SessionState();
}

class CheckingSession extends SessionState {
  const CheckingSession();
}

class GuestSession extends SessionState {
  const GuestSession();
}

class AuthenticatedSession extends SessionState {
  const AuthenticatedSession({this.client});

  /// Profile of the signed-in client; may be null until the first
  /// successful `GET /profile` (e.g. right after token refresh offline).
  final Profile? client;
}
