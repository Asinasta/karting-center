import '../../../core/network/api_client.dart';

/// `TokenPair` from `01-analysis/api/auth/models.yaml`.
class TokenPair {
  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
    this.expiresIn,
  });

  factory TokenPair.fromJson(Map<String, Object?> json) {
    return TokenPair(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: json['expires_in'] as int?,
    );
  }

  final String accessToken;
  final String refreshToken;
  final int? expiresIn;
}

abstract class AuthRepository {
  /// `sendOtp`: POST /auth/otp
  Future<void> sendOtp({required String phone});

  /// `verifyOtp`: POST /auth/verify. [name] is required for a new client.
  Future<TokenPair> verifyOtp({
    required String phone,
    required String code,
    String? name,
  });

  /// `refreshToken`: POST /auth/refresh
  Future<TokenPair> refreshToken({required String refreshToken});
}

class ApiAuthRepository implements AuthRepository {
  const ApiAuthRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<void> sendOtp({required String phone}) async {
    await _apiClient.post('/auth/otp', body: {'phone': phone});
  }

  @override
  Future<TokenPair> verifyOtp({
    required String phone,
    required String code,
    String? name,
  }) async {
    final payload = await _apiClient.post(
      '/auth/verify',
      body: {
        'phone': phone,
        'code': code,
        if (name != null) 'name': name,
      },
    );
    return TokenPair.fromJson(payload! as Map<String, Object?>);
  }

  @override
  Future<TokenPair> refreshToken({required String refreshToken}) async {
    final payload = await _apiClient.post(
      '/auth/refresh',
      body: {'refresh_token': refreshToken},
    );
    return TokenPair.fromJson(payload! as Map<String, Object?>);
  }
}
