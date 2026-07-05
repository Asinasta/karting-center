import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/theme/apex_tokens.dart';
import '../../../core/ui/load_state.dart';
import '../domain/booking_models.dart';
import '../domain/booking_policies.dart';

/// BS-003 — Подтверждение отмены (FL-11, LOGIC-004).
///
/// Returns the updated [Booking] from `cancelBooking`, or an [AppFailure]
/// wrapped result so the caller can refresh on `already_cancelled`.
sealed class CancelResult {
  const CancelResult();
}

class CancelSuccess extends CancelResult {
  const CancelSuccess(this.booking);

  final Booking booking;
}

class CancelFailed extends CancelResult {
  const CancelFailed(this.failure);

  final AppFailure failure;
}

Future<CancelResult?> showCancelConfirmSheet(
  BuildContext context,
  Booking booking,
) {
  return showModalBottomSheet<CancelResult>(
    context: context,
    showDragHandle: true,
    builder: (context) => _CancelConfirmSheet(booking: booking),
  );
}

class _CancelConfirmSheet extends StatefulWidget {
  const _CancelConfirmSheet({required this.booking});

  final Booking booking;

  @override
  State<_CancelConfirmSheet> createState() => _CancelConfirmSheetState();
}

class _CancelConfirmSheetState extends State<_CancelConfirmSheet> {
  ActionStatus _status = ActionStatus.idle;

  Future<void> _confirm() async {
    setState(() => _status = ActionStatus.submitting);
    try {
      final updated = await AppScope.of(context)
          .bookingRepository
          .cancelBooking(widget.booking.id);
      if (!mounted) return;
      Navigator.of(context).pop(CancelSuccess(updated));
    } on Object catch (error) {
      if (!mounted) return;
      Navigator.of(context).pop(CancelFailed(toAppFailure(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Local-time preview only; the server decides the final kind (LOGIC-004).
    final kind = CancellationPolicy.classify(
      startAt: widget.booking.slot.startAt,
      now: DateTime.now(),
    );
    final submitting = _status == ActionStatus.submitting;

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
            Text(
              'Отменить запись?',
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: ApexSpacing.sm),
            Text(
              'Отменяется вся бронь: ${widget.booking.seatsCount} мест(а).',
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: ApexSpacing.md),
            if (kind == CancellationKind.late)
              Container(
                padding: const EdgeInsets.all(ApexSpacing.md),
                decoration: BoxDecoration(
                  color: ApexColors.signalAmber.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(ApexRadius.sm),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_outlined),
                    SizedBox(width: ApexSpacing.sm),
                    Expanded(
                      child: Text(
                        'До старта меньше 2 часов — отмена будет поздней. '
                        'Места не вернутся в продажу.',
                      ),
                    ),
                  ],
                ),
              )
            else
              const Text('До старта больше 2 часов — отмена ранняя.'),
            const SizedBox(height: ApexSpacing.lg),
            FilledButton(
              onPressed: submitting ? null : _confirm,
              style: FilledButton.styleFrom(
                backgroundColor: ApexColors.trackRed,
              ),
              child: Text(submitting ? 'Отменяем…' : 'Отменить запись'),
            ),
            const SizedBox(height: ApexSpacing.sm),
            OutlinedButton(
              onPressed:
                  submitting ? null : () => Navigator.of(context).pop(),
              child: const Text('Оставить запись'),
            ),
          ],
        ),
      ),
    );
  }
}
