import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/theme/apex_tokens.dart';
import '../../../core/ui/formats.dart';
import '../../../core/ui/load_state.dart';
import '../../../core/ui/screen_states.dart';
import '../../../core/ui/snackbars.dart';
import '../../map/presentation/track_map_sheet.dart';
import '../../slots/domain/slot_models.dart' show SlotStatus;
import '../domain/booking_models.dart';
import '../domain/booking_policies.dart';
import 'booking_list_screen.dart' show BookingStatusLabel;
import 'cancel_confirm_sheet.dart';
import 'marshal_rating_section.dart';

/// SCR-006 — Детали брони (FL-10). Shows the slot snapshot, not live slot.
class BookingDetailsScreen extends StatefulWidget {
  const BookingDetailsScreen({
    required this.bookingId,
    super.key,
  });

  final String bookingId;

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  LoadState<Booking> _state = const Loading();
  ActionStatus _ratingAction = ActionStatus.idle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  Future<void> _load() async {
    setState(() => _state = const Loading());
    try {
      final booking =
          await AppScope.of(context).bookingRepository.getBooking(widget.bookingId);
      if (!mounted) return;
      setState(() => _state = Content(booking));
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _state = Failure(toAppFailure(error)));
    }
  }

  Future<void> _cancel(Booking booking) async {
    final result = await showCancelConfirmSheet(context, booking);
    if (!mounted || result == null) {
      return;
    }
    switch (result) {
      case CancelSuccess(booking: final updated):
        // API response replaces local details (FL-11 rule).
        setState(() => _state = Content(updated));
        showAppSnack(
          context,
          updated.status == BookingStatus.lateCancel
              ? 'Запись отменена (поздняя отмена)'
              : 'Запись отменена',
        );
      case CancelFailed(failure: final failure):
        showFailureSnack(context, failure);
        if (failure.code == ApiErrorCode.alreadyCancelled ||
            failure.code == ApiErrorCode.slotStarted) {
          await _load();
        }
    }
  }

  Future<void> _submitRating(Booking booking, int stars, String? comment) async {
    setState(() => _ratingAction = ActionStatus.submitting);
    final repo = AppScope.of(context).bookingRepository;
    final isEdit = booking.marshalRating != null;
    try {
      final updated = isEdit
          ? await repo.updateMarshalRating(
              bookingId: booking.id,
              stars: stars,
              comment: comment,
            )
          : await repo.rateMarshal(
              bookingId: booking.id,
              stars: stars,
              comment: comment,
            );
      if (!mounted) return;
      setState(() {
        _state = Content(updated);
        _ratingAction = ActionStatus.idle;
      });
      showAppSnack(context, isEdit ? 'Оценка обновлена' : 'Спасибо за оценку');
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _ratingAction = ActionStatus.idle);
      showFailureSnack(context, toAppFailure(error));
    }
  }

  Future<void> _deleteRating(Booking booking) async {
    setState(() => _ratingAction = ActionStatus.submitting);
    try {
      final updated =
          await AppScope.of(context).bookingRepository.deleteMarshalRating(
                booking.id,
              );
      if (!mounted) return;
      setState(() {
        _state = Content(updated);
        _ratingAction = ActionStatus.idle;
      });
      showAppSnack(context, 'Оценка удалена');
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _ratingAction = ActionStatus.idle);
      showFailureSnack(context, toAppFailure(error));
    }
  }

  void _openMap(Booking booking) {
    final slot = booking.slot;
    showTrackMapSheet(
      context,
      meetingPoint: slot.meetingPoint,
      meetingPointLat: slot.meetingPointLat,
      meetingPointLng: slot.meetingPointLng,
      geometry: slot.geometry ?? slot.trackConfig.geometry,
      trackType: slot.trackConfig.type,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Детали брони')),
      body: switch (_state) {
        Loading<Booking>() => const LoadingStateView(),
        Failure<Booking>(error: final error) => ErrorStateView(
            // forbidden / not_found show a safe generic error state.
            message: error.code == ApiErrorCode.forbidden ||
                    error.code == ApiErrorCode.notFound
                ? 'Бронь не найдена или недоступна'
                : error.uiMessage,
            onRetry: _load,
          ),
        Content<Booking>(data: final booking) => _content(booking),
        Empty<Booking>() || OfflineStale<Booking>() => const LoadingStateView(),
      },
    );
  }

  Widget _content(Booking booking) {
    final textTheme = Theme.of(context).textTheme;
    final slot = booking.slot;
    final canCancel = CancellationPolicy.canCancel(booking, DateTime.now());
    final now = DateTime.now();
    final canRate = RatingPolicy.canRate(booking, now);
    final canEditRating = RatingPolicy.canEdit(booking, now);
    final centerCancelled = booking.status == BookingStatus.cancelledByCenter ||
        slot.status == SlotStatus.cancelled;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(ApexSpacing.md),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  slot.trackConfig.name,
                  style: textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              BookingStatusLabel(booking: booking),
            ],
          ),
          const SizedBox(height: ApexSpacing.sm),
          Text(
            formatDateTimeWithWeekday(slot.startAt),
            style: textTheme.titleMedium,
          ),
          if (centerCancelled) ...[
            const SizedBox(height: ApexSpacing.md),
            Container(
              padding: const EdgeInsets.all(ApexSpacing.md),
              decoration: BoxDecoration(
                color: ApexColors.trackRed.withOpacity(0.08),
                borderRadius: BorderRadius.circular(ApexRadius.sm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: ApexColors.trackRed),
                  const SizedBox(width: ApexSpacing.sm),
                  Expanded(
                    child: Text(
                      'Заезд отменён центром.'
                      '${_centerReason(booking) != null ? '\nПричина: ${_centerReason(booking)}' : ''}',
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: ApexSpacing.lg),
          _InfoRow(
            icon: Icons.flag_outlined,
            title: 'Конфигурация',
            value: slot.trackConfig.type.label,
          ),
          _InfoRow(
            icon: Icons.person_outline,
            title: 'Маршал',
            value: slot.marshal.name,
          ),
          if (slot.marshal.ratingLabel != null)
            _InfoRow(
              icon: Icons.star_outline,
              title: 'Рейтинг маршала',
              value: slot.marshal.ratingLabel!,
            ),
          _InfoRow(
            icon: Icons.event_seat_outlined,
            title: 'Места',
            value: '${booking.seatsCount}',
          ),
          _InfoRow(
            icon: Icons.checkroom_outlined,
            title: 'Экипировка',
            value: _gearSummary(booking),
          ),
          _InfoRow(
            icon: Icons.payments_outlined,
            title: 'Итого',
            value: booking.priceTotal.formatted,
          ),
          _InfoRow(
            icon: Icons.location_on_outlined,
            title: 'Точка сбора',
            value: slot.meetingPoint,
          ),
          if (booking.cancelledAt != null)
            _InfoRow(
              icon: Icons.event_busy_outlined,
              title: 'Отменена',
              value: formatDateTime(booking.cancelledAt!),
            ),
          const SizedBox(height: ApexSpacing.md),
          OutlinedButton.icon(
            onPressed: () => _openMap(booking),
            icon: const Icon(Icons.map_outlined),
            label: const Text('Карта трассы'),
          ),
          const SizedBox(height: ApexSpacing.lg),
          if (canRate || canEditRating || booking.marshalRating != null)
            MarshalRatingSection(
              marshalName: slot.marshal.name,
              rating: booking.marshalRating,
              canEdit: canEditRating,
              submitting: _ratingAction == ActionStatus.submitting,
              onSubmit: (stars, comment) => _submitRating(booking, stars, comment),
              onDelete: canEditRating ? () => _deleteRating(booking) : null,
            ),
          if (canRate || canEditRating || booking.marshalRating != null)
            const SizedBox(height: ApexSpacing.lg),
          if (canCancel)
            FilledButton(
              onPressed: () => _cancel(booking),
              style: FilledButton.styleFrom(
                backgroundColor: ApexColors.trackRed,
              ),
              child: const Text('Отменить запись'),
            ),
          const SizedBox(height: ApexSpacing.lg),
        ],
      ),
    );
  }

  String? _centerReason(Booking booking) {
    return booking.cancelReason ?? booking.slot.cancelReason;
  }

  String _gearSummary(Booking booking) {
    final own = booking.seatsCount - booking.rentalCount;
    final parts = <String>[
      if (own > 0) 'своя × $own',
      if (booking.rentalCount > 0) 'прокат × ${booking.rentalCount}',
    ];
    return parts.join(', ');
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ApexSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: ApexColors.muted),
          const SizedBox(width: ApexSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(value, style: textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
