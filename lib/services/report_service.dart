import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sipandu/models/report.dart';

class ReportService {
  static const String _reportsStorageKey = 'local_reports';

  // Mendapatkan semua laporan untuk pengguna saat ini (dari penyimpanan lokal)
  static Future<List<Report>> getUserReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = prefs.getStringList(_reportsStorageKey) ?? [];

      if (reportsJson.isEmpty) {
        return [];
      }

      final reports = <Report>[];
      for (var jsonStr in reportsJson) {
        try {
          final jsonMap = json.decode(jsonStr);
          reports.add(Report.fromJson(jsonMap));
        } catch (e) {
          print('Error parsing report: $e');
        }
      }

      return reports;
    } catch (e) {
      print('Error getting reports: $e');
      return [];
    }
  }

  // Mendapatkan semua laporan (admin)
  static Future<List<Report>> getAllReports() async {
    return getUserReports();
  }

  // Membuat laporan baru (simpan ke penyimpanan lokal)
  static Future<Report> createReport({
    required String title,
    required String description,
    required String category,
    required List<io.File> imageFiles,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    const userId = 'local_user';

    List<String> imageBase64List = [];
    for (var image in imageFiles) {
      try {
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        imageBase64List.add(base64String);
      } catch (e) {
        print('Error encoding image: $e');
      }
    }

    final reportId =
        'report_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}';
    final report = Report(
      id: reportId,
      userId: userId,
      title: title,
      description: description,
      category: category,
      images: imageBase64List,
      latitude: latitude,
      longitude: longitude,
      address: address,
      createdAt: DateTime.now(),
      status: ReportStatus.pending,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final existingReportsJson = prefs.getStringList(_reportsStorageKey) ?? [];

      final reportJson = jsonEncode(report.toJson());
      existingReportsJson.add(reportJson);

      await prefs.setStringList(_reportsStorageKey, existingReportsJson);
      return report;
    } catch (e) {
      print('Error saving report: $e');
      throw Exception('Gagal menyimpan laporan: $e');
    }
  }

  // Untuk platform Web
  static Future<Report> createReportWeb({
    required String title,
    required String description,
    required String category,
    required List<String> imageBase64List,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    const userId = 'local_user';

    final reportId =
        'report_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}';
    final report = Report(
      id: reportId,
      userId: userId,
      title: title,
      description: description,
      category: category,
      images: imageBase64List,
      latitude: latitude,
      longitude: longitude,
      address: address,
      createdAt: DateTime.now(),
      status: ReportStatus.pending,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final existingReportsJson = prefs.getStringList(_reportsStorageKey) ?? [];

      final reportJson = jsonEncode(report.toJson());
      existingReportsJson.add(reportJson);

      await prefs.setStringList(_reportsStorageKey, existingReportsJson);
      return report;
    } catch (e) {
      print('Error saving report: $e');
      throw Exception('Gagal menyimpan laporan: $e');
    }
  }

  // Mendapatkan detail laporan
  static Future<Report> getReportDetails(String reportId) async {
    try {
      final reports = await getUserReports();
      final report = reports.firstWhere((r) => r.id == reportId);
      return report;
    } catch (e) {
      print('Error getting report details: $e');
      throw Exception('Laporan tidak ditemukan');
    }
  }

  // Memperbarui status laporan (hanya admin)
  static Future<void> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    String? response,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = prefs.getStringList(_reportsStorageKey) ?? [];

      if (reportsJson.isEmpty) {
        throw Exception('Tidak ada laporan yang tersimpan');
      }

      final updatedReportsJson = <String>[];
      bool found = false;

      for (var jsonStr in reportsJson) {
        final jsonMap = json.decode(jsonStr);
        final report = Report.fromJson(jsonMap);

        if (report.id == reportId) {
          final updatedReport = Report(
            id: report.id,
            userId: report.userId,
            title: report.title,
            description: report.description,
            category: report.category,
            images: report.images,
            latitude: report.latitude,
            longitude: report.longitude,
            address: report.address,
            createdAt: report.createdAt,
            status: status,
            response: response,
          );

          updatedReportsJson.add(jsonEncode(updatedReport.toJson()));
          found = true;
        } else {
          updatedReportsJson.add(jsonStr);
        }
      }

      if (!found) {
        throw Exception('Laporan tidak ditemukan');
      }

      await prefs.setStringList(_reportsStorageKey, updatedReportsJson);
    } catch (e) {
      print('Error updating report status: $e');
      throw Exception('Gagal memperbarui status laporan: $e');
    }
  }

  // Hapus semua laporan (untuk testing)
  static Future<void> clearAllReports() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_reportsStorageKey);
  }
}
