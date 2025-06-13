class UserProfile {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? avatarUrl;
  final String? address;
  final String? dateOfBirth;
  final String? gender;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.avatarUrl,
    this.address,
    this.dateOfBirth,
    this.gender,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      avatarUrl: json['avatar_url'],
      address: json['address'],
      dateOfBirth: json['date_of_birth'],
      gender: json['gender'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'avatar_url': avatarUrl,
      'address': address,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get formattedJoinDate {
    final day = createdAt.day.toString().padLeft(2, '0');
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    final month = months[createdAt.month - 1];
    final year = createdAt.year;
    return '$day $month $year';
  }
}
