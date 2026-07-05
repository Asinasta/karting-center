import '../../../core/network/api_client.dart';
import '../domain/notification_models.dart';

abstract class NotificationRepository {
  Future<NotificationList> listNotifications();
}

class ApiNotificationRepository implements NotificationRepository {
  const ApiNotificationRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<NotificationList> listNotifications() async {
    final payload = await _apiClient.get('/notifications', authorized: true);
    return NotificationList.fromJson(payload! as Map<String, Object?>);
  }
}
