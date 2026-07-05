/// Client profile (`01-analysis/api/profile/models.yaml#Profile`).
enum LoyaltyTier {
  regular,
  vip;

  static LoyaltyTier? fromJson(String? value) {
    return switch (value) {
      'regular' => LoyaltyTier.regular,
      'vip' => LoyaltyTier.vip,
      _ => null,
    };
  }

  String get label {
    return switch (this) {
      LoyaltyTier.regular => 'Постоянный клиент',
      LoyaltyTier.vip => 'VIP',
    };
  }
}

class Profile {
  const Profile({
    required this.id,
    required this.name,
    required this.phone,
    this.completedRidesCount = 0,
    this.loyaltyTier,
    this.loyaltyDiscountPercent,
  });

  factory Profile.fromJson(Map<String, Object?> json) {
    return Profile(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      completedRidesCount: json['completed_rides_count'] as int? ?? 0,
      loyaltyTier: LoyaltyTier.fromJson(json['loyalty_tier'] as String?),
      loyaltyDiscountPercent: json['loyalty_discount_percent'] as int?,
    );
  }

  final String id;
  final String name;
  final String phone;
  final int completedRidesCount;
  final LoyaltyTier? loyaltyTier;
  final int? loyaltyDiscountPercent;

  bool get hasLoyalty => loyaltyTier != null;
}
