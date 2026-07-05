import 'dart:convert';

import 'package:http/http.dart' as http;

import '../error/app_failure.dart';

/// Supplies bearer tokens for protected endpoints.
///
/// Implemented by `SessionRepository`; refresh is single-flight there.
abstract class AuthTokenProvider {
  Future<String?> currentAccessToken();

  /// Returns a fresh access token or null when refresh failed
  /// (failed refresh clears secure storage on the session side).
  Future<String?> refreshAccessToken();
}

/// Thin JSON HTTP client.
///
/// Public endpoints (`GET /slots`, `GET /slots/{id}`, `GET /marshals`) are
/// called with `authorized: false` and never send an access token.
class ApiClient {
  ApiClient({
    required Uri baseUri,
    required http.Client client,
  })  : _baseUri = baseUri,
        _client = client;

  final Uri _baseUri;
  final http.Client _client;

  /// Set once during dependency wiring (breaks the DI cycle with session).
  AuthTokenProvider? tokenProvider;

  Future<Object?> get(
    String path, {
    Map<String, Object>? query,
    bool authorized = false,
  }) {
    return _send('GET', path, query: query, authorized: authorized);
  }

  Future<Object?> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
    bool authorized = false,
  }) {
    return _send('POST', path, body: body, headers: headers, authorized: authorized);
  }

  Future<Object?> patch(
    String path, {
    Object? body,
    bool authorized = false,
  }) {
    return _send('PATCH', path, body: body, authorized: authorized);
  }

  Future<Object?> delete(
    String path, {
    bool authorized = false,
  }) {
    return _send('DELETE', path, authorized: authorized);
  }

  Future<Object?> _send(
    String method,
    String path, {
    Map<String, Object>? query,
    Object? body,
    Map<String, String>? headers,
    required bool authorized,
  }) async {
    String? token;
    if (authorized) {
      token = await tokenProvider?.currentAccessToken();
    }

    var response = await _request(method, path, query, body, headers, token);

    // 401 triggers a single refresh, then the request is retried once.
    if (authorized && response.statusCode == 401 && tokenProvider != null) {
      final refreshed = await tokenProvider!.refreshAccessToken();
      if (refreshed == null) {
        throw const AppFailureException(
          AppFailure(
            code: ApiErrorCode.unauthorized,
            message: 'Сессия истекла, войдите снова',
          ),
        );
      }
      response = await _request(method, path, query, body, headers, refreshed);
    }

    return _decode(response);
  }

  Future<http.Response> _request(
    String method,
    String path,
    Map<String, Object>? query,
    Object? body,
    Map<String, String>? extraHeaders,
    String? token,
  ) async {
    final uri = _baseUri.replace(
      path: _joinPath(_baseUri.path, path),
      queryParameters: query,
    );

    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?extraHeaders,
    };
    final encodedBody = body == null ? null : jsonEncode(body);

    try {
      final request = http.Request(method, uri);
      request.headers.addAll(headers);
      if (encodedBody != null) {
        request.body = encodedBody;
      }
      final streamed = await _client.send(request);
      return http.Response.fromStream(streamed);
    } on Object catch (error) {
      throw AppFailureException(AppFailure.network(error));
    }
  }

  Object? _decode(http.Response response) {
    final text = utf8.decode(response.bodyBytes);
    final body = text.isEmpty ? null : jsonDecode(text);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    if (body is Map<String, Object?>) {
      throw AppFailureException(AppFailure.api(body));
    }

    throw AppFailureException(
      AppFailure(
        message: 'HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'error'}',
      ),
    );
  }

  void close() => _client.close();
}

String _joinPath(String basePath, String path) {
  final normalizedBase = basePath.endsWith('/')
      ? basePath.substring(0, basePath.length - 1)
      : basePath;
  final normalizedPath = path.startsWith('/') ? path : '/$path';
  return '$normalizedBase$normalizedPath';
}
