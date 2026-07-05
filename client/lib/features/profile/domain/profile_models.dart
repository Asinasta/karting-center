/// Client profile (`01-analysis/api/profile/models.yaml#Profile`).
class Profile {
  const Profile({
    required this.id,
    required this.name,
    required this.phone,
  });

  factory Profile.fromJson(Map<String, Object?> json) {
    return Profile(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
    );
  }

  final String id;
  final String name;
  final String phone;
}
