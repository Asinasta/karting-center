import 'dart:math' as math;

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

  static const aspectRatio = 3 / 2;

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final tier = profile.loyaltyTier!;
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final maxHeight =
            MediaQuery.sizeOf(context).height * maxHeightFraction;
        final height = math.min(width / aspectRatio, maxHeight);

        return ClipRRect(
          borderRadius: BorderRadius.circular(ApexRadius.md),
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  ApexAssets.loyaltyCard(tier),
                  fit: BoxFit.cover,
                  alignment: Alignment.topLeft,
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
      },
    );
  }
}
