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

  /// Below this card height we use tighter padding and smaller base text.
  static const compactHeightThreshold = 132;

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final tier = profile.loyaltyTier!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final maxHeight =
            MediaQuery.sizeOf(context).height * maxHeightFraction;
        final height = math.min(width / aspectRatio, maxHeight);
        final compact = height < compactHeightThreshold;
        final padding = compact ? ApexSpacing.sm : ApexSpacing.lg;
        final inset = padding * 2;
        final textAreaHeight = math.max(0, height - inset);

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
                Positioned(
                  left: padding,
                  right: padding,
                  bottom: padding,
                  height: textAreaHeight,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.bottomLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: width - inset,
                          maxHeight: textAreaHeight,
                        ),
                        child: _LoyaltyCardText(
                          profile: profile,
                          tier: tier,
                          compact: compact,
                        ),
                      ),
                    ),
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

class _LoyaltyCardText extends StatelessWidget {
  const _LoyaltyCardText({
    required this.profile,
    required this.tier,
    required this.compact,
  });

  final Profile profile;
  final LoyaltyTier tier;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final titleStyle = (compact ? textTheme.titleMedium : textTheme.titleLarge)
        ?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
    );
    final bodyStyle = (compact ? textTheme.bodySmall : textTheme.bodyMedium)
        ?.copyWith(
      color: Colors.white70,
    );
    final discountStyle =
        (compact ? textTheme.bodySmall : textTheme.bodyMedium)?.copyWith(
      color: ApexColors.trackRed.withOpacity(0.95),
      fontWeight: FontWeight.w600,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tier.label,
          style: titleStyle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: compact ? ApexSpacing.xs : ApexSpacing.sm),
        Text(
          'Завершённых заездов: ${profile.completedRidesCount}',
          style: bodyStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (profile.loyaltyDiscountPercent != null) ...[
          SizedBox(height: compact ? ApexSpacing.xs : ApexSpacing.sm),
          Text(
            'Скидка ${profile.loyaltyDiscountPercent}% на каждую новую запись',
            style: discountStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
          ),
        ],
      ],
    );
  }
}
