// lib/models/report.dart
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // DIJAMIN PERLU UNTUK PARSING TIMESTAMP

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
  unknown,
}

class Report {
  final String id;
  final String userId;
  final String title;
  final String category;
  final String description;
  final List<String> images; // Berisi URL penuh hasil konversi
  final LatLng location;
  ReportStatus status;
  final DateTime created;
  final String? response;
  final ReporterData? reporter;

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
    this.response,
    this.reporter,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    // --- 1. Parsing Lokasi ---
    LatLng parsedLocation;
    final locData = json['lokasi'];
    if (locData is Map && locData['latitude'] != null && locData['longitude'] != null) {
      parsedLocation = LatLng(
        (locData['latitude'] as num).toDouble(),
        (locData['longitude'] as num).toDouble(),
      );
    } else {
      parsedLocation = LatLng(0.0, 0.0);
    }

    // --- 2. Parsing & Konversi Gambar ---
    // Mengambil field 'gambar_list' sesuai struktur data di Firestore
    final rawImages = json['gambar_list'] as List<dynamic>? ?? [];
    
    List<String> parsedUrls = rawImages.map((item) {
      String fileName = item.toString().trim();
      
      if (fileName.isEmpty) return '';
      if (fileName.startsWith('http')) return fileName;
      
      // Mengubah nama file mentah menjadi URL valid Firebase Storage
      String bucketName = "sipandu-app.appspot.com"; 
      return "https://firebasestorage.googleapis.com/v0/b/$bucketName/o/${Uri.encodeComponent(fileName)}?alt=media";
    }).where((url) => url.isNotEmpty).toList();

    // --- 3. Parsing Timestamp Firestore ke DateTime ---
    DateTime parsedCreated = DateTime.now();
    if (json['createdAt'] != null) {
      if (json['createdAt'] is Timestamp) {
        parsedCreated = (json['createdAt'] as Timestamp).toDate();
      } else if (json['createdAt'] is String) {
        parsedCreated = DateTime.tryParse(json['createdAt']) ?? DateTime.now();
      }
    }

    return Report(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['judul'] ?? 'Tanpa Judul',
      category: json['kategori'] ?? 'Lainnya',
      description: json['deskripsi'] ?? 'Tidak ada deskripsi.',
      images: parsedUrls, 
      location: parsedLocation,
      status: _parseReportStatus(json['status'] ?? ''),
      created: parsedCreated,
      response: json['tanggapan'],
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
    return "${created.day}/${created.month}/${created.year}";
  }

  String get address {
    return 'Lat: ${location.latitude.toStringAsFixed(4)}, Lon: ${location.longitude.toStringAsFixed(4)}';
  }
}