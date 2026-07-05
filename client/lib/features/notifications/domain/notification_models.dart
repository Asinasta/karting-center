class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.bookingId,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, Object?> json) {
    return AppNotification(
      id: json['id'] as String,
      type: json['type'] as String,
      bookingId: json['booking_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String type;
  final String title;
  final String body;
  final String bookingId;
  final DateTime createdAt;

  bool get isRateMarshal => type == 'rate_marshal';
}

class NotificationList {
  const NotificationList({required this.items});

  factory NotificationList.fromJson(Map<String, Object?> json) {
    return NotificationList(
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((item) => AppNotification.fromJson(item as Map<String, Object?>))
          .toList(),
    );
  }

  final List<AppNotification> items;
}
