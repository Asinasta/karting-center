import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

class ApiConfig {
  const ApiConfig({
    required this.baseUri,
  });

  factory ApiConfig.fromEnvironment() {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    final raw = fromEnv.isNotEmpty ? fromEnv : _defaultBaseUrl();
    return ApiConfig(baseUri: Uri.parse(raw));
  }

  /// Android emulator maps host localhost to `10.0.2.2`.
  /// Web and desktop use `localhost` so `flutter run` works without `--dart-define`.
  static String _defaultBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:8080';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8080';
      }
    } on Object {
      // Platform is unavailable on web (already handled above).
    }
    return 'http://localhost:8080';
  }

  final Uri baseUri;
}
