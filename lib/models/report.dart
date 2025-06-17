// lib/models/report.dart
import 'package:latlong2/latlong.dart';

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
  final String category;
  final String description;
  final List<String> images; // List of FULL URLs
  final LatLng location;
  ReportStatus status; // <--- UBAH INI: Hapus 'final'
  final String created;
  final String updated;
  final String? response;

  Report({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.description,
    required this.images,
    required this.location,
    required this.status,
    required this.created,
    required this.updated,
    this.response,
  });

  // Tambahkan fungsi copyWith untuk kemudahan membuat instance baru dengan perubahan
  Report copyWith({
    String? id,
    String? userId,
    String? title,
    String? category,
    String? description,
    List<String>? images,
    LatLng? location,
    ReportStatus? status,
    String? created,
    String? updated,
    String? response,
  }) {
    return Report(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      images: images ?? this.images,
      location: location ?? this.location,
      status: status ?? this.status,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      response: response ?? this.response,
    );
  }

  factory Report.fromJson(Map<String, dynamic> json) {
    LatLng parsedLocation;
    if (json['lokasi'] != null &&
        json['lokasi'] is Map &&
        json['lokasi']['latitude'] != null &&
        json['lokasi']['longitude'] != null) {
      parsedLocation = LatLng(
        (json['lokasi']['latitude'] as num).toDouble(), // Pastikan double
        (json['lokasi']['longitude'] as num).toDouble(), // Pastikan double
      );
    } else {
      print(
          'Warning: Lokasi tidak valid atau tidak ditemukan. Menggunakan 0,0. Data mentah: ${json['lokasi']}');
      parsedLocation = LatLng(0.0, 0.0);
    }

    return Report(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['judul'] as String,
      category: json['kategori'] as String,
      description: json['deskripsi'] as String,
      images: (json['gambar'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      location: parsedLocation,
      status: _parseReportStatus(json['status'] as String),
      created: json['created'] as String,
      updated: json['updated'] as String,
      response: json['tanggapan'] as String?,
    );
  }

  static ReportStatus _parseReportStatus(String statusString) {
    switch (statusString.toLowerCase()) {
      case 'menunggu':
        return ReportStatus.pending;
      case 'diproses':
        return ReportStatus.inProcess;
      case 'selesai':
        return ReportStatus.resolved;
      case 'ditolak':
        return ReportStatus.rejected;
      default:
        return ReportStatus.pending;
    }
  }

  String get formattedDate {
    final dateTime = DateTime.parse(created).toLocal();
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}";
  }

  String get address {
    return 'Lat: ${location.latitude.toStringAsFixed(4)}, Lon: ${location.longitude.toStringAsFixed(4)}';
  }
}
