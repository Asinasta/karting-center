import '../../../core/network/api_client.dart';
import '../domain/profile_models.dart';

abstract class ProfileRepository {
  /// `getProfile`: GET /profile
  Future<Profile> getProfile();

  /// `updateProfile`: PATCH /profile — name only, phone is never sent here.
  Future<Profile> updateProfile({required String name});

  /// `sendPhoneChangeOtp`: POST /profile/phone-change/otp
  Future<void> sendPhoneChangeOtp({required String newPhone});

  /// `verifyPhoneChange`: POST /profile/phone-change/verify
  Future<Profile> verifyPhoneChange({
    required String newPhone,
    required String code,
  });

  /// `deleteAccount`: DELETE /profile
  Future<void> deleteAccount();

  /// `registerPushToken`: POST /profile/push-token
  Future<void> registerPushToken({
    required String token,
    required String platform,
    String? deviceId,
  });
}

class ApiProfileRepository implements ProfileRepository {
  const ApiProfileRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<Profile> getProfile() async {
    final payload = await _apiClient.get('/profile', authorized: true);
    return Profile.fromJson(payload! as Map<String, Object?>);
  }

  @override
  Future<Profile> updateProfile({required String name}) async {
    final payload = await _apiClient.patch(
      '/profile',
      body: {'name': name},
      authorized: true,
    );
    return Profile.fromJson(payload! as Map<String, Object?>);
  }

  @override
  Future<void> sendPhoneChangeOtp({required String newPhone}) async {
    await _apiClient.post(
      '/profile/phone-change/otp',
      body: {'new_phone': newPhone},
      authorized: true,
    );
  }

  @override
  Future<Profile> verifyPhoneChange({
    required String newPhone,
    required String code,
  }) async {
    final payload = await _apiClient.post(
      '/profile/phone-change/verify',
      body: {'new_phone': newPhone, 'code': code},
      authorized: true,
    );
    return Profile.fromJson(payload! as Map<String, Object?>);
  }

  @override
  Future<void> deleteAccount() async {
    await _apiClient.delete('/profile', authorized: true);
  }

  @override
  Future<void> registerPushToken({
    required String token,
    required String platform,
    String? deviceId,
  }) async {
    await _apiClient.post(
      '/profile/push-token',
      body: {
        'token': token,
        'platform': platform,
        if (deviceId != null) 'device_id': deviceId,
      },
      authorized: true,
    );
  }
}
