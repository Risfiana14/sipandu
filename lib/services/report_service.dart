// lib/services/report_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sipandu/models/report.dart';

class ReportService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Samakan dengan nama koleksi yang sudah dipakai di create_report_screen.dart
  static const String _collection = 'laporan_masyarakat';

  static Future<List<Report>> getUserReports() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null || userId.isEmpty) {
        throw Exception('Pengguna tidak login.');
      }

      final snapshot = await _db
          .collection(_collection)
          .where('user_id', isEqualTo: userId)
          .get();

      final reports =
          snapshot.docs.map((doc) => Report.fromJson(_mapDocToJson(doc))).toList();

      // Urutkan di sisi client (menghindari kebutuhan composite index di Firestore)
      reports.sort((a, b) => b.created.compareTo(a.created));
      return reports;
    } catch (e) {
      print('Error di getUserReports: $e');
      rethrow;
    }
  }

  static Future<Report> getReportDetails(String reportId) async {
    try {
      final doc = await _db.collection(_collection).doc(reportId).get();
      if (!doc.exists) {
        throw Exception('Laporan tidak ditemukan.');
      }
      return Report.fromJson(_mapDocToJson(doc));
    } catch (e) {
      print('Error di getReportDetails untuk ID $reportId: $e');
      rethrow;
    }
  }

  static Future<List<Report>> getAllReportsForAdmin() async {
    try {
      final snapshot = await _db.collection(_collection).get();

      final reports =
          snapshot.docs.map((doc) => Report.fromJson(_mapDocToJson(doc))).toList();

      reports.sort((a, b) => b.created.compareTo(a.created));
      return reports;
    } catch (e) {
      print('Error di getAllReportsForAdmin: $e');
      rethrow;
    }
  }

  // Helper terpusat: mengubah dokumen Firestore menjadi Map
  // yang formatnya sesuai dengan yang dibaca oleh Report.fromJson()
  static Map<String, dynamic> _mapDocToJson(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final json = Map<String, dynamic>.from(data);

    json['id'] = doc.id;

    // create_report_screen.dart menyimpan nama file gambar di field 'gambar_list'
    final rawImageData = data['gambar_list'];
    List<String> imageFileNames = [];
    if (rawImageData is String && rawImageData.isNotEmpty) {
      imageFileNames.add(rawImageData);
    } else if (rawImageData is List) {
      imageFileNames = List<String>.from(rawImageData.map((e) => e.toString()));
    }
    json['gambar'] = imageFileNames;

    // Firestore mengembalikan Timestamp, Report.fromJson butuh String ISO8601
    final createdAt = data['createdAt'];
    json['created'] = createdAt is Timestamp
        ? createdAt.toDate().toIso8601String()
        : DateTime.now().toIso8601String();

    final updatedAt = data['updatedAt'];
    json['updated'] = updatedAt is Timestamp
        ? updatedAt.toDate().toIso8601String()
        : json['created'];

    json['tanggapan'] = data['tanggapan'];

    return json;
  }
}