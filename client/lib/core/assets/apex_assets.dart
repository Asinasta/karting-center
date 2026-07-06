import 'package:flutter/material.dart';

import '../../core/theme/apex_tokens.dart';
import '../../features/slots/domain/slot_models.dart';
import '../../features/profile/domain/profile_models.dart';

/// Bundled illustration assets for tracks and loyalty.
abstract final class ApexAssets {
  static const trackNovice = 'assets/images/tracks/novice.webp';
  static const trackExperienced = 'assets/images/tracks/experienced.webp';
  static const loyaltyRegular = 'assets/images/loyalty/regular.webp';

  static String trackMap(TrackConfigType type) {
    return switch (type) {
      TrackConfigType.novice => trackNovice,
      TrackConfigType.experienced => trackExperienced,
    };
  }

  static Color trackMapBackdrop(TrackConfigType type) {
    return switch (type) {
      TrackConfigType.novice => ApexColors.trackMapBackdropNovice,
      TrackConfigType.experienced => ApexColors.trackMapBackdropExperienced,
    };
  }

  static String loyaltyCard(LoyaltyTier tier) {
    // One card design; tier is shown in overlay text.
    return loyaltyRegular;
  }
}
