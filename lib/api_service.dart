import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Ganti IP untuk emulator Android (10.0.2.2 = localhost)
  static const String baseUrl = "http://127.0.0.1:8000/api";

  // Ambil semua laporan
  static Future<List<dynamic>> getLaporan() async {
    final url = Uri.parse("$baseUrl/laporan");

    final response = await http.get(url, headers: {
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      try {
        final jsonData = jsonDecode(response.body);
        return jsonData['data']; // Sesuaikan dengan response JSON Laravel
      } catch (e) {
        throw Exception("Gagal parsing data: $e");
      }
    } else {
      throw Exception("Gagal load data: ${response.statusCode}");
    }
  }

  // Tambah laporan
  static Future<bool> createLaporan(Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl/laporan");

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return result['success'] == true ||
          result['message'] == 'Laporan berhasil dibuat';
    } else {
      print("Error: ${response.body}");
      return false;
    }
  }
}
