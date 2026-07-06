import '../../features/slots/domain/slot_models.dart';
import '../../features/profile/domain/profile_models.dart';

/// Bundled illustration assets for tracks and loyalty.
abstract final class ApexAssets {
  static const trackNovice = 'assets/images/tracks/novice.png';
  static const trackExperienced = 'assets/images/tracks/experienced.png';
  static const loyaltyRegular = 'assets/images/loyalty/regular.png';

  static String? trackMap(TrackConfigType type) {
    return switch (type) {
      TrackConfigType.novice => trackNovice,
      TrackConfigType.experienced => trackExperienced,
    };
  }

  static String loyaltyCard(LoyaltyTier tier) {
    // One card design; tier is shown in overlay text.
    return loyaltyRegular;
  }
}
