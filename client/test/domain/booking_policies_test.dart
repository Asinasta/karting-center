import 'package:apex_client/features/booking/domain/booking_models.dart';
import 'package:apex_client/features/booking/domain/booking_policies.dart';
import 'package:apex_client/features/slots/domain/slot_models.dart';
import 'package:flutter_test/flutter_test.dart';

Slot _slot({
  int freeSeats = 6,
  int capacityCap = 8,
  int freeRentalGear = 4,
  int priceAmount = 150000,
  int rentalAmount = 50000,
  SlotStatus status = SlotStatus.scheduled,
}) {
  return Slot(
    id: 'slot-1',
    trackConfig: TrackConfig(
      id: 'track-1',
      name: 'Test track',
      type: TrackConfigType.novice,
      capacityCap: capacityCap,
    ),
    marshal: const Marshal(id: 'marshal-1', name: 'Иван'),
    startAt: DateTime.utc(2026, 7, 10, 12),
    totalSeats: 8,
    freeSeats: freeSeats,
    freeRentalGear: freeRentalGear,
    price: Money(amount: priceAmount, currency: 'RUB'),
    rentalPrice: Money(amount: rentalAmount, currency: 'RUB'),
    meetingPoint: 'Главный вход',
    status: status,
  );
}

Booking _booking({
  required BookingStatus status,
  required DateTime startAt,
}) {
  return Booking(
    id: 'booking-1',
    slot: BookingSlotSnapshot(
      id: 'slot-1',
      trackConfig: const TrackConfig(
        id: 'track-1',
        name: 'Test track',
        type: TrackConfigType.novice,
        capacityCap: 8,
      ),
      marshal: const Marshal(id: 'marshal-1', name: 'Иван'),
      startAt: startAt,
      price: const Money(amount: 150000, currency: 'RUB'),
      rentalPrice: const Money(amount: 50000, currency: 'RUB'),
      meetingPoint: 'Главный вход',
      status: SlotStatus.scheduled,
    ),
    seatsCount: 1,
    rentalCount: 0,
    seatGear: const [GearChoice.own],
    priceTotal: const Money(amount: 150000, currency: 'RUB'),
    status: status,
    createdAt: DateTime.utc(2026),
  );
}

