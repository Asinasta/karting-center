import '../../../core/network/api_client.dart';
import '../domain/slot_models.dart';

abstract class MarshalRepository {
  /// `listMarshals`: GET /marshals — public, no token.
  Future<List<Marshal>> listMarshals();
}

class ApiMarshalRepository implements MarshalRepository {
  const ApiMarshalRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<Marshal>> listMarshals() async {
    final payload = await _apiClient.get('/marshals');
    final items = payload! as List<dynamic>;
    return items
        .map((item) => Marshal.fromJson(item as Map<String, Object?>))
        .toList();
  }
}
