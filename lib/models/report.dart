import 'dart:convert';

enum ReportStatus {
  pending,
  inProcess,
  resolved,
  rejected,
}

class Report {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final List<String> images;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime createdAt;
  final ReportStatus status;
  final String? response;

  Report({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.images,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.createdAt,
    required this.status,
    this.response,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    List<String> parseImages(dynamic imagesData) {
      if (imagesData == null) return [];

      if (imagesData is List) {
        return imagesData.map((e) => e.toString()).toList();
      }

      if (imagesData is String) {
        try {
          final decoded = jsonDecode(imagesData);
          if (decoded is List) {
            return decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {}
      }

      return [];
    }

    return Report(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? json['userId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      images: parseImages(json['images']),
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      address: json['address'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : (json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now()),
      status: _parseStatus(json['status']),
      response: json['response'],
    );
  }

  static ReportStatus _parseStatus(dynamic status) {
    if (status == null) return ReportStatus.pending;

    if (status is int && status >= 0 && status < ReportStatus.values.length) {
      return ReportStatus.values[status];
    }

    if (status is String) {
      try {
        return ReportStatus.values.firstWhere(
          (e) =>
              e.toString().split('.').last.toLowerCase() ==
              status.toLowerCase(),
          orElse: () => ReportStatus.pending,
        );
      } catch (_) {}
    }

    return ReportStatus.pending;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'category': category,
      'images': images,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'created_at': createdAt.toIso8601String(),
      'status': status.index,
      'response': response,
    };
  }

  // Implementasi manual format tanggal tanpa menggunakan package intl
  String get formattedDate {
    final day = createdAt.day.toString().padLeft(2, '0');

    // Daftar nama bulan dalam bahasa Indonesia
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
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');

    return '$day $month $year, $hour:$minute';
  }
}
