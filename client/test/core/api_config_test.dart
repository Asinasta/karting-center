import 'package:apex_client/core/config/api_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ApiConfig stores base URI', () {
    final config = ApiConfig(baseUri: Uri.parse('http://localhost:8080'));
    expect(config.baseUri.toString(), 'http://localhost:8080');
  });
}
