import '../../slots/domain/slot_models.dart';
import 'booking_models.dart';

/// AvailabilityPolicy (LOGIC-002).
class AvailabilityPolicy {
  const AvailabilityPolicy._();

  /// `maxSeats = min(slot.freeSeats, slot.trackConfig.capacityCap)`.
  static int maxSeats(Slot slot) {
    final cap = slot.trackConfig.capacityCap;
    return slot.freeSeats < cap ? slot.freeSeats : cap;
  }

  /// seat_gear length must be 1..maxSeats and rental count must fit
  /// free_rental_gear. Own gear takes a seat but no rental unit.
  static bool isSelectionValid(Slot slot, List<GearChoice> seatGear) {
    final seats = seatGear.length;
    if (seats < 1 || seats > maxSeats(slot)) {
      return false;
    }
    final rentalCount =
        seatGear.where((g) => g == GearChoice.rental).length;
    return rentalCount <= slot.freeRentalGear;
  }

  /// Builds API `seat_gear` from compact own/rental counters.
  static List<GearChoice> seatGearFromCounts({
    required int totalSeats,
    required int rentalCount,
  }) {
    final ownCount = totalSeats - rentalCount;
    return [
      ...List.filled(ownCount, GearChoice.own),
      ...List.filled(rentalCount, GearChoice.rental),
    ];
  }
}

/// BookingPricePreviewCalculator (LOGIC-003).
///
/// Preview only: `price_total` from the API is authoritative.
class BookingPricePreviewCalculator {
  const BookingPricePreviewCalculator._();

  static Money preview({
    required Money price,
    required Money rentalPrice,
    required List<GearChoice> seatGear,
  }) {
    final seats = seatGear.length;
    final rentalCount =
        seatGear.where((g) => g == GearChoice.rental).length;
    return Money(
      amount: price.amount * seats + rentalPrice.amount * rentalCount,
      currency: price.currency,
    );
  }
}

enum CancellationKind { early, late, unavailable }

/// CancellationPolicy (LOGIC-004).
///
/// Client preview only; the final status comes from `cancelBooking`.
class CancellationPolicy {
  const CancellationPolicy._();

  static const Duration threshold = Duration(hours: 2);

  static CancellationKind classify({
    required DateTime startAt,
    required DateTime now,
  }) {
    if (!now.isBefore(startAt)) {
      return CancellationKind.unavailable;
    }
    final untilStart = startAt.difference(now);
    // Exactly 2 hours before start still counts as early.
    return untilStart >= threshold
        ? CancellationKind.early
        : CancellationKind.late;
  }

  /// Cancel button is visible only for an active future booking.
  static bool canCancel(Booking booking, DateTime now) {
    return booking.status == BookingStatus.active &&
        now.isBefore(booking.slot.startAt);
  }
}

enum BookingGroup { upcoming, past, cancelled }

/// Client-side grouping for SCR-005: upcoming / past / cancelled.
BookingGroup groupBooking(Booking booking, DateTime now) {
  if (booking.status.isCancelledKind) {
    return BookingGroup.cancelled;
  }
  if (booking.status == BookingStatus.completed ||
      !now.isBefore(booking.slot.startAt)) {
    return BookingGroup.past;
  }
  return BookingGroup.upcoming;
}

/// RatingPolicy (LOGIC-006).
class RatingPolicy {
  const RatingPolicy._();

  static bool canRate(Booking booking, DateTime now) {
    if (booking.marshalRating != null) {
      return false;
    }
    if (booking.status.isCancelledKind) {
      return false;
    }
    if (booking.status != BookingStatus.active &&
        booking.status != BookingStatus.completed) {
      return false;
    }
    return !now.isBefore(booking.slot.startAt);
  }
}
