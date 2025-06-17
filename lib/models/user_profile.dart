class UserProfile {
  final String? address;
  final String? avatar;
  final String? email;
  final bool emailVisibility;
  final String? name;
  final int? phone;
  final bool verified;
  final String id;
  final DateTime? created; // Changed to nullable
  final DateTime? updated; // Changed to nullable

  UserProfile({
    this.address,
    this.avatar,
    this.email,
    required this.emailVisibility,
    this.name,
    this.phone,
    required this.verified,
    required this.id,
    this.created,
    this.updated,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      address: json['address'] as String?,
      avatar: json['avatar'] as String?,
      email: json['email'] as String?,
      emailVisibility: json['emailVisibility'] as bool? ?? false,
      name: json['name'] as String?,
      phone: json['phone'] as int?,
      verified: json['verified'] as bool? ?? false,
      id: json['id'] as String,
      created: json['created'] != null
          ? DateTime.parse(json['created'] as String)
          : null,
      updated: json['updated'] != null
          ? DateTime.parse(json['updated'] as String)
          : null,
    );
  }

  String getPhoneAsString() {
    return phone?.toString() ?? 'Belum diatur';
  }
}
