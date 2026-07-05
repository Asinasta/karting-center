import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../profile/data/profile_repository.dart';

/// Push integration (FL-14, LOGIC-007).
///
/// The concrete push plugin is not agreed yet (open question in the client
/// plan), so this service implements the agreed contract around it:
/// - the system permission prompt is requested once, after the first
///   successful booking;
/// - the "already asked" flag is persisted locally;
/// - when a platform token exists it is sent to `registerPushToken`;
/// - push being unavailable never blocks the booking flow.
abstract class PushService {
  /// Called from BS-002 after the first successful booking.
  Future<void> requestPermissionAfterFirstBooking();

  /// Re-register the token (e.g. on profile/session load). Safe no-op when
  /// there is no token or no permission.
  Future<void> syncToken();
}

class LocalFlagPushService implements PushService {
  LocalFlagPushService(this._profileRepository);

  static const _requestedFlagKey = 'apex_push_permission_requested';

  final ProfileRepository _profileRepository;

  @override
  Future<void> requestPermissionAfterFirstBooking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_requestedFlagKey) ?? false) {
        return;
      }
      await prefs.setBool(_requestedFlagKey, true);
      // No push plugin in this build: nothing to request yet. When the
      // plugin is agreed, the system prompt goes here.
      await syncToken();
    } on Object catch (error) {
      // Push must never break the booking flow.
      debugPrint('Push permission request skipped: $error');
    }
  }

  @override
  Future<void> syncToken() async {
    final token = await _platformPushToken();
    if (token == null) {
      return;
    }
    final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
    try {
      await _profileRepository.registerPushToken(token: token, platform: platform);
    } on Object catch (error) {
      // Retried on the next profile/session load per FL-13.
      debugPrint('registerPushToken failed, will retry later: $error');
    }
  }

  Future<String?> _platformPushToken() async {
    // No push plugin wired yet -> no token on any platform.
    return null;
  }
}
