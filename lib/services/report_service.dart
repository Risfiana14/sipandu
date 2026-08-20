// lib/services/report_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sipandu/models/report.dart';

class ReportService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _collection = 'laporan_masyarakat';

  // ============================================================
  // MENGAMBIL LAPORAN USER
  // ============================================================

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

      final reports = await Future.wait(
        snapshot.docs.map(
          (doc) async {
            final json = await _mapDocToJson(doc);
            return Report.fromJson(json);
          },
        ),
      );

      reports.sort(
        (a, b) => b.created.compareTo(a.created),
      );

      return reports;
    } catch (e) {
      print('Error di getUserReports: $e');
      rethrow;
    }
  }

  // ============================================================
  // MENGAMBIL DETAIL LAPORAN
  // ============================================================

  static Future<Report> getReportDetails(String reportId) async {
    try {
      final doc = await _db
          .collection(_collection)
          .doc(reportId)
          .get();

      if (!doc.exists) {
        throw Exception('Laporan tidak ditemukan.');
      }

      final json = await _mapDocToJson(doc);

      return Report.fromJson(json);
    } catch (e) {
      print(
        'Error di getReportDetails untuk ID $reportId: $e',
      );
      rethrow;
    }
  }

  // ============================================================
  // MENGAMBIL SEMUA LAPORAN UNTUK ADMIN
  // ============================================================

  static Future<List<Report>> getAllReportsForAdmin() async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .get();

      final reports = await Future.wait(
        snapshot.docs.map(
          (doc) async {
            final json = await _mapDocToJson(doc);
            return Report.fromJson(json);
          },
        ),
      );

      reports.sort(
        (a, b) => b.created.compareTo(a.created),
      );

      return reports;
    } catch (e) {
      print('Error di getAllReportsForAdmin: $e');
      rethrow;
    }
  }

  // ============================================================
  // MENGUBAH DOKUMEN FIRESTORE MENJADI JSON
  // SEKALIGUS MENGAMBIL DATA USER / PELAPOR
  // ============================================================

  static Future<Map<String, dynamic>> _mapDocToJson(
    DocumentSnapshot doc,
  ) async {
    final data =
        doc.data() as Map<String, dynamic>? ?? {};

    final json = Map<String, dynamic>.from(data);

    // ID dokumen laporan
    json['id'] = doc.id;

    // ==========================================================
    // DATA GAMBAR
    // ==========================================================
    //
    // Tetap dibaca supaya tidak merusak data lama.
    // Namun gambar TIDAK akan ditampilkan di Dashboard Admin.
    //

    final rawImageData = data['gambar_list'];

    List<String> imageFileNames = [];

    if (rawImageData is String &&
        rawImageData.isNotEmpty) {
      imageFileNames.add(rawImageData);
    } else if (rawImageData is List) {
      imageFileNames = List<String>.from(
        rawImageData.map(
          (e) => e.toString(),
        ),
      );
    }

    json['gambar'] = imageFileNames;

    // ==========================================================
    // CREATED AT
    // ==========================================================

    final createdAt = data['createdAt'];

    json['created'] = createdAt is Timestamp
        ? createdAt.toDate().toIso8601String()
        : DateTime.now().toIso8601String();

    // ==========================================================
    // UPDATED AT
    // ==========================================================

    final updatedAt = data['updatedAt'];

    json['updated'] = updatedAt is Timestamp
        ? updatedAt.toDate().toIso8601String()
        : json['created'];

    // ==========================================================
    // TANGGAPAN
    // ==========================================================

    json['tanggapan'] = data['tanggapan'];

    // ==========================================================
    // AMBIL DATA PELAPOR DARI COLLECTION USERS
    // ==========================================================

    final userId = data['user_id'];

    if (userId != null &&
        userId.toString().isNotEmpty) {
      try {
        final userDoc = await _db
            .collection('users')
            .doc(userId.toString())
            .get();

        if (userDoc.exists) {
          final userData =
              userDoc.data() as Map<String, dynamic>? ?? {};

          json['user_data'] = {
            'id': userId.toString(),
            'name': userData['name'] ?? 'Nama Tidak Ada',
            'email': userData['email'] ?? 'Email Tidak Ada',
          };
        }
      } catch (e) {
        print(
          'Gagal mengambil data user $userId: $e',
        );
      }
    }

    return json;
  }
}