// lib/models/report.dart
import 'package:latlong2/latlong.dart';
// import 'package:sipandu/models/user_data.dart'; // Hilangkan komentar jika Anda punya model UserData

// Model sederhana untuk data user yang di-expand
class ReporterData {
  final String id;
  final String name;
  final String email;

  ReporterData({required this.id, required this.name, required this.email});

  factory ReporterData.fromJson(Map<String, dynamic> json) {
    return ReporterData(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Nama Tidak Ada',
      email: json['email'] ?? 'Email Tidak Ada',
    );
  }
}


enum ReportStatus {
  pending,
  inProcess,
  resolved,
  rejected,
  unknown, // Tambahkan status unknown untuk fallback
}

class Report {
  final String id;
  final String userId;
  final String title;
  final String category;
  final String description;
  final List<String> images; // Ini akan berisi FULL URLs dari ReportService
  final LatLng location;
  ReportStatus status;
  final DateTime created;
  final DateTime updated;
  final String? response;
  final ReporterData? reporter; // Opsional: untuk menampung data user dari 'expand'

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
    this.reporter,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    // --- Parsing Lokasi ---
    LatLng parsedLocation;
    final locData = json['lokasi'];
    if (locData is Map && locData['latitude'] != null && locData['longitude'] != null) {
      parsedLocation = LatLng(
        (locData['latitude'] as num).toDouble(),
        (locData['longitude'] as num).toDouble(),
      );
    } else {
      parsedLocation = LatLng(0.0, 0.0); // Fallback location
    }

    return Report(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['judul'] ?? 'Tanpa Judul',
      category: json['kategori'] ?? 'Lainnya',
      description: json['deskripsi'] ?? 'Tidak ada deskripsi.',
      images: List<String>.from(json['gambar'] ?? []), // Langsung cast ke List<String>
      location: parsedLocation,
      status: _parseReportStatus(json['status'] ?? ''),
      created: DateTime.tryParse(json['created'] ?? '') ?? DateTime.now(),
      updated: DateTime.tryParse(json['updated'] ?? '') ?? DateTime.now(),
      response: json['tanggapan'],
      // Jika ada data user dari expand, parse juga
      reporter: json.containsKey('user_data')
          ? ReporterData.fromJson(json['user_data'])
          : null,
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
        return ReportStatus.unknown;
    }
  }

  String get formattedDate {
    // Format tanggal menjadi: 19/6/2025
    return "${created.day}/${created.month}/${created.year}";
  }

  String get address {
    return 'Lat: ${location.latitude.toStringAsFixed(4)}, Lon: ${location.longitude.toStringAsFixed(4)}';
  }
}