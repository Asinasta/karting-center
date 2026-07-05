class ApiConfig {
  const ApiConfig({
    required this.baseUri,
  });

  factory ApiConfig.fromEnvironment() {
    const raw = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8080',
    );
    return ApiConfig(baseUri: Uri.parse(raw));
  }

  final Uri baseUri;
}
