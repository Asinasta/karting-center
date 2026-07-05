import '../../../core/network/api_client.dart';
import '../domain/booking_models.dart';

abstract class BookingRepository {
  /// `createBooking`: POST /bookings with required `Idempotency-Key`.
  Future<Booking> createBooking({
    required String slotId,
    required List<GearChoice> seatGear,
    required String idempotencyKey,
  });

  /// `listBookings`: GET /bookings
  Future<BookingList> listBookings({int limit = 20, int offset = 0});

  /// `getBooking`: GET /bookings/{bookingId}
  Future<Booking> getBooking(String bookingId);

  /// `cancelBooking`: POST /bookings/{bookingId}/cancel
  Future<Booking> cancelBooking(String bookingId);

  /// `rateMarshal`: POST /bookings/{bookingId}/marshal-rating
  Future<Booking> rateMarshal({
    required String bookingId,
    required int stars,
    String? comment,
  });

  /// `updateMarshalRating`: PATCH /bookings/{bookingId}/marshal-rating
  Future<Booking> updateMarshalRating({
    required String bookingId,
    required int stars,
    String? comment,
  });
}

class ApiBookingRepository implements BookingRepository {
  const ApiBookingRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<Booking> createBooking({
    required String slotId,
    required List<GearChoice> seatGear,
    required String idempotencyKey,
  }) async {
    final payload = await _apiClient.post(
      '/bookings',
      body: {
        'slot_id': slotId,
        'seat_gear': seatGear.map((g) => g.apiValue).toList(),
      },
      headers: {'Idempotency-Key': idempotencyKey},
      authorized: true,
    );
    return Booking.fromJson(payload! as Map<String, Object?>);
  }

  @override
  Future<BookingList> listBookings({int limit = 20, int offset = 0}) async {
    final payload = await _apiClient.get(
      '/bookings',
      query: {'limit': '$limit', 'offset': '$offset'},
      authorized: true,
    );
    return BookingList.fromJson(payload! as Map<String, Object?>);
  }

  @override
  Future<Booking> getBooking(String bookingId) async {
    final payload =
        await _apiClient.get('/bookings/$bookingId', authorized: true);
    return Booking.fromJson(payload! as Map<String, Object?>);
  }

  @override
  Future<Booking> cancelBooking(String bookingId) async {
    final payload =
        await _apiClient.post('/bookings/$bookingId/cancel', authorized: true);
    return Booking.fromJson(payload! as Map<String, Object?>);
  }

  @override
  Future<Booking> rateMarshal({
    required String bookingId,
    required int stars,
    String? comment,
  }) async {
    final payload = await _apiClient.post(
      '/bookings/$bookingId/marshal-rating',
      body: {
        'stars': stars,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
      authorized: true,
    );
    return Booking.fromJson(payload! as Map<String, Object?>);
  }

  @override
  Future<Booking> updateMarshalRating({
    required String bookingId,
    required int stars,
    String? comment,
  }) async {
    final payload = await _apiClient.patch(
      '/bookings/$bookingId/marshal-rating',
      body: {
        'stars': stars,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
      authorized: true,
    );
    return Booking.fromJson(payload! as Map<String, Object?>);
  }
}
