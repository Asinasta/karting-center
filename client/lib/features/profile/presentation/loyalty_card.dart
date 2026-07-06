import 'package:flutter/material.dart';

import '../../../core/assets/apex_assets.dart';
import '../../../core/theme/apex_tokens.dart';
import '../domain/profile_models.dart';

class LoyaltyCard extends StatelessWidget {
  const LoyaltyCard({
    required this.profile,
    super.key,
  });

  /// Max share of viewport height for the loyalty card.
  static const maxHeightFraction = 0.28;

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final tier = profile.loyaltyTier!;
    final textTheme = Theme.of(context).textTheme;
    final cardHeight =
        MediaQuery.sizeOf(context).height * maxHeightFraction;

    return ClipRRect(
      borderRadius: BorderRadius.circular(ApexRadius.md),
      child: SizedBox(
        height: cardHeight,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              ApexAssets.loyaltyCard(tier),
              fit: BoxFit.cover,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withOpacity(0.72),
                    Colors.black.withOpacity(0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(ApexSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text(
                    tier.label,
                    style: textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: ApexSpacing.xs),
                  Text(
                    profile.name,
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: ApexSpacing.sm),
                  Text(
                    'Завершённых заездов: ${profile.completedRidesCount}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  if (profile.loyaltyDiscountPercent != null)
                    Text(
                      'Скидка ${profile.loyaltyDiscountPercent}% на каждую новую запись',
                      style: textTheme.bodyMedium?.copyWith(
                        color: ApexColors.trackRed.withOpacity(0.95),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
