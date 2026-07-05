import 'dart:convert';

import 'package:apex_client/core/error/app_failure.dart';
import 'package:apex_client/core/network/api_client.dart';
import 'package:apex_client/features/booking/data/booking_repository.dart';
import 'package:apex_client/features/booking/domain/booking_models.dart';
import 'package:apex_client/features/slots/data/slot_repository.dart';
import 'package:apex_client/features/slots/domain/slot_filter.dart';
import 'package:apex_client/features/slots/domain/slot_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _jsonResponse(Object body, int status) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

Map<String, Object?> _slotJson(String id, String startAt) {
  return {
    'id': id,
    'track_config': {
      'id': 'track-1',
      'name': 'Новичковая',
      'type': 'novice',
      'capacity_cap': 8,
    },
    'marshal': {'id': 'marshal-1', 'name': 'Иван'},
    'start_at': startAt,
    'total_seats': 8,
    'free_seats': 5,
    'free_rental_gear': 3,
    'price': {'amount': 150000, 'currency': 'RUB'},
    'rental_price': {'amount': 50000, 'currency': 'RUB'},
    'meeting_point': 'Главный вход',
    'status': 'scheduled',
  };
}

Map<String, Object?> _bookingJson(String id) {
  return {
    'id': id,
    'slot': _slotJson('slot-1', '2026-07-10T12:00:00Z')
      ..remove('total_seats')
      ..remove('free_seats')
      ..remove('free_rental_gear'),
    'seats_count': 2,
    'rental_count': 1,
    'seat_gear': ['rental', 'own'],
    'price_total': {'amount': 350000, 'currency': 'RUB'},
    'status': 'active',
    'created_at': '2026-07-04T10:00:00Z',
  };
}

class _StaticTokenProvider implements AuthTokenProvider {
  _StaticTokenProvider(this.token);

  final String token;
  int refreshCalls = 0;

  @override
  Future<String?> currentAccessToken() async => token;

  @override
  Future<String?> refreshAccessToken() async {
    refreshCalls++;
    return 'refreshed-token';
  }
}

ApiClient _client(MockClient mock, {AuthTokenProvider? tokens}) {
  final client = ApiClient(
    baseUri: Uri.parse('http://localhost:8080'),
    client: mock,
  );
  client.tokenProvider = tokens;
  return client;
}

void main() {
  group('SlotRepository', () {
    test('listSlots builds filter query and sorts by start_at', () async {
      late Uri captured;
      final mock = MockClient((request) async {
        captured = request.url;
        expect(request.headers.containsKey('Authorization'), isFalse);
        return _jsonResponse(
          [
            _slotJson('slot-late', '2026-07-11T12:00:00Z'),
            _slotJson('slot-early', '2026-07-10T12:00:00Z'),
          ],
          200,
        );
      });

      final repository = ApiSlotRepository(_client(mock));
      final filter = SlotFilter(
        trackConfigTypes: const {TrackConfigType.novice},
        marshalIds: const {'marshal-1'},
        onlyAvailable: true,
      );
      final slots = await repository.listSlots(filter: filter);

      expect(captured.path, '/slots');
      expect(captured.queryParameters['only_available'], 'true');
      expect(captured.queryParametersAll['track_config_type'], ['novice']);
      expect(captured.queryParametersAll['marshal_id'], ['marshal-1']);
      expect(slots.map((s) => s.id).toList(), ['slot-early', 'slot-late']);
    });

    test('default filter sends no date params (7 days is server default)',
        () async {
      late Uri captured;
      final mock = MockClient((request) async {
        captured = request.url;
        return _jsonResponse(<Object>[], 200);
      });

      await ApiSlotRepository(_client(mock)).listSlots();

      expect(captured.queryParameters.containsKey('date_from'), isFalse);
      expect(captured.queryParameters.containsKey('date_to'), isFalse);
    });

    test('API error body maps to AppFailure with code', () async {
      final mock = MockClient((request) async {
        return _jsonResponse(
          {'code': 'not_found', 'message': 'Slot not found'},
          404,
        );
      });

      expect(
        () => ApiSlotRepository(_client(mock)).getSlot('missing'),
        throwsA(
          isA<AppFailureException>().having(
            (e) => e.failure.code,
            'code',
            ApiErrorCode.notFound,
          ),
        ),
      );
    });
  });

  group('BookingRepository', () {
    test('createBooking sends Idempotency-Key, bearer token and seat_gear',
        () async {
      late http.Request captured;
      final mock = MockClient((request) async {
        captured = request;
        return _jsonResponse(_bookingJson('booking-1'), 201);
      });

      final tokens = _StaticTokenProvider('access-token');
      final repository = ApiBookingRepository(_client(mock, tokens: tokens));
      final booking = await repository.createBooking(
        slotId: 'slot-1',
        seatGear: const [GearChoice.rental, GearChoice.own],
        idempotencyKey: 'test-key-12345678',
      );

      expect(captured.headers['Idempotency-Key'], 'test-key-12345678');
      expect(captured.headers['Authorization'], 'Bearer access-token');
      final body = jsonDecode(captured.body) as Map<String, Object?>;
      expect(body['slot_id'], 'slot-1');
      expect(body['seat_gear'], ['rental', 'own']);
      expect(booking.priceTotal.amount, 350000);
      expect(booking.status, BookingStatus.active);
    });

    test('401 triggers one refresh and one retry', () async {
      var calls = 0;
      final mock = MockClient((request) async {
        calls++;
        if (request.headers['Authorization'] == 'Bearer refreshed-token') {
          return _jsonResponse(
            {
              'items': [_bookingJson('booking-1')],
              'pagination': {'limit': 20, 'offset': 0, 'total': 1},
            },
            200,
          );
        }
        return _jsonResponse(
          {'code': 'unauthorized', 'message': 'expired'},
          401,
        );
      });

      final tokens = _StaticTokenProvider('stale-token');
      final repository = ApiBookingRepository(_client(mock, tokens: tokens));
      final page = await repository.listBookings();

      expect(calls, 2);
      expect(tokens.refreshCalls, 1);
      expect(page.items, hasLength(1));
      expect(page.pagination?.total, 1);
    });

    test('double_booking failure exposes existing booking id', () async {
      final mock = MockClient((request) async {
        return _jsonResponse(
          {
            'code': 'double_booking',
            'message': 'already booked',
            'details': {'booking_id': 'booking-42'},
          },
          409,
        );
      });

      final tokens = _StaticTokenProvider('access-token');
      final repository = ApiBookingRepository(_client(mock, tokens: tokens));

      try {
        await repository.createBooking(
          slotId: 'slot-1',
          seatGear: const [GearChoice.own],
          idempotencyKey: 'test-key-12345678',
        );
        fail('expected AppFailureException');
      } on AppFailureException catch (e) {
        expect(e.failure.code, ApiErrorCode.doubleBooking);
        expect(e.failure.existingBookingId, 'booking-42');
      }
    });
  });
}
