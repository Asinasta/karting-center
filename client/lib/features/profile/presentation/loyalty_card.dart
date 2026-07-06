import 'package:flutter/material.dart';

import '../../../core/assets/apex_assets.dart';
import '../../../core/theme/apex_tokens.dart';
import '../domain/profile_models.dart';

class LoyaltyCard extends StatelessWidget {
  const LoyaltyCard({
    required this.profile,
    super.key,
  });

  static const _cardHeight = 128.0;

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final tier = profile.loyaltyTier!;
    final textTheme = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(ApexRadius.md),
      child: SizedBox(
        height: _cardHeight,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              ApexAssets.loyaltyCard(tier),
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.55),
                    Colors.black.withOpacity(0.82),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ApexSpacing.md,
                vertical: ApexSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    tier.label,
                    style: textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    profile.name,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Заездов: ${profile.completedRidesCount}'
                    '${profile.loyaltyDiscountPercent != null ? ' · скидка ${profile.loyaltyDiscountPercent}%' : ''}',
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
