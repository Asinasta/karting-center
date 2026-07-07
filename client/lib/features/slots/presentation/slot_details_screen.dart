import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/theme/apex_tokens.dart';
import '../../../core/assets/apex_assets.dart';
import '../../../core/ui/formats.dart';
import '../../../core/ui/load_state.dart';
import '../../../core/ui/screen_states.dart';
import '../../map/presentation/track_map_sheet.dart';
import '../domain/slot_models.dart';
import 'slot_card.dart';

/// SCR-003 — Карточка заезда (FL-06). Public, no token.
class SlotDetailsScreen extends StatefulWidget {
  const SlotDetailsScreen({
    required this.slotId,
    super.key,
  });

  final String slotId;

  @override
  State<SlotDetailsScreen> createState() => _SlotDetailsScreenState();
}

class _SlotDetailsScreenState extends State<SlotDetailsScreen> {
  LoadState<Slot> _state = const Loading();

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
      final slot = await AppScope.of(context).slotRepository.getSlot(widget.slotId);
      if (!mounted) return;
      setState(() => _state = Content(slot));
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _state = Failure(toAppFailure(error)));
    }
  }

  void _openMap(Slot slot) {
    showTrackMapSheet(
      context,
      meetingPoint: slot.meetingPoint,
      meetingPointLat: slot.meetingPointLat,
      meetingPointLng: slot.meetingPointLng,
      geometry: slot.trackConfig.geometry,
      trackType: slot.trackConfig.type,
    );
  }

  void _book(Slot slot) {
    context.go('/slots/${slot.id}/book');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Заезд')),
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
              SlotStatusLabel(slot: slot),
            ],
          ),
          const SizedBox(height: ApexSpacing.sm),
          Text(
            formatDateTimeWithWeekday(slot.startAt),
            style: textTheme.titleMedium,
          ),
          if (slot.isCancelled && slot.cancelReason != null) ...[
            const SizedBox(height: ApexSpacing.md),
            _CancelReasonBanner(reason: slot.cancelReason!),
          ],
          const SizedBox(height: ApexSpacing.lg),
          _InfoRow(
            icon: Icons.flag_outlined,
            title: 'Конфигурация',
            value:
                '${slot.trackConfig.type.label}${slot.trackConfig.durationMin != null ? ', ${slot.trackConfig.durationMin} мин' : ''}',
          ),
          if (slot.trackConfig.description != null)
            _InfoRow(
              icon: Icons.notes_outlined,
              title: 'Описание',
              value: slot.trackConfig.description!,
            ),
          _InfoRow(
            icon: Icons.person_outline,
            title: 'Маршал',
            value: slot.marshal.name,
          ),
          _InfoRow(
            icon: Icons.event_seat_outlined,
            title: 'Свободные места',
            value: '${slot.freeSeats} из ${slot.totalSeats}',
          ),
          _InfoRow(
            icon: Icons.checkroom_outlined,
            title: 'Прокатная экипировка',
            value: '${slot.freeRentalGear} компл. — ${slot.rentalPrice.formatted} за комплект',
          ),
          _InfoRow(
            icon: Icons.payments_outlined,
            title: 'Цена за место',
            value: slot.price.formatted,
          ),
          _InfoRow(
            icon: Icons.location_on_outlined,
            title: 'Точка сбора',
            value: slot.meetingPoint,
          ),
          const SizedBox(height: ApexSpacing.md),
          _MapPreview(
            trackType: slot.trackConfig.type,
            onTap: () => _openMap(slot),
          ),
          const SizedBox(height: ApexSpacing.lg),
          FilledButton(
            onPressed: slot.isAvailable ? () => _book(slot) : null,
            child: Text(
              slot.isCancelled
                  ? 'Заезд отменён'
                  : slot.freeSeats == 0
                      ? 'Мест нет'
                      : 'Записаться',
            ),
          ),
          const SizedBox(height: ApexSpacing.lg),
        ],
      ),
    );
  }
}

class _CancelReasonBanner extends StatelessWidget {
  const _CancelReasonBanner({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ApexSpacing.md),
      decoration: BoxDecoration(
        color: ApexColors.trackRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(ApexRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: ApexColors.trackRed),
          const SizedBox(width: ApexSpacing.sm),
          Expanded(child: Text('Причина отмены: $reason')),
        ],
      ),
    );
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

class _MapPreview extends StatelessWidget {
  const _MapPreview({
    required this.trackType,
    required this.onTap,
  });

  final TrackConfigType trackType;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final assetPath = ApexAssets.trackMap(trackType);

    return Material(
      color: ApexAssets.trackMapBackdrop(trackType),
      borderRadius: BorderRadius.circular(ApexRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 160,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                assetPath,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.28),
                ),
                child: const SizedBox.expand(),
              ),
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 32, color: Colors.white),
                  SizedBox(height: ApexSpacing.sm),
                  Text(
                    'Открыть карту трассы',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
