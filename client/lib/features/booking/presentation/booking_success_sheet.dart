import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/apex_tokens.dart';
import '../../../core/ui/formats.dart';
import '../domain/booking_models.dart';

/// BS-002 — Успех записи (FL-08). Shows API `Booking` values only.
Future<void> showBookingSuccessSheet(BuildContext context, Booking booking) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    builder: (context) => BookingSuccessSheet(booking: booking),
  );
}

class BookingSuccessSheet extends StatelessWidget {
  const BookingSuccessSheet({
    required this.booking,
    super.key,
  });

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final slot = booking.slot;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          ApexSpacing.lg,
          0,
          ApexSpacing.lg,
          ApexSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 56,
              color: ApexColors.grassGreen,
            ),
            const SizedBox(height: ApexSpacing.md),
            Text(
              'Вы записаны!',
              textAlign: TextAlign.center,
              style:
                  textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: ApexSpacing.lg),
            _SummaryRow(
              icon: Icons.flag_outlined,
              text: slot.trackConfig.name,
            ),
            _SummaryRow(
              icon: Icons.schedule_outlined,
              text: formatDateTimeWithWeekday(slot.startAt),
            ),
            _SummaryRow(
              icon: Icons.event_seat_outlined,
              text:
                  'Мест: ${booking.seatsCount}, прокатной экипировки: ${booking.rentalCount}',
            ),
            _SummaryRow(
              icon: Icons.location_on_outlined,
              text: 'Точка сбора: ${slot.meetingPoint}',
            ),
            _SummaryRow(
              icon: Icons.payments_outlined,
              text: 'Итого: ${booking.priceTotal.formatted}',
              bold: true,
            ),
            const SizedBox(height: ApexSpacing.lg),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/bookings');
              },
              child: const Text('Мои записи'),
            ),
            const SizedBox(height: ApexSpacing.sm),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/slots');
              },
              child: const Text('К заездам'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.text,
    this.bold = false,
  });

  final IconData icon;
  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ApexSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: ApexColors.muted),
          const SizedBox(width: ApexSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
