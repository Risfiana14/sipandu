import 'package:flutter/material.dart';
import '../models/report.dart';

class ReportProvider extends ChangeNotifier {
  final List<Report> _reports = [];

  List<Report> get allReports => _reports;

  void addReport(Report report) {
    _reports.add(report);
    notifyListeners();
  }

  List<Report> getMyReports(String userId) {
    return _reports.where((r) => r.userId == userId).toList();
  }
}
