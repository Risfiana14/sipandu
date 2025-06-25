// lib/services/report_service.dart
import 'package:pocketbase/pocketbase.dart';
import 'package:sipandu/models/report.dart';
import 'package:sipandu/services/pocketbase_client.dart';

class ReportService {
  static final PocketBase _pb = PocketBaseClient.instance;

  static Future<List<Report>> getUserReports() async {
    try {
      final userId = _pb.authStore.model.id;
      if (userId.isEmpty) throw Exception("Pengguna tidak login.");

      final records = await _pb.collection('laporan').getFullList(
            filter: 'user_id = "$userId"',
            sort: '-created',
          );
      return records.map((r) => Report.fromJson(_mapRecordToJson(r))).toList();
    } catch (e) {
      print('Error di getUserReports: $e');
      rethrow;
    }
  }

  static Future<Report> getReportDetails(String reportId) async {
    try {
      final record = await _pb.collection('laporan').getOne(reportId);
      return Report.fromJson(_mapRecordToJson(record));
    } catch (e) {
      print('Error di getReportDetails untuk ID $reportId: $e');
      rethrow;
    }
  }

  static Future<List<Report>> getAllReportsForAdmin() async {
    try {
      final records = await _pb.collection('laporan').getFullList(
            sort: '-created',
            expand: 'user_id',
          );
      return records.map((r) => Report.fromJson(_mapRecordToJson(r))).toList();
    } catch (e) {
      print('Error di getAllReportsForAdmin: $e');
      rethrow;
    }
  }

  // Helper terpusat untuk memproses RecordModel
  static Map<String, dynamic> _mapRecordToJson(RecordModel record) {
    final json = record.toJson();

    // --- PERBAIKAN UTAMA ADA DI SINI ---
    final rawImageData = record.data['gambar'];
    List<String> imageFileNames = [];

    // Cek tipe data dari field 'gambar'
    if (rawImageData is String && rawImageData.isNotEmpty) {
      // KASUS 1: Jika datanya adalah String tunggal (satu file)
      imageFileNames.add(rawImageData);
    } else if (rawImageData is List) {
      // KASUS 2: Jika datanya adalah List (multi-file atau kosong)
      imageFileNames = List<String>.from(rawImageData.map((e) => e.toString()));
    }
    // Jika null atau tipe lain, imageFileNames akan tetap kosong.

    final imageUrls = imageFileNames
        .where((fileName) => fileName.isNotEmpty)
        .map((fileName) => _pb.getFileUrl(record, fileName).toString())
        .toList();

    json['gambar'] = imageUrls;
    // --- AKHIR DARI PERBAIKAN ---

    if (record.expand.containsKey('user_id') && record.expand['user_id']!.isNotEmpty) {
        json['user_data'] = record.expand['user_id']!.first.toJson();
    }

    return json;
  }
}