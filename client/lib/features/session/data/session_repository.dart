import 'dart:async';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/data/auth_repository.dart';

/// Owns the token pair. The only place tokens are read or written (plan rule:
/// token storage goes only through SessionRepository).
///
/// Implements [AuthTokenProvider] for the network layer: a 401 triggers one
/// single-flight refresh; a failed refresh clears secure storage.
class SessionRepository implements AuthTokenProvider {
  SessionRepository({
    required TokenStorage tokenStorage,
    required AuthRepository authRepository,
  })  : _tokenStorage = tokenStorage,
        _authRepository = authRepository;

  final TokenStorage _tokenStorage;
  final AuthRepository _authRepository;

  String? _accessToken;
  Future<String?>? _refreshInFlight;

  /// Called after a failed refresh so the app can drop to GuestSession.
  void Function()? onSessionExpired;

  /// Restores tokens on app start. Returns true when a refresh token exists.
  Future<bool> restore() async {
    _accessToken = await _tokenStorage.readAccessToken();
    final refresh = await _tokenStorage.readRefreshToken();
    return refresh != null;
  }

  Future<void> saveTokenPair(TokenPair pair) async {
    _accessToken = pair.accessToken;
    await _tokenStorage.saveTokens(
      accessToken: pair.accessToken,
      refreshToken: pair.refreshToken,
    );
  }

  Future<void> clear() async {
    _accessToken = null;
    await _tokenStorage.clear();
  }

  @override
  Future<String?> currentAccessToken() async {
    return _accessToken ??= await _tokenStorage.readAccessToken();
  }

  @override
  Future<String?> refreshAccessToken() {
    // Single-flight: concurrent 401s share one refresh request.
    return _refreshInFlight ??= _doRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) {
      return null;
    }
    try {
      final pair = await _authRepository.refreshToken(refreshToken: refreshToken);
      await saveTokenPair(pair);
      return pair.accessToken;
    } on Object {
      await clear();
      onSessionExpired?.call();
      return null;
    }
  }
}
