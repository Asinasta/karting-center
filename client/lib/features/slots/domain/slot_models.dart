import '../../../core/domain/common_models.dart';

export '../../../core/domain/common_models.dart' show Money;

/// `Marshal` from `01-analysis/api/marshals/models.yaml`.
class Marshal {
  const Marshal({
    required this.id,
    required this.name,
    this.averageRating,
    this.ratingCount = 0,
  });

  factory Marshal.fromJson(Map<String, Object?> json) {
    return Marshal(
      id: json['id'] as String,
      name: json['name'] as String,
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      ratingCount: json['rating_count'] as int? ?? 0,
    );
  }

  final String id;
  final String name;
  final double? averageRating;
  final int ratingCount;

  String? get ratingLabel {
    if (ratingCount <= 0 || averageRating == null) {
      return null;
    }
    final formatted = averageRating! % 1 == 0
        ? averageRating!.toStringAsFixed(0)
        : averageRating!.toStringAsFixed(1);
    return '★ $formatted ($ratingCount)';
  }
}

enum TrackConfigType {
  novice,
  experienced;

  static TrackConfigType fromJson(String value) {
    return switch (value) {
      'novice' => TrackConfigType.novice,
      'experienced' => TrackConfigType.experienced,
      _ => throw FormatException('Unknown track config type: $value'),
    };
  }

  String get apiValue => name;

  String get label {
    return switch (this) {
      TrackConfigType.novice => 'Новичковая',
      TrackConfigType.experienced => 'Опытная',
    };
  }
}

/// `TrackConfig` from `01-analysis/api/slots/models.yaml`.
class TrackConfig {
  const TrackConfig({
    required this.id,
    required this.name,
    required this.type,
    required this.capacityCap,
    this.description,
    this.durationMin,
    this.geometry,
  });

  factory TrackConfig.fromJson(Map<String, Object?> json) {
    return TrackConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: TrackConfigType.fromJson(json['type'] as String),
      capacityCap: json['capacity_cap'] as int,
      durationMin: json['duration_min'] as int?,
      geometry: parseGeometry(json['geometry']),
    );
  }

  final String id;
  final String name;
  final String? description;
  final TrackConfigType type;
  final int capacityCap;
  final int? durationMin;
  final List<List<num>>? geometry;
}

List<List<num>>? parseGeometry(Object? raw) {
  if (raw is! List) {
    return null;
  }
  return raw
      .map(
        (point) =>
            (point as List<dynamic>).map((value) => value as num).toList(),
      )
      .toList();
}

enum SlotStatus {
  scheduled,
  cancelled;

  static SlotStatus fromJson(String value) {
    return switch (value) {
      'scheduled' => SlotStatus.scheduled,
      'cancelled' => SlotStatus.cancelled,
      _ => throw FormatException('Unknown slot status: $value'),
    };
  }
}

/// `Slot` from `01-analysis/api/slots/models.yaml`.
class Slot {
  const Slot({
    required this.id,
    required this.trackConfig,
    required this.marshal,
    required this.startAt,
    required this.totalSeats,
    required this.freeSeats,
    required this.freeRentalGear,
    required this.price,
    required this.rentalPrice,
    required this.meetingPoint,
    required this.status,
    this.meetingPointLat,
    this.meetingPointLng,
    this.cancelReason,
  });

  factory Slot.fromJson(Map<String, Object?> json) {
    return Slot(
      id: json['id'] as String,
      trackConfig:
          TrackConfig.fromJson(json['track_config'] as Map<String, Object?>),
      marshal: Marshal.fromJson(json['marshal'] as Map<String, Object?>),
      startAt: DateTime.parse(json['start_at'] as String),
      totalSeats: json['total_seats'] as int,
      freeSeats: json['free_seats'] as int,
      freeRentalGear: json['free_rental_gear'] as int,
      price: Money.fromJson(json['price'] as Map<String, Object?>),
      rentalPrice: Money.fromJson(json['rental_price'] as Map<String, Object?>),
      meetingPoint: json['meeting_point'] as String,
      meetingPointLat: json['meeting_point_lat'] as num?,
      meetingPointLng: json['meeting_point_lng'] as num?,
      status: SlotStatus.fromJson(json['status'] as String),
      cancelReason: json['cancel_reason'] as String?,
    );
  }

  final String id;
  final TrackConfig trackConfig;
  final Marshal marshal;
  final DateTime startAt;
  final int totalSeats;
  final int freeSeats;
  final int freeRentalGear;
  final Money price;
  final Money rentalPrice;
  final String meetingPoint;
  final num? meetingPointLat;
  final num? meetingPointLng;
  final SlotStatus status;
  final String? cancelReason;

  bool get isCancelled => status == SlotStatus.cancelled;

  bool get isAvailable => status == SlotStatus.scheduled && freeSeats > 0;
}
