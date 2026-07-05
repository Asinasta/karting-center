import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/theme/apex_tokens.dart';
import '../../../core/ui/formats.dart';
import '../../../core/ui/load_state.dart';
import '../../../core/ui/screen_states.dart';
import '../../../core/ui/snackbars.dart';
import '../../slots/domain/slot_models.dart';
import '../domain/booking_models.dart';
import '../domain/booking_policies.dart';
import 'booking_success_sheet.dart';

/// SCR-004 — Оформление записи (FL-07).
///
/// Protected route: the router auth gate guarantees an authenticated session.
class BookingFormScreen extends StatefulWidget {
  const BookingFormScreen({
    required this.slotId,
    super.key,
  });

  final String slotId;

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  LoadState<Slot> _state = const Loading();
  ActionStatus _action = ActionStatus.idle;

  /// Gear choice per selected seat (length = seats count).
  List<GearChoice> _seatGear = [GearChoice.own];

  /// Same key is reused while the payload is unchanged, so an ambiguous
  /// network failure can be retried without double booking (SCR-004 rule).
  String? _idempotencyKey;

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
      // Fresh slot data right before booking (FL-06 rule).
      final slot = await AppScope.of(context).slotRepository.getSlot(widget.slotId);
      if (!mounted) return;
      setState(() {
        _state = Content(slot);
        _clampSelection(slot);
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _state = Failure(toAppFailure(error)));
    }
  }

  void _clampSelection(Slot slot) {
    final maxSeats = AvailabilityPolicy.maxSeats(slot);
    if (maxSeats <= 0) {
      _seatGear = [];
      return;
    }
    if (_seatGear.isEmpty) {
      _seatGear = [GearChoice.own];
    }
    if (_seatGear.length > maxSeats) {
      _seatGear = _seatGear.sublist(0, maxSeats);
    }
    // Rental units above the free amount fall back to own gear.
    var rentalBudget = slot.freeRentalGear;
    _seatGear = _seatGear.map((gear) {
      if (gear == GearChoice.rental) {
        if (rentalBudget > 0) {
          rentalBudget--;
          return GearChoice.rental;
        }
        return GearChoice.own;
      }
      return gear;
    }).toList();
  }

  void _resetIdempotencyKey() => _idempotencyKey = null;

  String _ensureIdempotencyKey() {
    return _idempotencyKey ??= _generateKey();
  }

  static String _generateKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  void _setSeats(Slot slot, int seats) {
    setState(() {
      if (seats < _seatGear.length) {
        _seatGear = _seatGear.sublist(0, seats);
      } else {
        _seatGear = [
          ..._seatGear,
          ...List.filled(seats - _seatGear.length, GearChoice.own),
        ];
      }
      _clampSelection(slot);
      _resetIdempotencyKey();
    });
  }

  void _setGear(Slot slot, int seatIndex, GearChoice gear) {
    setState(() {
      _seatGear = [..._seatGear]..[seatIndex] = gear;
      _resetIdempotencyKey();
    });
  }

  int get _rentalCount => _seatGear.where((g) => g == GearChoice.rental).length;

  Future<void> _submit(Slot slot) async {
    if (!AvailabilityPolicy.isSelectionValid(slot, _seatGear)) {
      showAppSnack(context, 'Выбор мест недоступен, обновите данные заезда');
      return;
    }

    setState(() => _action = ActionStatus.submitting);
    final deps = AppScope.of(context);
    try {
      final booking = await deps.bookingRepository.createBooking(
        slotId: slot.id,
        seatGear: _seatGear,
        idempotencyKey: _ensureIdempotencyKey(),
      );
      if (!mounted) return;
      setState(() => _action = ActionStatus.idle);
      _resetIdempotencyKey();
      // Push permission is asked after the first successful booking and
      // must not block the flow (LOGIC-007).
      deps.pushService.requestPermissionAfterFirstBooking();
      await showBookingSuccessSheet(context, booking);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _action = ActionStatus.idle);
      final failure = toAppFailure(error);
      await _handleSubmitFailure(failure);
    }
  }

  Future<void> _handleSubmitFailure(AppFailure failure) async {
    switch (failure.code) {
      case ApiErrorCode.slotFull:
        // Server availability wins: refresh the slot and clamp selection.
        showFailureSnack(context, failure);
        _resetIdempotencyKey();
        await _load();
      case ApiErrorCode.doubleBooking:
        _resetIdempotencyKey();
        final bookingId = failure.existingBookingId;
        final go = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Вы уже записаны'),
            content: const Text('У вас уже есть активная запись на этот заезд.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Закрыть'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Открыть запись'),
              ),
            ],
          ),
        );
        if (go == true && mounted) {
          context.go(bookingId != null ? '/bookings/$bookingId' : '/bookings');
        }
      case ApiErrorCode.slotCancelled || ApiErrorCode.slotStarted:
        showFailureSnack(context, failure);
        _resetIdempotencyKey();
        await _load();
      case ApiErrorCode.unauthorized:
        showFailureSnack(context, failure);
      default:
        // Ambiguous/server error: keep the idempotency key for a safe retry.
        showFailureSnack(context, failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Оформление записи')),
      body: switch (_state) {
        Loading<Slot>() => const LoadingStateView(),
        Failure<Slot>(error: final error) => ErrorStateView(
            message: error.uiMessage,
            onRetry: _load,
          ),
        Content<Slot>(data: final slot) => _content(slot),
        Empty<Slot>() || OfflineStale<Slot>() => const LoadingStateView(),
      },
    );
  }

  Widget _content(Slot slot) {
    final textTheme = Theme.of(context).textTheme;
    final maxSeats = AvailabilityPolicy.maxSeats(slot);
    final bookable = slot.isAvailable && maxSeats > 0;
    final submitting = _action == ActionStatus.submitting;

    final preview = BookingPricePreviewCalculator.preview(
      price: slot.price,
      rentalPrice: slot.rentalPrice,
      seatGear: _seatGear,
    );

    return ListView(
      padding: const EdgeInsets.all(ApexSpacing.md),
      children: [
        // Slot summary.
        Card(
          child: Padding(
            padding: const EdgeInsets.all(ApexSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.trackConfig.name,
                  style:
                      textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: ApexSpacing.xs),
                Text(formatDateTimeWithWeekday(slot.startAt)),
                const SizedBox(height: ApexSpacing.xs),
                Text(
                  '${slot.trackConfig.type.label} · маршал ${slot.marshal.name}',
                ),
                const SizedBox(height: ApexSpacing.xs),
                Text(
                  'Свободно мест: ${slot.freeSeats}, прокат: ${slot.freeRentalGear}',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: ApexSpacing.lg),
        if (!bookable) ...[
          Text(
            slot.isCancelled
                ? 'Заезд отменён центром, запись недоступна.'
                : 'Свободных мест не осталось.',
            style: const TextStyle(color: ApexColors.trackRed),
          ),
          const SizedBox(height: ApexSpacing.md),
          OutlinedButton(
            onPressed: () => context.go('/slots'),
            child: const Text('К списку заездов'),
          ),
        ] else ...[
          Text(
            'Количество мест',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: ApexSpacing.sm),
          SegmentedButton<int>(
            segments: [
              for (var seats = 1; seats <= maxSeats; seats++)
                ButtonSegment(value: seats, label: Text('$seats')),
            ],
            selected: {_seatGear.length},
            onSelectionChanged: submitting
                ? null
                : (selection) => _setSeats(slot, selection.first),
          ),
          const SizedBox(height: ApexSpacing.xs),
          Text(
            'Максимум $maxSeats на одну бронь',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: ApexSpacing.lg),
          Text(
            'Экипировка',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: ApexSpacing.sm),
          for (var i = 0; i < _seatGear.length; i++) ...[
            _SeatGearSelector(
              seatIndex: i,
              value: _seatGear[i],
              rentalPrice: slot.rentalPrice,
              // A rental option is enabled while free gear remains for it.
              rentalEnabled: _seatGear[i] == GearChoice.rental ||
                  _rentalCount < slot.freeRentalGear,
              enabled: !submitting,
              onChanged: (gear) => _setGear(slot, i, gear),
            ),
            const SizedBox(height: ApexSpacing.sm),
          ],
          if (slot.freeRentalGear == 0)
            Text(
              'Прокатной экипировки на этот заезд не осталось.',
              style: textTheme.bodySmall?.copyWith(color: ApexColors.muted),
            ),
          const SizedBox(height: ApexSpacing.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(ApexSpacing.md),
              child: Column(
                children: [
                  _PriceLine(
                    label: 'Места · ${_seatGear.length} × ${slot.price.formatted}',
                    value: Money(
                      amount: slot.price.amount * _seatGear.length,
                      currency: slot.price.currency,
                    ).formatted,
                  ),
                  if (_rentalCount > 0)
                    _PriceLine(
                      label:
                          'Прокат · $_rentalCount × ${slot.rentalPrice.formatted}',
                      value: Money(
                        amount: slot.rentalPrice.amount * _rentalCount,
                        currency: slot.rentalPrice.currency,
                      ).formatted,
                    ),
                  const Divider(),
                  _PriceLine(
                    label: 'Предварительно итого',
                    value: preview.formatted,
                    bold: true,
                  ),
                  const SizedBox(height: ApexSpacing.xs),
                  Text(
                    'Финальная сумма подтверждается после оформления.',
                    style: textTheme.bodySmall?.copyWith(color: ApexColors.muted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: ApexSpacing.lg),
          FilledButton(
            onPressed: submitting ? null : () => _submit(slot),
            child: Text(submitting ? 'Оформляем…' : 'Подтвердить запись'),
          ),
        ],
        const SizedBox(height: ApexSpacing.lg),
      ],
    );
  }
}

class _SeatGearSelector extends StatelessWidget {
  const _SeatGearSelector({
    required this.seatIndex,
    required this.value,
    required this.rentalPrice,
    required this.rentalEnabled,
    required this.enabled,
    required this.onChanged,
  });

  final int seatIndex;
  final GearChoice value;
  final Money rentalPrice;
  final bool rentalEnabled;
  final bool enabled;
  final ValueChanged<GearChoice> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(ApexSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Место ${seatIndex + 1}',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: ApexSpacing.sm),
            SegmentedButton<GearChoice>(
              segments: [
                const ButtonSegment(
                  value: GearChoice.own,
                  label: Text('Своя'),
                  icon: Icon(Icons.backpack_outlined),
                ),
                ButtonSegment(
                  value: GearChoice.rental,
                  label: Text('Прокат (+${rentalPrice.formatted})'),
                  icon: const Icon(Icons.checkroom_outlined),
                  enabled: rentalEnabled,
                ),
              ],
              selected: {value},
              onSelectionChanged:
                  enabled ? (selection) => onChanged(selection.first) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 15,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ApexSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
