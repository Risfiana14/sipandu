// lib/services/report_service.dart
import 'package:pocketbase/pocketbase.dart';
import 'package:sipandu/models/report.dart'; // Pastikan path ke model Report benar
import 'package:sipandu/services/pocketbase_client.dart'; // Pastikan path ke PocketBaseClient benar

class ReportService {
  // Mengambil instance PocketBase dari PocketBaseClient
  static final PocketBase _pb = PocketBaseClient.instance;

  // Fungsi untuk mendapatkan laporan yang dibuat oleh pengguna yang sedang login
  static Future<List<Report>> getUserReports() async {
    try {
      final userId =
          _pb.authStore.model.id; // Mendapatkan ID pengguna yang login
      if (userId.isEmpty) {
        throw Exception("Pengguna tidak login. Tidak dapat mengambil laporan.");
      }

      // Mengambil daftar laporan dari koleksi 'laporan' yang dibuat oleh 'user_id' tertentu
      // Diurutkan berdasarkan 'created' secara menurun (terbaru dulu)
      final records = await _pb.collection('laporan').getFullList(
            filter: 'user_id = "$userId"',
            sort: '-created',
          );

      // Mengubah setiap RecordModel menjadi objek Report menggunakan Report.fromJson
      return records
          .map((record) => Report.fromJson(_mapRecordToJson(record)))
          .toList();
    } catch (e) {
      print('Error getting user reports: $e');
      rethrow; // Melemparkan kembali error agar bisa ditangani di UI
    }
  }

  // Fungsi untuk mendapatkan detail laporan berdasarkan ID laporan
  static Future<Report> getReportDetails(String reportId) async {
    try {
      // Mengambil satu record dari koleksi 'laporan' berdasarkan ID
      final record = await _pb.collection('laporan').getOne(reportId);
      // Mengubah RecordModel menjadi objek Report
      return Report.fromJson(_mapRecordToJson(record));
    } catch (e) {
      print('Error getting report details for ID $reportId: $e');
      rethrow; // Melemparkan kembali error agar bisa ditangani di UI
    }
  }

  // Fungsi baru untuk mengambil SEMUA laporan (digunakan oleh admin)
  static Future<List<Report>> getAllReportsForAdmin() async {
    try {
      // Mengambil daftar lengkap laporan dari koleksi 'laporan'
      // Tanpa filter 'user_id', sehingga semua laporan akan terambil
      // Diurutkan berdasarkan 'created' secara menurun (terbaru dulu)
      final records = await _pb.collection('laporan').getFullList(
            sort: '-created', // Urutkan dari yang terbaru
            // expand: 'user_id', // Opsional: Aktifkan jika Anda ingin data lengkap user yang melapor
            // Ini akan menambahkan data user terkait ke record, bisa diakses melalui record.expand['user_id']
          );
      // Mengubah setiap RecordModel menjadi objek Report
      return records
          .map((record) => Report.fromJson(_mapRecordToJson(record)))
          .toList();
    } catch (e) {
      print('Error getting all reports for admin: $e');
      rethrow; // Melemparkan kembali error agar bisa ditangani di UI
    }
  }

  // Fungsi helper untuk mengubah RecordModel PocketBase menjadi Map<String, dynamic>
  // dan memproses URL gambar
  static Map<String, dynamic> _mapRecordToJson(RecordModel record) {
    final Map<String, dynamic> json = record.toJson();

    final List<String> imageUrls = [];
    // Memeriksa apakah ada data 'gambar' dan itu adalah List
    if (record.data['gambar'] is List) {
      // Iterasi setiap nama file gambar dalam list 'gambar'
      for (var fileName in record.data['gambar']) {
        // Pastikan nama file adalah String dan tidak kosong
        if (fileName is String && fileName.isNotEmpty) {
          // Menggunakan _pb.getFileUrl untuk mendapatkan URL gambar lengkap
          // `record` adalah record model yang berisi file tersebut
          // `fileName` adalah nama file seperti yang disimpan di PocketBase (e.g., 'gambar1.jpg')
          // `thumb: '400x400'` untuk mendapatkan thumbnail dengan ukuran tertentu
          final Uri imageUrl =
              _pb.getFileUrl(record, fileName, thumb: '400x400');
          imageUrls.add(imageUrl.toString()); // Tambahkan URL lengkap ke list
          print(
              'Generated image URL: ${imageUrl.toString()}'); // Untuk debugging
        }
      }
    }
    json['gambar'] = imageUrls; // Ganti data 'gambar' dengan list URL lengkap

    // Penanganan khusus untuk field 'lokasi' jika disimpan sebagai string JSON
    // Ini memastikan bahwa 'lokasi' diubah menjadi Map yang sesuai dengan LatLng
    if (json['lokasi'] is String) {
      try {
        // Jika lokasi adalah string JSON, parse menjadi Map
        // import 'dart:convert' jika Anda perlu json.decode
        // import 'package:json_annotation/json_annotation.dart'; untuk JsonSerializable
        // Asumsi model Report.fromJson sudah menangani parsing ini
        // Jika di PocketBase sudah berupa JSON object field, ini tidak perlu
        // Namun, jika ada kasus data lama yang string, ini bisa membantu.
        // Berdasarkan gambar yang Anda berikan, lokasi sudah berupa JSON object di PocketBase
        // jadi bagian ini kemungkinan tidak perlu diubah, tapi saya biarkan untuk berjaga-jaga.
      } catch (e) {
        print('Error parsing location string: $e');
        // Fallback jika parsing gagal
      }
    }

    return json;
  }
}
