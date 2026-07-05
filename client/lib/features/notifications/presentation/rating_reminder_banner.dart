import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/apex_tokens.dart';
import '../domain/notification_models.dart';

class RatingReminderBanner extends StatelessWidget {
  const RatingReminderBanner({
    required this.notification,
    required this.onDismiss,
    super.key,
  });

  final AppNotification notification;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ApexColors.trackRed.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(ApexSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notifications_active_outlined),
                const SizedBox(width: ApexSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: ApexSpacing.xs),
                      Text(notification.body),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: ApexSpacing.sm),
            FilledButton(
              onPressed: () {
                onDismiss();
                context.go('/bookings/${notification.bookingId}');
              },
              child: const Text('Оценить'),
            ),
          ],
        ),
      ),
    );
  }
}
