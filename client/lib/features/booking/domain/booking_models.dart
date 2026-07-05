import '../../../core/domain/common_models.dart';
import '../../slots/domain/slot_models.dart';

/// `GearChoice` from `01-analysis/api/bookings/models.yaml`.
enum GearChoice {
  own,
  rental;

  static GearChoice fromJson(String value) {
    return switch (value) {
      'own' => GearChoice.own,
      'rental' => GearChoice.rental,
      _ => throw FormatException('Unknown gear choice: $value'),
    };
  }

  String get apiValue => name;

  String get label {
    return switch (this) {
      GearChoice.own => 'Своя экипировка',
      GearChoice.rental => 'Прокатная экипировка',
    };
  }
}

/// `Booking.status` enum.
enum BookingStatus {
  active,
  cancelled,
  lateCancel,
  cancelledByCenter,
  completed;

  static BookingStatus fromJson(String value) {
    return switch (value) {
      'active' => BookingStatus.active,
      'cancelled' => BookingStatus.cancelled,
      'late_cancel' => BookingStatus.lateCancel,
      'cancelled_by_center' => BookingStatus.cancelledByCenter,
      'completed' => BookingStatus.completed,
      _ => throw FormatException('Unknown booking status: $value'),
    };
  }

  String get label {
    return switch (this) {
      BookingStatus.active => 'Активна',
      BookingStatus.cancelled => 'Отменена',
      BookingStatus.lateCancel => 'Поздняя отмена',
      BookingStatus.cancelledByCenter => 'Отменена центром',
      BookingStatus.completed => 'Завершена',
    };
  }

  bool get isCancelledKind =>
      this == BookingStatus.cancelled ||
      this == BookingStatus.lateCancel ||
      this == BookingStatus.cancelledByCenter;
}

/// `BookingSlotSnapshot` — slot fields frozen with the booking.
class BookingSlotSnapshot {
  const BookingSlotSnapshot({
    required this.id,
    required this.trackConfig,
    required this.marshal,
    required this.startAt,
    required this.price,
    required this.rentalPrice,
    required this.meetingPoint,
    required this.status,
    this.meetingPointLat,
    this.meetingPointLng,
    this.geometry,
    this.cancelReason,
  });

  factory BookingSlotSnapshot.fromJson(Map<String, Object?> json) {
    return BookingSlotSnapshot(
      id: json['id'] as String,
      trackConfig:
          TrackConfig.fromJson(json['track_config'] as Map<String, Object?>),
      marshal: Marshal.fromJson(json['marshal'] as Map<String, Object?>),
      startAt: DateTime.parse(json['start_at'] as String),
      price: Money.fromJson(json['price'] as Map<String, Object?>),
      rentalPrice: Money.fromJson(json['rental_price'] as Map<String, Object?>),
      meetingPoint: json['meeting_point'] as String,
      meetingPointLat: json['meeting_point_lat'] as num?,
      meetingPointLng: json['meeting_point_lng'] as num?,
      geometry: parseGeometry(json['geometry']),
      status: SlotStatus.fromJson(json['status'] as String),
      cancelReason: json['cancel_reason'] as String?,
    );
  }

  final String id;
  final TrackConfig trackConfig;
  final Marshal marshal;
  final DateTime startAt;
  final Money price;
  final Money rentalPrice;
  final String meetingPoint;
  final num? meetingPointLat;
  final num? meetingPointLng;
  final List<List<num>>? geometry;
  final SlotStatus status;
  final String? cancelReason;
}

/// `Booking` from `01-analysis/api/bookings/models.yaml`.
class Booking {
  const Booking({
    required this.id,
    required this.slot,
    required this.seatsCount,
    required this.rentalCount,
    required this.seatGear,
    required this.priceTotal,
    required this.status,
    required this.createdAt,
    this.cancelledAt,
    this.cancelReason,
  });

  factory Booking.fromJson(Map<String, Object?> json) {
    return Booking(
      id: json['id'] as String,
      slot: BookingSlotSnapshot.fromJson(json['slot'] as Map<String, Object?>),
      seatsCount: json['seats_count'] as int,
      rentalCount: json['rental_count'] as int,
      seatGear: (json['seat_gear'] as List<dynamic>)
          .map((g) => GearChoice.fromJson(g as String))
          .toList(),
      priceTotal: Money.fromJson(json['price_total'] as Map<String, Object?>),
      status: BookingStatus.fromJson(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      cancelReason: json['cancel_reason'] as String?,
    );
  }

  final String id;
  final BookingSlotSnapshot slot;
  final int seatsCount;
  final int rentalCount;
  final List<GearChoice> seatGear;
  final Money priceTotal;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime? cancelledAt;
  final String? cancelReason;
}

class BookingList {
  const BookingList({
    required this.items,
    this.pagination,
  });

  factory BookingList.fromJson(Map<String, Object?> json) {
    return BookingList(
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((item) => Booking.fromJson(item as Map<String, Object?>))
          .toList(),
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'] as Map<String, Object?>)
          : null,
    );
  }

  final List<Booking> items;
  final Pagination? pagination;
}