void main() {
  group('AvailabilityPolicy', () {
    test('maxSeats = min(freeSeats, capacityCap)', () {
      expect(AvailabilityPolicy.maxSeats(_slot(freeSeats: 6, capacityCap: 8)), 6);
      expect(AvailabilityPolicy.maxSeats(_slot(freeSeats: 2, capacityCap: 8)), 2);
      expect(AvailabilityPolicy.maxSeats(_slot(freeSeats: 6, capacityCap: 1)), 1);
      expect(AvailabilityPolicy.maxSeats(_slot(freeSeats: 0)), 0);
    });

    test('seatGearFromCounts builds own then rental entries', () {
      expect(
        AvailabilityPolicy.seatGearFromCounts(totalSeats: 4, rentalCount: 2),
        const [
          GearChoice.own,
          GearChoice.own,
          GearChoice.rental,
          GearChoice.rental,
        ],
      );
    });

    test('selection must be 1..maxSeats seats', () {
      final slot = _slot(freeSeats: 2);
      expect(AvailabilityPolicy.isSelectionValid(slot, const []), isFalse);
      expect(
        AvailabilityPolicy.isSelectionValid(slot, const [GearChoice.own]),
        isTrue,
      );
      expect(
        AvailabilityPolicy.isSelectionValid(
          slot,
          const [GearChoice.own, GearChoice.own, GearChoice.own],
        ),
        isFalse,
      );
    });

    test('rental count is limited by freeRentalGear; own gear is not', () {
      final slot = _slot(freeRentalGear: 1);
      expect(
        AvailabilityPolicy.isSelectionValid(
          slot,
          const [GearChoice.rental, GearChoice.rental],
        ),
        isFalse,
      );
      expect(
        AvailabilityPolicy.isSelectionValid(
          slot,
          const [GearChoice.rental, GearChoice.own, GearChoice.own],
        ),
        isTrue,
      );
    });
  });

  group('BookingPricePreviewCalculator', () {
    test('preview = price * seats + rentalPrice * rentalCount', () {
      final preview = BookingPricePreviewCalculator.preview(
        price: const Money(amount: 150000, currency: 'RUB'),
        rentalPrice: const Money(amount: 50000, currency: 'RUB'),
        seatGear: const [GearChoice.rental, GearChoice.own, GearChoice.rental],
      );
      expect(preview.amount, 150000 * 3 + 50000 * 2);
      expect(preview.currency, 'RUB');
    });
  });

  group('CancellationPolicy', () {
    final startAt = DateTime.utc(2026, 7, 10, 12);

    test('exactly 2 hours before start is early', () {
      expect(
        CancellationPolicy.classify(
          startAt: startAt,
          now: startAt.subtract(const Duration(hours: 2)),
        ),
        CancellationKind.early,
      );
    });

    test('less than 2 hours before start is late', () {
      expect(
        CancellationPolicy.classify(
          startAt: startAt,
          now: startAt.subtract(const Duration(hours: 1, minutes: 59)),
        ),
        CancellationKind.late,
      );
    });

    test('at or after start cancellation is unavailable', () {
      expect(
        CancellationPolicy.classify(startAt: startAt, now: startAt),
        CancellationKind.unavailable,
      );
      expect(
        CancellationPolicy.classify(
          startAt: startAt,
          now: startAt.add(const Duration(minutes: 1)),
        ),
        CancellationKind.unavailable,
      );
    });

    test('cancel button only for active future booking', () {
      final now = DateTime.utc(2026, 7, 10, 9);
      expect(
        CancellationPolicy.canCancel(
          _booking(status: BookingStatus.active, startAt: startAt),
          now,
        ),
        isTrue,
      );
      expect(
        CancellationPolicy.canCancel(
          _booking(status: BookingStatus.cancelled, startAt: startAt),
          now,
        ),
        isFalse,
      );
      expect(
        CancellationPolicy.canCancel(
          _booking(status: BookingStatus.active, startAt: now),
          now,
        ),
        isFalse,
      );
    });
  });

  group('groupBooking', () {
    final now = DateTime.utc(2026, 7, 10, 12);

    test('cancelled statuses go to cancelled group', () {
      for (final status in [
        BookingStatus.cancelled,
        BookingStatus.lateCancel,
        BookingStatus.cancelledByCenter,
      ]) {
        expect(
          groupBooking(
            _booking(status: status, startAt: now.add(const Duration(days: 1))),
            now,
          ),
          BookingGroup.cancelled,
        );
      }
    });

    test('active future booking is upcoming', () {
      expect(
        groupBooking(
          _booking(
            status: BookingStatus.active,
            startAt: now.add(const Duration(hours: 1)),
          ),
          now,
        ),
        BookingGroup.upcoming,
      );
    });

    test('completed or started bookings are past', () {
      expect(
        groupBooking(
          _booking(
            status: BookingStatus.completed,
            startAt: now.subtract(const Duration(days: 1)),
          ),
          now,
        ),
        BookingGroup.past,
      );
      expect(
        groupBooking(
          _booking(status: BookingStatus.active, startAt: now),
          now,
        ),
        BookingGroup.past,
      );
    });
  });

  group('RatingPolicy', () {
    final startAt = DateTime.utc(2026, 7, 10, 12);
    final now = DateTime.utc(2026, 7, 10, 13);

    test('allows rating after start for completed booking without rating', () {
      expect(
        RatingPolicy.canRate(
          _booking(status: BookingStatus.completed, startAt: startAt),
          now,
        ),
        isTrue,
      );
    });

    test('blocks rating before start and when already rated', () {
      expect(
        RatingPolicy.canRate(
          _booking(status: BookingStatus.active, startAt: startAt.add(const Duration(hours: 1))),
          now,
        ),
        isFalse,
      );
      expect(
        RatingPolicy.canRate(
          Booking(
            id: 'booking-1',
            slot: BookingSlotSnapshot(
              id: 'slot-1',
              trackConfig: const TrackConfig(
                id: 'track-1',
                name: 'Test track',
                type: TrackConfigType.novice,
                capacityCap: 8,
              ),
              marshal: const Marshal(id: 'marshal-1', name: 'Иван'),
              startAt: startAt,
              price: const Money(amount: 150000, currency: 'RUB'),
              rentalPrice: const Money(amount: 50000, currency: 'RUB'),
              meetingPoint: 'Главный вход',
              status: SlotStatus.scheduled,
            ),
            seatsCount: 1,
            rentalCount: 0,
            seatGear: const [GearChoice.own],
            priceTotal: const Money(amount: 150000, currency: 'RUB'),
            status: BookingStatus.completed,
            createdAt: DateTime.utc(2026),
            marshalRating: MarshalRating(
              stars: 5,
              createdAt: DateTime.utc(2026, 7, 10, 14),
            ),
          ),
          now,
        ),
        isFalse,
      );
    });
  });
}
