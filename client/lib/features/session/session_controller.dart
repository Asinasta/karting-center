import 'package:flutter/foundation.dart';

import '../auth/data/auth_repository.dart';
import '../profile/data/profile_repository.dart';
import '../profile/domain/profile_models.dart';
import 'data/session_repository.dart';
import 'session_state.dart';

/// App-wide session state (FL-03).
///
/// Start: no refresh token -> GuestSession (public catalog).
/// With refresh token -> AuthenticatedSession; profile is loaded lazily.
class SessionController extends ChangeNotifier {
  SessionController({
    required SessionRepository sessionRepository,
    required ProfileRepository profileRepository,
  })  : _sessionRepository = sessionRepository,
        _profileRepository = profileRepository {
    _sessionRepository.onSessionExpired = _handleSessionExpired;
  }

  final SessionRepository _sessionRepository;
  final ProfileRepository _profileRepository;

  SessionState _state = const CheckingSession();

  SessionState get state => _state;
  bool get isAuthenticated => _state is AuthenticatedSession;

  Future<void> checkSession() async {
    _setState(const CheckingSession());

    try {
      final hasRefresh = await _sessionRepository.restore();
      if (!hasRefresh) {
        _setState(const GuestSession());
        return;
      }

      _setState(const AuthenticatedSession());
      await _loadProfileSilently();
    } on Object {
      // Secure storage or token read failed — continue as guest.
      _setState(const GuestSession());
    }
  }

  /// Called by AuthFlow after a successful verifyOtp.
  Future<void> signIn(TokenPair pair) async {
    await _sessionRepository.saveTokenPair(pair);
    _setState(const AuthenticatedSession());
    await _loadProfileSilently();
  }

  Future<void> logout() async {
    await _sessionRepository.clear();
    _setState(const GuestSession());
  }

  /// Keeps the cached profile in sync after profile edits.
  void updateClient(Profile profile) {
    if (_state is AuthenticatedSession) {
      _setState(AuthenticatedSession(client: profile));
    }
  }

  Future<void> _loadProfileSilently() async {
    try {
      final profile = await _profileRepository.getProfile();
      if (_state is AuthenticatedSession) {
        _setState(AuthenticatedSession(client: profile));
      }
    } on Object {
      // Session stays authenticated; profile screen retries on open.
      // An invalid token is handled by refresh/onSessionExpired.
    }
  }

  void _handleSessionExpired() {
    if (_state is! GuestSession) {
      _setState(const GuestSession());
    }
  }

  void _setState(SessionState next) {
    if (_state == next) {
      return;
    }
    _state = next;
    notifyListeners();
  }
}
