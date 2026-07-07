import 'package:flutter/material.dart';

import '../../../core/theme/apex_tokens.dart';
import '../../../core/ui/formats.dart';
import '../domain/slot_models.dart';

String _marshalChipLabel(Slot slot) {
  final rating = slot.marshal.ratingLabel;
  if (rating == null) {
    return slot.marshal.name;
  }
  return '${slot.marshal.name} · $rating';
}

class SlotCard extends StatelessWidget {
  const SlotCard({
    required this.slot,
    this.onTap,
    this.onBook,
    super.key,
  });

  final Slot slot;
  final VoidCallback? onTap;

  /// Null disables the CTA (full or cancelled slot).
  final VoidCallback? onBook;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ApexRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(ApexSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      slot.trackConfig.name,
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  SlotStatusLabel(slot: slot),
                ],
              ),
              const SizedBox(height: ApexSpacing.sm),
              Text(
                formatDateTimeWithWeekday(slot.startAt),
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: ApexSpacing.sm),
              Wrap(
                spacing: ApexSpacing.sm,
                runSpacing: ApexSpacing.xs,
                children: [
                  ChipText(
                    icon: Icons.flag_outlined,
                    label: slot.trackConfig.type.label,
                  ),
                  ChipText(icon: Icons.person_outline, label: _marshalChipLabel(slot)),
                  ChipText(
                    icon: Icons.event_seat_outlined,
                    label: 'Мест: ${slot.freeSeats}',
                  ),
                  ChipText(
                    icon: Icons.checkroom_outlined,
                    label: 'Прокат: ${slot.freeRentalGear}',
                  ),
                ],
              ),
              const SizedBox(height: ApexSpacing.md),
              Wrap(
                spacing: ApexSpacing.md,
                runSpacing: ApexSpacing.sm,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'от ${slot.price.formatted}',
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  FilledButton(
                    onPressed: onBook,
                    child: const Text('Записаться'),
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

class SlotStatusLabel extends StatelessWidget {
  const SlotStatusLabel({
    required this.slot,
    super.key,
  });

  final Slot slot;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (slot.status) {
      SlotStatus.cancelled => ('Отменён', ApexColors.trackRed),
      SlotStatus.scheduled when slot.freeSeats == 0 => (
          'Нет мест',
          ApexColors.muted,
        ),
      SlotStatus.scheduled => ('Доступен', ApexColors.grassGreen),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(ApexRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ApexSpacing.sm,
          vertical: ApexSpacing.xs,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class ChipText extends StatelessWidget {
  const ChipText({
    required this.icon,
    required this.label,
    super.key,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ApexSpacing.sm,
        vertical: ApexSpacing.xs,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: ApexColors.outline),
        borderRadius: BorderRadius.circular(ApexRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: ApexSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
